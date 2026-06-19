// =============================================================
// PrintMapComplete
// =============================================================
// This file contain the code related to the server command PrintMapComplete

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
    
        CBaseEntity@ cmd = EntityList().FindByName(null, "InitCmd");
        if (cmd !is null) {
            Variant vFade;
            
            vFade.SetString("fadeout 0.2");
            cmd.FireInput("Command", vFade, 0.0f, null, null, 0);
            
            
        }
    }
    

} // namespace Archipelago
