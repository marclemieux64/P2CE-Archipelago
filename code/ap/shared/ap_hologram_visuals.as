// =============================================================
// ARCHIPELAGO HOLOGRAM VISUAL REGISTRY
// =============================================================

void GetHologramVisualOverrides(CBaseEntity@ ent, Vector&out targetPos, QAngle&out targetAng, int&out targetSkin, float&out targetScale) {
    if (ent is null) return;
    UpdateInternalMapName();

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

    if (current_map == "sp_a1_intro2") {
        if (name.locate("box") != uint(-1)) {
            targetPos = ent.GetAbsOrigin() + (ent.Up() * -24.0f);
            targetAng.x = 0.0f;
            targetAng.y = 0.0f;
            targetAng.z = 0.0f;
            targetSkin = 4;
            targetScale = 0.66f;
            return;
        }
    }
    
    if (current_map == "sp_a1_intro4") {
        if (name.locate("box_dropper-cube_dropper_box") != uint(-1) || classname == "env_entity_maker") {
            targetPos = ent.GetAbsOrigin() + (ent.Up() * -330.0f);
            targetSkin = 4;
            return;
        }
        if (name.locate("section_2_box_2") != uint(-1) || classname == "prop_weighted_cube") {
            targetPos = ent.GetAbsOrigin();
            targetSkin = 4;
            targetScale = 0.66f;
            return;
        }

    }

    if (current_map == "sp_a1_intro5") {
        if (name.locate("cube_dropper_1-cube_dropper_box") != uint(-1) || classname == "env_entity_maker") {
            targetPos = ent.GetAbsOrigin() + (ent.Up() * -330.0f);
            targetSkin = 4;
            return;
        }
        if (name.locate("cube_dropper_2-cube_dropper_box") != uint(-1) || classname == "env_entity_maker") {
            targetPos = ent.GetAbsOrigin() + (ent.Up() * -330.0f);
            targetSkin = 4;
            return;
        }

    }

    if (current_map == "sp_a1_intro6") {
        if (name.locate("cube_dropper-cube_dropper_box") != uint(-1)) {
            CBaseEntity@ maker = null;
            while ((@maker = EntityList().FindByClassname(maker, "env_entity_maker")) !is null) {
                if (maker.GetEntityName().locate("cube_dropper") != uint(-1)) {
                    targetPos = maker.GetAbsOrigin() + (maker.Up() * -420.0f);
                    break;
                }
            }
            targetSkin = 4;
            return;
        }
        if (name.locate("prop_weighted_cube") != uint(-1) || classname == "prop_weighted_cube") {
            targetPos = ent.GetAbsOrigin() + (ent.Up() * 30.0f);
            targetScale = 0.66f;
            targetSkin = 4;
            return;
        }
    }

    if (current_map == "sp_a1_intro7") {
        Vector pos = ent.GetAbsOrigin();
        targetAng = QAngle(0.0f, 0.0f, 0.0f);
        
        if ((pos - Vector(-2801.72f, 213.41f, 1522.55f)).Length() < 10.0f) {
            targetPos = Vector(-2801.72f, 213.41f, 1522.55f); 
            targetAng = QAngle(-70.74f, 349.67f, 0.0f);
            targetSkin = 2; 
            targetScale = 0.7f;
            return;
        }
        if ((pos - Vector(-2768.0f, -146.0f, 1512.0f)).Length() < 10.0f) {
            targetPos = Vector(-2768.0f, -146.0f, 1512.0f);
            targetAng = QAngle(-90.0f, 0.0f, 0.0f);
            targetSkin = 2;
            targetScale = 0.7f;
            return;
        }
        if ((pos - Vector(-2860.0f, 304.0f, 1266.0f)).Length() < 10.0f) {
            targetPos = Vector(-2860.0f, 304.0f, 1266.0f);
            targetAng = QAngle(-60.0f, 0.0f, 0.0f);
            targetSkin = 2;
            targetScale = 0.7f;
            return;
        }
        if ((pos - Vector(-2838.0f, -256.0f, 1268.0f)).Length() < 10.0f) {
            targetPos = Vector(-2838.0f, -256.0f, 1268.0f);
            targetAng = QAngle(-64.31f, 182.29f, 31.14f);
            targetSkin = 2;
            targetScale = 0.7f;
            return;
        }
        if ((pos - Vector(-2943.43f, 37.41f, 1426.5f)).Length() < 10.0f) {
            targetPos = Vector(-2943.43f, 37.41f, 1426.5f);
            targetAng = QAngle(-84.78f, 319.40f, 30.71f);
            targetSkin = 5;
            targetScale = 0.7f;
            return;
        }
        if ((pos - Vector(-2802.90f, 101.77f, 1520.28f)).Length() < 10.0f) {
            targetPos = Vector(-2802.90f, 101.77f, 1520.28f);
            targetAng = QAngle(-75.0f, 0.0f, 0.0f);
            targetSkin = 2;
            targetScale = 0.7f;
            return;
        }
        if ((pos - Vector(-2951.71f, -74.22f, 1442.0f)).Length() < 10.0f) {
            targetPos = Vector(-2951.71f, -74.22f, 1442.0f);
            targetAng = QAngle(-60.0f, 0.0f, 0.0f);
            targetSkin = 3;
            targetScale = 0.7f;
            return;
        }
        if ((pos - Vector(-2851.05f, -66.81f, 1264.59f)).Length() < 10.0f) {
            targetPos = Vector(-2851.05f, -66.81f, 1264.59f);
            targetAng = QAngle(-82.38f, 173.60f, 109.29f);
            targetSkin = 2;
            targetScale = 0.7f;
            return;
        }
        if ((pos - Vector(-2857.17f, -112.81f, 1264.47f)).Length() < 10.0f) {
            targetPos = Vector(-2857.17f, -112.81f, 1264.47f);
            targetAng = QAngle(-82.51f, 6.50f, -83.49f);
            targetSkin = 2;
            targetScale = 0.7f;
            return;
        }
        if ((pos - Vector(-2983.71f, 256.0f, 1146.0f)).Length() < 10.0f) {
            targetPos = Vector(-2983.71f, 256.0f, 1146.0f);
            targetAng = QAngle(-60.0f, 0.0f, 0.0f);
            targetSkin = 2;
            targetScale = 0.7f;
            return;
        }
        if ((pos - Vector(-2912.0f, -238.47f, 1141.86f)).Length() < 10.0f) {
            targetPos = Vector(-2940.0f, -238.47f, 1141.86f);
            targetAng = QAngle(-64.31f, 182.29f, 31.14f);
            targetSkin = 2;
            targetScale = 0.7f;
            return;
        }
        if ((pos - Vector(-2824.36f, -395.82f, 1297.38f)).Length() < 10.0f) {
            targetPos = Vector(-2824.36f, -395.82f, 1297.38f);
            targetAng = QAngle(2.08f, 4.29f, 68.86f);
            targetSkin = 2;
            targetScale = 0.7f;
            return;
        }
    }

    if (current_map == "sp_a2_laser_stairs") {
        if (name.locate("cube_dropper_01-cube_dropper_box") != uint(-1)) {
            CBaseEntity@ maker = null;
            while ((@maker = EntityList().FindByClassname(maker, "env_entity_maker")) !is null) {
                if (maker.GetEntityName().locate("cube_dropper") != uint(-1)) {
                    targetPos = maker.GetAbsOrigin() + (maker.Up() * -420.0f);
                    break;
                }
            }
            targetSkin = 4;
            return;
        }
    }
     
    if (current_map == "sp_a2_laser_over_goo") {
        if (name.locate("cube_dropper_box") != uint(-1) || classname == "env_entity_maker") {
            targetPos = ent.GetAbsOrigin() + (ent.Up() * -370.0f);
            targetSkin = 4;
            return;
        }
    }

    if (current_map == "sp_a2_catapult_intro") {
        if (name.locate("cube_dropper-cube_dropper_box") != uint(-1)) {
            CBaseEntity@ maker = null;
            while ((@maker = EntityList().FindByClassname(maker, "env_entity_maker")) !is null) {
                if (maker.GetEntityName().locate("cube_dropper") != uint(-1)) {
                    targetPos = maker.GetAbsOrigin() + (maker.Up() * -420.0f);
                    break;
                }
            }
            targetSkin = 4;
            return;
        }
    }

    if (current_map == "sp_a2_ricochet") {
        if (name.locate("juggled_cube") != uint(-1)) {
            targetPos = ent.GetAbsOrigin() + (ent.Left() * 25.0f);
            targetAng.x = 0.0f;
            targetAng.y = 0.0f;
            targetAng.z = 0.0f;
            targetSkin = 4;
            targetScale = 0.66f;
            return;
        }
    }

    if (current_map == "sp_a2_laser_relays") {
        if (name.locate("laser_cube_spawner") != uint(-1)) {
            targetPos = ent.GetAbsOrigin() + (ent.Up() * -24.0f);
            targetAng.x = 0.0f;
            targetAng.y = 0.0f;
            targetAng.z = 0.0f;
            targetSkin = 4;
            targetScale = 0.66f;
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

  // 4. PAINT SPRAYERS / GEL BOMBS / PAINT SPHERES
    bool isSprayer = (classname == "info_paint_sprayer" || classname == "paint_sphere" || 
        name.locate("paint") != uint(-1) || name.locate("sprayer") != uint(-1));

    if (isSprayer) {
        bool isNozzle = (classname == "info_paint_sprayer" || classname == "paint_sphere");
        targetSkin = 4;
        if (isNozzle) {
            // Forward from mouth + Local Up nudge (follows sprayer tilt)
            targetPos = ent.
                GetAbsOrigin() + (ent.
                Forward() * 60.0f); 
        } else {
            targetPos = ent.
                GetAbsOrigin() + (ent.
                Up() * 24.0f);
        }
        
        // Use full 3-axis rotation with Inverted Pitch
        targetAng = ent.GetAbsAngles();
        
        if (current_map == "sp_a3_jump_intro") {
            // Apply custom distance offset ONLY on jump_intro
            targetPos = ent.
                GetAbsOrigin() + (ent.
                Up() * -60.0f); 
            // We do NOT invert pitch or yaw here
        } else {
            // Standard behavior for all other maps
            targetAng.x = -targetAng.x; // Invert Pitch
            targetAng.y += 180.0f; // Flip to face the player
        }
        
        // Exception for that one stubborn sprayer on sp_a3_speed_ramp
        if (current_map == "sp_a3_speed_ramp" && name == "paint_sprayer") {
            // Change these values to move it around!
            // ent.Forward(), ent.Up(), ent.Left()
            targetPos = ent.
                GetAbsOrigin() + (ent.
                Forward() * 120.0f); 
        }

        // Exception for the bounce sprayer on sp_a3_speed_flings
        if (current_map == "sp_a3_speed_flings" && name == "paint_sprayer_bounce") {
            // Adjust the 120.0f to push it further out or closer in!
            targetPos = ent.
                GetAbsOrigin() + (ent.
                Forward() * 270.0f); 
        }

        // Exception for the bounce sprayer on sp_a3_speed_flings
        if (current_map == "sp_a3_speed_flings" && name == "paint_sprayer_speed") {
            // Adjust the 120.0f to push it further out or closer in!
            targetPos = ent.
                GetAbsOrigin() + (ent.
                Forward() * 20.0f); 
        }

// Exceptional orientations for sp_a3_portal_intro
        if (current_map == "sp_a3_portal_intro" && name == "pump_machine_white_sprayer") {
            targetPos = ent.
                GetAbsOrigin() + (ent.
                Forward() * 60.0f); 
            // The user requested to grab and apply the EXACT raw angles of the sprayer, bypassing the standard inversion
            targetAng = ent.GetAbsAngles(); 
            // If you still need slight tweaks, you can add them below:
            // targetAng.x += 0.0f; 
        }

        if (current_map == "sp_a3_portal_intro" && name == "pump_machine_blue_sprayer") {
            targetPos = ent.
                GetAbsOrigin() + (ent.
                Forward() * 40.0f); 
            // Re-adding the raw angle grab since the code line was missing!
            targetAng = ent.GetAbsAngles();
        }

        // Using .locate() so it catches ALL of them if there are multiple!
        if (current_map == "sp_a3_portal_intro" && name.locate("intermediate_chamber_paint_sprayer") != uint(-1)) {
            targetPos = ent.
                GetAbsOrigin() + (ent.
                Forward() * 0.0f) + (ent.
                Up() * -20.0f); 
            // Grab the raw angles first
            targetAng = ent.GetAbsAngles();
            // Force the pitch to 90 degrees (Straight Down in the Source Engine)
            targetAng.x = 90.0f; 
        }

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
        targetPos = ent.
            GetAbsOrigin() + (ent.
            Up() * 24.0f);
        return;
    }

    // 6. TRACTOR BEAMS / FUNNELS
    if (classname == "prop_tractor_beam" || classname == "prop_excursion_funnel") {
        targetSkin = 4;
        targetPos = ent.
            GetAbsOrigin() + (ent.
            Forward() * 95.0f);
        targetAng.x += 90.0f; 
        return;
    }

    // 7. CUBES
    if (classname.locate("cube") != uint(-1) || model.locate("metal_box") != uint(-1)) {
        targetSkin = 4;
        targetPos = ent.
            GetAbsOrigin() + (ent.
            Up() * 32.0f);
        return;
    }
// 8. RATMAN DEN BUTTONS (Check for both "rd" and "Ratman Den")
    if (name.locate("rd") == 0 || name.locate("Ratman Den") != uint(-1)) {
        targetPos = ent.
            GetAbsOrigin() + (ent.
            Up() * 90.0f);
        targetScale = 0.66f;
        return;
    }

// 9. STANDARD PEDESTAL BUTTONS (Everything else)
    if (classname == "prop_button" || classname == "prop_under_button") {
        targetSkin = 4;
        targetPos = ent.
            GetAbsOrigin() + (ent.
            Up() * 70.0f);
        targetScale = 0.66f;
        return;
    }

    // 10. FLOOR BUTTONS (Standardized to 40.0f)
    if (classname == "prop_floor_button" || classname == "prop_floor_cube_button" || classname == "prop_floor_ball_button" || classname == "prop_under_floor_button") {
        targetSkin = 4;
        targetPos = ent.
            GetAbsOrigin() + (ent.
            Up() * 40.0f);
        targetScale = 1.0f;
        return;
    }

// 11. LASER DEVICES (Catchers, Relays, Sensors, Emitters)
    bool isLaser = (classname.locate("laser") != uint(-1) || name.locate("laser") != uint(-1) || classname.locate("catcher") != uint(-1));
    if (isLaser) {
        targetSkin = 4;
        targetScale = 0.7f;
        targetAng = ent.GetAbsAngles(); // Match mounting angle
        if (classname.locate("relay") != uint(-1) || name.locate("relay") != uint(-1)) {
            // Relays use the Top (Up) sensor
            targetPos = ent.
                GetAbsOrigin() + (ent.
                Up() * 40.0f);
            targetScale = 0.66f;
        } else {
            // Catchers and Emitters face Forward out of the device
            targetPos = ent.
                GetAbsOrigin() + (ent.
                Forward() * 24.0f);
            targetAng.x += 90.0f; // Tilt to face out
            targetScale = 0.55f;
        }
        return;
    }

    // 12. HARD LIGHT BRIDGES
    if (classname == "prop_wall_projector" || name.locate("bridge") != uint(-1)) {
        targetSkin = 4;
        targetPos = ent.
            GetAbsOrigin() + (ent.
            Forward() * 25.0f);
        targetScale = 0.8f;
        return;
    }

    // 13. TURRETS
    if (classname == "npc_portal_turret_floor" || classname == "npc_rocket_turret" || model.locate("turret") != uint(-1)) {
        targetSkin = 2;
        targetPos = ent.
            GetAbsOrigin() + (ent.
            Up() * 80.0f);
        targetScale = 0.7f;
        return;
    }

    // 14. FAITH PLATES (Catapults)
    if (classname == "trigger_catapult") {
        targetSkin = 4;
        targetScale = 0.7f;
        
        CBaseEntity@ plate = null;
        bool foundPlate = false;
        while ((@plate = EntityList().FindByClassname(plate, "prop_dynamic")) !is null) {
            if (plate.GetModelName().locate("faith_plate") != uint(-1)) {
                float dist = (plate.GetAbsOrigin() - ent.GetAbsOrigin()).Length();
                if (dist < 128.0f) {
                    targetPos = plate.GetAbsOrigin() + (plate.Up() * 32.0f);
                    targetAng = plate.GetAbsAngles();
                    foundPlate = true;
                    break;
                }
            }
        }
        
        if (!foundPlate) {
            targetPos = ent.GetAbsOrigin() + (ent.Up() * 32.0f);
        }
        return;
    }
}
