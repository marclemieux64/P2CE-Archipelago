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
                if (isArchipelagoMonitor && monitorClasses[i] == "logic_relay") {
                    if (name.locate("_ap_hooked") == uint(-1)) {
                        string check_id = "";
                        g_monitor_break_names.get(key, check_id);
                        Variant v;
                        v.SetString("OnTrigger ap_init_cmd:Command:ap_print_monitor " + check_id + ":0.0:-1");
                        ent.FireInput("AddOutput", v, 0.0f, null, null, 0);
                        ent.KeyValue("targetname", name + "_ap_hooked");
                    }
                }

                // 2. Visual Management (Syncing)
                string base_name = name.replace("_ap_hooked", "");
                string holo_name = base_name + "_holo";
                CBaseEntity@ holo = EntityList().FindByName(null, holo_name);

                if (holo !is null) {
                    CBaseEntity@ anchor = ent;
                    CBaseEntity@ prop = EntityList().FindByClassnameNearest("prop_dynamic", ent.GetAbsOrigin(), 128.0f);
                    if (prop !is null && prop.GetModelName().locate("wheatley_monitor") != uint(-1)) {
                        @anchor = prop;
                    }

                    // Apply Registry Offsets (Registry now handles local axis math!)
                    Vector hPos;
                    QAngle hAng;
                    int hSkin;
                    float hScale;
                    GetHologramVisualOverrides(anchor, hPos, hAng, hSkin, hScale);

                    holo.SetAbsOrigin(hPos);
                    holo.SetAbsAngles(hAng);
                    holo.KeyValue("modelscale", "" + hScale);
                }
            }
        }
    }
}
