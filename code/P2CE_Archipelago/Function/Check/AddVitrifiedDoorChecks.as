namespace Archipelago {

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
                    int doorIndex = 0;
                    if (checkName.locate("Vitrified Door 2") != uint(-1) || entName.locate("button2") != uint(-1)) doorIndex = 2; else if (checkName.locate("Vitrified Door 3") != uint(-1) || entName.locate("button3") != uint(-1)) doorIndex = 3; else if (checkName.locate("Vitrified Door 1") != uint(-1) || entName.locate("button") != uint(-1)) doorIndex = 1; else if (checkName.locate("Vitrified Door 4") != uint(-1)) doorIndex = 4; else if (checkName.locate("Vitrified Door 5") != uint(-1)) doorIndex = 5; else if (checkName.locate("Vitrified Door 6") != uint(-1)) doorIndex = 6;

                    SafeAddOutput(ent, "OnPressed", "InitCmd", "Command", "PrintItem " + checkName, 0.0f, 1);
                
                    if (doorIndex > 0) {
                        SafeAddOutput(ent, "OnPressed", "InitCmd", "Command", "ArchipelagoVitrifiedFound " + doorIndex, 0.0f, 1);
                    }
                    SafeAddOutput(ent, "OnPressed", entName + "_holo", "Skin", "4", 0.0f, 1);
                
                // 3. VISUALS (Local-space via Overrides)
                    Vector hPos(0, 0, 0);
                    QAngle hAng(0, 0, 0);
                    int hSkin = 0;
                    float hScale = 1.0f;
                    bool hParent = false;
                    bool hAbs = false;
                    Archipelago::GetHologramVisualOverrides(ent, hPos, hAng, hSkin, hScale, hParent, hAbs);

                    // Check local save state for skin override
                    string bitmask = cv_ArchipelagoVitrifiedStatus.GetString();
                    if (doorIndex > 0 && bitmask.length() >= uint(doorIndex) && bitmask.substr(doorIndex - 1, 1) == "1") {
                        hSkin = 4;
                    }

                    Vector finalPos = ent.GetAbsOrigin() + (AnglesToForward(ent.GetAbsAngles()) * hPos.x) + (AnglesToRight(ent.GetAbsAngles()) * -hPos.y) + (AnglesToUp(ent.GetAbsAngles()) * hPos.z);
                    QAngle finalAng = hAbs ? hAng : (ent.GetAbsAngles() + hAng);

                    CreateAPHologram(finalPos, finalAng, hScale, null, "", hSkin, entName + "_holo", false);
                }
            }
        }
    }

dictionary screen_names;
        array<string> checked_screens;

} // namespace Archipelago
