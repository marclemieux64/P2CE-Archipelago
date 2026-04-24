void DeleteEntity(string target, bool create_holo = true, float scale = 0.7f, bool ignore_delay = false) {
    UpdateInternalMapName();
    
    // Safety check for trigger_catapult in specific levels
    if (target == "trigger_catapult") {
        for (uint i = 0; i < scripted_fling_levels.length(); i++) {
            if (scripted_fling_levels[i] == current_map) {
                Msgl("[AP] AngelScript: Not removing trigger_catapult in " + current_map);
                return;
            }
        }
    }

    array<CBaseEntity@> targets = FindEntities(target);

    for (uint i = 0; i < targets.length(); i++) {
        CBaseEntity@ t = targets[i];
        if (t is null) continue;
        
        string classname = t.GetClassname();

        // DELAY LOGIC: For cubes, wait for them to fall/settle before spawning the holo
        if (!ignore_delay && (classname == "prop_weighted_cube" || classname == "prop_monster_box")) {
            string tModel = t.GetModelName();
            string tName = t.GetEntityName();
            
            // SPECIAL CASE: Is this a cube currently inside a dropper?
            // Checking both modern naming ("cube_dropper_box") and underground models!
            if (tName.locate("cube_dropper_box") != uint(-1) || tModel.locate("underground_weighted_cube") != uint(-1)) {
                // Find the instance prefix (e.g. "box_dropper_01-")
                uint dashIdx = tName.locate("-");
                if (dashIdx != uint(-1)) {
                    string prefix = tName.substr(0, int(dashIdx) + 1);
                    
                    // 1. Disable the Spawner and Clip to prevent further drops
                    DisableEntity(prefix + "cube_dropper_spawner");
                    DisableEntity(prefix + "cube_dropper_clip");
                    DisableEntity(prefix + "cube_dropper_trigger");
                    DisableEntity(prefix + "cube_dropper_spawner_rl"); // Relay for underground droppers
                    DisableEntity(prefix + "gel_dropper_spawner_rl"); // Gel version
                    
                    // 2. Determine position 
                    // Nudge it down -350.0 units from the spawner to sit in the glass dome
                    Vector holoPos = t.GetAbsOrigin();
                    holoPos.z -= 350.0f;

                    // 3. Spawn the hologram immediately inside the glass
                    CreateAPHologram(holoPos, QAngle(0, 0, 0), scale, "", "", 4);
                    
                    // 4. Remove the "stuck" cube immediately
                    t.Remove();
                    continue; 
                }
            }

            if (tName == "") {
                // If they don't have a name, give them one so we can target them later
                tName = "ap_cube_delayed_" + i;
                t.KeyValue("targetname", tName);
            }
            string cmd = "ap_finalize_delete " + tName + " " + (create_holo ? "1" : "0") + " " + scale;
            WaitExecute(cmd, 4.0f, "Cube Settlement");
            continue; // Skip immediate deletion
        }

        if (target == "trigger_catapult" || classname == "trigger_catapult") {
            // ... (keep catapult logic)
            bool nearPlate = false;
            CBaseEntity@ plate = null;
            while ((@plate = EntityList().FindByClassname(plate, "prop_dynamic")) !is null) {
                string m = plate.GetModelName();
                if (m == "models/props/faith_plate.mdl" || m == "models/props/faith_plate_128.mdl") {
                    if ((plate.GetAbsOrigin() - t.GetAbsOrigin()).Length() <= 40.0f) {
                        nearPlate = true;
                        break;
                    }
                }
            }
            if (!nearPlate) continue;
        }

        if (create_holo) {
            Vector pos = t.GetAbsOrigin();
            QAngle ang = t.GetAbsAngles();
            
            if (target == "prop_tractor_beam" || classname == "prop_tractor_beam") {
                // Use 95.0f for the perfect gap
                pos = pos + (t.Forward() * 95.0f);
                
                // SYNC ORIENTATION: Apply the same +90 pitch we gave to the frame
                // This makes it match the "luxury" of the ceiling buttons!
                ang.x += 90.0f;
            }
            
            CreateAPHologram(pos, ang, scale, "", "", 4);
        }
        if (target == "prop_tractor_beam" || classname == "prop_tractor_beam" || 
            target == "prop_excursion_funnel" || classname == "prop_excursion_funnel") {
            DisableEntity(target);
            continue;
        }

        t.Remove();
    }
}
