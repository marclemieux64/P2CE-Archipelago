void UpdateInternalMapName() {
    ConVarRef hostVar("host_map");
    if (hostVar.IsValid()) {
        string detected = hostVar.GetString();
        if (detected != "" && detected != "nomap" && detected != "unknown") {
            if (current_map != detected) {
                current_map = detected; 
                Msgl("map_name:" + current_map);
            }
        }
    }
}
