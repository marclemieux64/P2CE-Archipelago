[ServerCommand("SetCheckedMaps", "Updates the list of completed maps and updates map check holograms")]
void SetCheckedMapsCmd(const CommandArgs@ args) {
    // 1. On vide et on remplit la liste globale des cartes complétées (à déclarer dans tes globales si ce n'est pas fait)
    // Ici, nous utilisons un tableau local pour traiter la commande et mettre à jour les entités de la carte actuelle
    array<string> checkedMaps;

    for (int i = 1; i < args.ArgC(); i++) {
        string arg = args.Arg(i);
        // Nettoyage des caractères parasites résiduels
        arg = arg.replace("[", "").replace("]", "").replace("\"", "").replace(",", "");
        
        if (arg.length() > 0) {
            checkedMaps.insertLast(arg.tolower());
            Archipelago::ArchipelagoLog("AP DEBUG: Completed map registered -> '" + arg.tolower() + "'");
        }
    }
    
    Archipelago::ArchipelagoLog("AP: Checked maps updated (" + checkedMaps.length() + " items)");

    // Récupération de la carte actuelle depuis les variables globales de ton mod
    string currentMapName = ::current_map.tolower();
    if (currentMapName == "" || currentMapName == "unknown") return;

    // 2. On vérifie si la carte actuelle est marquée comme complétée dans Archipelago
    bool isCurrentMapCompleted = false;
    for (uint i = 0; i < checkedMaps.length(); i++) {
        if (checkedMaps[i] == currentMapName) {
            isCurrentMapCompleted = true;
            break;
        }
    }

    // Si la carte actuelle n'est pas complétée, on n'éteint pas ses hologrammes principaux de fin de niveau
    if (!isCurrentMapCompleted) return;

    // 3. Balayage de tous les hologrammes (prop_dynamic) de la carte pour appliquer le Skin 4
    CBaseEntity@ holo = null;
    while ((@holo = EntityList().FindByClassname(holo, "prop_dynamic")) !is null) {
        string holoName = holo.GetEntityName();
        bool shouldDisable = false;

        // Condition A : Match des hologrammes de placement manuel ou générique de fin de niveau
        if (holoName.locate("map_check_holo") != uint(-1) || 
            holoName.locate("map_check_trigger_holo") != uint(-1) ||
            holoName.locate("map_check_trigger_elevator_holo") != uint(-1)) {
            shouldDisable = true;
        }
        // Condition B : Match de l'hologramme spécifique de la Lune sur sp_a4_finale4
        else if (currentMapName == "sp_a4_finale4" && holoName == "moon_holo") {
            shouldDisable = true;
        }

        // Si l'hologramme correspond à un indicateur de fin de niveau validé, on applique le Skin 4 (Éteint)
        if (shouldDisable) {
            CBaseAnimating@ animHolo = cast<CBaseAnimating>(holo);
            if (animHolo !is null) {
                animHolo.SetSkin(4);
                Archipelago::ArchipelagoLog("AP: Map check hologram '" + holoName + "' set to Skin 4 (Disabled).");
            }
        }
    }
}