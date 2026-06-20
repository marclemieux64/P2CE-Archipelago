// =============================================================
// PLAYER GETTER UTILITIES
// =============================================================

namespace Archipelago {

/**
 * Returns the local host player instance, casted as CBasePlayer.
 */
CBasePlayer@ GetPlayer() {
    return cast<CBasePlayer>(EntityList().FindByClassname(null, "player"));
}

} // namespace Archipelago
