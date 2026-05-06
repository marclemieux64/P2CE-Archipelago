// =============================================================
// ARCHIPELAGO RUN DEATH LINK TICK
// =============================================================

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
