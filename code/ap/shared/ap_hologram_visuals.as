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
    bool isRegistered = g_monitor_break_names.exists(current_map + ":" + name);
    bool isMonitorTrigger = (name.locate("trigger_tv_crack") != uint(-1));
    bool isMonitorProp = (model.locate("wheatley_monitor") != uint(-1));

    if (isRegistered || isMonitorTrigger || isMonitorProp) {
        targetPos = ent.GetAbsOrigin() + (ent.Up() * 125.0f);
        targetAng = ent.GetAbsAngles(); 
        targetSkin = 0;
        targetScale = 0.9f;
        return;
    }

    // 3. CUBE DROPPERS (item_dropper.mdl / env_entity_maker)
    bool isDropper = (name.locate("dropper") != uint(-1) || model.locate("dropper") != uint(-1) || classname == "env_entity_maker");
    
    // EXCLUSION: Only standalone buttons/cubes are excluded. If it has "dropper" in name, it counts.
    if (!isDropper && (classname.locate("cube") != uint(-1) || classname.locate("button") != uint(-1))) {
        // already false
    } else if (isDropper) {
        targetSkin = 4;
        
        bool isUnderground = (model.locate("underground") != uint(-1) || current_map.locate("sp_a3_") == 0);
        float zOffset = isUnderground ? -130.0f : -355.0f;
        
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
                if (mName.locate(prefix) != uint(-1)) {
                    // Found a maker for this instance! Use its full center as base
                    Vector makerPos = maker.GetAbsOrigin();
                    targetPos = makerPos; 
                    // Fine-tune underground maker centering (trap-style droppers)
                    if (isUnderground) {
                        targetPos.x += -0.625f;
                        targetPos.y += 0.0f;
                        targetPos.z += -70.0f; // User identified nudge
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

        Msgl("[AP-DEBUG] Dropper: " + name + " Model: " + model + " Cls: " + classname);
        Msgl("  > Origin: " + ent.GetAbsOrigin().x + ", " + ent.GetAbsOrigin().y + ", " + ent.GetAbsOrigin().z);
        Msgl("  > TargetPos: " + targetPos.x + ", " + targetPos.y + ", " + targetPos.z);
        Msgl("  > FinalAng: " + targetAng.x);
        return;
    }

    // 4. PAINT SPRAYERS / GEL BOMBS (GEL DROPPERS)
    if (classname == "info_paint_sprayer" || classname == "prop_paint_bomb" || name.locate("paint_sprayer") != uint(-1)) {
        targetSkin = 4;
        if (classname == "info_paint_sprayer") {
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
}
