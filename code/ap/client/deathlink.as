/**
 * AttachDeathTrigger - Creates a logic_timer to monitor player health.
 */
void AttachDeathTrigger() {
    CBaseEntity@ old = EntityList().FindByName(null, "DeathlinkTimer");
    if (old !is null) old.Remove();

    CBaseEntity@ timer = util::CreateEntityByName("logic_timer");
    if (timer !is null) {
        timer.KeyValue("targetname", "DeathlinkTimer");
        timer.KeyValue("RefireTime", "0.1");
        timer.KeyValue("StartDisabled", "1");
        timer.Spawn();
        
        SafeAddOutput(timer, "OnTimer", "InitCmd", "Command", "DeathlinkTick", 0.0f, -1);

        Variant vEnable;
        timer.FireInput("Enable", vEnable, 1.0f, null, null, 0);
    }
    ArchipelagoLog("Archipelago-Mod: Deathlink monitoring active.");
}

/**
 * RunDeathLinkTick - Checks health and sends deathlink signal.
 */
void RunDeathLinkTick() {
    CBaseEntity@ pEnt = EntityList().FindByClassname(null, "player");


    if (pEnt is null) return;
    
    CBasePlayer@ player = cast<CBasePlayer>(pEnt);
    int hp = player.GetHealth();

    if (hp <= 0 && !g_bSentDeathLink) {
        g_bSentDeathLink = true;
        ArchipelagoLog("send_deathlink");
        
        // Trigger a restart 
        CBaseEntity@ cmd = EntityList().FindByName(null, "InitCmd");
        if (cmd !is null) {
            Variant v;
            v.SetString("restart");
            cmd.FireInput("Command", v, 1.0f, null, null, 0);
        }
    }
}
