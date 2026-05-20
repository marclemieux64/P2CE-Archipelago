// =============================================================
// ARCHIPELAGO HOLOGRAM OVERRIDES (GEL SUB-SYSTEM)
// =============================================================

namespace Archipelago {

void OverrideGel(const string&in name, CBaseEntity@ ent, Vector&out targetPos, QAngle&out targetAng, int&out targetSkin, float&out targetScale, bool&out shouldParent, bool&out absoluteAngles) {
    
    // 1. INITIALISATION DES DEFAUTS POUR GEL (Obligatoire à cause du &out)
    targetPos = Vector(0, 0, 0);
    targetAng = QAngle(180, 0, 0); // La Règle générale pour TOUS les gels
    targetSkin = 4;
    targetScale = 1.0f;
    shouldParent = false;
    absoluteAngles = false;

    // 2. Exception globale pour la map sp_a3_jump_intro (Restaurée sans conflit)
    if (::current_map == "sp_a3_jump_intro") {
        targetAng = QAngle(-90, 0, 0);
    }

    if (::current_map == "sp_a3_bomb_flings") {
        if (name == "paint_bomb_maker_-224_-64_656_holo") {
            targetPos = Vector(0, 0, -85);
        }
    }

    if (::current_map == "sp_a3_crazy_box") {
        // 1. Le générateur de bombes de gel (489)
        if (name.locate("paint_bomb_template_2240_-896_656_holo") != uint(-1)) {
            targetPos = Vector(0, 0, -350.0f);
        }
        // 2. Le goutte-à-goutte / drip (490)
        else if (name.locate("paint_drip1_1716_-1772_714_holo") != uint(-1)) {
            targetPos = Vector(25, 0, 0);
            targetAng = QAngle(90, 0, 0); 
        }
        // 3. Le sprayer de saut / bounce (491)
        else if (name.locate("paint_sprayer_bounce_1280_-1408_1776_holo") != uint(-1)) {
            targetPos = Vector(60, 0, 0);
            targetAng = QAngle(90, 0, 0); 
        }
    }
    
    if (::current_map == "sp_a3_speed_ramp") {
        if (name == "paint_sprayer_576_0_704_holo") {
            targetScale = 0.0f;
            targetPos = Vector(0, 0, -5000.0f);
        }
        else if (name == "paint_sprayer_576_0_696_holo") {
            targetPos = Vector(120, 0, 0);
            targetAng = QAngle(90, 0, 0); 
        }
        else if (name == "paint_sprayer_2_-1600_-896_960_holo" || name == "paint_sprayer_3_-1600_-384_960_holo") {
            targetPos = Vector(65, 0, 0);
            targetAng = QAngle(90, 0, 0); 
        }
    }

    if (::current_map == "sp_a3_speed_flings") {
        if (name == "paint_sprayer_bounce_2816_-128_320_holo") {
            targetPos = Vector(260, 0, 0);
            targetAng = QAngle(90, 0, 0); 
        }
        else if (name == "paint_sprayer_speed_2560_-128_-152_holo") {
            targetPos = Vector(10, 0, 0);
            targetAng = QAngle(90, 0, 0); 
        }
    }

    if (::current_map == "sp_a3_portal_intro") {
        // 1. Le sprayer de gel Blanc
        if (name == "pump_machine_white_sprayer_1908_1712_-1984_holo") {
            targetPos = Vector(15, 0, 0);
            targetAng = QAngle(-90, 0, 0); 
        } 
        // 2. Le sprayer de gel Bleu
        else if (name == "pump_machine_blue_sprayer_1088_1712_-2068_holo") {
            targetPos = Vector(10, 0, 0);
            targetAng = QAngle(90, 0, 0); 
        }
        // 3. GROUPE -1680 (Incliné 45°)
        else if (name.locate("_-1680_holo") != uint(-1)) {
            targetPos = Vector(0, 0, -10);
            targetAng = QAngle(0, 270, 0); 
        }
        // 4. GROUPE -1672 (La rangée principale à plat)
        else if (name.locate("_-1672_holo") != uint(-1)) {
            targetPos = Vector(25, 0, 0);
            targetAng = QAngle(-90, 0, 0);
        }
        // 5. GROUPE -1728 (Incliné -30°)
        else if (name.locate("_-1728_holo") != uint(-1)) {
            targetPos = Vector(0, 0, 35);
            targetAng = QAngle(0, 270, 0); 
        }
        // 5. GROUPE -1704 (Incliné -30°)
        else if (name.locate("_-1704_holo") != uint(-1)) {
            targetPos = Vector(0, 0, 10);
            targetAng = QAngle(0, 270, 0); 
        }
        // 6. GROUPE -1712 (Incliné -15°)
        else if (name.locate("_-1712_holo") != uint(-1)) {
            targetPos = Vector(0, 0, 20);
            targetAng = QAngle(0, 270, 0); 
        }
        // 5a. Premier paint sprayer isolé (Syntaxe sécurisée)
        else if (name == "paint_sprayer_1_32_99_144_holo") {
            targetPos = ent.GetAbsOrigin();
            targetAng = QAngle(0, 0, 0);
            absoluteAngles = true;
        }
        // 5b. Deuxième paint sprayer isolé (Syntaxe sécurisée)
        else if (name == "paint_sprayer_2_287_192_292_holo") {
            targetPos = ent.GetAbsOrigin() + Vector(-80.0f, 0.0f, -80.0f);
            QAngle nativeAng = ent.GetAbsAngles(); 
            targetAng = QAngle(nativeAng.x + 90.0f, nativeAng.y + 0.0f, nativeAng.z + 0.0f);
            absoluteAngles = true;
        }
    }

    if (::current_map == "sp_a3_end") {
        if (name.locate("paint_trickle") != uint(-1)) {
            if (name.locate("paint_trickle_blue_1") != uint(-1)) {
                targetPos = Vector(35, 0, -10);
                targetAng = QAngle(90, 0, 0);
                absoluteAngles = false; 
            } 
            else if (name.locate("paint_trickle_white_2") != uint(-1)) {
                targetPos = Vector(50, 0, 0);
                targetAng = QAngle(90, 0, 0);
                absoluteAngles = false; 
            }
            else {
                targetPos = Vector(35, 0, 0);
                targetAng = QAngle(90, 0, 0);
                absoluteAngles = false; 
            }
        }
        else if (name.locate("paint_duct") != uint(-1)) {
            targetPos = ent.GetAbsOrigin();
            targetAng = QAngle(90, -90, 0); 
            absoluteAngles = true; 
        }
    }

    if (::current_map == "sp_a4_speed_tb_catch") {
            if (name == "AutoInstance1-paint_sprayer_256_1376_552_holo") {
                targetPos = Vector(135, 0, 0);
                targetAng = QAngle(90, 0, 0); 
            }
        }

    if (::current_map == "sp_a4_jump_polarity") {
        if (name.locate("paint_meSilly_1902_65_188_holo") != uint(-1) || name.locate("paint_meSilly_1742_-62_140_holo") != uint(-1)) {
            targetPos = Vector(0, 0, 0);
            targetAng = QAngle(0, 0, 0); 
            absoluteAngles = false;
        }
        else if (name.locate("paint_sprayer_-576_-64_640_holo") != uint(-1)) {
            targetPos = Vector(320, 0, 0);
            targetAng = QAngle(90, 0, 0); 
            absoluteAngles = false; 
        }
    }

    if (::current_map == "sp_a4_finale1") {
        if (name.locate("paint_sprayer_portal_") != uint(-1)) {
            targetPos = Vector(0, 0, 0);
            targetAng = QAngle(-90, 0, 0); 
        }
        else if (name.locate("platform_sprayer") != uint(-1)) {
            targetPos = Vector(0, 0, 0);
            targetAng = QAngle(0, 0, 0); 
        }
    }

    if (::current_map == "sp_a4_finale2") {
        string lowerName = name.tolower();
        if (lowerName.locate("paint_sprayer_jump_-1710_") != uint(-1)) {
            targetPos = Vector(0, 0, 0);
            targetAng = QAngle(-90, 0, 0); 
            absoluteAngles = false;
        }
        else if (lowerName.locate("trigger_to_drop") != uint(-1) || lowerName.locate("template_artillery") != uint(-1)) {
            targetScale = 0.0f;
            targetPos = Vector(0, 0, -5000.0f); 
            shouldParent = false;               
            absoluteAngles = true;
        }
        else if (lowerName.locate("bomb_") != uint(-1)) { 
            targetPos = Vector(0, 0, 215.0f);
        }
    }

    if (::current_map == "sp_a4_finale3") {
        if (name.locate("practice_paint_sprayer_") != uint(-1)) {
            targetPos = Vector(100, 100, 0);
            targetAng = QAngle(90, 0, 90); 
        }
        else if (name.locate("paint_sprayer_2_-960_113_-70_holo") != uint(-1)) {
            targetPos = Vector(135, 0, 145);
            targetAng = QAngle(0, 0, 0); 
        }
        else {
            targetScale = 0.0f;
            targetPos = Vector(0, 0, -5000.0f);
            shouldParent = false;
        }
    }

    if (::current_map == "sp_a4_finale4") {
        if (name.locate("_160_") != uint(-1)) {
            targetScale = 0.0f;
            targetPos = Vector(0, 0, -500.0f); 
            shouldParent = false;               
            absoluteAngles = true;
        } 
        else if (name.locate("paint_blue_sprayer_-544_-16_320_holo") != uint(-1)) {
            targetPos = Vector(0, 0, 0);
            targetAng = QAngle(0, -90, 0); 
            absoluteAngles = false;
        }
        else if (name.locate("pipe_bounce_paint_bomb_template1_") != uint(-1)) {
            targetPos = Vector(90, 0, 0);
            targetAng = QAngle(90, 0, 0); 
            absoluteAngles = false;
        }
        else if (name.locate("toxin_paint_sprayer_882_256_192_holo") != uint(-1)) {
            targetPos = Vector(105, 135, 0);
            targetAng = QAngle(0, -90, 0); 
            absoluteAngles = false;
        }
        else if (name.locate("_728_-368_60_") != uint(-1)) {
            targetPos = Vector(0, 0, 0);
            targetAng = QAngle(0, 0, -90); 
            absoluteAngles = false;
        }
        else if (name.locate("_752_-368_184_") != uint(-1)) {
            targetPos = Vector(0, 0, 0);
            targetAng = QAngle(0, 90, 0); 
            absoluteAngles = false;
        }
        else if (name.locate("_329_-315_443_") != uint(-1) || name.locate("_0_-403_443_") != uint(-1) || name.locate("_0_-325_578_") != uint(-1) || name.locate("_-290_-247_578_") != uint(-1) || name.locate("_-346_775_578_") != uint(-1) || name.locate("_329_827_443_") != uint(-1) || name.locate("_503_546_578_") != uint(-1)) {
            targetPos = Vector(0, 0, 0);
            targetAng = QAngle(0, 0, -90); 
            absoluteAngles = false;
        }
        else if (name.locate("_240_0_64_") != uint(-1) || name.locate("_448_64_64_") != uint(-1)) {
            targetPos = Vector(0, 0, -55);
            targetAng = QAngle(0, 0, 0); 
            absoluteAngles = false;
        }
        else if (name.locate("_544_-360_32_") != uint(-1)) {
            targetPos = Vector(0, 0, -10);
            targetAng = QAngle(0, 0, 0); 
            absoluteAngles = false;
        }
        else if (name.locate("_240_144_24_") != uint(-1)) {
            targetPos = Vector(0, 0, -10);
            targetAng = QAngle(0, 0, 0); 
            absoluteAngles = false;
        }
        else if (name.locate("_0_256_8_") != uint(-1)) {
            targetPos = Vector(0, 0, -10);
            targetAng = QAngle(0, 0, 0); 
            absoluteAngles = false;
        }
        else if (name.locate("paint_white_event_sphere1_") != uint(-1) || name.locate("paint_white_event_sphere2_") != uint(-1) || name.locate("paint_white_event_sphere4_") != uint(-1) || name.locate("paint_white_event_sphere5_") != uint(-1) || name.locate("paint_white_event_sphere7_") != uint(-1) || name.locate("paint_white_event_sphere8_") != uint(-1) || name.locate("paint_white_event_sphere10_") != uint(-1)) {
            targetPos = Vector(0, 0, 0);
            targetAng = QAngle(0, 0, 0); 
            absoluteAngles = false;
        }
        else if (name.locate("paint_blue_event_sphere1_") != uint(-1) || name.locate("paint_blue_event_sphere2_") != uint(-1) || name.locate("paint_blue_event_sphere3_") != uint(-1) || name.locate("paint_blue_event_sphere4_") != uint(-1)) {
            targetPos = Vector(0, 0, -20);
            targetAng = QAngle(0, 0, 0); 
            absoluteAngles = false;
        }
    }
}

} // namespace Archipelago