[ServerCommand("SetCheckedMaps", "Updates the list of completed maps and updates map check holograms")]
void SetCheckedMapsCmd(const CommandArgs@ args) {
    array<string> checkedMaps;

    for (int i = 1; i < args.ArgC(); i++) {
        string arg = CleanArg(args.Arg(i));
        if (arg.length() > 0) {
            checkedMaps.insertLast(arg.tolower());
            Archipelago::ArchipelagoLog("AP DEBUG: Completed map registered -> '" + arg.tolower() + "'");
        }
    }
    
    Archipelago::ArchipelagoLog("AP: Checked maps updated (" + checkedMaps.length() + " items)");

    string currentMapName = Archipelago::current_map.tolower();
    if (currentMapName == "" || currentMapName == "unknown") return;

    // Check if current map is checked/completed
    bool isCurrentMapCompleted = false;
    for (uint i = 0; i < checkedMaps.length(); i++) {
        if (checkedMaps[i] == currentMapName) {
            isCurrentMapCompleted = true;
            break;
        }
    }

    if (!isCurrentMapCompleted) return;

    // Traverse all holograms on the map to set checked skin
    CBaseEntity@ holo = null;
    while ((@holo = EntityList().FindByClassname(holo, "prop_dynamic")) !is null) {
        string holoName = holo.GetEntityName();
        bool shouldDisable = false;

        if (holoName.locate("map_check_holo") != uint(-1) || 
            holoName.locate("map_check_trigger_holo") != uint(-1) ||
            holoName.locate("map_check_trigger_elevator_holo") != uint(-1)) {
            shouldDisable = true;
        }
        else if (currentMapName == "sp_a4_finale4" && holoName == "moon_holo") {
            shouldDisable = true;
        }

        if (shouldDisable) {
            CBaseAnimating@ animHolo = cast<CBaseAnimating>(holo);
            if (animHolo !is null) {
                animHolo.SetSkin(4);
                Archipelago::ArchipelagoLog("AP: Map check hologram '" + holoName + "' set to Skin 4 (Disabled).");
            }
        }
    }
}