// =============================================================
// ARCHIPELAGO START GAME STATUS TIMER
// =============================================================

void StartGameStatusTimer() {
    CBaseEntity@ old = EntityList().FindByName(null, "GameStatusTimer");
    if (old !is null) old.Remove();

    CBaseEntity@ timer = util::CreateEntityByName("logic_timer");
    if (timer !is null) {
        timer.KeyValue("targetname", "GameStatusTimer");
        timer.KeyValue("RefireTime", "0.5"); // Slower refire for stability
        timer.KeyValue("StartDisabled", "1");
        timer.Spawn();
        
        SafeAddOutput(timer, "OnTimer", "InitCmd", "Command", "GameStatusTick", 0.0f, -1);

        Variant vEnable;
        timer.FireInput("Enable", vEnable, 1.0f, null, null, 0);
    }
    ArchipelagoLog("Archipelago-Mod: Game Status monitoring active.");
}