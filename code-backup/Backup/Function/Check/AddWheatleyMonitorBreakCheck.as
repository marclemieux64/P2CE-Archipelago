// =============================================================
// ARCHIPELAGO ADD WHEATLEY MONITOR BREAK CHECK
// =============================================================
void AddWheatleyMonitorBreakCheck(string map_name) {
    InitWheatleyMonitorRegistry();
    
    // 1. PROCESS REGISTERED MONITORS (Exact Dictionary Match)
    // We only hook and spawn holograms for the SPECIFIC entities listed in the registry.
    array<string>@ keys = g_monitor_break_names.getKeys();
    for (uint i = 0; i < keys.length(); i++) {
        string key = keys[i];
        if (key.locate(map_name + ":") == 0) {
            // Found a monitor for this map!
            string entName = key.substr(map_name.length() + 1);
            string locationID;
            g_monitor_break_names.get(key, locationID);
            
            // Find the EXACT entity named in the dictionary
            CBaseEntity@ ent = EntityList().FindByName(null, entName);
            if (ent !is null) {
                // A. LOGIC HOOK
                // Determine the correct output signal based on the entity class
                string cls = ent.GetClassname();
                string output = "OnTrigger"; // Default for logic_relay
                if (cls == "func_breakable") {
                    output = "OnBreak";
                } else if (cls.locate("trigger") != uint(-1)) {
                    output = "OnStartTouch";
                }
                
                string safe_id = locationID.replace(" ", "."); // Use period for safe engine transfer
                Variant v;
                v.SetString(output + " InitCmd:Command:PrintMonitor " + safe_id + ":0.0:-1");
                ent.FireInput("AddOutput", v, 0.0f, null, null, 0);

                ArchipelagoLog("[AP DEBUG] Hooked EXACT entity: " + entName + " (" + cls + ") using signal: " + output);

                // B. VISUALS & HOLOGRAM
                // Spawn exactly ONE hologram at this entity's location
                string holo_name = entName + "_holo";
                
                // Determine anchor (Use nearby monitor model if possible for better positioning)
                CBaseEntity@ anchor = ent;
                CBaseEntity@ prop = EntityList().FindByClassnameNearest("prop_dynamic", ent.GetAbsOrigin(), 128.0f);
                if (prop !is null && prop.GetModelName().locate("wheatley_monitor") != uint(-1)) {
                    @anchor = prop;
                }

                Vector hPos;
                QAngle hAng;
                int hSkin;
                float hScale;
                bool shouldParent;
                GetHologramVisualOverrides(anchor, hPos, hAng, hSkin, hScale, shouldParent);

                StableCreateAPHologram(hPos, hAng, hScale, "", "", hSkin, holo_name, shouldParent ? anchor : null);
            }
        }
    }

} // End of function
