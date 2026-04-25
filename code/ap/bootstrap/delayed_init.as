/**
 * RunDelayedInitialization - The "Heavy Lift" called once the engine is stable.
 */
void RunDelayedInitialization() {
    // Refresh map name

    UpdateInternalMapName();
    
    if (current_map == "unknown" || current_map == "") return;
    
    // 1. Sanitize once per map load
    if (last_initialized_map != current_map) {
        ResetPersistentSystems();
        DisarmLegacyLogic();
        last_initialized_map = current_map;

        // Queue holograms (Only on fresh map load)
        CBaseEntity@ cmd = EntityList().FindByName(null, "ap_init_cmd");
        if (cmd !is null) {
            Variant v;
            v.SetString("ap_spawn_holos");
            cmd.FireInput("Command", v, 0.5f, null, null, 0);
        }
    }

    // 2. Setup map specific monitors and logic (Always run on refresh)
    AddWheatleyMonitorBreakCheck(current_map); 
    DoMapSpecificSetup(current_map);
    CreateCompleteLevelAlertHook(current_map);

    // 5. MAP SPECIFIC LOGIC (Monitors, etc)
    AddWheatleyMonitorBreakCheck(current_map);
}
