void AddVitrifiedDoorChecks(string map_name) {
    InitLocationRegistries();
    
    array<string>@ keys = g_vitrified_door_names.getKeys();
    for (uint i = 0; i < keys.length(); i++) {
        string key = keys[i];
        if (key.locate(map_name + ":") == 0) {
            string entName = key.substr(map_name.length() + 1);
            string checkName;
            g_vitrified_door_names.get(key, checkName);
            
            CBaseEntity@ ent = EntityList().FindByName(null, entName);
            if (ent !is null) {
                // 1. LOGIC HOOK
                // We use PrintItemCmd to report the check name to the client
                string trigger = "PrintItem " + checkName;
                SafeAddOutput(ent, "OnPressed", "InitCmd", "Command", trigger, 0.0f, -1);
                
                ArchipelagoLog("[AP DEBUG] Hooked Vitrified Door: " + entName + " -> " + checkName);

                // 2. VISUALS & HOLOGRAM
                Vector hPos = ent.GetAbsOrigin();
                hPos.z -= 25.0f; // As per the user's VScript: Vector(0, 0, -25)
                
                QAngle hAng = QAngle(0, 0, 0);
                int hSkin = 0;
                float hScale = 0.6f;

                // Check for current status (¢ symbol)
                bool vDone = (g_map_symbols != "" && g_map_symbols.locate("¢") != uint(-1));
                if (vDone || g_map_status == 2) {
                    hSkin = 4;
                }

                StableCreateAPHologram(hPos, hAng, hScale, "", "", hSkin, entName + "_holo", ent);
            }
        }
    }
}
