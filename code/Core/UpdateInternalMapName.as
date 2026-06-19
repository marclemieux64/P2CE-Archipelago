namespace Archipelago {

void UpdateInternalMapName() {
    if (host_map.IsValid()) {
        string detected = host_map.GetString();
        if (detected != "" && detected != "nomap" && detected != "unknown") {
            if (current_map != detected) {
                current_map = detected; 
                ArchipelagoLog("map_name:" + current_map);
                CallVScript("SendToPanorama(\"ArchipelagoMapNameUpdated\", \"" + current_map + "|0\")");
            }
        }
    }
}

} // namespace Archipelago
