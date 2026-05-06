// =============================================================
// ARCHIPELAGO RUN DELAYED INITIALIZATION
// =============================================================

/**
 * RunDelayedInitialization - The "Heavy Lift" called once the engine is stable.
 */
void RunDelayedInitialization() {
    if (cv_ArchipelagoDebug.GetBool()) ArchipelagoLog("[AP DEBUG] RunDelayedInitialization STARTED");
    UpdateInternalMapName();
    
    if (current_map == "unknown" || current_map == "") return;

    // Force client to resync
    current_map = ""; 
    UpdateInternalMapName();
    CallVScript("SendToPanorama(\"ArchipelagoMapNameUpdated\", \"" + current_map + "|1\")");

    // 1. Sanitize and Disarm
    ResetPersistentSystems();
    DisarmLegacyLogic();

    // 2. Setup map specific monitors and logic
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


