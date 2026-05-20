// =============================================================
// ARCHIPELAGO HOLOGRAM OVERRIDES (CUBE SUB-SYSTEM)
// =============================================================

namespace Archipelago {

void OverrideCube(const string&in name, CBaseEntity@ ent, Vector&out targetPos, QAngle&out targetAng, int&out targetSkin, float&out targetScale, bool&out shouldParent, bool&out absoluteAngles) {
    
    // ÉTAPE OBLIGATOIRE : Ré-initialisation des valeurs reçues par défaut pour un cube
    targetPos = Vector(0, 0, 0);
    targetAng = QAngle(0, 0, 0);
    targetSkin = 4;
    targetScale = 0.8f;   
    shouldParent = false;
    absoluteAngles = true;

    string lowerName = name.tolower();

    // EXCEPTIONS PAR MAPS
    if (::current_map == "sp_a1_intro1") {
        if (lowerName.locate("entity_box_maker_rm1") != uint(-1) || lowerName.locate("cube_dropper_2-cube_dropper_box") != uint(-1)) {
            targetPos = Vector(0, 0, -195);
            targetAng = QAngle(180, 0, 0);
            targetScale = 1.0f;      
        }
    }
    if (::current_map == "sp_a1_intro4") {
        if (lowerName.locate("box_dropper-cube_dropper_box") != uint(-1)) {
            targetPos = Vector(0, 0, -500);
            targetAng = QAngle(180, 0, 0);
            targetScale = 1.0f;      
        }
        if (lowerName.locate("metal_box.mdl_1307_-909_-39") != uint(-1)) {
            targetPos = Vector(0, 0, -800);
        }
    }
    if (::current_map == "sp_a1_intro5") {
        if (lowerName.locate("cube_dropper_1-cube_dropper_box") != uint(-1) || lowerName.locate("cube_dropper_2-cube_dropper_box") != uint(-1)) {
            targetPos = Vector(0, 0, -500);
            targetAng = QAngle(180, 0, 0);
            targetScale = 1.0f;      
        }
    }
    if (::current_map == "sp_a1_intro6") {
        if (lowerName.locate("cube_dropper-cube_dropper_box") != uint(-1)) {
            targetPos = Vector(0, 0, -500);
            targetAng = QAngle(180, 0, 0);
            targetScale = 1.0f;      
        }
    }
    if (::current_map == "sp_a1_intro7") {
        if (lowerName.locate("metal_box.mdl") != uint(-1) || lowerName.locate("reflection_cube.mdl") != uint(-1)) {
            targetPos = Vector(25, 0, 0);
            targetAng = QAngle(0, 0, 90);
        }
    }
    if (::current_map == "sp_a2_laser_stairs") {
        if (lowerName.locate("cube_dropper_01-cube_dropper_box") != uint(-1)) {
            targetPos = Vector(0, 0, -500);
            targetAng = QAngle(180, 0, 0);
            targetScale = 1.0f;      
        }
    }
    if (::current_map == "sp_a2_laser_over_goo") {
        if (lowerName.locate("cube_dropper_box") != uint(-1)) {
            targetPos = Vector(0, 0, -535);
            targetAng = QAngle(180, 0, 0);
            targetScale = 1.0f;      
        }
    }
    if (::current_map == "sp_a2_catapult_intro") {
        if (lowerName.locate("cube_dropper-cube_dropper_box") != uint(-1)) {
            targetPos = Vector(0, 0, -500);
            targetAng = QAngle(180, 0, 0);
            targetScale = 1.0f;      
        }
    }
    if (::current_map == "sp_a2_trust_fling") {
        if (lowerName.locate("cube_dropper_box") != uint(-1)) {
            targetPos = Vector(0, 0, -530);
            targetAng = QAngle(180, 0, 0);
            targetScale = 1.0f;      
        }
    }
    if (::current_map == "sp_a2_pit_flings") {
        if (lowerName.locate("cube_dropper-cube_dropper_box") != uint(-1)) {
            targetPos = Vector(0, 0, -500);
            targetAng = QAngle(180, 0, 0);
            targetScale = 1.0f;      
        }
    }
    if (::current_map == "sp_a2_fizzler_intro") {
        if (lowerName.locate("cube_dropper-cube_dropper_box") != uint(-1)) {
            targetPos = Vector(0, 0, -500);
            targetAng = QAngle(180, 0, 0);
            targetScale = 1.0f;      
        }
    }
    if (::current_map == "sp_a2_sphere_peek") {
        if (lowerName.locate("reflectocube_dropper_box") != uint(-1)) {
            targetPos = Vector(0, 0, -530);
            targetAng = QAngle(180, 0, 0);
            targetScale = 1.0f;      
        }
    }
    if (::current_map == "sp_a2_ricochet") {
        if (lowerName.locate("reflecto_cube_dropper-cube_dropper_box") != uint(-1)) {
            targetPos = Vector(0, 0, -500);
            targetAng = QAngle(180, 0, 0);
            targetScale = 1.0f;      
        }
        if (lowerName.locate("juggled_cube") != uint(-1)) {
            targetPos = Vector(0, 0, 35);
        }
    }
    if (::current_map == "sp_a2_bridge_intro") {
        if (lowerName.locate("box_dropper_01-cube_dropper_box") != uint(-1)) {
            targetPos = Vector(0, 0, -500);
            targetAng = QAngle(180, 0, 0);
            targetScale = 1.0f;      
        }
    }
    if (::current_map == "sp_a2_bridge_the_gap") {
        if (lowerName.locate("cube_dropper-cube_dropper_box") != uint(-1)) {
            targetPos = Vector(0, 0, -500);
            targetAng = QAngle(180, 0, 0);
            targetScale = 1.0f;      
        }
    }
    if (::current_map == "sp_a2_laser_relays") {
        if (lowerName.locate("laser_cube_spawner") != uint(-1)) {
            targetPos = Vector(0, 0, -30);
            targetAng = QAngle(0, 0, 0);
        }
    }
    if (::current_map == "sp_a2_column_blocker") {
        if (lowerName.locate("cube_dropper_1-cube_dropper_box") != uint(-1) || lowerName.locate("cube_dropper_2-cube_dropper_box") != uint(-1)) {
            targetPos = Vector(0, 0, -500);
            targetAng = QAngle(180, 0, 0);
            targetScale = 1.0f;
        }
    }
    if (::current_map == "sp_a2_bts1") {
        if (lowerName.locate("cube_dropper-cube_dropper_box") != uint(-1)) {
            targetPos = Vector(0, 0, -530);
            targetAng = QAngle(180, 0, 0);  
            targetScale = 1.0f;  
        }
    }
    if (::current_map == "sp_a3_jump_intro") {
        if (lowerName.locate("cube_dropper_box") != uint(-1)) {
            targetPos = Vector(0, 25, -65);
            targetAng = QAngle(180, 0, 0);  
            targetScale = 1.0f;  
        }
    }
    if (::current_map == "sp_a3_speed_flings") {
        if (lowerName.locate("cube_dropper_box") != uint(-1)) {
            targetPos = Vector(0, 25, -65);
            targetAng = QAngle(180, 0, 0);  
            targetScale = 1.0f;  
        }
    }
    if (::current_map == "sp_a4_laser_platform") {
        if (lowerName.locate("cube_dropper_box") != uint(-1)) {
            targetPos = Vector(0, 0, -500);
            targetAng = QAngle(180, 0, 0);  
            targetScale = 1.0f;  
        }
    }
    if (::current_map == "sp_a4_intro") {
        if (lowerName.locate("cube_dropper_box") != uint(-1)) {
            targetPos = Vector(0, 0, -530);
            targetAng = QAngle(180, 0, 0);  
            targetScale = 1.0f;  
        }
    }
    if (::current_map == "sp_a4_tb_intro") {
        if (lowerName.locate("cube_dropper_box") != uint(-1)) {
            targetPos = Vector(0, 0, -540);
            targetAng = QAngle(180, 0, 0);  
            targetScale = 1.0f;  
        }
    }
    if (::current_map == "sp_a4_tb_trust_drop") {
        if (lowerName.locate("cube_dropper_box") != uint(-1)) {
            targetPos = Vector(0, 0, -540);
            targetAng = QAngle(180, 0, 0);  
            targetScale = 1.0f;  
        }
    }
    if (::current_map == "sp_a4_tb_trust_drop") {
        if (lowerName.locate("cube_dropper_box") != uint(-1)) {
            targetPos = Vector(0, 0, -540);
            targetAng = QAngle(180, 0, 0);  
            targetScale = 1.0f;  
        }
    }
    if (::current_map == "sp_a4_tb_wall_button") {
        if (lowerName.locate("cube_dropper_box_spawner") != uint(-1)) {
            targetPos = Vector(0, 0, -500);
            targetAng = QAngle(180, 0, 0);  
            targetScale = 1.0f;  
        }
    }
    if (::current_map == "sp_a4_tb_polarity") {
        if (lowerName.locate("cube_dropper_box") != uint(-1)) {
            targetPos = Vector(0, 0, -525);
            targetAng = QAngle(180, 0, 0);  
            targetScale = 1.0f;  
        }
    }
    if (::current_map == "sp_a4_tb_catch") {
        if (lowerName.locate("cube_dropper_box") != uint(-1)) {
            targetPos = Vector(0, 0, -525);
            targetAng = QAngle(180, 0, 0);  
            targetScale = 1.0f;  
        }
    }
    if (::current_map == "sp_a4_stop_the_box") {
        if (lowerName.locate("cube_dropper_box") != uint(-1)) {
            targetPos = Vector(0, 0, -525);
            targetAng = QAngle(180, 0, 0);  
            targetScale = 1.0f;  
        }
    }
    if (::current_map == "sp_a4_speed_tb_catch") {
        if (lowerName.locate("cube_dropper_box") != uint(-1)) {
            targetPos = Vector(0, 0, -525);
            targetAng = QAngle(180, 0, 0);  
            targetScale = 1.0f;  
        }
    }
}

} // namespace Archipelago