// =============================================================
// ARCHIPELAGO CREATE MAP SPECIFIC HOLOS
// =============================================================
void CreateMapSpecificHolos(string current_map) {
    // 1. Spatially defined map holograms
    if (current_map == "sp_a1_intro3") {
        StableCreateAPHologram(Vector(25, 1958, -267), QAngle(0, 0, 0), 0.66f, "", "", 0, "portal_gun_spawner_holo");
    } else if (current_map == "sp_a2_intro") {
        CBaseEntity@ gun_trigger = EntityList().FindByName(null, "player_near_portalgun");
        if (gun_trigger !is null) {
            Vector pos = gun_trigger.GetAbsOrigin();
            pos.z += 32.0f;
            StableCreateAPHologram(pos, QAngle(0, 0, 0), 0.66f, "", "", 0, "player_near_portalgun_holo");
        }
    } else if (current_map == "sp_a3_transition01") {
        CBaseEntity@ potato_button = EntityList().FindByName(null, "sphere_entrance_potatos_button");
        if (potato_button !is null) {
            Vector pos = potato_button.GetAbsOrigin();
            pos.z += 32.0f;
            StableCreateAPHologram(pos, QAngle(0, 0, 0), 0.66f, "", "", 0, "sphere_entrance_potatos_button_holo");
        }
    }
    
    // 2. Transition Logic (Elevators vs. Transition Triggers)
    bool isNonElevatorMap = false;
    for (uint i = 0; i < non_elevator_maps.length(); i++) {
        if (non_elevator_maps[i] == current_map) { isNonElevatorMap = true; break; }
    }

    if (isNonElevatorMap) {
        // GLOBAL TRANSITION TRIGGER HANDLING (Synchronized with CreateCompleteLevelAlertHook)
        
        // A. Positional Triggers (Unnamed trigger_once)
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
                    StableCreateAPHologram(tr.GetAbsOrigin(), QAngle(0, 0, 0), 1.0f, "", "", 0, "transition_trigger_holo");
                }
            }
        }

        // B. Named Transition Hooks
        array<string> transTargets = { 
            "transition_trigger", "trigger_transition", "@transition_from_map", 
            "potatos_end_relay", "relay_transition", "ending_relay"
        };
        
        for (uint s = 0; s < transTargets.length(); s++) {
            CBaseEntity@ t = null;
            while ((@t = EntityList().FindByName(t, transTargets[s])) !is null) {
                StableCreateAPHologram(t.GetAbsOrigin(), QAngle(0, 0, 0), 1.0f, "", "", 0, t.GetEntityName() + "_holo");
            }
        }
    } else {
        // STANDARD ELEVATOR HANDLING
        CBaseEntity@ tEnt = null;
        while ((@tEnt = EntityList().FindByClassname(tEnt, "func_tracktrain")) !is null) {
            string tName = tEnt.GetEntityName();
            if (tName.locate("exit_lift_train") != uint(-1) || tName.locate("departure_elavator") != uint(-1) || tName.locate("departure_elevator") != uint(-1)) {
                AttachHologramToEntity(tName, "", 1.0f, 0.0f, 0);
            }
        }
    }

    // 3. Persistent Overrides
    AddVitrifiedDoorChecks(current_map);
    AttachHologramToEntity("npc_portal_turret_floor", "", 0.66f, 20.0f, 2);

    // 4. Final visual refresh
    RefreshAllAPHolograms();
}
