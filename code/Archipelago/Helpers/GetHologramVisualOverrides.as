// =============================================================
// ARCHIPELAGO GET HOLOGRAM VISUAL OVERRIDES
// =============================================================

/**
 * GetHologramVisualOverrides - The single source of truth for all hologram rules.
 * Determines position, orientation, skin, scale, and parenting behavior.
 */
void GetHologramVisualOverrides(CBaseEntity@ ent, Vector&out targetPos, QAngle&out targetAng, int&out targetSkin, float&out targetScale, bool&out shouldParent) {
    if (ent is null) return;
    UpdateInternalMapName();

    string classname = ent.GetClassname();
    string model = ent.GetModelName().tolower();
    string name = ent.GetEntityName();
    string lowerName = name.tolower();
    string lowerClass = classname.tolower();

    // Default values
    targetPos = ent.GetAbsOrigin();
    targetAng = ent.GetAbsAngles();
    targetSkin = 1; // Default to Green (Skin 1) for found checks
    targetScale = 0.7f;
    shouldParent = true;

    // 0. SHARED LOGIC FLAGS
    bool isCore = (lowerClass.locate("core") != uint(-1) || lowerName.locate("core") != uint(-1) || model.locate("personality_sphere") != uint(-1));
    bool isElevator = (lowerName.locate("exit_lift_train") != uint(-1) || lowerName.locate("departure_elavator") != uint(-1) || lowerName.locate("departure_elevator") != uint(-1));
    bool isRatmanDen = (lowerName.locate("rd") == 0);
    bool isPortalGun = (lowerName.locate("portal") != uint(-1) && lowerName.locate("gun") != uint(-1));
    bool isTurret = (model.locate("npcs/turret/turret.mdl") != uint(-1));
    bool isCube = (model.locate("box") != uint(-1) || model.locate("cube") != uint(-1) || model.locate("mp_ball") != uint(-1) || lowerClass.locate("cube") != uint(-1));
    bool isAntique = (model.locate("underground") != uint(-1) || model.locate("antique") != uint(-1) || model.locate("vitrified") != uint(-1));
    bool isVitrified = (isAntique || lowerName.locate("vitrified") != uint(-1) || lowerName.locate("dummy_chamber") != uint(-1));
    
    // Fallback: check dictionary for any map if the name is unique to vitrified doors
    if (!isVitrified) {
        array<string>@ keys = g_vitrified_door_names.getKeys();
        for (uint i = 0; i < keys.length(); i++) {
            if (keys[i].locate(":" + name) != uint(-1)) {
                isVitrified = true;
                break;
            }
        }
    }
    
    if (lowerName.locate("dummy_chamber") != uint(-1)) {
        ArchipelagoLog("[AP DEBUG] Found Vitrified Door Candidate: " + name + " (isVitrified: " + isVitrified + ")");
    }

    // 1. GLOBAL BASE RULES (Model/Class based)
    
    // X. VITRIFIED & SPECIAL CHECKS (Must come first to avoid generic class overrides)
    if (isElevator || isRatmanDen || isPortalGun || isVitrified) {
        if (isRatmanDen) targetPos = targetPos + (ent.Up() * 75.0f); else if (isPortalGun) targetPos = targetPos + (ent.Up() * 32.0f);

        string symbols = g_map_symbols;
        bool mapDone = (symbols != "" && symbols.locate("ã") == uint(-1));
        bool rDone = (symbols == "" || symbols.locate("ø") == uint(-1)); 
        bool pDone = (symbols == "" || (symbols.locate("þ") == uint(-1) && symbols.locate("ý") == uint(-1) && symbols.locate("ǫ") == uint(-1)));
        bool vDone = (symbols == "" || symbols.locate("¢") == uint(-1));

        if (isRatmanDen) targetSkin = (rDone || g_ratman_status == 1 || mapDone) ? 4 : 0; 
        else if (isPortalGun) targetSkin = (pDone || mapDone) ? 4 : 0; 
        else if (isVitrified) targetSkin = (vDone || mapDone) ? 4 : 0;
        else targetSkin = mapDone ? 4 : 0;
        return;
    }

    // A. TURRETS (Red Skin 2, Fixed height)
    if (isTurret) {
        targetSkin = 2;
        targetPos = ent.GetAbsOrigin() + (ent.Up() * 80.0f);
        targetScale = 0.66f;
        return;
    }

    // B. CUBES (Weighted, Reflection, Antique, Ball)
    if (isCube) {
        targetPos = ent.GetAbsOrigin() + (ent.Up() * 40.0f);
        targetScale = 0.66f;
        
        // ALL CUBES get absolute downward orientation (90.0f) and no parenting
        targetAng = QAngle(0.0f, 0.0f, 0.0f);
        shouldParent = false;
        return;
    }

    // C. BUTTONS (Pedestal & Floor)
    if (classname.locate("button") != uint(-1)) {
        if (classname.locate("floor") != uint(-1)) {
            targetPos = ent.GetAbsOrigin() + (ent.Up() * 40.0f);
            targetScale = 1.0f;
        } else {
            targetPos = ent.GetAbsOrigin() + (ent.Up() * 70.0f);
            targetScale = 0.66f;
        }
        return;
    }

    // D. LASER DEVICES (Projectors, Catchers, Relays)
    if (classname.locate("laser") != uint(-1) || classname.locate("catcher") != uint(-1) || name.locate("laser") != uint(-1)) {
        targetSkin = 4;
        if (classname.locate("relay") != uint(-1) || name.locate("relay") != uint(-1)) {
            targetPos = ent.GetAbsOrigin() + (ent.Up() * 40.0f);
            targetScale = 0.66f;
        } else {
            targetPos = ent.GetAbsOrigin() + (ent.Forward() * 24.0f);
            targetAng.x += 90.0f;
            targetScale = 0.55f;
        }
        return;
    }

    // E. FUNNELS & BRIDGES (Special Orientation)
    if (classname == "prop_tractor_beam" || classname == "prop_excursion_funnel" || classname == "prop_wall_projector") {
        targetSkin = 4;
        if (classname == "prop_wall_projector") {
            targetPos = ent.GetAbsOrigin() + (ent.Forward() * 32.0f);
            targetAng.x += 90.0f;
            targetScale = 0.8f;
        } else {
            targetPos = ent.GetAbsOrigin() + Vector(0, 0, -50.0f);
            targetAng = QAngle(0, 0, 0);
            targetScale = 0.7f;
        }
        return;
    }

    // F. CORES
    if (isCore) {
        if (name.locate("1") != uint(-1)) targetSkin = 6; else if (name.locate("2") != uint(-1)) targetSkin = 5; else if (name.locate("3") != uint(-1)) targetSkin = 3; else targetSkin = 4;
        targetPos = ent.GetAbsOrigin() + Vector(0, 0, 10.0f);
        targetAng = QAngle(0, 0, 0); 
        return;
    }

    // G. VARIOUS (Frankenturrets, Monitors, Sprayers)
    if (classname == "prop_monster_box" || model.locate("monster") != uint(-1)) {
        targetSkin = 4;
        targetPos = ent.GetAbsOrigin() + (ent.Up() * 24.0f);
        return;
    }
    if (classname == "info_paint_sprayer") {
        targetSkin = 4;
        targetPos = ent.GetAbsOrigin() + (ent.Forward() * 120.0f);
        targetAng.x += 90.0f;
        return;
    }
    if (model.locate("wheatley_monitor") != uint(-1) || name.locate("monitor") != uint(-1)) {
        targetPos = ent.GetAbsOrigin() + (ent.Up() * 140.0f) + (ent.Left() * 40.0f);
        targetScale = 0.9f;
        return;
    }

}
