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
    bool isFunnelBridge = (classname == "prop_tractor_beam" || classname == "prop_excursion_funnel");
    bool isMonsterBox = (classname == "prop_monster_box");

    // G. WHEATLEY MONITORS
    if (model.locate("monitor") != uint(-1) || model.locate("screen") != uint(-1) || name.tolower().locate("monitor") != uint(-1)) {
        if (classname == "logic_relay") {
            targetPos = Vector(0.0f, 20.0f, 64.0f); // Pop it out from the relay's wall position
        } else {
            targetPos = Vector(0.0f, -40.0f, 140.0f); // Backup Match: High and Left (Y is Left in some models)
        }
        targetAng = QAngle(0, 0, 0); 
        targetSkin = 0;
        targetScale = 0.8f;
        shouldParent = true;
        absoluteAngles = false;
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

    if (isCube || isFaithPlate) {
        targetPos = Vector(0, 0, 40.0f); // Local UP
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
            targetScale = 0.55f;
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
        shouldParent = true;
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
