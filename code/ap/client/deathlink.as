/**
 * AttachDeathTrigger - Creates a logic_timer to monitor player health.
 */
void AttachDeathTrigger() {
    CBaseEntity@ old = EntityList().FindByName(null, "ap_deathlink_timer");
    if (old !is null) old.Remove();

    CBaseEntity@ timer = util::CreateEntityByName("logic_timer");
    if (timer !is null) {
        timer.KeyValue("targetname", "ap_deathlink_timer");
        timer.KeyValue("RefireTime", "1.0");
        timer.Spawn();
        
        Variant v;
        v.SetString("OnTimer ap_init_cmd:Command:ap_deathlink_tick:0.0:-1");
        timer.FireInput("AddOutput", v, 0.0f, null, null, 0);
    }
    Msgl("AP-Mod: DeathLink monitoring active.");
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
        Msgl("send_deathlink");
        
        // Trigger a restart 
        CBaseEntity@ cmd = EntityList().FindByName(null, "ap_init_cmd");
        if (cmd !is null) {
            Variant v;
            v.SetString("restart");
            cmd.FireInput("Command", v, 1.0f, null, null, 0);
        }
    }
}
