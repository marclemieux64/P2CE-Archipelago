// =============================================================
// ARCHIPELAGO HOLOGRAM OVERRIDES (OPTIMIZED MAIN DISPATCHER)
// =============================================================

namespace Archipelago {

void GetHologramVisualOverrides(CBaseEntity@ ent, Vector&out targetPos, QAngle&out targetAng, int&out targetSkin, float&out targetScale, bool&out shouldParent, bool&out absoluteAngles) {
    
    // 0. GENERAL DEFAULT INITIALIZATION
    targetPos = Vector(0, 0, 0);
    targetAng = QAngle(0, 0, 0);
    targetSkin = 4; // Default Archipelago rusty skin
    targetScale = 1.0f;
    shouldParent = false;
    absoluteAngles = false;

    if (ent is null) return;
    
    string classname = ent.GetClassname();
    string model = ent.GetModelName().tolower();
    
    // ANONYMOUS CUBE SAFETY PATCH
    string name = ent.GetEntityName();
    if (name == "") {
        string shortModelName = ent.GetModelName().tolower();
        int lastSlash = -1;
        int len = shortModelName.length();
        for (int c = len - 1; c >= 0; c--) {
            if (shortModelName[c] == 47) { lastSlash = c; break; }
        }
        if (lastSlash != -1) name = shortModelName.substr(lastSlash + 1); else name = shortModelName;
    }
    string name_lower = name.tolower();

    // =============================================================
    // ROUTING CASCADE (Early-Exit for performance)
    // =============================================================

    string mapName = ConVarRef("host_map").GetString();
    if (mapName == "sp_a3_crazy_box") {
        // Intercept by real entity name or underground model
        if (name_lower == "erase_blocker_button" || model.locate("underground_testchamber_button") != uint(-1)) {
            // 1. Relative offsets: AddButtonFrame automatically calculates:
            // BaseOrigin + (Forward * 45.0f) + (Up * 25.0f)
            targetPos = Vector(45.0f, 0.0f, 25.0f);
        
            // 2. Modify pitch angle locally by +90 degrees
            // AddButtonFrame automatically does: BaseAngles + QAngle(90.0f, 0.0f, 0.0f)
            targetAng = QAngle(90.0f, 0.0f, 0.0f); 
        
            targetSkin = 4;
            targetScale = 0.66f;
            shouldParent = false; // Detach from Valve bone parent to free rotation
            absoluteAngles = false; // Add angles relatively
            return;
        }
    }

    if (mapName == "sp_a2_bts1") {
        // Verify it is a button but exclude floor buttons
        if ((name_lower.locate("button") != uint(-1) || model.locate("button") != uint(-1) || classname.locate("button") != uint(-1)) && 
            classname.locate("floor") == uint(-1) && model.locate("floor") == uint(-1) && name_lower.locate("floor") == uint(-1)) {
            
            // Local nudge: Forward 45 units, Up 25 units relative to button face
            targetPos = Vector(45.0f, 0.0f, 25.0f);
            
            // Rotation: Add +90.0f pitch to face the player
            targetAng = ent.GetAbsAngles();
            targetAng.x += 90.0f;
            
            targetSkin = 4;
            targetScale = 0.66f;
            shouldParent = false;  // Detach bone attachment to apply offsets correctly
            absoluteAngles = true; // Force AddButtonFrame to use targetAng as absolute world angles
            return;
        }
    }

    // 0.5. TURRETS (Robust check moved before cubes/gels to prevent incorrect cube skin overrides)
    if (classname == "npc_portal_turret_floor") {
        targetPos = Vector(0.0f, 0.0f, 60.0f);
        targetSkin = 2; 
        shouldParent = true;
        return;
    }

    // 1. CUBES (Immediate delegation)
    if (classname == "prop_weighted_cube" || model.locate("metal_box") != uint(-1) || model.locate("box") != uint(-1) || model.locate("cube") != uint(-1) || model.locate("reflection") != uint(-1) || model.locate("mp_ball") != uint(-1) || model.locate("underground_weighted_cube") != uint(-1) || name_lower.locate("metal_box") != uint(-1) || name_lower.locate("entity_box_maker_rm1") != uint(-1) || name_lower.locate("cube_dropper_box_spawner") != uint(-1) || name_lower.locate("laser_cube_spawner") != uint(-1) || name_lower.locate("reflection_cube") != uint(-1)) {
        OverrideCube(name, ent, targetPos, targetAng, targetSkin, targetScale, shouldParent, absoluteAngles);
        return; 
    }

    // 2. GELS (Immediate delegation)
    if (classname == "info_paint_sprayer" || classname == "prop_paint_bomb" || classname == "paint_sphere" || name_lower.locate("trigger_to_drop") != uint(-1) || name_lower.locate("template_artillery") != uint(-1) || (name_lower.locate("paint") != uint(-1) && name_lower.locate("panel") == uint(-1))) {
        OverrideGel(name, ent, targetPos, targetAng, targetSkin, targetScale, shouldParent, absoluteAngles);
        return;
    }

    // 3. DUMMY BUTTONS LOGIC
    if (name_lower.locate("dummy_chamber_button") != uint(-1)) {
        targetSkin = 0;
        targetScale = 1.0f;
        shouldParent = true;
        absoluteAngles = true; 

        uint idx = name_lower.locate("dummy_chamber_button");
        uint idx2 = name_lower.locate("dummy_chamber_button2");
        uint idx3 = name_lower.locate("dummy_chamber_button3");

        bool is_btn1 = (idx != uint(-1) && (idx + 20 == name_lower.length()));
        bool is_btn2 = (idx2 != uint(-1) && (idx2 + 21 == name_lower.length()));
        bool is_btn3 = (idx3 != uint(-1) && (idx3 + 21 == name_lower.length()));

        if (is_btn1) {
            if (current_map == "sp_a3_03") { targetPos = Vector(-6.0f, -44.0f, -34.5f); targetAng = QAngle(0, 90, 0); } else if (current_map == "sp_a3_transition01") { targetPos = Vector(44.0f, -6.0f, -34.5f); targetAng = QAngle(0, 180, 0); }
        } else if (is_btn2) {
            if (current_map == "sp_a3_03") { targetPos = Vector(-6.0f, -44.0f, -34.5f); targetAng = QAngle(0, 90, 0); } else if (current_map == "sp_a3_transition01") { targetPos = Vector(-44.0f, -6.0f, -34.5f); targetAng = QAngle(0, 180, 0); }
        } else if (is_btn3) {
            if (current_map == "sp_a3_03") { targetPos = Vector(-44.0f, 5.5f, -34.5f); targetAng = QAngle(0, 0, 0); } else if (current_map == "sp_a3_transition01") { targetPos = Vector(-4.05f, -45.0f, -34.5f); targetAng = QAngle(0, -90, 0); }
        }
        return;
    }

    // 4. DIRECT OVERRIDES
    if (model.locate("glados_screenborder_curve.mdl") != uint(-1)) {
        targetPos = Vector(30.0f, 0.0f, 100.0f);
        targetAng = QAngle(0.0f, 0.0f, 0.0f); 
        targetSkin = 0;
        targetScale = 1.0f;
        shouldParent = true;  
        absoluteAngles = false; 
        return;
    }

    if (classname.locate("core") != uint(-1) || name_lower.locate("core") != uint(-1) || model.locate("personality_sphere") != uint(-1)) {
        if (name.locate("1") != uint(-1)) targetSkin = 6; else if (name.locate("2") != uint(-1)) targetSkin = 5; else if (name.locate("3") != uint(-1)) targetSkin = 3; else targetSkin = 4;
        targetPos = Vector(0, 0, 0.0f);
        targetAng = QAngle(0, 0, 0);
        absoluteAngles = true;
        shouldParent = false;
        targetScale = 1.0f;
        return;
    }

    if (model.locate("faith_plate") != uint(-1)) {
        targetScale = 1.0f;
        targetPos = Vector(0, 0, 30.0f);
        return;
    }
    
    if (classname == "prop_wall_projector") {
        OverrideProjector(mapName, ent, targetPos, targetAng, targetSkin, targetScale, shouldParent, absoluteAngles);
        return;
    }

    if (classname == "prop_monster_box") {
        targetPos = Vector(0, 0, 32.0f);
        targetScale = 0.66f;
        shouldParent = true;
        absoluteAngles = true;
        return;
    } 

    if (classname.locate("env_portal_laser") != uint(-1) || classname.locate("prop_laser_relay") != uint(-1) || classname.locate("prop_laser_catcher") != uint(-1)) {
        shouldParent = false;   // No unstable physics parenting
        absoluteAngles = true;  // Force absolute reconstructed world angles
        targetScale = 0.66f;
        targetSkin = 4;

        // 1. Extract directional vectors of emitter
        Vector forward, right, up;
        AngleVectors(ent.GetAbsAngles(), forward, right, up);

        // 2. Calculate absolute target world position
        Vector worldPos;
        if (classname.locate("prop_laser_relay") != uint(-1)) {
            worldPos = ent.GetAbsOrigin() + (up * 32.0f); // Offset 32 units along local up
        } else {
            worldPos = ent.GetAbsOrigin() + (forward * 32.0f); // Offset 32 units along local forward
        }

        // Subtract base origin to feed relative hPos properly
        targetPos = worldPos - ent.GetAbsOrigin();

        // 3. Calculate absolute target world rotation
        if (classname.locate("prop_laser_relay") != uint(-1)) {
            targetAng = ent.GetAbsAngles(); // Remain aligned with relay
        } else {
            // Reconstruct QAngle to face the beam correctly
            VectorAngles(up, forward, targetAng);
        }
        return;
    } 

    if (classname.locate("button") != uint(-1)) {
        shouldParent = true;
        if (classname.locate("floor") != uint(-1) || model.locate("floor_button") != uint(-1)) {
            targetPos = Vector(0, 0, 50.0f);
        } else {
            targetPos = Vector(0, 0, 70.0f);
            targetScale = 0.66f;
        }
        return;
    } 

    if (classname == "prop_tractor_beam" || classname == "prop_excursion_funnel") {
        targetSkin = 4;
        targetPos = Vector(80.0f, 0, 0); 
        targetAng = QAngle(90.0f, 0, 0); 
        return;
    }
}

} // namespace Archipelago
