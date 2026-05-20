// =============================================================
// ARCHIPELAGO ADD VITRIFIED DOOR CHECK
// =============================================================
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
                // Ensure InitCmd exists for local commands
                if (EntityList().FindByName(null, "InitCmd") is null) {
                    CBaseEntity@ cmd = util::CreateEntityByName("point_clientcommand");
                    if (cmd !is null) {
                        cmd.KeyValue("targetname", "InitCmd");
                        cmd.Spawn();
                    }
                }

                // 1. LOGIC HOOK
                // Get the index (1-6) from the check name
                int doorIndex = 0;
                if (checkName.locate("Vitrified Door 2") != uint(-1) || entName.locate("button2") != uint(-1)) doorIndex = 2;
                else if (checkName.locate("Vitrified Door 3") != uint(-1) || entName.locate("button3") != uint(-1)) doorIndex = 3;
                else if (checkName.locate("Vitrified Door 1") != uint(-1) || entName.locate("button") != uint(-1)) doorIndex = 1;
                else if (checkName.locate("Vitrified Door 4") != uint(-1)) doorIndex = 4;
                else if (checkName.locate("Vitrified Door 5") != uint(-1)) doorIndex = 5;
                else if (checkName.locate("Vitrified Door 6") != uint(-1)) doorIndex = 6;

                string trigger = "PrintItem " + checkName;
                SafeAddOutput(ent, "OnPressed", "InitCmd", "Command", trigger, 0.0f, 1);
                
                // 1b. INSTANT VISUAL FEEDBACK & PERSISTENCE
                // We use a custom command to update the local bitmask
                if (doorIndex > 0) {
                    SafeAddOutput(ent, "OnPressed", "InitCmd", "Command", "ArchipelagoVitrifiedFound " + doorIndex, 0.0f, 1);
                }
                SafeAddOutput(ent, "OnPressed", entName + "_holo", "Skin", "4", 0.0f, 1);
                
                ArchipelagoLog("[AP DEBUG] Hooked Vitrified Door: " + entName + " -> " + checkName + " (Index: " + doorIndex + ")");

                // 2. VISUALS & HOLOGRAM
                Vector hPos = ent.GetAbsOrigin() + (ent.Up() * -10.0f + ent.Left() * -30.0f); 
                
                // Manual Position Overrides
                if (key == "sp_a3_03:dummy_chamber_button") hPos = ent.GetAbsOrigin() + (ent.Up() * -34.5f + ent.Left() * -44.0f) + (ent.Forward() * -6.0f);
                else if (key == "sp_a3_03:dummy_chamber_button2") hPos = ent.GetAbsOrigin() + (ent.Up() * -34.5f + ent.Left() * -44.0f) + (ent.Forward() * -6.0f);
                else if (key == "sp_a3_03:dummy_chamber_button3") hPos = ent.GetAbsOrigin() + (ent.Up() * -34.5f + ent.Left() * 5.5f) + (ent.Forward() * -44.0f);
                else if (key == "sp_a3_transition01:dummy_chamber_button") hPos = ent.GetAbsOrigin() + (ent.Up() * -34.5f + ent.Left() * -6.0f) + (ent.Forward() * 44.0f);
                else if (key == "sp_a3_transition01:dummy_chamber_button2") hPos = ent.GetAbsOrigin() + (ent.Up() * -34.5f + ent.Left() * -6.0f) + (ent.Forward() * -44.0f);
                else if (key == "sp_a3_transition01:dummy_chamber_button3") hPos = ent.GetAbsOrigin() + (ent.Up() * -34.5f + ent.Left() * -45.0f) + (ent.Forward() * -4.05f);
                
                QAngle hAng = ent.GetAbsAngles();
                
                // Manual overrides for func_buttons (which have no 'face' angles)
                if (key == "sp_a3_03:dummy_chamber_button") hAng = QAngle(0, 90, 0); 
                else if (key == "sp_a3_03:dummy_chamber_button2") hAng = QAngle(0, 90, 0); 
                else if (key == "sp_a3_03:dummy_chamber_button3") hAng = QAngle(0, 0, 0); 
                else if (key == "sp_a3_transition01:dummy_chamber_button") hAng = QAngle(0, 180, 0); 
                else if (key == "sp_a3_transition01:dummy_chamber_button2") hAng = QAngle(0, 180, 0); 
                else if (key == "sp_a3_transition01:dummy_chamber_button3") hAng = QAngle(0, -90, 0);
                
                // 3. STATUS & SKIN
                int hSkin = 0;
                float hScale = 1.0f;
                
                // Check local bitmask first
                string bitmask = cv_ArchipelagoVitrifiedStatus.GetString();
                bool isLocallyFound = (doorIndex > 0 && bitmask.length() >= uint(doorIndex) && bitmask.substr(doorIndex-1, 1) == "1");

                // Check server symbols (ALL done check)
                bool vDone = (g_map_symbols == "" || g_map_symbols.locate("¢") == uint(-1));
                
                if (isLocallyFound || vDone || g_map_status == 2) {
                    hSkin = 4;
                }

                StableCreateAPHologram(hPos, hAng, hScale, "", "", hSkin, entName + "_holo", ent, "");

                StableCreateAPHologram(hPos, hAng, hScale, "", "", hSkin, entName + "_holo", ent, "");
            }
        }
    }
}
