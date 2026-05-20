// =============================================================
// ARCHIPELAGO HOLOGRAM OVERRIDES (OPTIMIZED MAIN DISPATCHER)
// =============================================================

namespace Archipelago {

void GetHologramVisualOverrides(CBaseEntity@ ent, Vector&out targetPos, QAngle&out targetAng, int&out targetSkin, float&out targetScale, bool&out shouldParent, bool&out absoluteAngles) {
    
    // 0. INITIALISATION GÉNÉRALE PAR DÉFAUT
    targetPos = Vector(0, 0, 0);
    targetAng = QAngle(0, 0, 0);
    targetSkin = 4;        // Le Skin 4 rouillé Archipelago par défaut
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
        if (lastSlash != -1) name = shortModelName.substr(lastSlash + 1);
        else name = shortModelName;
    }
    string name_lower = name.tolower();

    // =============================================================
    // CASCADE DE ROUTAGE (Early-Exit pour performances)
    // =============================================================

    // 1. CUBES (Délégation immédiate)
    if (classname == "prop_weighted_cube" || model.locate("metal_box") != uint(-1) || model.locate("box") != uint(-1) || model.locate("cube") != uint(-1) || model.locate("reflection") != uint(-1) || model.locate("mp_ball") != uint(-1) || model.locate("underground_weighted_cube") != uint(-1) || name_lower.locate("metal_box") != uint(-1) || name_lower.locate("entity_box_maker_rm1") != uint(-1) || name_lower.locate("cube_dropper_box_spawner") != uint(-1) || name_lower.locate("laser_cube_spawner") != uint(-1) || name_lower.locate("reflection_cube") != uint(-1)) 
    {
        OverrideCube(name, ent, targetPos, targetAng, targetSkin, targetScale, shouldParent, absoluteAngles);
        return; 
    }

    // 2. GELS (Délégation immédiate)
    if (classname == "info_paint_sprayer" || classname == "prop_paint_bomb" || classname == "paint_sphere" || name_lower.locate("trigger_to_drop") != uint(-1) || name_lower.locate("template_artillery") != uint(-1) || (name_lower.locate("paint") != uint(-1) && name_lower.locate("panel") == uint(-1))) 
    {
        OverrideGel(name, ent, targetPos, targetAng, targetSkin, targetScale, shouldParent, absoluteAngles);
        return;
    }

    // 3. LOGIQUE ORIGINALE POUR LES BOUTONS FACTICES (Restaurée à l'identique)
    if (name_lower.locate("dummy_chamber_button") != uint(-1)) {
        targetSkin = 0;
        targetScale = 1.0f;
        shouldParent = true;
        absoluteAngles = true; 

        if (name_lower == "dummy_chamber_button") {
            if (::current_map == "sp_a3_03") { targetPos = Vector(-6.0f, -44.0f, -34.5f); targetAng = QAngle(0, 90, 0); }
            else if (::current_map == "sp_a3_transition01") { targetPos = Vector(44.0f, -6.0f, -34.5f); targetAng = QAngle(0, 180, 0); }
        } else if (name_lower == "dummy_chamber_button2") {
            if (::current_map == "sp_a3_03") { targetPos = Vector(-6.0f, -44.0f, -34.5f); targetAng = QAngle(0, 90, 0); }
            else if (::current_map == "sp_a3_transition01") { targetPos = Vector(-44.0f, -6.0f, -34.5f); targetAng = QAngle(0, 180, 0); }
        } else if (name_lower == "dummy_chamber_button3") {
            if (::current_map == "sp_a3_03") { targetPos = Vector(-44.0f, 5.5f, -34.5f); targetAng = QAngle(0, 0, 0); }
            else if (::current_map == "sp_a3_transition01") { targetPos = Vector(-4.05f, -45.0f, -34.5f); targetAng = QAngle(0, -90, 0); }
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
        if (name.locate("1") != uint(-1)) targetSkin = 6;
        else if (name.locate("2") != uint(-1)) targetSkin = 5; 
        else if (name.locate("3") != uint(-1)) targetSkin = 3; 
        else targetSkin = 4;
        targetPos = Vector(0, 0, 0.0f);
        targetAng = QAngle(0, 0, 0);
        absoluteAngles = true;
        shouldParent = false;
        targetScale = 1.0f;
        return;
    }

    if (model.locate("faith_plate") != uint(-1)) {
        targetScale = 0.66f;
        absoluteAngles = true;
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
        targetAng = QAngle(90.0f, 0, 0); 
        return;
    }
}

} // namespace Archipelago