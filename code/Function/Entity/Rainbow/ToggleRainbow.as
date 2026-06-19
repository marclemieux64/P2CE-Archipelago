namespace Archipelago {

void ToggleRainbow() {
    g_rainbow_active = !g_rainbow_active;
    CBaseEntity@ oldTimer = EntityList().FindByName(null, "ap_rainbow_timer");
    if (oldTimer !is null) oldTimer.Remove();
    
    if (g_rainbow_active) {
        Archipelago::ArchipelagoLog("[AP] Rainbow Mode Activated!");
        CBaseEntity@ timer = util::CreateEntityByName("logic_timer");
        if (timer !is null) {
            timer.KeyValue("targetname", "ap_rainbow_timer");
            timer.KeyValue("RefireTime", "0.015");
            timer.Spawn();
            
            Variant v; 
            v.SetString("OnTimer ap_init_cmd,Command,RainbowTick,0,-1");
            timer.FireInput("AddOutput", v, 0.0f, null, null, 0);
            timer.FireInput("Enable", Variant(), 0.0f, null, null, 0);
        }
    } else {
        Archipelago::ArchipelagoLog("[AP] Rainbow Mode Deactivated!");
        Variant vDefault, vLaserDefault;
        vDefault.SetString("255 255 255"); 
        vLaserDefault.SetString("255 0 0 255");
        
        CBaseEntity@ ent = EntityList().First();
        while (@ent !is null) {
            string cls = ent.GetClassname();
            if (cls == "prop_weighted_cube") ent.FireInput("Color", vDefault, 0.0f, null, null);
            else if (cls == "env_portal_laser") ent.FireInput("SetBeamColor", vLaserDefault, 0.0f, null, null);
            @ent = EntityList().Next(ent);
        }
    }
}
}