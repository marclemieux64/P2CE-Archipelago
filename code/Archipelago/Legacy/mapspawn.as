// =============================================================
// ARCHIPELAGO LEGACY MAPSPAWN (Converted from Squirrel)
// =============================================================

namespace Legacy {

// Helper: Check if item is in array
    bool ItemInList(string item, array<string> list) {
        for (uint i = 0; i < list.length(); i++) {
            if (list[i] == item) return true;
        }
        return false;
    }

    float DegToRad(float degrees) {
        return degrees * (3.14159f / 180.0f);
    }

    Vector AnglesToForward(QAngle angles) {
        Vector forward;
        AngleVectors(angles, forward);
        return forward;
    }

    Vector AnglesToRight(QAngle angles) {
        Vector forward, right, up;
        AngleVectors(angles, forward, right, up);
        return right;
    }

    Vector AnglesToUp(QAngle angles) {
        Vector forward, right, up;
        AngleVectors(angles, forward, right, up);
        return up;
    }

    array<string> scripted_fling_levels = { "sp_a3_03", "sp_a3_bomb_flings", "sp_a3_transition01", "sp_a3_speed_flings", "sp_a3_end", "sp_a4_jump_polarity" };

/**
 * DeleteEntity - Collects targets first to safely iterate and remove.
 */
    void DeleteEntity(string entity_name, bool create_holo = true) {
        if (entity_name == "trigger_catapult" && ItemInList(current_map, scripted_fling_levels)) {
            ArchipelagoLog("not removing trigger_catapult");
            return;
        }

        array<CBaseEntity@> targets = FindEntities(entity_name);
        
        if (targets.length() == 0) {
            ArchipelagoLog("[AP DEBUG] DeleteEntity: No targets found for '" + entity_name + "'");
            return;
        }

        for (uint i = 0; i < targets.length(); i++) {
            CBaseEntity@ ent = targets[i];
            if (ent is null) continue;

            string classname = ent.GetClassname();
            string tName = ent.GetEntityName();
            if (classname == "point_servercommand") continue;
            string model = ent.GetModelName();
            CBaseEntity@ holoSource = ent;

            // SPECIAL CASE: trigger_catapult is a brush (*), so we try to find a nearby physical plate to host the holo
            if (classname == "trigger_catapult" && model.locate("*") == 0) {
                @holoSource = EntityList().FindByClassnameNearest("prop_dynamic", ent.GetAbsOrigin(), 128.0f);
                if (holoSource !is null) {
                    string plateModel = holoSource.GetModelName().tolower();
                    if (plateModel.locate("faith_plate") == uint(-1)) @holoSource = ent; // Revert if not a plate
                } else {
                    @holoSource = ent;
                }
            }

            if (holoSource.GetModelName() == "" || holoSource.GetModelName().locate("*") == 0) {
                if (create_holo) ArchipelagoLog("[AP DEBUG] Skipping hologram for " + entity_name + " (Invisible/Brush entity)");
            } else if (create_holo) {
                Vector hPos;
                QAngle hAng;
                int hSkin;
                float hScale;
                bool hParent;
                bool hAbsolute;
                Legacy::GetHologramVisualOverrides(holoSource, hPos, hAng, hSkin, hScale, hParent, hAbsolute);
                
                string hName = (tName != "") ? (tName + "_holo") : (classname + "_" + ent.GetEntityIndex() + "_holo");
                
                Vector finalPos;
                QAngle finalAng;
                CBaseEntity@ finalParent = hParent ? holoSource : null;

                if (hParent) {
                    finalPos = hPos;
                    finalAng = hAng; // Local space
                } else {
                    finalPos = holoSource.GetAbsOrigin() + (AnglesToForward(holoSource.GetAbsAngles()) * hPos.x) + (AnglesToRight(holoSource.GetAbsAngles()) * -hPos.y) + (AnglesToUp(holoSource.GetAbsAngles()) * hPos.z);
                    finalAng = hAbsolute ? hAng : (holoSource.GetAbsAngles() + hAng);
                }

                Legacy::ArchipelagoLog("Hologram Spawned: " + (hName == "" ? "[UNNAMED]" : hName) + " on " + holoSource.GetClassname() + " (Parented: " + hParent + ")");
                CreateAPHologram(finalPos, finalAng, hScale, finalParent, "", hSkin, hName);
            }

        // 1. EXECUTION RULES
            if (classname == "trigger_catapult") {
                Legacy::HandleFaithPlateLock(ent);
                ent.FireInput("Disable", Variant(), 0.0f, null, null, 0);
            } else if (classname == "npc_portal_turret_floor" || ent.GetModelName().tolower().locate("npcs/turret/turret.mdl") != uint(-1)) {
                DisableEntityPickup(tName != "" ? tName : "turret_ent");
            } else if (classname.locate("core") != uint(-1) || ent.GetModelName().tolower().locate("personality_sphere") != uint(-1)) {
                ent.FireInput("Disable", Variant(), 0.0f, null, null, 0);
                ent.FireInput("DisableDraw", Variant(), 0.0f, null, null, 0);
            } else {
                ent.Remove();
            }
        }
    }

    bool portalgun_2_disabled = false;

    void DisablePortalGun(bool blue, bool orange) {
        if (current_map == "sp_a3_01") {
            EntFire("weapon_portalgun", "AddOutput", "CanFirePortal2 0", 13.0f);
        }

        if (current_map == "sp_a2_intro") {
            portalgun_2_disabled = true;
        }

        if (blue) EntFire("weapon_portalgun", "AddOutput", "CanFirePortal1 0");
        if (orange) EntFire("weapon_portalgun", "AddOutput", "CanFirePortal2 0");
    }

    void DisableEntityPickup(string entity_name) {
        array<CBaseEntity@> targets = FindEntities(entity_name);
        for (uint i = 0; i < targets.length(); i++) {
            targets[i].KeyValue("PickupEnabled", "0");
        }
    }

    void DisableEntityPhysics(string entity_name) {
        array<CBaseEntity@> targets = FindEntities(entity_name);
        for (uint i = 0; i < targets.length(); i++) {
            targets[i].KeyValue("movetype", "4");
        }
    }

    void AddFloorButtonFrame(string entity_name) {
        array<CBaseEntity@> targets = FindEntities(entity_name);
        for (uint i = 0; i < targets.length(); i++) {
            CBaseEntity@ ent = targets[i];
            Vector position = ent.GetAbsOrigin();
            QAngle angles = ent.GetAbsAngles();
            CBaseEntity@ box = util::CreateEntityByName("prop_dynamic");
            if (box !is null) {
                box.KeyValue("targetname", entity_name + "_frame");
                box.KeyValue("model", "models/props/archipelago/ap_floorbuttonframe.mdl");
                box.KeyValue("solid", "6");
                box.SetAbsOrigin(position);
                box.SetAbsAngles(angles);
                box.Spawn();
            }
            string holoName = entity_name + "_" + ent.GetEntityIndex() + "_holo";
            if (EntityList().FindByName(null, holoName) is null) {
                CreateAPHologram(position + Vector(0, 0, 40.0f), angles, 1.0f, null, "", 4, holoName);
            }
        }
    }

    void AddButtonFrame(string entity_name) {
        array<CBaseEntity@> targets = FindEntities(entity_name);
        for (uint i = 0; i < targets.length(); i++) {
            CBaseEntity@ ent = targets[i];
            Vector position = ent.GetAbsOrigin();
            QAngle angles = ent.GetAbsAngles();
        
            CBaseEntity@ box = util::CreateEntityByName("prop_dynamic");
            if (box !is null) {
                box.KeyValue("targetname", entity_name + "_frame");
                box.KeyValue("model", "models/props/archipelago/ap_buttonframe.mdl");
                box.KeyValue("solid", "6");
                box.SetAbsOrigin(position);
                box.SetAbsAngles(angles);
                box.Spawn();
            }

            string model = ent.GetModelName();
            CBaseEntity@ btn = util::CreateEntityByName("prop_dynamic");
            if (btn !is null) {
                btn.KeyValue("model", model);
                btn.SetAbsOrigin(position);
                btn.SetAbsAngles(angles);
                btn.Spawn();
            }
        
            string holoName = entity_name + "_" + ent.GetEntityIndex() + "_holo";
            if (EntityList().FindByName(null, holoName) is null) {
                CreateAPHologram(position + (AnglesToUp(angles) * 60.0f), angles, 0.66f, null, "", 4, holoName);
            }
        }
        DeleteEntity(entity_name, false);
    }

    void DeleteCoreOnOutput(string core_name, string target_name, string output) {
        float delay = 5.0f;
        EntFire(target_name, "AddOutput", output + " InitCmd,Command,DeleteEntity " + core_name + " 0, " + delay + ",-1");
    }

    void BlockWheatleyFight() {
        CBaseEntity@ socket = EntityList().FindByName(null, "breaker_socket_button");
        if (socket !is null) {
            Vector place = socket.GetAbsOrigin();
            CBaseEntity@ target = util::CreateEntityByName("info_target_instructor_hint");
            target.KeyValue("targetname", "hint_target_no_potatos");
            target.SetAbsOrigin(place);
            target.Spawn();
        
            DeleteEntity("breaker_socket_button", false);
            DeleteEntity("breaker_hint", false);
        }

        CBaseEntity@ hint = util::CreateEntityByName("env_instructor_hint");
        hint.KeyValue("targetname", "hudhint_no_potatos");
        hint.KeyValue("hint_target", "hint_target_no_potatos");
        hint.KeyValue("hint_static", "0");
        hint.KeyValue("hint_caption", "PotatOS not unlocked");
        hint.KeyValue("hint_icon_onscreen", "icon_alert");
        hint.KeyValue("hint_color", "255 50 50");
        hint.Spawn();

        SafeAddOutput(EntityList().FindByName(null, "trigger_portal_cleanser"), "OnStartTouch", "hudhint_no_potatos", "ShowHint", "", 0.0f, -1);
    }

    void RemovePotatOS() {
        CBaseEntity@ button = EntityList().FindByName(null, "sphere_entrance_potatos_button");
        if (button !is null) {
            Vector place = button.GetAbsOrigin();
            CBaseEntity@ target = util::CreateEntityByName("info_target_instructor_hint");
            target.KeyValue("targetname", "hint_target_no_potatos");
            target.SetAbsOrigin(place);
            target.Spawn();
        
            DeleteEntity("sphere_entrance_lift_relay", false);
            DeleteEntity("potatos_prop", false);
        }

        CBaseEntity@ hint = util::CreateEntityByName("env_instructor_hint");
        hint.KeyValue("targetname", "hudhint_no_potatos");
        hint.KeyValue("hint_target", "hint_target_no_potatos");
        hint.KeyValue("hint_static", "0");
        hint.KeyValue("hint_caption", "PotatOS not unlocked");
        hint.KeyValue("hint_icon_onscreen", "icon_alert");
        hint.KeyValue("hint_color", "255 50 50");
        hint.Spawn();

        SafeAddOutput(EntityList().FindByName(null, "sphere_entrance_potatos_button"), "OnPressed", "hudhint_no_potatos", "ShowHint", "", 0.0f, -1);
    }

    void DisableTractorBeam(string search_term) {
        array<CBaseEntity@> targets = FindEntities(search_term);
        
        for (uint i = 0; i < targets.length(); i++) {
            CBaseEntity@ target = targets[i];
            if (target is null) continue;
            
            // 1. Primary Disable
            target.FireInput("Disable", Variant(), 0.0f, null, null, 0);
            target.FireInput("Deactivate", Variant(), 0.0f, null, null, 0);
            target.FireInput("TurnOff", Variant(), 0.0f, null, null, 0);
            
            Vector pos = target.GetAbsOrigin();
            Vector totalMins(-16, -16, -16);
            Vector totalMaxs(16, 16, 16);
            bool foundClip = false;
            
            // 2. Positional Sweep (Funnels)
            string cls = target.GetClassname();
            if (cls == "prop_tractor_beam" || cls == "prop_excursion_funnel") {
                CBaseEntity@ nearby = null;
                while ((@nearby = EntityList().FindInSphere(nearby, pos, 64.0f)) !is null) {
                    string nCls = nearby.GetClassname();
                    if (nCls == "light" || nCls == "trigger_player_clip" || nCls == "env_instructor_hint" || 
                        nCls == "func_clip_vphysics" || nCls == "func_brush" || nCls == "trigger_vphysics_motion") {
                        
                        bool isClip = (nCls == "func_clip_vphysics" || nCls == "trigger_player_clip" || nCls == "func_brush");
                        
                        if (isClip) {
                            Vector cMins, cMaxs;
                            nearby.ComputeWorldSpaceSurroundingBox(cMins, cMaxs);
                            
                            cMins = cMins - pos;
                            cMaxs = cMaxs - pos;
                            
                            if (!foundClip) {
                                totalMins = cMins;
                                totalMaxs = cMaxs;
                                foundClip = true;
                            } else {
                                totalMins = totalMins.Min(cMins);
                                totalMaxs = totalMaxs.Max(cMaxs);
                            }
                        }
                        
                        nearby.FireInput("Disable", Variant(), 0.0f, null, null, 0);
                        nearby.FireInput("TurnOff", Variant(), 0.0f, null, null, 0);
                    }
                }
            }

            target.SetSolid(SOLID_BBOX);
            target.SetCollisionBounds(totalMins, totalMaxs);
            target.SetMoveType(MOVETYPE_PUSH);

            // --- PHYSICAL PLUG ---
            CBaseEntity@ frame = util::CreateEntityByName("prop_dynamic");
            if (frame !is null) {
                frame.SetModel("models/props/archipelago/ap_proptractorbeamframe.mdl");
                
                // Nudge the frame forward slightly to prevent clipping
                Vector nudge = target.Forward() * 5.0f;
                frame.SetAbsOrigin(pos + nudge);
                
                QAngle frameAngles = target.GetAbsAngles();
                frameAngles.x += 90.0f;
                frame.SetAbsAngles(frameAngles);
                
                frame.KeyValue("solid", "6");
                frame.KeyValue("modelscale", "1.0");
                frame.KeyValue("disableshadows", "1");
                frame.Spawn();
                
                frame.SetSolid(SOLID_VPHYSICS);
                frame.SetMoveType(MOVETYPE_PUSH);
                frame.FireInput("EnableCollision", Variant(), 0.0f, null, null, 0);
            }
        }
        
        ArchipelagoLog("[Archipelago] Disabled tractor beam: " + search_term);
    }

    void RemovePotatosFromGun() {
        ArchipelagoLog("[AP DEBUG] RemovePotatosFromGun: Executing viewmodel and world cleanup.");
        
        // 1. VIEWMODEL: Force removal via the player proxy
        CBaseEntity@ lpp = EntityList().FindByClassname(null, "logic_playerproxy");
        if (lpp is null) {
            @lpp = util::CreateEntityByName("logic_playerproxy");
            if (lpp !is null) { lpp.KeyValue("targetname", "ap_lpp"); lpp.Spawn(); }
        }
        
        if (lpp !is null) {
            lpp.FireInput("RemovePotatosFromPortalgun", Variant(), 0.0f, null, null, 0);
        }

        // 2. WORLD SPACE: Remove any physical representations
        DeleteEntity("potatos_prop", false);
        DeleteEntity("potatos", false);
        DeleteEntity("models/props/potatos.mdl", false);
        
        // 3. VOICE & UI: Silence audio group and subtitles via mixer
        CBaseEntity@ cmd = EntityList().FindByName(null, "InitCmd");
        if (cmd !is null) {
            Variant vMix;
            vMix.SetString("snd_setmixer potatosVO vol 0.0");
            cmd.FireInput("Command", vMix, 0.0f, null, null, 0);
            
            Variant vCapt;
            vCapt.SetString("script MutePotatOSSubtitles(true)");
            cmd.FireInput("Command", vCapt, 0.1f, null, null, 0);

            Variant vStopShock;
            vStopShock.SetString("stopsound playonce/scripted_sequence/glados_potados_shock.wav");
            cmd.FireInput("Command", vStopShock, 0.0f, null, null, 0);
        }
        ArchipelagoLog("[AP DEBUG] RemovePotatosFromGun: Done (Visuals, Mixer & Subtitles silenced).");
    }

    void CreateAPButton(string name, Vector position, QAngle angle, float holo_scale, int skin = 0) {
        string scenarioName = TranslateButtonName(name);

    // 0. CLEANUP & IDEMPOTENCY
        CBaseEntity@ entCheck = null;
        while ((@entCheck = EntityList().FindInSphere(entCheck, position, 24.0f)) !is null) {
            string cls = entCheck.GetClassname();
            string entName = entCheck.GetEntityName();
            if (entName == scenarioName + "_model" || entName.locate("ap_") == 0) return;
            if (cls.locate("button") != uint(-1) || cls.locate("switch") != uint(-1) || cls.locate("dynamic") != uint(-1)) entCheck.Remove();
        }

        string uid = "ap_" + RandomInt(1000, 9999);
        CBaseEntity@ body = util::CreateEntityByName("prop_dynamic");
        if (body !is null) {
            body.KeyValue("targetname", scenarioName + "_model");
            body.SetModel("models/props/switch001.mdl");
            body.SetAbsOrigin(position);
            body.SetAbsAngles(angle);
            body.Spawn();
        }

        CBaseEntity@ snd_dn = util::CreateEntityByName("ambient_generic");
        if (snd_dn !is null) {
            snd_dn.KeyValue("targetname", uid + "_dn");
            snd_dn.KeyValue("message", "Portal.button_down");
            snd_dn.KeyValue("spawnflags", "48"); 
            snd_dn.SetAbsOrigin(position);
            snd_dn.Spawn();
            snd_dn.SetParent(body);
        }

        CBaseEntity@ snd_up = util::CreateEntityByName("ambient_generic");
        if (snd_up !is null) {
            snd_up.KeyValue("targetname", uid + "_up");
            snd_up.KeyValue("message", "Portal.button_up");
            snd_up.KeyValue("spawnflags", "48"); 
            snd_up.SetAbsOrigin(position);
            snd_up.Spawn();
            snd_up.SetParent(body);
        }

        CBaseEntity@ brain = util::CreateEntityByName("func_rot_button");
        if (brain !is null) {
            brain.KeyValue("targetname", scenarioName);
            brain.KeyValue("spawnflags", "1025");
            brain.KeyValue("wait", "0.5");
        
            SafeAddOutput(brain, "OnPressed", "InitCmd", "Command", "ReportAPButton " + scenarioName, 0.1f, -1);
            SafeAddOutput(brain, "OnPressed", "!parent", "SetAnimation", "down", 0.0f, -1);
            SafeAddOutput(brain, "OnPressed", "!parent", "SetAnimation", "up", 0.5f, -1);
            SafeAddOutput(brain, "OnPressed", uid + "_dn", "PlaySound", "", 0.0f, -1);
            SafeAddOutput(brain, "OnPressed", uid + "_up", "PlaySound", "", 0.5f, -1);
        
            brain.Spawn();
            brain.SetParent(body);
            brain.SetLocalOrigin(Vector(0, 0, 40)); 
        }

        CreateAPHologram(position + (Vector(0, 0, 75.0f) * holo_scale), angle + QAngle(0, 90, 0), holo_scale, body, "", skin, name);
    }

    void CreateAPHologram(Vector position, QAngle angle, float scale, CBaseEntity@ parent = null, string attachment = "", int skin = 0, string name = "", bool animate = true) {
        if (name != "" && EntityList().FindByName(null, name) !is null) return; // Already exists

        if (parent !is null) {
            string pCls = parent.GetClassname();
            if (name == "" && (pCls == "point_servercommand" || pCls.locate("logic_") == 0 || pCls.locate("info_") == 0 || pCls.locate("func_instance") == 0)) {
                ArchipelagoLog("[AP DEBUG] Rejected hologram on logic infrastructure: " + pCls);
                return; // Don't spawn unnamed holograms on logic infrastructure
            }
        } else if (position.Length() < 0.1f) {
            ArchipelagoLog("[AP DEBUG] Rejected hologram at (0,0,0) without parent.");
            return; 
        }

        CBaseEntity@ holo = util::CreateEntityByName("prop_dynamic");
        if (holo !is null) {
            string hName = name;
            if (hName == "") {
                if (parent !is null) {
                    string pName = parent.GetEntityName();
                    if (pName != "") hName = pName + "_holo"; else hName = parent.GetClassname() + "_" + parent.GetEntityIndex() + "_holo";
                } else {
                    hName = "unparented_holo_" + holo.GetEntityIndex();
                }
            }
            hName = hName.replace("@", "");

            holo.SetModel("models/effects/ap/archipelago_hologram.mdl");
            holo.KeyValue("solid", "0");
            holo.KeyValue("skin", "" + skin);
            holo.KeyValue("modelscale", "" + scale);
            hName = hName.replace("@", "");
            if (hName != "") holo.KeyValue("targetname", hName);
            holo.Spawn();

            // Force visibility and animation
            holo.FireInput("EnableDraw", Variant(), 0.0f, null, null, 0);
            if (animate) {
                Variant vSeq;
                vSeq.SetString("idle");
                holo.FireInput("SetAnimation", vSeq, 0.1f, null, null, 0);
            }

            // Debug logging to track stray holograms
            Legacy::ArchipelagoLog("Hologram Spawned: " + (hName == "" ? "[UNNAMED]" : hName) + " at " + position.x + "," + position.y + "," + position.z);
        
            if (parent !is null) {
                holo.SetParent(parent);
                holo.SetLocalOrigin(position);
                holo.SetLocalAngles(angle);
                if (attachment != "") {
                    Variant vAttach;
                    vAttach.SetString(attachment);
                    holo.FireInput("SetParentAttachmentMaintainOffset", vAttach, 0.0f, null, null, 0);
                }
            } else {
                holo.SetAbsOrigin(position);
                holo.SetAbsAngles(angle);
            }
        
            holo.Spawn();
        
            if (animate) {
                Variant vAnim;
                vAnim.SetString("idle");
                holo.FireInput("SetAnimation", vAnim, 0.0f, null, null, 0);
            }
        }
    }

    void AttachHologramToEntity(string entity_name, string attachment_point, float holo_scale, float offset, int skin = 0) {
        array<CBaseEntity@> targets = FindEntities(entity_name);
        for (uint i = 0; i < targets.length(); i++) {
            CBaseEntity@ ent = targets[i];
            
            Vector hPos;
            QAngle hAng;
            int hSkin = 0;
            float hScale = 1.0f;
            bool hParent = true;
            bool hAbsolute = false;
            
            Legacy::GetHologramVisualOverrides(ent, hPos, hAng, hSkin, hScale, hParent, hAbsolute);
            
            // Use provided defaults if overrides are zero/empty
            if (hSkin == 0) hSkin = skin;
            if (hScale == 1.0f) hScale = holo_scale;
            
            string name = entity_name + "_" + i;
            ent.KeyValue("targetname", name);
            
            if (hAbsolute) {
                // World aligned, no parent
                Vector worldPos = ent.GetAbsOrigin() + (AnglesToForward(ent.GetAbsAngles()) * (hPos.x + offset)) + (AnglesToRight(ent.GetAbsAngles()) * hPos.y) + (AnglesToUp(ent.GetAbsAngles()) * hPos.z);
                CreateAPHologram(worldPos, hAng, hScale, null, "", hSkin, "");
            } else {
                // Parented
                CreateAPHologram(hPos + Vector(offset, 0, 0), hAng, hScale, ent, attachment_point, hSkin, "");
            }
        }
    }

    void PrintMapName() {
        ArchipelagoLog("map_name:" + current_map);
    }

// --- MAP COMPLETION CHAIN ---

    void PrintMapCompleteNoExit() {
        if (g_has_printed_map_complete) return;
        g_has_printed_map_complete = true;

        UpdateInternalMapName();
        ArchipelagoLog("map_complete:" + current_map);

        if (current_map == "sp_a4_finale4") return;

        CBasePlayer@ player = GetPlayer();
        if (player !is null) {
            Variant v;
            player.FireInput("Disable", v, 0.0f, null, null, 0);
        }
    
        SendToConsole("fadeout 0.2");
    }

    void WaitExecute(string command, float delay, string timerName = "") {
        CBaseEntity@ cmdEnt = EntityList().FindByName(null, "InitCmd");
        if (cmdEnt !is null) {
            Variant v;
            v.SetString(command);
            cmdEnt.FireInput("Command", v, delay, null, null, 0);
            ArchipelagoLog("Scheduled command in " + delay + "s: " + command);
        }
    }

    void PrintMapComplete() {
        if (transition_script_count > 0) {
            transition_script_count--;
            return;
        }
        PrintMapCompleteNoExit();
        WaitExecute("WarpToMenu", 2.0f, "return_to_menu");
    }

    void WarpToMenu() {
        UpdateInternalMapName();
        CallVScript("SendToPanorama(\"Archipelago_WarpToMenu\", \"" + current_map + "\")");
    }

    void CreateCompleteLevelAlertHook(string map) {
        g_has_printed_map_complete = false;
        if (two_trigger_levels.find(map) >= 0) transition_script_count = 1;

    // Standard hooks for non-elevator maps
        if (non_elevator_maps.find(map) >= 0) {
            array<CBaseEntity@> logicScripts = FindEntities("@transition_script");
            for (uint i = 0; i < logicScripts.length(); i++) logicScripts[i].Remove();

            array<string> targets = { "transition_trigger", "trigger_transition", "@transition_from_map", "relay_transition", "ending_relay" };
            for (uint s = 0; s < targets.length(); s++) {
                array<CBaseEntity@> ents = FindEntities(targets[s]);
                for (uint i = 0; i < ents.length(); i++) {
                    SafeAddOutput(ents[i], "OnStartTouch", "InitCmd", "Command", "FinishedMap", 0.0f, -1);
                    SafeAddOutput(ents[i], "OnTrigger", "InitCmd", "Command", "FinishedMap", 0.0f, -1);
                }
            }
        } else {
            array<CBaseEntity@> cls = FindEntities("@transition_from_map");
            for (uint i = 0; i < cls.length(); i++) {
                SafeAddOutput(cls[i], "OnTrigger", "InitCmd", "Command", "FinishedMap", 0.0f, -1);
            }
            DeleteEntity("@exit_teleport", false);
        }
    }

    void DoMapSpecificSetup() {
        if (current_map == "sp_a1_intro3") {
            SafeAddOutput(EntityList().FindByName(null, "portalgun_pickup_trigger"), "OnStartTouch", "InitCmd", "Command", "PrintItem Portal.Gun", 0.0f, -1);
        } else if (current_map == "sp_a2_intro") {
            SafeAddOutput(EntityList().FindByName(null, "player_near_portalgun"), "OnStartTouch", "InitCmd", "Command", "PrintItem Upgraded.Portal.Gun", 0.0f, -1);
        } else if (current_map == "sp_a3_transition01") {
            SafeAddOutput(EntityList().FindByName(null, "sphere_entrance_potatos_button"), "OnPressed", "InitCmd", "Command", "PrintItem PotatOS", 0.0f, -1);
        }
    }

    void CreateMapSpecificHolos() {
        if (current_map == "sp_a1_intro3") CreateAPHologram(Vector(25, 1958, -299), QAngle(0, 0, 0), 0.66f, null, "", 0, "intro3_portalgun_holo"); else if (current_map == "sp_a2_intro") {
            CBaseEntity@ gun = EntityList().FindByName(null, "player_near_portalgun");
            if (gun !is null) CreateAPHologram(gun.GetAbsOrigin(), QAngle(0, 0, 0), 0.66f, null, "", 0, "a2_intro_gun_holo");
        } else if (current_map == "sp_a3_transition01") {
            CBaseEntity@ btn = EntityList().FindByName(null, "sphere_entrance_potatos_button");
            if (btn !is null) CreateAPHologram(btn.GetAbsOrigin(), QAngle(0, 0, 0), 0.66f, null, "", 0, "a3_potatos_button_holo");
        }
    
        AddMapCheck();
        AddVitrifiedDoorChecks(current_map);
        AddWheatleyMonitorChecks(current_map);
    }

    void AddVitrifiedDoorChecks(string map_name) {
        InitLocationRegistries();
    
        array<string>@ keys = g_vitrified_door_names.getKeys();
        for (uint i = 0; i < keys.length(); i++) {
            string key = keys[i];
            if (key.locate(map_name + ":") == 0) {
                string entName = key.substr(map_name.length() + 1);
                string checkName;
                g_vitrified_door_names.get(key, checkName);
            
                CBaseEntity@ ent = EntityList().FindByName(null, entName);
                if (ent !is null) {
                // 1. LOGIC HOOK
                    int doorIndex = 0;
                    if (checkName.locate("Vitrified Door 2") != uint(-1) || entName.locate("button2") != uint(-1)) doorIndex = 2; else if (checkName.locate("Vitrified Door 3") != uint(-1) || entName.locate("button3") != uint(-1)) doorIndex = 3; else if (checkName.locate("Vitrified Door 1") != uint(-1) || entName.locate("button") != uint(-1)) doorIndex = 1; else if (checkName.locate("Vitrified Door 4") != uint(-1)) doorIndex = 4; else if (checkName.locate("Vitrified Door 5") != uint(-1)) doorIndex = 5; else if (checkName.locate("Vitrified Door 6") != uint(-1)) doorIndex = 6;

                    SafeAddOutput(ent, "OnPressed", "InitCmd", "Command", "PrintItem " + checkName, 0.0f, 1);
                
                    if (doorIndex > 0) {
                        SafeAddOutput(ent, "OnPressed", "InitCmd", "Command", "ArchipelagoVitrifiedFound " + doorIndex, 0.0f, 1);
                    }
                    SafeAddOutput(ent, "OnPressed", entName + "_holo", "Skin", "4", 0.0f, 1);
                
                // 3. VISUALS (Local-space via Overrides)
                    Vector hPos(0, 0, 0);
                    QAngle hAng(0, 0, 0);
                    int hSkin = 0;
                    float hScale = 1.0f;
                    bool hParent = true;
                    bool hAbs = false;
                    Legacy::GetHologramVisualOverrides(ent, hPos, hAng, hSkin, hScale, hParent, hAbs);

                    // Check local save state for skin override
                    string bitmask = cv_ArchipelagoVitrifiedStatus.GetString();
                    if (doorIndex > 0 && bitmask.length() >= uint(doorIndex) && bitmask.substr(doorIndex - 1, 1) == "1") {
                        hSkin = 4;
                    }

                    Vector finalPos;
                    QAngle finalAng;
                    CBaseEntity@ finalParent = hParent ? ent : null;

                    if (hParent) {
                        finalPos = hPos;
                        finalAng = hAng; // Local space
                    } else {
                        finalPos = ent.GetAbsOrigin() + (AnglesToForward(ent.GetAbsAngles()) * hPos.x) + (AnglesToRight(ent.GetAbsAngles()) * -hPos.y) + (AnglesToUp(ent.GetAbsAngles()) * hPos.z);
                        finalAng = hAbs ? hAng : (ent.GetAbsAngles() + hAng);
                    }

                    CreateAPHologram(finalPos, finalAng, hScale, finalParent, "", hSkin, entName + "_holo", false);
                }
            }
        }
    }

    void AddWheatleyMonitorChecks(string map_name) {
        InitWheatleyMonitorRegistry();
    
        array<string>@ keys = g_monitor_break_names.getKeys();
        for (uint i = 0; i < keys.length(); i++) {
            string key = keys[i];
            if (key.locate(map_name + ":") == 0) {
                string entName = key.substr(map_name.length() + 1);
                string locationID;
                g_monitor_break_names.get(key, locationID);
            
                CBaseEntity@ ent = EntityList().FindByName(null, entName);
                if (ent !is null) {
                    string cls = ent.GetClassname();
                    string output = "OnTrigger";
                    if (cls == "func_breakable") output = "OnBreak"; else if (cls.locate("trigger") != uint(-1)) output = "OnStartTouch";
                
                    string safe_id = locationID.replace(" ", ".");
                    SafeAddOutput(ent, output, "InitCmd", "Command", "PrintMonitor " + safe_id, 0.0f, 1);

                // Visuals (Anchor directly to the trigger entity from the registry)
                    CBaseEntity@ anchor = ent;

                    Vector hPos(0, 0, 0);
                    QAngle hAng(0, 0, 0);
                    int hSkin = 4;
                    float hScale = 0.7f;
                    bool hParent = true;
                    bool hAbs = false;
                    Legacy::GetHologramVisualOverrides(anchor, hPos, hAng, hSkin, hScale, hParent, hAbs);
                    
                    Vector finalPos;
                    QAngle finalAng;
                    CBaseEntity@ finalParent = hParent ? anchor : null;

                    if (hParent) {
                        finalPos = hPos;
                        finalAng = hAng; // Local space
                    } else {
                        finalPos = anchor.GetAbsOrigin() + (AnglesToForward(anchor.GetAbsAngles()) * hPos.x) + (AnglesToRight(anchor.GetAbsAngles()) * -hPos.y) + (AnglesToUp(anchor.GetAbsAngles()) * hPos.z);
                        finalAng = hAbs ? hAng : (anchor.GetAbsAngles() + hAng);
                    }

                    ArchipelagoLog("Monitor Hologram Spawned on " + anchor.GetClassname() + " (Skin: " + hSkin + ") Model: " + anchor.GetModelName());
                    CreateAPHologram(finalPos, finalAng, hScale, finalParent, "", hSkin, entName + "_holo");
                }
            }
        }
    }
    void AddToTextQueue(string text, string color = "") { }

} // namespace Legacy
