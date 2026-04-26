// =============================================================
// ARCHIPELAGO MASTER HEARTBEAT
// =============================================================

/**
 * APDeathLinkTickCmd - The 1-second pulse that drives the mod.
 * We register this last so it can see both the Bootstrap and the Client.
 */
[ServerCommand("ap_deathlink_tick", "Internal mod heartbeat")]
void APDeathLinkTickCmd(const CommandArgs@ args) {
    // 1. Ensure map is initialized (Self-Healing)
    RunDelayedInitialization();
    
    
    // 2. Perform periodic health checks
    RunDeathLinkTick();

    // 3. Constant Suppression Loop (Force Stop marked entities)
    CBaseEntity@ cmd = EntityList().FindByName(null, "ap_init_cmd");
    if (cmd !is null && g_suppressed_entities.length() > 0) {
        for (uint i = 0; i < g_suppressed_entities.length(); i++) {
            Variant v;
            v.SetString("ent_fire " + g_suppressed_entities[i] + " Stop");
            cmd.FireInput("Command", v, 0.0f, null, null, 0);
        }
    }
}
