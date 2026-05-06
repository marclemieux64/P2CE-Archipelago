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
    

    // 1. DEFAULT VALUES (Relative to parent)
    targetPos = Vector(0, 0, 0);
    targetAng = QAngle(0, 0, 0);
    targetSkin = 4; // Default to Skin 4 (Item Skin)
    targetScale = 0.7f;
    shouldParent = true;
    absoluteAngles = false;

    // 2. ITEM CATEGORIES (Translated from Backup)
    bool isCube = (classname == "prop_weighted_cube" || model.locate("metal_box") != uint(-1) || model.locate("box") != uint(-1) || model.locate("cube") != uint(-1));
    bool isLaser = (classname.locate("laser") != uint(-1) || classname.locate("catcher") != uint(-1) || name.locate("laser") != uint(-1));
    bool isButton = (classname.locate("button") != uint(-1));
    bool isFaithPlate = (model.locate("faith_plate") != uint(-1));
    bool isFunnelBridge = (classname == "prop_tractor_beam" || classname == "prop_excursion_funnel" || classname == "prop_wall_projector");

    // G. WHEATLEY MONITORS
    if (model.locate("wheatley_monitor") != uint(-1) || model.locate("screen") != uint(-1) || model.locate("monitor") != uint(-1) || name.tolower().locate("monitor") != uint(-1)) {
        targetPos = Vector(130.0f, 30.0f, 0.0f); // Out from screen
        targetAng = QAngle(90, 0, 0); // Face player
        targetSkin = 0;
        targetScale = 1.0f;
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

    if (isCube || isFaithPlate) {
        targetPos = Vector(0, 0, 40.0f); // Local UP
        targetAng = QAngle(0, 0, 0); // Point Down
        targetSkin = 4;
        targetScale = 0.66f;
        absoluteAngles = true; 
    } else if (isLaser) {
        targetSkin = 4;
        if (classname.locate("relay") != uint(-1) || name.locate("relay") != uint(-1)) {
            targetPos = Vector(0, 0, 40.0f); // Local UP
            targetScale = 0.66f;
        } else {
            targetPos = Vector(24.0f, 0, 0); // Local Forward (out of device)
            targetAng = QAngle(90.0f, 0, 0); 
            targetScale = 0.55f;
        }
    } else if (isButton) {
        targetSkin = 4;
        if (classname.locate("floor") != uint(-1)) {
            targetPos = Vector(0, 0, 40.0f);
            targetScale = 1.0f;
        } else {
            targetPos = Vector(0, 0, 70.0f);
            targetScale = 0.66f;
        }
    } else if (isFunnelBridge) {
        targetSkin = 4;
        if (classname == "prop_wall_projector") {
            targetPos = Vector(32.0f, 0, 0); // Local Forward
            targetAng = QAngle(90.0f, 0, 0);
            targetScale = 0.8f;
        } else {
            targetPos = Vector(0, 0, -50.0f); // Funnels
            targetScale = 0.7f;
        }
    }

    if (::current_map == "sp_a1_intro5") {
        if (name == "cube_dropper_1-cube_dropper_box" || name == "cube_dropper_2-cube_dropper_box") {
            targetPos = Vector(0, 0, 370); // Local vertical offset
            targetAng = QAngle(-180, 0, 0); // Local flip
        }
    }
}

} // namespace Legacy
