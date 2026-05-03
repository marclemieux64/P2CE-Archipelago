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
        } else {
            ArchipelagoLog("Archipelago-Mod: Warning - Could not find 'player_near_portalgun' to spawn hologram.");
        }
    } else if (current_map == "sp_a3_transition01") {
        CBaseEntity@ potato_button = EntityList().FindByName(null, "sphere_entrance_potatos_button");
        if (potato_button !is null) {
            Vector pos = potato_button.GetAbsOrigin();
            pos.z += 32.0f;
            StableCreateAPHologram(pos, QAngle(0, 0, 0), 0.66f, "", "", 0, "sphere_entrance_potatos_button_holo");
        } else {
            ArchipelagoLog("Archipelago-Mod: Warning - Could not find 'sphere_entrance_potatos_button' to spawn hologram.");
        }
    } else if (current_map == "sp_a1_intro7") {
        CBaseEntity@ ent = null;
        while ((@ent = EntityList().FindByClassname(ent, "prop_dynamic")) !is null) {
            if (ent.GetModelName().locate("turret_01.mdl") != uint(-1)) {
                Vector hPos;
                QAngle hAng;
                int hSkin;
                float hScale;
                GetHologramVisualOverrides(ent, hPos, hAng, hSkin, hScale);
                
                string tName = ent.GetEntityName();
                string hName = (tName != "") ? (tName + "_holo") : "turret_holo";
                StableCreateAPHologram(hPos, hAng, hScale, "", "", hSkin, hName);
            }
        }
    }
    
    // 2. Attached moving holograms (Trains, Elevators)
    AddVitrifiedDoorChecks(current_map);

    CBaseEntity@ tEnt = null;
    while ((@tEnt = EntityList().FindByClassname(tEnt, "func_tracktrain")) !is null) {
        string tName = tEnt.GetEntityName();
        if (tName.locate("exit_lift_train") != uint(-1) || tName.locate("departure_elavator") != uint(-1) || tName.locate("departure_elevator") != uint(-1)) {
            AttachHologramToEntity(tName, "", 1.0f, 0.0f, 0);
        }
    }

    // 3. Persistent Turret Handling
    AttachHologramToEntity("npc_portal_turret_floor", "", 0.66f, 20.0f, 2);

    // 4. Final visual refresh to ensure all new holos have correct skins
    RefreshAllAPHolograms();

    // 5. Kill any legacy map-based triggers that try to call 'ppmod'
    DisarmLegacyLogic();
}
