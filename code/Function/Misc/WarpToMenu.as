namespace Archipelago {

void WarpToMenu() {
        UpdateInternalMapName();
        CallVScript("SendToPanorama(\"Archipelago_WarpToMenu\", \"" + current_map + "\")");
    }

} // namespace Archipelago
