namespace Archipelago {

/**
 * GetPlayer - Helper to find the local player.
 */
    CBasePlayer@ GetPlayer() {
        return cast<CBasePlayer>(EntityList().FindByClassname(null, "player"));
    }

} // namespace Archipelago
