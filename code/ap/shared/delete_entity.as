void DeleteEntity(string target, bool create_holo = true, float scale = 0.7f, bool ignore_delay = false) {
    UpdateInternalMapName();
    
    // 1. Get our targets (The finding logic handles the 'universal monster' complexity)
    Msgl("[AP] DeleteEntity called for: '" + target + "'");
    
    array<CBaseEntity@> targets = FindEntities(target);
    Msgl("[AP] FindEntities returned " + targets.length() + " result(s).");

    for (uint i = 0; i < targets.length(); i++) {
        CBaseEntity@ t = targets[i];
        if (t is null) continue;
        
        string classname = t.GetClassname();
        string tName = t.GetEntityName();
        // Msgl("[AP] Processing deletion for: [" + classname + "] " + tName);

        // Disable blockade teleport on sp_a2_ricochet when deleting lasers
        if (current_map == "sp_a2_ricochet" && (classname == "prop_laser_catcher" || classname == "env_portal_laser")) {
            CBaseEntity@ teleport = EntityList().FindByName(null, "lower_blockade_player_teleport_trigger");
            if (teleport !is null) {
                teleport.FireInput("Disable", Variant(), 0.0f, null, null, 0);
            }
        }

        // Early Faith Plate Proximity Check for trigger_catapult
        if (classname == "trigger_catapult") {
            CBaseEntity@ plate = null;
            bool foundPlate = false;
            while ((@plate = EntityList().FindByClassname(plate, "prop_dynamic")) !is null) {
                if (plate.GetModelName().locate("faith_plate") != uint(-1)) {
                    float dist = (plate.GetAbsOrigin() - t.GetAbsOrigin()).Length();
                    if (dist < 128.0f) {
                        foundPlate = true;
                        break;
                    }
                }
            }
            if (!foundPlate) continue;
        }

        bool shouldSpawnHolo = create_holo;

        if (tName == "cube_platform_bad_landing" || tName == "cube_platform_good_landing" || tName.locate("paint_duct") != uint(-1)) {
            continue; // Skip system-critical or decorative triggers
        }

        // 2. Instant Hologram (Unified Registry) - Spawns only if allowed
        if (shouldSpawnHolo) {
            Vector hPos;
            QAngle hAng;
            int hSkin;
            float hScale;
            GetHologramVisualOverrides(t, hPos, hAng, hSkin, hScale);
            
            string hName = (tName != "") ? (tName + "_" + t.GetEntityIndex() + "_holo") : (classname + "_" + t.GetEntityIndex() + "_holo");
            CreateAPHologram(hPos, hAng, hScale, "", "", hSkin, hName);
        }

        if (classname == "trigger_catapult") {
            t.FireInput("Disable", Variant(), 0.0f, null, null, 0);
            
            // Using original names exclusively to prevent P2CE heap reallocation errors
            
            CBaseEntity@ proxTimer = EntityList().FindByName(null, "ap_cat_timer");
            if (proxTimer is null) {
                @proxTimer = util::CreateEntityByName("logic_timer");
                if (proxTimer !is null) {
                    proxTimer.KeyValue("targetname", "ap_cat_timer");
                    proxTimer.KeyValue("RefireTime", "1.5");
                    proxTimer.Spawn();
                    
                    Variant vProx;
                    vProx.SetString("OnTimer ap_init_cmd:Command:ap_catapult_effect_check:0.0:-1");
                    proxTimer.FireInput("AddOutput", vProx, 0.0f, null, null, 0);
                }
            }

            CBaseEntity@ plate = null;
            while ((@plate = EntityList().FindByClassname(plate, "prop_dynamic")) !is null) {
                if (plate.GetModelName().locate("faith_plate") != uint(-1)) {
                    float dist = (plate.GetAbsOrigin() - t.GetAbsOrigin()).Length();
                    if (dist < 128.0f) {
                        string pName = plate.GetEntityName();
                        if (pName == "") {
                            pName = "ap_faith_plate_" + RandomInt(1000, 9999);
                            plate.KeyValue("targetname", pName);
                        }

                        plate.KeyValue("solid", "2");
                        plate.SetSolid(SOLID_BBOX);
                        plate.SetMoveType(MOVETYPE_PUSH);
                        plate.FireInput("EnableCollision", Variant(), 0.0f, null, null, 0);
                        
                        string uid = "ap_cat_snd_" + pName;
                        CBaseEntity@ snd = EntityList().FindByName(null, uid);
                        if (snd is null) {
                            @snd = util::CreateEntityByName("ambient_generic");
                            if (snd !is null) {
                                snd.KeyValue("targetname", uid);
                                snd.KeyValue("message", "World.RobotNegInteractPitchedUp");
                                snd.KeyValue("spawnflags", "48"); 
                                snd.KeyValue("health", "10"); 
                                snd.SetAbsOrigin(plate.GetAbsOrigin());
                                snd.Spawn();
                            }
                        }

                        string targetUid = "ap_hint_target_" + pName;
                        CBaseEntity@ hintTarget = EntityList().FindByName(null, targetUid);
                        if (hintTarget is null) {
                            @hintTarget = util::CreateEntityByName("info_target_instructor_hint");
                            if (hintTarget !is null) {
                                hintTarget.KeyValue("targetname", targetUid);
                                hintTarget.SetAbsOrigin(plate.GetAbsOrigin());
                                hintTarget.Spawn();
                            }
                        }

                        string hintUid = "ap_hint_" + pName;
                        CBaseEntity@ hint = EntityList().FindByName(null, hintUid);
                        if (hint is null) {
                            @hint = util::CreateEntityByName("env_instructor_hint");
                            if (hint !is null) {
                                hint.KeyValue("targetname", hintUid);
                                hint.KeyValue("hint_target", targetUid);
                                hint.KeyValue("hint_static", "0");
                                hint.KeyValue("hint_caption", "You don't have the Aerial Faith Plates");
                                hint.KeyValue("hint_icon_onscreen", "icon_alert");
                                hint.KeyValue("hint_color", "255 50 50");
                                hint.KeyValue("hint_timeout", "0");
                                hint.Spawn();
                            }
                        }
                        break;
                    }
                }
            }
            
            continue;
        }

        // 4. Final Removal / Disabling
        bool isSprayer = (classname == "info_paint_sprayer" || classname == "paint_sphere" || 
            tName.locate("paint") != uint(-1) || tName.locate("sprayer") != uint(-1));
        
        if (isSprayer) {
            // 1. Change the base property so it doesn't start on its own
            t.KeyValue("start_active", "0");

            // 2. IDENTITY THEFT: Disable associated paint templates so they can't be spawned
            CBaseEntity@ template = null;
            while ((@template = EntityList().FindByClassname(template, "point_template")) !is null) {
                string tempName = template.GetEntityName();
                // Check if it's a paint bomb template (handles global and instanced names like prefix-paint_bomb_template)
                if (tempName.locate("paint_bomb_template") != uint(-1) && tempName.locate("_disabled") == uint(-1)) {
                    template.KeyValue("targetname", tempName + "_disabled");
                    // Msgl("[AP] Disabled point_template: " + tempName);
                }
            }
            
            // 3. Direct AngelScript deactivation
            Variant vEmpty;
            // Stop it instantly...
            t.FireInput("Stop", vEmpty, 0.0f, null, null, 0);
            
            // ...AND apply "this" (the delay) to the Stop input as well!
            // This tells the sprayer to Stop again after 3 seconds, just in case the map tried to turn it back on.
            t.FireInput("Stop", vEmpty, 3.0f, null, null, 0);
            
            // Map-specific fix for sp_a3_speed_flings
            // Disable the timers that constantly try to turn the sprayers back on!
            if (current_map == "sp_a3_speed_flings") {
                CBaseEntity@ bounceTimer = EntityList().FindByName(null, "paint_bounce_timer");
                if (bounceTimer !is null) bounceTimer.FireInput("Disable", vEmpty, 0.0f, null, null, 0);
                
                CBaseEntity@ speedTimer = EntityList().FindByName(null, "paint_speed_timer");
                if (speedTimer !is null) speedTimer.FireInput("Disable", vEmpty, 0.0f, null, null, 0);
            }
            
            // Map-specific fix for sp_a3_portal_intro
            // Lock the pump buttons so the player can't manually start them, and show a hint if they try!
            if (current_map == "sp_a3_portal_intro") {
                string hintName = "ap_paint_hint";
                CBaseEntity@ hint = EntityList().FindByName(null, hintName);
                if (hint is null) {
                    @hint = util::CreateEntityByName("env_instructor_hint");
                    if (hint !is null) {
                        hint.KeyValue("targetname", hintName);
                        hint.KeyValue("hint_caption", "You don't have Paint!");
                        hint.KeyValue("hint_color", "255 50 50");
                        hint.KeyValue("hint_timeout", "3");
                        hint.KeyValue("hint_icon_onscreen", "icon_tip");
                        hint.KeyValue("hint_forcecaption", "1");
                        hint.Spawn();
                    }
                }

                Variant vHook;
                vHook.SetString("OnUseLocked " + hintName + ":ShowHint::0:-1");

                CBaseEntity@ btnBlue = EntityList().FindByName(null, "pump_machine_blue_button");
                if (btnBlue !is null) {
                    btnBlue.FireInput("Lock", vEmpty, 0.0f, null, null, 0);
                    btnBlue.FireInput("AddOutput", vHook, 0.0f, null, null, 0);
                }
                
                // Handling both just in case the trailing underscore you typed was a typo from Hammer!
                CBaseEntity@ btnOrange = EntityList().FindByName(null, "pump_machine_orange_button");
                if (btnOrange !is null) {
                    btnOrange.FireInput("Lock", vEmpty, 0.0f, null, null, 0);
                    btnOrange.FireInput("AddOutput", vHook, 0.0f, null, null, 0);
                }
                CBaseEntity@ btnOrangeTypo = EntityList().FindByName(null, "pump_machine_orange_button_");
                if (btnOrangeTypo !is null) {
                    btnOrangeTypo.FireInput("Lock", vEmpty, 0.0f, null, null, 0);
                    btnOrangeTypo.FireInput("AddOutput", vHook, 0.0f, null, null, 0);
                }
                
                CBaseEntity@ btnWhite = EntityList().FindByName(null, "pump_machine_white_button");
                if (btnWhite !is null) {
                    btnWhite.FireInput("Lock", vEmpty, 0.0f, null, null, 0);
                    btnWhite.FireInput("AddOutput", vHook, 0.0f, null, null, 0);
                }
            }
            
            // 4. Scrub existing gel messes after a safe delay to catch any pre-load spills
            CBaseEntity@ cmd = EntityList().FindByName(null, "ap_init_cmd");
            if (cmd !is null) {
                Variant vRelay;
                vRelay.SetString("removeallpaint");
                // Wait 4.5s to ensure any falling paint blobs hit the ground and explode first
                cmd.FireInput("Command", vRelay, 3.0f, null, null, 0);
            }

            continue; // Keep the entity but stop its flow
        }

        if (classname == "prop_tractor_beam" || classname == "prop_excursion_funnel") {
            DisableEntity(target);
        } else {
            // Map-specific cleanup for the Frankenturret on sp_a4_intro
            if (current_map == "sp_a4_intro" && classname == "prop_monster_box") {
                CBaseEntity@ cubeBot = null;
                // 1. Delete the specific attached model the mapper used for this box
                while ((@cubeBot = EntityList().FindByName(cubeBot, "cube_bot_model")) !is null) {
                    cubeBot.Remove();
                }

                // 2. ONLY hook the dynamic spawner if Archipelago specifically asked us to delete them!
                CBaseEntity@ trigger = EntityList().FindByClassnameNearest("trigger_once", Vector(-816, 64, 320), 10.0f);
                if (trigger !is null) {
                    Variant vOut;
                    // Delete the dynamic box 1s after trigger touch
                    vOut.SetString("OnStartTouch ap_init_cmd:Command:DeleteEntity prop_monster_box 1 0.7:1.0:-1");
                    trigger.FireInput("AddOutput", vOut, 0.0f, null, null, 0);
                }
            }
            
            t.Remove();
        }
    }
}
