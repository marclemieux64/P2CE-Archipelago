// =============================================================
// ARCHIPELAGO HOLOGRAM OVERRIDES (MAIN DISPATCHER)
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
    string name = ent.GetEntityName();

    // 1. ANALYSE UNIQUE DES CATÉGORIES
    bool isCube = (classname == "prop_weighted_cube" || model.locate("metal_box") != uint(-1) || model.locate("box") != uint(-1) || model.locate("cube") != uint(-1));
    bool isLaser = (classname.locate("env_portal_laser") != uint(-1) || classname.locate("prop_laser_relay") != uint(-1) || classname.locate("prop_laser_catcher") != uint(-1));
    bool isButton = (classname.locate("button") != uint(-1));
    bool isFaithPlate = (model.locate("faith_plate") != uint(-1));
    bool isBridge = (classname == "prop_wall_projector");
    bool isMonsterBox = (classname == "prop_monster_box");
    bool isWheatleyScreen = (model.locate("glados_screenborder_curve.mdl") != uint(-1));
    bool isCore = (classname.locate("core") != uint(-1) || name.locate("core") != uint(-1) || model.locate("personality_sphere") != uint(-1));
    bool isTurret = (classname == "npc_portal_turret_floor" || model.locate("turret.mdl") != uint(-1));
    
    bool isGel = (classname == "info_paint_sprayer" || 
                  classname == "prop_paint_bomb" || 
                  classname == "paint_sphere" || 
                  name.locate("trigger_to_drop") != uint(-1) ||
                  name.locate("template_artillery") != uint(-1) ||
                  (name.locate("paint") != uint(-1) && name.locate("panel") == uint(-1) && !isButton && !isCube && !isLaser && !isFaithPlate));

    // 2. DISPATCHER VERS LES FICHIERS EXTERNES (Uniquement pour les structures lourdes)
    if (isGel) {
        // 1. RÈGLE GÉNÉRALE PAR DÉFAUT (Appliquée à TOUS les gels du jeu)
        absoluteAngles = false; 
        shouldParent = false;
        targetAng = QAngle(180, 0, 0);

        // 2. PASSE LE RELAIS AU FICHIER SPÉCIALISÉ (Pour les cas particuliers)
        OverrideGel(name, ent, targetPos, targetAng, targetSkin, targetScale, shouldParent, absoluteAngles);
        return;
    }

    if (isCube) {
        targetScale = 0.66f;
        absoluteAngles = true;
        return;
    }

    // 3. LOGIQUE DIRECTE ET VISIBLE POUR LES OBJETS FIXES ET SIMPLES
    
    // WHEATLEY SCREENS (Visible directement ici !)
    if (isWheatleyScreen) {
        targetPos = Vector(30.0f, 0.0f, 100.0f);
        targetAng = QAngle(0.0f, 0.0f, 0.0f); 
        targetSkin = 0;
        targetScale = 1.0f;
        shouldParent = true;  
        absoluteAngles = false; 
        return;
    }

    // CORES
    if (isCore) {
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

    // VITRIFIED BUTTONS
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

    // FAITH PLATES
    if (isFaithPlate) {
        targetScale = 0.66f;
        absoluteAngles = true;
        return;
    } 

    // BRIDGES / PONS DE LUMIÈRE
    if (isBridge) {
        targetPos = Vector(0.0f, -40.0f, 0.0f);
        targetAng = QAngle(90.0f, 0.0f, 0.0f);
        targetScale = 0.66f;
        shouldParent = true;
        return;
    } 

    // MONSTER BOXES
    if (isMonsterBox) {
        targetPos = Vector(0, 0, 50.0f);
        targetScale = 0.8f;
        shouldParent = true;
        absoluteAngles = true;
        return;
    } 

    // TURRETS
    if (isTurret) {
        targetPos = Vector(0.0f, 0.0f, 60.0f);
        targetSkin = 2; // Rouge par défaut pour les tourelles
        shouldParent = true;
        return;
    } 

    // LASERS
    if (isLaser) {
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

    // BUTTONS NORMaux
    if (isButton) {
        shouldParent = true; 
        if (classname.locate("floor") != uint(-1) || model.locate("floor_button") != uint(-1)) {
            targetPos = Vector(0, 0, 50.0f);
        } else {
            targetPos = Vector(0, 0, 70.0f);
            targetScale = 0.66f;
        }
        return;
    } 

    // TRACTOR BEAMS / FUNNELS
    if (classname == "prop_tractor_beam" || classname == "prop_excursion_funnel") {
        targetSkin = 4; 
        targetPos = Vector(80.0f, 0, 0); 
        targetAng = QAngle(90.0f, 0, 0); 
        return;
    }
}

} // namespace Archipelago