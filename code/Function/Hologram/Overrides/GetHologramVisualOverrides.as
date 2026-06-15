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
            // FIX: Pass mapName parameter context cleanly matching function layout rules
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

        if (classname == "npc_portal_turret_floor" || model.locate("turret.mdl") != uint(-1)) {
            targetPos = Vector(0.0f, 0.0f, 60.0f);
            targetSkin = 2; 
            shouldParent = true;
            return;
        } 

        if (classname.locate("env_portal_laser") != uint(-1) || classname.locate("prop_laser_relay") != uint(-1) || classname.locate("prop_laser_catcher") != uint(-1)) {
            shouldParent = false;   // Pas de parentage physique instable
            absoluteAngles = true;  // Force l'utilisation d'angles mondiaux absolus reconstruits
            targetScale = 0.66f;
            targetSkin = 4;

            // 1. Extraction des axes directionnels de l'émetteur (S'adapte automatiquement au sol, mur, ou plafond)
            Vector forward, right, up;
            AngleVectors(ent.GetAbsAngles(), forward, right, up);

            // 2. Calcul de la position mondiale absolue voulue
            Vector worldPos;
            if (classname.locate("prop_laser_relay") != uint(-1)) {
                worldPos = ent.GetAbsOrigin() + (up * 32.0f); // Décale de 40 unités vers le haut local
            } else {
                worldPos = ent.GetAbsOrigin() + (forward * 32.0f); // Avance de 32 unités dans l'axe du faisceau
            }

            // Contre-mesure pour DeleteEntity : comme cette fonction fait (spawnPos + hPos) de force,
            // on soustrait l'origine de base pour injecter la position absolue parfaite.
            targetPos = worldPos - ent.GetAbsOrigin();

            // 3. Calcul de la rotation mondiale absolue voulue (Orientation adaptée à l'entité)
            if (classname.locate("prop_laser_relay") != uint(-1)) {
                targetAng = ent.GetAbsAngles(); // Reste aligné sur le relais
            } else {
                // Pour faire face au faisceau proprement sur toutes les surfaces (sol, murs, plafonds) :
                // On utilise la deuxième signature valide de l'API pour reconstruire le QAngle complet
                // en lui donnant une direction de visée (up) et un axe de torsion stable (forward * -1)
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
