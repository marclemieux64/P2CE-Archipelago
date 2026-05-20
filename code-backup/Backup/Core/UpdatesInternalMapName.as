// =============================================================
// ARCHIPELAGO UPDATES INTERNAL MAP NAME
// =============================================================

/**
 * UpdateInternalMapName - Safely grabs the current map name from the engine.
 */
void UpdateInternalMapName() {
    // Access the global ConVarRef from globals.as
    if (host_map.IsValid()) {
        string detected = host_map.GetString();
        
        // Ensure the string is non-empty and not a default value
        if (detected != "" && detected != "nomap" && detected != "unknown") {
            // Standardizing the current_map check to avoid null-access on boot
            if (current_map != detected) {
                current_map = detected; 
                ArchipelagoLog("map_name:" + current_map);
                CallVScript("SendToPanorama(\"ArchipelagoMapNameUpdated\", \"" + current_map + "|0\")");
            }
        }
    }
}
