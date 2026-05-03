// =============================================================
// ARCHIPELAGO WARP TO MENU
// =============================================================

/**
 * WarpToMenu - Returns the player to the main menu.
 */
void WarpToMenu() {
    UpdateInternalMapName();
    CallVScript("SendToPanorama(\"Archipelago_WarpToMenu\", \"" + current_map + "\")");
}
