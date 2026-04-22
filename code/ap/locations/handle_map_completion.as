bool g_has_printed_map_complete = false;

/**
 * PrintMapCompleteNoExit - Prints map complete without exiting.
 */
void PrintMapCompleteNoExit() {
    if (g_has_printed_map_complete) return;
    g_has_printed_map_complete = true;

    UpdateInternalMapName();
    Msgl("map_complete:" + current_map);

    // --- L'EXCEPTION POUR LA FINALE ---
    // Si on est sur la map finale, on s'arrête ici !
    // On laisse le jeu dérouler sa cinématique de fin nativement sans fadeout ni freeze.
    if (current_map == "sp_a4_finale4") {
        return;
    }
    
    // Play a distinct UI alert sound instantly on the same engine tick (no VScript latency)
    CBaseEntity@ cmdInfo = EntityList().FindByName(null, "ap_init_cmd");
    if (cmdInfo !is null) {
        Variant vSnd; vSnd.SetString("play ui/menu_accept.wav");
        cmdInfo.FireInput("Command", vSnd, 0.0f, null, null, 0);
    }

    // Disable the player inputs cleanly
    CBaseEntity@ player = EntityList().FindByName(null, "!player");
    if (player !is null) {
        Variant v;
        v.SetString("");
        player.FireInput("Disable", v, 0.0f, null, null, 0);
    }
    
    // Smooth 0.2s extremely fast snap to black without messing with timescale
    CBaseEntity@ cmdEnt = EntityList().FindByName(null, "ap_init_cmd");
    if (cmdEnt !is null) {
        Variant vCmd;
        vCmd.SetString("fadeout 0.2");
        cmdEnt.FireInput("Command", vCmd, 0.0f, null, null, 0);
    }
}

/**
 * PrintMapComplete - Print map complete and trigger the warp to the main menu.
 */
void PrintMapComplete() {
    if (transition_script_count > 0) {
        transition_script_count--;
        return;
    }
    
    PrintMapCompleteNoExit();
    
    // Normal 2.0s real time delay. The engine isn't slowed down anymore,
    // so this will execute perfectly on schedule.
    WaitExecute("ap_warp_to_menu", 2.0f, "return_to_menu");
}

/**
 * Backwards compatibility or alternative hook if needed
 */
void HandleMapCompletion() {
    PrintMapComplete();
}
