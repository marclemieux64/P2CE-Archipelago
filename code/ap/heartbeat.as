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
}
