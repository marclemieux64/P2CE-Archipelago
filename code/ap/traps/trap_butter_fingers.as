void TriggerButterFingersTrap(float duration = 30.0f) {
    CallVScript("SendToPanorama(\"ArchipelagoTrapTriggered\", \"ButterFingers|" + duration + "\")");
    CBaseEntity@ oldTimer = EntityList().FindByName(null, "ap_bf_timer");
    if (oldTimer !is null) oldTimer.Remove();
    CBaseEntity@ oldRelay = EntityList().FindByName(null, "ap_bf_relay");
    if (oldRelay !is null) oldRelay.Remove();

    CBaseEntity@ timer = util::CreateEntityByName("logic_timer");
    if (timer !is null) {
        timer.KeyValue("targetname", "ap_bf_timer");
        timer.KeyValue("RefireTime", "2.5");
        SafeAddOutput(timer, "OnTimer", "InitCmd", "Command", "ButterfingersTick", 0.0f, -1);
        timer.Spawn();
    }
    
    CBaseEntity@ relay = util::CreateEntityByName("logic_relay");
    if (relay !is null) {
        relay.KeyValue("targetname", "ap_bf_relay");
        relay.Spawn();
        
        SafeAddOutput(relay, "OnTrigger", "ap_bf_timer", "Kill", "", duration, 1);
        SafeAddOutput(relay, "OnTrigger", "InitCmd", "Command", "say [Archipelago] Butter Fingers Trap Activated!", 0.0f, -1);
        
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
