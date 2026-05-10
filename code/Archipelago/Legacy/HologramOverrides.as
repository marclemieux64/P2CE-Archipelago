// =============================================================
// ARCHIPELAGO HOLOGRAM OVERRIDES (LOCAL OFFSET SYSTEM)
// =============================================================

namespace Legacy {

/**
 * GetHologramVisualOverrides - Centrally defines LOCAL position/angle offsets for holograms.
 * targetPos and targetAng are RELATIVE to the parent entity if shouldParent is true.
 */
void GetHologramVisualOverrides(CBaseEntity@ ent, Vector&out targetPos, QAngle&out targetAng, int&out targetSkin, float&out targetScale, bool&out shouldParent, bool&out absoluteAngles) {
    if (ent is null) return;
    
    string classname = ent.GetClassname();
    string model = ent.GetModelName().tolower();
    string name = ent.GetEntityName();
    

    // 1. OVERRIDE LOGIC (Modify only if category matches)
    // We no longer set defaults here because they are provided by the caller/client.

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
    bool isGel = (classname == "info_paint_sprayer" || classname == "prop_paint_bomb" || classname == "paint_sphere" || name.locate("paint") != uint(-1));
    bool isTurret = (classname == "npc_portal_turret_floor" || model.locate("turret.mdl") != uint(-1));
    
    // WHEATLEY SCREENS
    if (isWheatleyScreen) {
        // Tweak this vector to push the hologram out of the screen.
        // X = Forward/Backward, Y = Left/Right, Z = Up/Down
        targetPos = Vector(30.0f, 0.0f, 100.0f); 
        
        targetAng = QAngle(0.0f, 0.0f, 0.0f); // Keep aligned with the screen
        targetSkin = 0; // Use default skin (or 4 if you prefer)
        targetScale = 1.0f;
        
        shouldParent = true;  // Crucial: stick it to the screen!
        absoluteAngles = false; // Crucial: rotate with the screen!
        
        return; // Exit early so no other rules mess this up
    }
// F. CORES
    if (isCore) {
        // 1. Sélection du skin
        if (name.locate("1") != uint(-1)) targetSkin = 6; 
        else if (name.locate("2") != uint(-1)) targetSkin = 5; 
        else if (name.locate("3") != uint(-1)) targetSkin = 3; 
        else targetSkin = 4;
        
        // 2. Position et Rotation
        // On garde l'origine du cœur, mais on force l'angle mondial
        targetPos = ent.GetAbsOrigin() + Vector(0, 0, 0.0f); // Position absolue
        targetAng = QAngle(0, 0, 0);                        // Angle absolu (Vers le bas)
        
        // 3. Flags de calcul
        // On passe à TRUE pour ignorer l'orientation bizarre du cœur
        absoluteAngles = true; 
        
        // On ne parente pas car l'entité va être supprimée (Remove)
        shouldParent = false; 
        
        // On s'assure que le scale est correct pour éviter le bug "1e-45"
        targetScale = 1.0f; 
        
        return;
    }

    // GELS / PAINT (Système ultra-simplifié)
    if (isGel) {
        targetSkin = 4;              // Skin 4 pour tous les éléments
        targetScale = 1.0f;          // Taille normale
        targetPos = Vector(0, 0, 0); // Zéro offset (pile au centre de l'entité)
        targetAng = QAngle(90, 0, 0); // Zéro rotation supplémentaire
        shouldParent = false;         // Attaché à l'entité (parenting)
        absoluteAngles = false;      // Suit l'orientation de l'entité automatiquement
        return;
    }
    // H. VITRIFIED BUTTONS
    if (name.locate("dummy_chamber_button") != uint(-1)) {
        targetSkin = 0;
        targetScale = 1.0f;
        shouldParent = true;
        absoluteAngles = true; // Use fixed world-angles for these specific buttons

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
        targetPos = Vector(0, 0, 50.0f); // Higher UP for FrankenCubes
        targetAng = QAngle(0, 0, 0);
        targetSkin = 4;
        targetScale = 0.8f;
        shouldParent = true;
        absoluteAngles = true;
        return;
    }
if (isTurret) {
        targetPos = Vector(0.0f, 0.0f, 60.0f); // Monte l'hologramme de 40 unités
        targetAng = QAngle(0.0f, 0.0f, 0.0f);
        targetSkin = 2;       // Skin par défaut (verrouillé)
        targetScale = 1.0f;
        shouldParent = true;  // Stick it to the turret!
        absoluteAngles = false; // Rotation avec la tourelle
        return;
    }
    if (isBridge) {
    targetPos = Vector(0.0f, -40.0f, 0.0f);
    targetAng = QAngle(90.0f, 0.0f, 0.0f);
    targetSkin = 4;
    targetScale = 0.66f;
    absoluteAngles = false; 
    shouldParent = true;
    return;
}
    if (isCube || isFaithPlate) {
        targetPos = Vector(0, 0, 0); // Local UP
        targetAng = QAngle(0, 0, 0); // Point Down
        targetSkin = 4;
        targetScale = 0.66f;
        absoluteAngles = true; 

    } else if (isLaser) {
        targetSkin = 4;
        shouldParent = true;
        absoluteAngles = false; // Follow entity orientation
        if (classname.locate("prop_laser_relay") != uint(-1)) {
            targetPos = Vector(0, 0, 40.0f); // Local UP
            targetAng = QAngle(0, 0, 0);
            targetScale = 0.66f;
        } else {
            targetPos = Vector(32.0f, 0, 0); // Further out to avoid clipping
            targetScale = 0.66f;
            targetAng = QAngle(90.0f, 0, 0); // Rotate to face outward
        }
    } else if (isButton) {
        targetSkin = 4;
        if (classname.locate("floor") != uint(-1) || model.locate("floor_button") != uint(-1)) {
            targetPos = Vector(0, 0, 50.0f);
            targetScale = 1.0f;
            absoluteAngles = false; // Follow button orientation (Floor/Wall/Ceiling)
        } else {
            targetPos = Vector(0, 0, 70.0f);
            targetScale = 0.66f;
        }
    } else if (classname == "prop_tractor_beam") {
        targetSkin = 4;
        targetPos = Vector(80.0f, 0, 0); // Out from wall frame
        targetAng = QAngle(90.0f, 0, 0); // Rotate face to match emitter orientation
        targetScale = 1.0f;
        shouldParent = false;
        absoluteAngles = false; 
    }

    if (::current_map == "sp_a1_intro5") {
        if (name == "cube_dropper_1-cube_dropper_box" || name == "cube_dropper_2-cube_dropper_box") {
            targetPos = Vector(0, 0, 370); // Local vertical offset
            targetAng = QAngle(-180, 0, 0); // Local flip
        }
    }
}

} // namespace Legacy
