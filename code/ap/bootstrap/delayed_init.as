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
    
    // Automatic Hologram Spawning (Direct call for testing)
    CreateMapSpecificHolos(current_map);
    
    // 3. Flag as initialized
    last_initialized_map = current_map;
    
    // 4. Queue holograms (handled via a safe delay on the entity)
    CBaseEntity@ cmd = EntityList().FindByName(null, "InitCmd");
    if (cmd !is null) {
        Variant v;
        v.SetString("SpawnHolos");
        cmd.FireInput("Command", v, 0.5f, null, null, 0);
    }
}

[ServerCommand("RunDelayedInit", "Runs one-time map setup")]
void RunDelayedInitCmd(const CommandArgs@ args) {
    RunDelayedInitialization();
}
