namespace Archipelago {

void PrintMapCompleteNoExit() {
        if (g_has_printed_map_complete) return;
        g_has_printed_map_complete = true;

        UpdateInternalMapName();
        ArchipelagoLog("map_complete:" + current_map);

        if (current_map == "sp_a4_finale4") return;

        CBasePlayer@ player = GetPlayer();
        if (player !is null) {
            Variant v;
            player.FireInput("Disable", v, 0.0f, null, null, 0);
        }
    
        SendToConsole("fadeout 0.2");
    }

} // namespace Archipelago
