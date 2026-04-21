void CreateMapSpecificHolos(string current_map) {
    // 1. Spatially defined map holograms
    if (current_map == "sp_a1_intro3") {
        CreateAPHologram(Vector(25, 1958, -299), QAngle(0, 0, 0), 0.66f, "", "", 0);
    } else if (current_map == "sp_a2_intro") {
        CBaseEntity@ gun_trigger = EntityList().FindByName(null, "player_near_portalgun");
        if (gun_trigger !is null) {
            CreateAPHologram(gun_trigger.GetAbsOrigin(), QAngle(0, 0, 0), 0.66f, "", "", 0);
        } else {
            Msgl("AP-Mod: Warning - Could not find 'player_near_portalgun' to spawn hologram.");
        }
    } else if (current_map == "sp_a3_transition01") {
        CBaseEntity@ potato_button = EntityList().FindByName(null, "sphere_entrance_potatos_button");
        if (potato_button !is null) {
            CreateAPHologram(potato_button.GetAbsOrigin(), QAngle(0, 0, 0), 0.66f, "", "", 0);
        } else {
            Msgl("AP-Mod: Warning - Could not find 'sphere_entrance_potatos_button' to spawn hologram.");
        }
    }
    
    // 2. Portal 4 (Chapter 8) Monitor Break Checks
    AddWheatlyMonitorBreakCheck(current_map);

    // 3. Kill any legacy map-based triggers that try to call 'ppmod'
    DisarmLegacyLogic();

    // 4. Detailed map-specific functional setup
    DoMapSpecificSetup(current_map);
    
    // 5. Setup exact legacy map completion hooks natively
    CreateCompleteLevelAlertHook(current_map);
}
