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
        Msgl("[AP] Processing deletion for: [" + classname + "] " + tName);

        if (tName == "cube_platform_bad_landing" || tName == "cube_platform_good_landing" || tName.locate("paint_duct") != uint(-1)) {
            continue; // Skip system-critical or decorative triggers
        }

        // Check if map is in the scripted fling protection list
        bool isProtectedMap = false;
        for (uint j = 0; j < scripted_fling_levels.length(); j++) {
            if (current_map == scripted_fling_levels[j]) {
                isProtectedMap = true;
                break;
            }
        }
        
        // Special Rule: We never want holograms for catapults (user request for clean visuals)
        bool shouldSpawnHolo = create_holo;
        if (classname == "trigger_catapult") {
            shouldSpawnHolo = false;
        }

        if (classname == "trigger_catapult" && isProtectedMap) {
            Msgl("[AP] BLOCKED Deletion of protected catapult '" + tName + "' on " + current_map);
            // On these maps, we KEEP the catapult and spawn NO holo.
            shouldSpawnHolo = false; 
        }

        // 2. Instant Hologram (Unified Registry) - Spawns only if allowed
        if (shouldSpawnHolo) {
            Vector hPos;
            QAngle hAng;
            int hSkin;
            float hScale;
            GetHologramVisualOverrides(t, hPos, hAng, hSkin, hScale);
            
            string hName = (tName != "") ? (tName + "_holo") : (classname + "_holo");
            CreateAPHologram(hPos, hAng, hScale, "", "", hSkin, hName);
        }

        // 3. Skip removal logic for protected maps
        if (classname == "trigger_catapult" && isProtectedMap) {
            continue; 
        }

        // 4. Removal (With Faith Plate Proximity Check)
        if (classname == "trigger_catapult") {
            CBaseEntity@ plate = null;
            bool foundPlate = false;
            
            // Search through dynamics for faith plates
            while ((@plate = EntityList().FindByClassname(plate, "prop_dynamic")) !is null) {
                if (plate.GetModelName().locate("faith_plate") != uint(-1)) {
                    // Manual distance check (within 64 units)
                    float dist = (plate.GetAbsOrigin() - t.GetAbsOrigin()).Length();
                    if (dist < 64.0f) {
                        foundPlate = true;
                        break;
                    }
                }
            }
            
            if (!foundPlate) {
                Msgl("[AP] SKIPPING invisible catapult deletion (no faith plate nearby)");
                continue; 
            }
        }

        // 4. Final Removal / Disabling
        bool isSprayer = (classname == "info_paint_sprayer" || classname == "paint_sphere" || 
                          tName.locate("paint") != uint(-1) || tName.locate("sprayer") != uint(-1));
        
        if (isSprayer) {
            // IDENTITY THEFT: Rename the entity so map-based loops targeting the original name fail!
            string originalName = tName;
            string newName = "ap_dead_sprayer_" + t.GetEntityIndex();
            
            // Apply the new identity
            t.KeyValue("targetname", newName);
            
            // Register for recurring global suppression (heartbeat loop)
            g_suppressed_entities.insertLast(newName);

            // Force deactivation on the NEW name via engine command relay
            CBaseEntity@ cmd = EntityList().FindByName(null, "ap_init_cmd");
            if (cmd !is null) {
                Variant vRelay;
                vRelay.SetString("ent_fire " + newName + " Stop");
                // Postpone deactivation to allow map sequence stability
                cmd.FireInput("Command", vRelay, 0.5f, null, null, 0);

                // Scrub existing gel messes after a safe delay to catch all initial flow
                vRelay.SetString("removeallpaint");
                cmd.FireInput("Command", vRelay, 1.0f, null, null, 0);
            }

            continue; // Keep the entity but orphan its map connections
        }

        if (classname == "prop_tractor_beam" || classname == "prop_excursion_funnel") {
            DisableEntity(target);
        } else {
            t.Remove();
        }
    }
}
