/**
 * RunDelayedInitialization - The "Heavy Lift" called once the engine is stable.
 */
void RunDelayedInitialization() {
    // Refresh map name
    UpdateInternalMapName();
    
    if (current_map == "unknown" || current_map == "") return;
    if (last_initialized_map == current_map) return;

    // 1. Sanitize and Disarm
    ResetPersistentSystems();
    DisarmLegacyLogic();

    // 2. Setup map specific monitors and logic
    AddWheatleyMonitorBreakCheck(current_map);
    DoMapSpecificSetup(current_map);
    CreateCompleteLevelAlertHook(current_map);
    
    // 3. Flag as initialized
    last_initialized_map = current_map;
    
    // 4. Queue holograms (handled via a safe delay on the entity)
    CBaseEntity@ cmd = EntityList().FindByName(null, "ap_init_cmd");
    if (cmd !is null) {
        Variant v;
        v.SetString("ap_spawn_holos");
        cmd.FireInput("Command", v, 0.5f, null, null, 0);

        // 5. Start the Master Heartbeat Timer (High Frequency for smooth movement)
        CBaseEntity@ timer = util::CreateEntityByName("logic_timer");
        if (timer !is null) {
            timer.KeyValue("targetname", "ap_heartbeat_timer");
            timer.KeyValue("RefireTime", "0.1"); // 10 times per second
            timer.Spawn();

            Variant vTimer;
            vTimer.SetString("OnTimer ap_init_cmd:Command:ap_deathlink_tick:0:-1");
            timer.FireInput("AddOutput", vTimer, 0.0f, null, null, 0);
            
            // Separate Enable input with an empty variant to be safe
            Variant vEmpty;
            timer.FireInput("Enable", vEmpty, 0.01f, null, null, 0);
        }
    }
}
