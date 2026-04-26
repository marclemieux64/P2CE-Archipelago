void AddWheatleyMonitorBreakCheck(string map_name) {
    InitWheatleyMonitorRegistry();
    
    array<string> monitorClasses = {
        "logic_relay", "trigger_once", "trigger_multiple",
        "prop_button", "prop_under_button", "prop_floor_button", "prop_floor_cube_button", "prop_floor_ball_button", "prop_underfloor_button"
    };
    
    for (uint i = 0; i < monitorClasses.length(); i++) {
        CBaseEntity@ ent = null;
        while ((@ent = EntityList().FindByClassname(ent, monitorClasses[i])) !is null) {
            string name = ent.GetEntityName();
            string key = map_name + ":" + name;
            
            bool isArchipelagoMonitor = g_monitor_break_names.exists(key);
            bool isTargetTrigger = (name.locate("trigger_tv_crack") != uint(-1));
            bool isButton = (monitorClasses[i].locate("button") != uint(-1));

            if (isArchipelagoMonitor || isTargetTrigger || isButton) {
                // 1. Logic Hook
                if (isArchipelagoMonitor || isTargetTrigger) {
                    string full_id = current_map;
                    string target_sub = "";
                    
                    // Try to find the monitor ID in the registry
                    if (isArchipelagoMonitor) {
                        g_monitor_break_names.get(key, target_sub);
                    } else if (isTargetTrigger) {
                        // Triggers often share a prefix with relays (e.g., mono1-trigger / mono1-relay)
                        uint dashIdx = name.locate("-");
                        if (dashIdx != uint(-1)) {
                            string prefix = name.substr(0, int(dashIdx));
                            array<string>@ regKeys = g_monitor_break_names.getKeys();
                            for (uint k = 0; k < regKeys.length(); k++) {
                                if (regKeys[k].locate(current_map + ":" + prefix) != uint(-1)) {
                                    g_monitor_break_names.get(regKeys[k], target_sub);
                                    break;
                                }
                            }
                        }
                    }

                    if (target_sub != "") {
                        full_id = target_sub;
                    }
                    
                    // Select the correct output based on class
                    string outputName = (monitorClasses[i].locate("trigger") != uint(-1)) ? "OnStartTouch" : "OnTrigger";
                    
                    Variant v;
                    string safe_id = full_id.replace(" ", "."); // Use period for safe engine transfer
                    v.SetString(outputName + " ap_init_cmd:Command:ap_print_monitor " + safe_id + ":0.0:-1");
                    ent.FireInput("AddOutput", v, 0.0f, null, null, 0);

                    // DEBUG: Show what we are baking into the entity
                    Msgl("[AP DEBUG] Hooking " + name + " (" + monitorClasses[i] + ") with ID: " + full_id);
                }

                // 2. Visual Management (Syncing/Spawning)
                string base_name = name.replace("_ap_hooked", "");
                string holo_name = base_name + "_holo";

                // Determine anchor (Use nearby monitor model if possible)
                CBaseEntity@ anchor = ent;
                CBaseEntity@ prop = EntityList().FindByClassnameNearest("prop_dynamic", ent.GetAbsOrigin(), 128.0f);
                if (prop !is null && prop.GetModelName().locate("wheatley_monitor") != uint(-1)) {
                    @anchor = prop;
                }

                // Calculate Registry Offsets
                Vector hPos;
                QAngle hAng;
                int hSkin;
                float hScale;
                GetHologramVisualOverrides(anchor, hPos, hAng, hSkin, hScale);

                // Proactive Spawn: Create hologram if it's a monitor check
                if (isArchipelagoMonitor || isTargetTrigger) {
                    CreateAPHologram(hPos, hAng, hScale, "", "", hSkin, holo_name);
                } else if (isButton) {
                    // For buttons, only update if the hologram exists
                    CBaseEntity@ holo = EntityList().FindByName(null, holo_name);
                    if (holo !is null) {
                        holo.SetAbsOrigin(hPos);
                        holo.SetAbsAngles(hAng);
                        holo.KeyValue("modelscale", "" + hScale);
                    }
                }
            }
        }
    }
}
