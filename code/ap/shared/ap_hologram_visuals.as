// =============================================================
// ARCHIPELAGO HOLOGRAM VISUAL REGISTRY
// =============================================================

void GetHologramVisualOverrides(CBaseEntity@ ent, Vector&out targetPos, QAngle&out targetAng, int&out targetSkin, float&out targetScale) {
    if (ent is null) return;

    string classname = ent.GetClassname();
    string model = ent.GetModelName();
    string name = ent.GetEntityName();
    
    // Default values
    targetPos = ent.GetAbsOrigin();
    targetAng = ent.GetAbsAngles();
    targetSkin = 0; 
    targetScale = 1.0f;

    // 1. MAP-SPECIFIC OVERRIDES
    if (current_map == "sp_a1_intro1") {
        if (name.locate("dropper") != uint(-1) || model.locate("dropper") != uint(-1) || classname == "env_entity_maker") {
            targetPos = ent.GetAbsOrigin() + (ent.Up() * -175.0f);
            targetSkin = 4;
            return;
        }
    }

    if (current_map == "sp_a3_crazy_box") {
        if (classname == "prop_under_button") {
            // Nudge out from the front of the box AND up slightly
            targetPos = ent.GetAbsOrigin() + (ent.Forward() * 45.0f) + (ent.Up() * 25.0f);
            // Face outward
            targetAng = ent.GetAbsAngles();
            targetAng.x += 90.0f; 
            targetSkin = 4;
            return;
        }
    }

    // 2. WHEATLEY MONITORS
    if (model.locate("wheatley_monitor") != uint(-1) || name.locate("monitor") != uint(-1) || name.locate("tv_crack") != uint(-1)) {
        targetPos = ent.GetAbsOrigin() + (ent.Up() * 140.0f) + (ent.Left() * 40.0f);
        targetAng = ent.GetAbsAngles(); 
        targetScale = 0.9f;
        return;
    }

    // 3. CUBE DROPPERS (item_dropper.mdl / env_entity_maker)
    bool isDropper = (name.locate("dropper") != uint(-1) || model.locate("dropper") != uint(-1) || classname == "env_entity_maker");
    
    // EXCLUSION: Ignore technical brushes/triggers that might have 'dropper' in name
    if (classname.locate("func_") == 0 || classname.locate("trigger_") == 0) {
        isDropper = false;
    }

    // EXCLUSION: Only standalone buttons/cubes are excluded. If it has "dropper" in name, it counts.
    if (!isDropper && (classname.locate("cube") != uint(-1) || classname.locate("button") != uint(-1))) {
        // already false
    } else if (isDropper) {
        targetSkin = 4;
        
        bool isUnderground = (model.locate("underground") != uint(-1) || current_map.locate("sp_a3_") == 0);
        float zOffset = isUnderground ? -130.0f : -420.0f;
        
        // env_entity_maker is usually placed at the mouth already
        if (classname == "env_entity_maker") {
            zOffset = -24.0f; 
        }

        // 1. Calculate base position with vertical nudge
        targetPos = ent.GetAbsOrigin() + (ent.Up() * zOffset);

        // 2. INSTANCE ALIGNMENT: Find any maker that starts with our instance prefix
        uint dashIdx = name.locate("-");
        if (dashIdx != uint(-1)) {
            string prefix = name.substr(0, int(dashIdx));
            CBaseEntity@ maker = null;
            Msgl("[AP-DEBUG] Searching for maker with prefix: " + prefix);
            while ((@maker = EntityList().FindByClassname(maker, "env_entity_maker")) !is null) {
                string mName = maker.GetEntityName();
                Msgl("  > Found maker in map: " + mName);
                if (mName.locate(prefix) != uint(-1) && mName.locate("spawner") != uint(-1)) {
                    // Found a maker for this instance! Use its center as base
                    Vector makerPos = maker.GetAbsOrigin();
                    targetPos = makerPos + (ent.Up() * zOffset); 
                    
                    // Fine-tune underground maker centering (trap-style droppers)
                    if (isUnderground) {
                        targetPos.x += -0.625f;
                        targetPos.y += 0.0f;
                        targetPos.z = makerPos.z + -70.0f; // Force specific Z for traps
                    }
                    break;
                }
            }
        }
        
        targetAng = ent.GetAbsAngles();
        targetAng.z = 0.0f; // Zero out roll (no sideways tilt)
        
        // Finalize pitch for upright/flat logo
        if (isUnderground) {
            targetAng.x = 180.0f; // Face "Up" out of the pit/tube
        } else {
            targetAng.x = 0.0f; // Standard floor/ceiling flat
        }

        // Msgl("[AP-DEBUG] Dropper: " + name + " Model: " + model + " Cls: " + classname);
        return;
    }

    // 4. PAINT SPRAYERS / GEL BOMBS / PAINT SPHERES
    bool isSprayer = (classname == "info_paint_sprayer" || classname == "paint_sphere" || 
        name.locate("paint") != uint(-1) || name.locate("sprayer") != uint(-1));

    if (isSprayer) {
        bool isNozzle = (classname == "info_paint_sprayer" || classname == "paint_sphere");
        targetSkin = 4;
        if (isNozzle) {
            targetPos = ent.GetAbsOrigin() + (ent.Forward() * 48.0f); 
        } else {
            targetPos = ent.GetAbsOrigin() + (ent.Up() * 24.0f);
        }
        targetAng = ent.GetAbsAngles();
        
// Exceptional orientation for sp_a3_portal_intro
        if (current_map == "sp_a3_portal_intro" && name.locate("paint_sprayer_2") != uint(-1)) {
    
    // --- 1. BASE POSITION (The nozzle center) ---
            Vector basePos(287.0f, 192.0f, 292.0f);
    
    // --- 2. YOUR MANUAL OFFSETS ---
    // Adjust these numbers to nudge the hologram exactly where you want it.
            float offsetX = -80.0f; // Positive = Further into wall | Negative = Out toward player
            float offsetY = 0.0f; // Positive = Right | Negative = Left
            float offsetZ = -85.0f; // Positive = Up | Negative = Down (toward floor)
    
            targetPos.x = basePos.x + offsetX;
            targetPos.y = basePos.y + offsetY;
            targetPos.z = basePos.z + offsetZ;
    
    // --- 3. BASE ANGLE (Pointing Up/Forward) ---
    // We start with the standing-up fix (270) and your baseline (45)
            float basePitch = 270.0f - 45.0f; // Looking Up
            float baseYaw = 5.0f; // Facing "Forward"
            float baseRoll = 0.0f;
    
    // --- 4. YOUR ROTATION OFFSETS ---
    // If the logo isn't facing the pipe, change offsetYaw in 90 degree steps.
            float offsetPitchRot = 0.0f; 
            float offsetYawRot = 0.0f; // Try 90.0f, 180.0f, or -90.0f
            float offsetRollRot = 0.0f;
    
            targetAng.x = basePitch + offsetPitchRot;
            targetAng.y = baseYaw + offsetYawRot;
            targetAng.z = baseRoll + offsetRollRot;
    
        } else {
            targetAng.x += 270.0f; 
        }
        return;
    }

    // 5. FRANKENTURRETS / MONSTER BOXES
    if (classname == "prop_monster_box" || model.locate("monster") != uint(-1)) {
        targetSkin = 4;
        targetPos = ent.GetAbsOrigin() + (ent.Up() * 24.0f);
        return;
    }

    // 6. TRACTOR BEAMS / FUNNELS
    if (classname == "prop_tractor_beam" || classname == "prop_excursion_funnel") {
        targetSkin = 4;
        targetPos = ent.GetAbsOrigin() + (ent.Forward() * 95.0f);
        targetAng.x += 90.0f; 
        return;
    }

    // 7. CUBES
    if (classname.locate("cube") != uint(-1) || model.locate("metal_box") != uint(-1)) {
        targetSkin = 4;
        targetPos = ent.GetAbsOrigin() + (ent.Up() * 32.0f);
        return;
    }

    // 8. STANDARD PEDESTAL BUTTONS (40.0f Offset)
    if (classname == "prop_button" || classname == "prop_under_button") {
        targetSkin = 4;
        targetPos = ent.GetAbsOrigin() + (ent.Up() * 70.0f);
        targetScale = 0.66f;
        return;
    }

    // 9. RATMAN DEN BUTTONS (66.0f Offset)
    if (classname == "prop_dynamic" && name.locate("rd") == 0 && name.locate("_model") != uint(-1)) {
        targetPos = ent.GetAbsOrigin() + (ent.Up() * 90.0f);
        targetScale = 0.66f;
        return;
    }

    // 10. FLOOR BUTTONS (Standardized to 40.0f)
    if (classname == "prop_floor_button" || classname == "prop_floor_cube_button" || classname == "prop_floor_ball_button" || classname == "prop_under_floor_button") {
        targetSkin = 4;
        targetPos = ent.GetAbsOrigin() + (ent.Up() * 40.0f);
        targetScale = 1.0f;
        return;
    }

    // 11. LASER DEVICES (Catchers, Relays, Sensors, Emitters)
    bool isLaser = (classname.locate("laser") != uint(-1) || name.locate("laser") != uint(-1));
    if (isLaser) {
        targetSkin = 4;
        targetScale = 0.7f; // Default scale for all laser checks
        
        // Relay/Catcher/Emitter logic based on keyword found
        if (classname.locate("relay") != uint(-1) || name.locate("relay") != uint(-1)) {
            targetPos = ent.GetAbsOrigin() + (ent.Up() * 50.0f);
            targetScale = 0.66f;
        } else if (classname.locate("catcher") != uint(-1) || name.locate("catcher") != uint(-1) ||
            classname.locate("sensor") != uint(-1) || name.locate("sensor") != uint(-1)) {
            
            // ADAPTIVE OFFSET: If on floor/ceiling (high pitch), we need more room
            QAngle ang = ent.GetAbsAngles();
            float offsetDist = (abs(ang.x) > 45.0f) ? 45.0f : 32.0f;
            
            targetPos = ent.GetAbsOrigin() + (ent.Forward() * offsetDist);
            targetScale = 0.5f;
        } else if (classname.locate("env_portal_laser") != uint(-1) || model.locate("laser") != uint(-1)) {
            // Emitters also stick out from face
            targetPos = ent.GetAbsOrigin() + (ent.Forward() * 25.0f);
            targetScale = 0.7f;
        }
        return;
    }

    // 12. HARD LIGHT BRIDGES
    if (classname == "prop_wall_projector" || name.locate("bridge") != uint(-1)) {
        targetSkin = 4;
        targetPos = ent.GetAbsOrigin() + (ent.Forward() * 25.0f);
        targetScale = 0.8f;
        return;
    }

    // 13. TURRETS
    if (classname == "npc_portal_turret_floor" || classname == "npc_rocket_turret" || model.locate("turret") != uint(-1)) {
        targetSkin = 2;
        targetPos = ent.GetAbsOrigin() + (ent.Up() * 80.0f);
        targetScale = 0.7f;
        return;
    }
}
