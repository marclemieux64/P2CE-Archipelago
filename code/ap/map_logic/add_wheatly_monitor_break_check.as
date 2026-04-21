void AddWheatlyMonitorBreakCheck(string map_name) {
    InitWheatleyMonitorRegistry();
    
    CBaseEntity@ relay = null;
    while ((@relay = EntityList().FindByClassname(relay, "logic_relay")) !is null) {
        string name = relay.GetEntityName();
        string key = map_name + ":" + name;
        
        if (g_monitor_break_names.exists(key)) {
            string check_id = "";
            g_monitor_break_names.get(key, check_id);
            
            Variant vOut;
            vOut.SetString("OnTrigger ap_init_cmd:Command:ap_print_monitor " + check_id + ":0.0:-1");
            relay.FireInput("AddOutput", vOut, 0.0f, null, null, 0);
            
            CreateAPHologram(relay.GetAbsOrigin(), QAngle(0, 0, 0), 0.9f, "", "", 0, name + "_monitor_holo");
        }
    }
}
