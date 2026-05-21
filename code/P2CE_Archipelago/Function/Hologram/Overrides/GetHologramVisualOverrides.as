// =============================================================
// ARCHIPELAGO HOLOGRAM OVERRIDES (OPTIMIZED MAIN DISPATCHER)
// =============================================================

namespace Archipelago {

    void GetHologramVisualOverrides(CBaseEntity@ ent, Vector&out targetPos, QAngle&out targetAng, int&out targetSkin, float&out targetScale, bool&out shouldParent, bool&out absoluteAngles) {
    
    // 0. INITIALISATION GÉNÉRALE PAR DÉFAUT
        targetPos = Vector(0, 0, 0);
        targetAng = QAngle(0, 0, 0);
        targetSkin = 4; // Le Skin 4 rouillé Archipelago par défaut
        targetScale = 1.0f;
        shouldParent = false;
        absoluteAngles = false;

        if (ent is null) return;
    
        string classname = ent.GetClassname();
        string model = ent.GetModelName().tolower();
    
    // CORRECTIF SÉCURITÉ CUBES ANONYMES
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
    // CASCADE DE ROUTAGE (Early-Exit pour performances)
    // =============================================================

   
        string mapName = ConVarRef("host_map").GetString();
        if (mapName == "sp_a3_crazy_box") {
        // Interception par son nom d'entité réel ou son modèle underground
            if (name_lower == "erase_blocker_button" || model.locate("underground_testchamber_button") != uint(-1)) {
            
            // 1. Offsets relatifs : AddButtonFrame va calculer automatiquement :
            // BaseOrigin + (Forward * 45.0f) + (Up * 25.0f) -> Strictement ton plan !
                targetPos = Vector(45.0f, 0.0f, 25.0f);
            
            // 2. Modifie l'angle localement de +90° sur le Pitch (axe X)
            // AddButtonFrame fera automatiquement : BaseAngles + QAngle(90.0f, 0.0f, 0.0f)
                targetAng = QAngle(90.0f, 0.0f, 0.0f); 
            
                targetSkin = 4;
                targetScale = 0.66f;
                shouldParent = false; // Coupe le parentage d'os de Valve pour libérer la rotation
                absoluteAngles = false; // Laisse l'addition relative de l'angle s'exécuter proprement
                return;
            }
        }

    
        if (mapName == "sp_a2_turret_blocker") {
            if (classname == "prop_wall_projector") {
                // =============================================================
                // TWEAK THESE VALUES TO ADJUST THE BRIDGE HOLOGRAM!
                // =============================================================
                // targetPos: Offset relative to the projector (X = Forward, Y = Right, Z = Up)
                targetPos = Vector(15.0f, 0.0f, 0.0f);
                
                // targetAng: Angle offset relative to the projector (Pitch, Yaw, Roll)
                // Modify these angles to find the correct orientation for the bridge hologram
                targetAng = QAngle(0.0f, 90.0f, 0.0f); 
                
                targetSkin = 4;        // Skin 4 (Rusty / Uncollected)
                targetScale = 0.66f;   // Visual scale multiplier
                shouldParent = false;  // Keep false so the hologram is unparented and free to rotate
                absoluteAngles = false;// Keep false to combine relative angles properly
                return;
            }
        }

        if (mapName == "sp_a4_stop_the_box") {
            if (classname == "prop_wall_projector") {
                // =============================================================
                // TWEAK THESE VALUES TO ADJUST THE BRIDGE HOLOGRAM!
                // =============================================================
                // targetPos: Offset relative to the projector (X = Forward, Y = Right, Z = Up)
                targetPos = Vector(15.0f, 0.0f, 0.0f);
                
                // targetAng: Angle offset relative to the projector (Pitch, Yaw, Roll)
                // Modify these angles to find the correct orientation for the bridge hologram
                targetAng = QAngle(0.0f, 90.0f, 0.0f); 
                
                targetSkin = 4;        // Skin 4 (Rusty / Uncollected)
                targetScale = 0.66f;   // Visual scale multiplier
                shouldParent = false;  // Keep false so the hologram is unparented and free to rotate
                absoluteAngles = false;// Keep false to combine relative angles properly
                return;
            }
        }

       if (mapName == "sp_a2_bts1") {
        // On vérifie que c'est un bouton, mais on exclut strictement les boutons de sol ("floor")
        if ((name_lower.locate("button") != uint(-1) || model.locate("button") != uint(-1) || classname.locate("button") != uint(-1)) && 
            classname.locate("floor") == uint(-1) && model.locate("floor") == uint(-1) && name_lower.locate("floor") == uint(-1)) {
            
            // Nudge local : Avancer de 45 unités, monter de 25 unités par rapport à la face du bouton
            targetPos = Vector(45.0f, 0.0f, 25.0f);
            
            // Rotation : On récupère l'orientation du bouton et on incline le Pitch de +90.0f pour faire face à toi
            targetAng = ent.GetAbsAngles();
            targetAng.x += 90.0f;
            
            targetSkin = 4;
            targetScale = 0.66f;
            shouldParent = false;  // Brise l'attachement d'os pour appliquer l'offset proprement
            absoluteAngles = true; // Force AddButtonFrame à utiliser targetAng comme angle mondial absolu
            return;
        }
    }

    // 1. CUBES (Délégation immédiate)
        if (classname == "prop_weighted_cube" || model.locate("metal_box") != uint(-1) || model.locate("box") != uint(-1) || model.locate("cube") != uint(-1) || model.locate("reflection") != uint(-1) || model.locate("mp_ball") != uint(-1) || model.locate("underground_weighted_cube") != uint(-1) || name_lower.locate("metal_box") != uint(-1) || name_lower.locate("entity_box_maker_rm1") != uint(-1) || name_lower.locate("cube_dropper_box_spawner") != uint(-1) || name_lower.locate("laser_cube_spawner") != uint(-1) || name_lower.locate("reflection_cube") != uint(-1)) {
            OverrideCube(name, ent, targetPos, targetAng, targetSkin, targetScale, shouldParent, absoluteAngles);
            return; 
        }

    // 2. GELS (Délégation immédiate)
        if (classname == "info_paint_sprayer" || classname == "prop_paint_bomb" || classname == "paint_sphere" || name_lower.locate("trigger_to_drop") != uint(-1) || name_lower.locate("template_artillery") != uint(-1) || (name_lower.locate("paint") != uint(-1) && name_lower.locate("panel") == uint(-1))) {
            OverrideGel(name, ent, targetPos, targetAng, targetSkin, targetScale, shouldParent, absoluteAngles);
            return;
        }

    // 3. LOGIQUE ORIGINALE POUR LES BOUTONS FACTICES
        if (name_lower.locate("dummy_chamber_button") != uint(-1)) {
            targetSkin = 0;
            targetScale = 1.0f;
            shouldParent = true;
            absoluteAngles = true; 

            if (name_lower == "dummy_chamber_button") {
                if (::current_map == "sp_a3_03") { targetPos = Vector(-6.0f, -44.0f, -34.5f); targetAng = QAngle(0, 90, 0); } else if (::current_map == "sp_a3_transition01") { targetPos = Vector(44.0f, -6.0f, -34.5f); targetAng = QAngle(0, 180, 0); }
            } else if (name_lower == "dummy_chamber_button2") {
                if (::current_map == "sp_a3_03") { targetPos = Vector(-6.0f, -44.0f, -34.5f); targetAng = QAngle(0, 90, 0); } else if (::current_map == "sp_a3_transition01") { targetPos = Vector(-44.0f, -6.0f, -34.5f); targetAng = QAngle(0, 180, 0); }
            } else if (name_lower == "dummy_chamber_button3") {
                if (::current_map == "sp_a3_03") { targetPos = Vector(-44.0f, 5.5f, -34.5f); targetAng = QAngle(0, 0, 0); } else if (::current_map == "sp_a3_transition01") { targetPos = Vector(-4.05f, -45.0f, -34.5f); targetAng = QAngle(0, -90, 0); }
            }
            return;
        }

    // 4. AUTRES LOGIQUES DIRECTES
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
            targetPos = Vector(15.0f, 0.0f, 0.0f);
            targetAng = QAngle(90.0f, 0.0f, 0.0f);  
            targetScale = 0.66f;               
            return;
        }

        if (classname == "prop_monster_box") {
            targetPos = Vector(0, 0, 50.0f);
            targetScale = 0.8f;
            shouldParent = true;
            absoluteAngles = true;
            return;
        } 

        if (classname == "npc_portal_turret_floor" || model.locate("turret.mdl") != uint(-1)) {
            targetPos = Vector(0.0f, 0.0f, 60.0f);
            targetSkin = 2; 
            shouldParent = true;
            return;
        } 

        if (classname.locate("env_portal_laser") != uint(-1) || classname.locate("prop_laser_relay") != uint(-1) || classname.locate("prop_laser_catcher") != uint(-1)) {
            shouldParent = true;
            if (classname.locate("prop_laser_relay") != uint(-1)) {
                targetPos = Vector(0, 0, 40.0f);
                targetScale = 0.66f;
            } else {
                targetPos = Vector(32.0f, 0, 0);
                targetScale = 0.66f;
                targetAng = QAngle(90.0f, 0, 0); 
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
            targetAng = QAngle(-90.0f, 0, 0); 
            return;
        }
    }

} // namespace Archipelago
