void TriggerButterFingersTrap() {
    CBaseEntity@ oldTimer = EntityList().FindByName(null, "ap_bf_timer");
    if (oldTimer !is null) oldTimer.Remove();
    CBaseEntity@ oldRelay = EntityList().FindByName(null, "ap_bf_relay");
    if (oldRelay !is null) oldRelay.Remove();

    CBaseEntity@ timer = util::CreateEntityByName("logic_timer");
    if (timer !is null) {
        timer.KeyValue("targetname", "ap_bf_timer");
        timer.KeyValue("RefireTime", "2.5");
        timer.Spawn();
        
        Variant v;
        v.SetString("OnTimer ap_init_cmd:Command:ap_butterfingers_tick:0.0:-1");
        timer.FireInput("AddOutput", v, 0.0f, null, null);
    }
    
    CBaseEntity@ relay = util::CreateEntityByName("logic_relay");
    if (relay !is null) {
        relay.KeyValue("targetname", "ap_bf_relay");
        relay.Spawn();
        Variant v;
        v.SetString("OnTrigger ap_bf_timer:Kill::30.0:1");
        relay.FireInput("AddOutput", v, 0.0f, null, null);
        
        v.SetString("OnTrigger ap_init_cmd:Command:say [AP] Butter Fingers Trap Activated!:0.0:-1");
        relay.FireInput("AddOutput", v, 0.0f, null, null);
        
        relay.FireInput("Trigger", Variant(), 0.0f, null, null);
    }
}

void RunButterFingersTick() {
    CBaseEntity@ player = EntityList().FindByClassname(null, "player");
    if (player !is null) {
        CBasePlayer@ p = cast<CBasePlayer>(player);
        p.ForceDropOfCarriedPhysObjects();
    }
}
