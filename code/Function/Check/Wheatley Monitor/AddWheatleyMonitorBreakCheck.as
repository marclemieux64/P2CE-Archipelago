namespace Archipelago {

void AddWheatleyMonitorBreakCheck() {
            InitMonitorData(); 

            string map_name = current_map;
            ArchipelagoLog("AP DEBUG: Running check for map: '" + map_name + "'");

            if (!screen_names.exists(map_name)) {
                ArchipelagoLog("AP DEBUG: Map '" + map_name + "' NOT found in dictionary.");
                return;
            }

            dictionary@ map_screens;
            screen_names.get(map_name, @map_screens);

            if (map_screens is null) return;

            CBaseEntity@ relay = null;
            while ((@relay = EntityList().FindByClassname(relay, "logic_relay")) !is null) {
                string name = relay.GetEntityName();

                if (map_screens.exists(name)) {
                    string check_name;
                    map_screens.get(name, check_name);

                    // --- 1. OUTPUT SQUIRREL (Le Printl) ---
                    string scriptCode = "printl(\"monitor_break:" + check_name + "\")";
                    string payloadPrint = "worldspawn\x1BRunScriptCode\x1B" + scriptCode + "\x1B0\x1B-1";
                    relay.KeyValue("OnTrigger", payloadPrint);

                    // --- 2. OUTPUT ANGELSCRIPT (La Téléportation) ---
                    // On utilise InitCmd pour lancer une commande custom "AP_WarpMonitor" avec un délai de 0.1s
                    string payloadWarp = "InitCmd\x1BCommand\x1BWarpMonitor " + check_name + "\x1B0.1\x1B-1";
                    relay.KeyValue("OnTrigger", payloadWarp);

                    string payloadSkin = name + "_holo\x1BSkin\x1B4\x1B0.1\x1B-1";
                    relay.KeyValue("OnTrigger", payloadSkin);

                    int skin = 0;
                    uint count = checked_screens.length();
                    for (uint i = 0; i < count; i++) {
                        if (checked_screens.opIndex(i) == check_name) {
                            skin = 4;
                            break;
                        }
                    }

                    // Calcul de l'offset local pour l'hologramme
                    QAngle angles = relay.GetAbsAngles();
                    float forwardOffset = 0.0f; 
                    float rightOffset = -20.0f;
                    float upOffset = 50.0f;

                    Vector forwardVec = Archipelago::AnglesToForward(angles);
                    Vector rightVec = Archipelago::AnglesToRight(angles);
                    Vector upVec = Archipelago::AnglesToUp(angles);

                    Vector finalPos = relay.GetAbsOrigin() + 
                                      (forwardVec * forwardOffset) + 
                                      (rightVec * rightOffset) + 
                                      (upVec * upOffset);

                    Archipelago::CreateAPHologram(finalPos, angles, 1.0f, null, "", skin, name + "_holo");
                    
                    Msgl("AP: Attached check '" + check_name + "' to relay '" + name + "'");
                }
            }
        }

/**
 * HandleMonitorWarp - Checks for specific monitor IDs that should trigger a player teleport.
 */

} // namespace Archipelago
