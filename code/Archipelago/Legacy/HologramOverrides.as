// =============================================================
// ARCHIPELAGO HOLOGRAM OVERRIDES (LOCAL OFFSET SYSTEM)
// =============================================================

namespace Legacy {

void GetHologramVisualOverrides(CBaseEntity@ ent, Vector&out targetPos, QAngle&out targetAng, int&out targetSkin, float&out targetScale, bool&out shouldParent, bool&out absoluteAngles) {
    
    // 0. INITIALISATION OBLIGATOIRE (Détruit par le &out d'AngelScript)
    // C'est ici que l'on définit la couleur et la taille pour tous les objets normaux
    targetPos = Vector(0, 0, 0);
    targetAng = QAngle(0, 0, 0);
    targetSkin = 4;        // <-- Le fameux Skin 4 rouillé par défaut !
    targetScale = 1.0f;
    shouldParent = false;
    absoluteAngles = false;

    if (ent is null) return;
    
    string classname = ent.GetClassname();
    string model = ent.GetModelName().tolower();
    string name = ent.GetEntityName();
    

    // 2. ITEM CATEGORIES (Translated from Backup)
    bool isCube = (classname == "prop_weighted_cube" || model.locate("metal_box") != uint(-1) || model.locate("box") != uint(-1) || model.locate("cube") != uint(-1));
    bool isLaser = (classname.locate("env_portal_laser") != uint(-1) || classname.locate("prop_laser_relay") != uint(-1) || classname.locate("prop_laser_catcher") != uint(-1));
    bool isButton = (classname.locate("button") != uint(-1));
    bool isFaithPlate = (model.locate("faith_plate") != uint(-1));
    bool isFunnel = (classname == "prop_tractor_beam" || classname == "prop_excursion_funnel");
    bool isBridge = (classname == "prop_wall_projector");
    bool isMonsterBox = (classname == "prop_monster_box");
    bool isWheatleyScreen = (model.locate("glados_screenborder_curve.mdl") != uint(-1));
    bool isCore = (classname.locate("core") != uint(-1) || name.locate("core") != uint(-1) || model.locate("personality_sphere") != uint(-1));
    bool isTurret = (classname == "npc_portal_turret_floor" || model.locate("turret.mdl") != uint(-1));
    
    // LE CORRECTIF EST ICI : On ajoute des exclusions strictes pour éviter les faux positifs !
    bool isGel = (classname == "info_paint_sprayer" || classname == "prop_paint_bomb" || classname == "paint_sphere" || (name.locate("paint") != uint(-1) && !isButton && !isCube && !isLaser && !isFaithPlate));

    // WHEATLEY SCREENS
    if (isWheatleyScreen) {
        targetPos = Vector(30.0f, 0.0f, 100.0f);
        targetAng = QAngle(0.0f, 0.0f, 0.0f); 
        targetSkin = 0;
        targetScale = 1.0f;
        shouldParent = true;  
        absoluteAngles = false; 
        return;
    }

    // F. CORES
    if (isCore) {
        if (name.locate("1") != uint(-1)) targetSkin = 6;
        else if (name.locate("2") != uint(-1)) targetSkin = 5; 
        else if (name.locate("3") != uint(-1)) targetSkin = 3; 
        else targetSkin = 4;
        
        // CORRECTIF : On n'utilise plus ent.GetAbsOrigin() ! 
        // On utilise un simple décalage local de zéro.
        targetPos = Vector(0, 0, 0.0f);
        targetAng = QAngle(0, 0, 0);
        absoluteAngles = true;
        shouldParent = false;
        targetScale = 1.0f;
        return;
    }

    // GELS / PAINT
    if (isGel) {
        // 1. Règle générale (Appliquée en premier à tous les gels)
        targetAng = QAngle(180, 0, 0);
        
        // 2. Exception globale pour la map sp_a3_jump_intro
        if (::current_map == "sp_a3_jump_intro") {
            // Écrase la règle générale : TOUS les gels de cette map seront à -90
            targetAng = QAngle(-90, 0, 0); 
        }
        
        if (::current_map == "sp_a3_speed_ramp") {
            
            if (name == "paint_sprayer_576_0_704_holo") {
                // Pour "annuler" ce doublon, on le réduit à 0 et on le cache sous la map
                targetScale = 0.0f;
                targetPos = Vector(0, 0, -5000.0f);
            } 
            else if (name == "paint_sprayer_576_0_696_holo" || 
                     name == "paint_sprayer_2_-1600_-896_960_holo" || 
                     name == "paint_sprayer_3_-1600_-384_960_holo") {
                
                targetAng = QAngle(90, 0, 0); 
            }
        }

        if (::current_map == "sp_a3_speed_flings") {
            if (name == "paint_sprayer_speed_2560_-128_-152_holo" || 
                name == "paint_sprayer_bounce_2816_-128_320_holo") {
                
                targetAng = QAngle(90, 0, 0); 
            }
        }
        if (::current_map == "sp_a3_portal_intro") {
            
            // 1. Le sprayer de gel Blanc
            if (name == "pump_machine_white_sprayer_1908_1712_-1984_holo") {
                targetAng = QAngle(-90, 0, 0); 
            } 
            
            // 2. Le sprayer de gel Bleu
            else if (name == "pump_machine_blue_sprayer_1088_1712_-2068_holo") {
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
            // 5a. Premier paint sprayer isolé (Ang d'origine: 270 0 0)
            else if (name == "paint_sprayer_1_32_99_144_holo") {
                targetPos = ent.GetAbsOrigin(); 
                QAngle nativeAng = ent.GetAbsAngles(); 
                
                // Modifiez les offsets ici (Pitch, Yaw, Roll)
                targetAng = QAngle(0, 0, 0); 
                absoluteAngles = true;
            }

            // 5b. Deuxième paint sprayer isolé (Ang d'origine: 225 180 0)
            else if (name == "paint_sprayer_2_287_192_292_holo") {
                targetPos = ent.GetAbsOrigin(); 
                QAngle nativeAng = ent.GetAbsAngles(); 
                
                // Modifiez les offsets ici indépendamment du premier (Pitch, Yaw, Roll)
                targetAng = QAngle(nativeAng.x + 90.0f, nativeAng.y + 0.0f, nativeAng.z + 0.0f); 
                absoluteAngles = true;
            }
        }

        if (::current_map == "sp_a3_end") {
            
            // Attrape les 6 hologrammes paint_trickle (Bleu, Orange et Blanc) d'un coup
            if (name.locate("paint_trickle") != uint(-1)) {
            
            }
        }
        
        // 3. On quitte la fonction proprement
        return;
    }

    // H. VITRIFIED BUTTONS
    if (name.locate("dummy_chamber_button") != uint(-1)) {
        targetSkin = 0;
        targetScale = 1.0f;
        shouldParent = true;
        absoluteAngles = true; 

        if (name == "dummy_chamber_button") {
            if (::current_map == "sp_a3_03") { targetPos = Vector(-6.0f, -44.0f, -34.5f); targetAng = QAngle(0, 90, 0); }
            else if (::current_map == "sp_a3_transition01") { targetPos = Vector(44.0f, -6.0f, -34.5f); targetAng = QAngle(0, 180, 0); }
        } else if (name == "dummy_chamber_button2") {
            if (::current_map == "sp_a3_03") { targetPos = Vector(-6.0f, -44.0f, -34.5f); targetAng = QAngle(0, 90, 0); }
            else if (::current_map == "sp_a3_transition01") { targetPos = Vector(-44.0f, -6.0f, -34.5f); targetAng = QAngle(0, 180, 0); }
        } else if (name == "dummy_chamber_button3") {
            if (::current_map == "sp_a3_03") { targetPos = Vector(-44.0f, 5.5f, -34.5f); targetAng = QAngle(0, 0, 0); }
            else if (::current_map == "sp_a3_transition01") { targetPos = Vector(-4.05f, -45.0f, -34.5f); targetAng = QAngle(0, -90, 0); }
        }
        return;
    }

    if (isMonsterBox) {
        targetPos = Vector(0, 0, 50.0f);
        targetScale = 0.8f;
        shouldParent = true;
        absoluteAngles = true;
        return;
    }

    if (isTurret) {
        targetPos = Vector(0.0f, 0.0f, 60.0f);
        targetSkin = 2; // Rouge par défaut pour les tourelles
        shouldParent = true;  
        return;
    }

    if (isBridge) {
        targetPos = Vector(0.0f, -40.0f, 0.0f);
        targetAng = QAngle(90.0f, 0.0f, 0.0f);
        targetScale = 0.66f;
        shouldParent = true;
        return;
    }

    if (isCube || isFaithPlate) {
        targetScale = 0.66f;
        absoluteAngles = true;
    } else if (isLaser) {
        shouldParent = true;
        if (classname.locate("prop_laser_relay") != uint(-1)) {
            targetPos = Vector(0, 0, 40.0f); 
            targetScale = 0.66f;
        } else {
            targetPos = Vector(32.0f, 0, 0); 
            targetScale = 0.66f;
            targetAng = QAngle(90.0f, 0, 0); 
        }
    } else if (isButton) {
        shouldParent = true; // <-- AJOUT CRUCIAL pour les boutons
        if (classname.locate("floor") != uint(-1) || model.locate("floor_button") != uint(-1)) {
            targetPos = Vector(0, 0, 50.0f);
        } else {
            targetPos = Vector(0, 0, 70.0f);
            targetScale = 0.66f;
        }
    } else if (classname == "prop_tractor_beam") {
        targetSkin = 4; // <-- AJOUT CRUCIAL pour forcer le bleu sur les rayons tracteurs
        targetPos = Vector(80.0f, 0, 0); 
        targetAng = QAngle(90.0f, 0, 0); 
    }

    if (::current_map == "sp_a1_intro5") {
        if (name == "cube_dropper_1-cube_dropper_box" || name == "cube_dropper_2-cube_dropper_box") {
            targetPos = Vector(0, 0, 370);
            targetAng = QAngle(-180, 0, 0);
        }
    }
}

} // namespace Legacy