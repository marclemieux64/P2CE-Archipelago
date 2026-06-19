// =============================================================
// ARCHIPELAGO MAP CHECK
// =============================================================

namespace Archipelago {

class HologramConfig {
    Vector pos;
    QAngle ang;
    bool animate;
    HologramConfig(Vector p, QAngle a, bool anim) { pos = p; ang = a; animate = anim; }
}

void AddMapCheck() {
    if (current_map == "unknown" || current_map == "") return;

    bool isNonElevatorMap = (non_elevator_maps.find(current_map) != -1);

    // --- 1. NON-ELEVATOR MAPS REGISTRY ---
    if (isNonElevatorMap) {
    // map internal name           | Position (x, y, z)           | Angle (pitch, yaw, roll)  | is Animated |
        dictionary staticHolograms = {
            { "sp_a1_intro1",          HologramConfig(Vector(-9728, -2976, -550),      QAngle(0, 0, 0),       true) },
            { "sp_a1_intro2",          HologramConfig(Vector(-8448, -4448, -550),      QAngle(0, 0, 0),       true) },
            { "sp_a1_intro4",          HologramConfig(Vector(-5504, -4064, -220),      QAngle(0, 0, 0),       true) },
            { "sp_a1_intro5",          HologramConfig(Vector(-3904, -3456, -350),      QAngle(0, 0, 0),       true) },
            { "sp_a1_intro6",          HologramConfig(Vector(-1024, -3456, -350),      QAngle(0, 0, 0),       true) },
            { "sp_a2_intro",           HologramConfig(Vector(192, 128, -90),           QAngle(0, 0, 0),       true) },
            { "sp_a1_intro7",          HologramConfig(Vector(-2208, 376, 1280),        QAngle(0, 0, 0),       true) },
            { "sp_a1_wakeup",          HologramConfig(Vector(6165, 3456, 904),         QAngle(0, -90, 90),    false) },
            { "sp_a2_turret_intro",    HologramConfig(Vector(-352.380, 392, -206),     QAngle(0, 0, 0),       true) },
            { "sp_a2_bts1",            HologramConfig(Vector(1264, -1344, -390),       QAngle(0, 0, 0),       true) },
            { "sp_a2_bts2",            HologramConfig(Vector(2208, 1896, 688),         QAngle(0, 0, 0),       true) },
            { "sp_a2_bts3",            HologramConfig(Vector(5952, 4624, -1736),       QAngle(0, 0, 0),       true) },
            { "sp_a2_bts4",            HologramConfig(Vector(-4080, -7232, 6328),      QAngle(0, 0, 0),       true) },
            { "sp_a2_bts5",            HologramConfig(Vector(1592.840, 512.986, 4492), QAngle(0, 90, 0),      false) },
            { "sp_a2_bts6",            HologramConfig(Vector(-2656, -5120, 5228),      QAngle(0, 90, 0),      false) },
            { "sp_a3_01",              HologramConfig(Vector(6016, 4496, -448),        QAngle(0, 0, 0),       true) },
            { "sp_a3_portal_intro",    HologramConfig(Vector(3839.990, 348.800, 5674), QAngle(0, 0, 0),       true) },
            { "sp_a4_laser_platform",  HologramConfig(Vector(3456, -1024, -2480),      QAngle(0, 0, 0),       true) },
            { "sp_a4_finale1",         HologramConfig(Vector(-12832, -3040, -112),     QAngle(0, 0, 0),       true) },
            { "sp_a4_finale2",         HologramConfig(Vector(-3152, -1928, -280),      QAngle(0, 0, 0),       true) },
            { "sp_a4_finale3",         HologramConfig(Vector(-616, 5376, 580),         QAngle(0, 0, 0),       true) }
        };

        if (staticHolograms.exists(current_map)) {
            HologramConfig@ cfg = cast<HologramConfig>(staticHolograms[current_map]);
            CreateAPHologram(cfg.pos, cfg.ang, 1.0f, null, "", 0, current_map + "_map_check_holo", cfg.animate);
        }
        
        // Specific tracking parent logic for sp_a3_00
        else if (current_map == "sp_a3_00") {
            CBaseEntity@ shaft = EntityList().FindByName(null, "shaft_section_10");
            if (shaft !is null) {
                CreateAPHologram(Vector(0, 0, 350), QAngle(0, 0, 90), 1.5f, shaft, "", 0, "sp_a3_00_map_check_holo", false);
            }
        }

        // Named Relays (Dynamic Transition Entities)
        string[] transTargets = { "transition_logic_relay", "relay_exit_opened", "elevator_entry_relay", "end_relay" };
        for (uint s = 0; s < transTargets.length(); s++) {
            CBaseEntity@ t = null;
            while ((@t = EntityList().FindByName(t, transTargets[s])) !is null) {
                CreateAPHologram(t.WorldSpaceCenter(), QAngle(0, 0, 0), 1.0f, null, "", 0, t.GetEntityName() + "map_check_trigger_holo", true);
            }
        }
    }
    
    // --- 2. ELEVATOR LOGIC ---
    if (!isNonElevatorMap || current_map == "sp_a2_core" || current_map == "sp_a1_intro1") {
        CBaseEntity@ tEnt = null;
        while ((@tEnt = EntityList().FindByClassname(tEnt, "func_tracktrain")) !is null) {
            string tName = tEnt.GetEntityName();
            if (tName.locate("exit_lift_train") != uint(-1) || tName.locate("departure_elevator-elevator") != uint(-1) || tName.locate("exit_elevator_train") != uint(-1)) {
                CreateAPHologram(Vector(0, 0, 0), QAngle(0, 0, 0), 1.0f, tEnt, "", 0, "map_check_trigger_elevator_holo", true);
            }
        }
    }

    // --- MOON HOLOGRAM ---
    if (current_map == "sp_a4_finale4") {
        CBaseEntity@ moon = EntityList().FindByName(null, "sprite_moon_portal"); 
        if (moon !is null) {
            Vector pos = moon.GetAbsOrigin() + Vector(-85.0f, 25.0f, 0.0f); 
            CreateAPHologram(pos, QAngle(0.0f, -277.0f, 90.0f), 2.0f, null, "", 0, "moon_holo", false);
        }
    }
} 

} // namespace Archipelago