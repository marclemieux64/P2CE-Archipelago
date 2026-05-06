// =============================================================
// ARCHIPELAGO LEGACY MAP CHECK (Hologram Spawning)
// =============================================================

namespace Legacy {

void AddMapCheck() {
    if (current_map == "unknown" || current_map == "") return;

    bool isNonElevatorMap = false;
    for (uint i = 0; i < non_elevator_maps.length(); i++) {
        if (non_elevator_maps[i] == current_map) { 
            isNonElevatorMap = true; 
            break; 
        }
    }

    if (isNonElevatorMap) {
        // 1. Unnamed Positional Triggers
        CBaseEntity@ tr = null;
        while ((@tr = EntityList().FindByClassname(tr, "trigger_once")) !is null) {
            if (tr.GetEntityName() == "") { 
                Vector pos = tr.GetAbsOrigin();
                bool is_target = false;
                if (current_map == "sp_a2_bts3" && pos.DistTo(Vector(5952, 4624, -1736)) < 100) is_target = true;
                else if (current_map == "sp_a2_bts4" && pos.DistTo(Vector(-4080, -7232, 6328)) < 100) is_target = true;
                else if (current_map == "sp_a2_core" && pos.DistTo(Vector(0, 304, -10438)) < 100) is_target = true;
                else if (current_map == "sp_a4_finale1" && pos.DistTo(Vector(-12832, -3040, -112)) < 100) is_target = true;
                else if (current_map == "sp_a4_finale2" && pos.DistTo(Vector(-3152, -1928, -240)) < 100) is_target = true;

                if (is_target) {
                    CreateAPHologram(tr.WorldSpaceCenter(), QAngle(0, 0, 0), 1.0f, null, "", 0, "transition_trigger_holo");
                }
            }
        }

        // 2. Named Transition Hooks
        array<string> transTargets = { 
            "transition_trigger", "trigger_transition", "@transition_from_map", 
            "potatos_end_relay", "relay_transition", "ending_relay"
        };
        
        for (uint s = 0; s < transTargets.length(); s++) {
            CBaseEntity@ t = null;
            while ((@t = EntityList().FindByName(t, transTargets[s])) !is null) {
                CreateAPHologram(t.WorldSpaceCenter(), QAngle(0, 0, 0), 1.0f, null, "", 0, t.GetEntityName() + "_holo");
            }
        }
    } else {
        // 3. Standard Elevator Handling
        CBaseEntity@ tEnt = null;
        while ((@tEnt = EntityList().FindByClassname(tEnt, "func_tracktrain")) !is null) {
            string tName = tEnt.GetEntityName();
            if (tName.locate("exit_lift_train") != uint(-1) || tName.locate("departure_elavator") != uint(-1) || tName.locate("departure_elevator") != uint(-1)) {
                CreateAPHologram(Vector(0, 0, 0), QAngle(0, 0, 0), 1.0f, tEnt, "", 0, tName + "_holo");
            }
        }
    }
}

} // namespace Legacy
