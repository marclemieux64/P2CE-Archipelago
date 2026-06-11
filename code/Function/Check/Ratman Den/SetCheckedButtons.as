namespace Archipelago {
   
    void SetCheckedButtons(const array<string>@ checkedButtons) {
        // On vide et on remplit la variable GLOBALE déjà existante dans tes globales
        checked_buttons.resize(0);
        for (uint i = 0; i < checkedButtons.length(); i++) {
            checked_buttons.insertLast(checkedButtons[i]);
        }

        // On parcourt tous les hologrammes (prop_dynamic) directement présents sur la map
        CBaseEntity@ holo = null;
        while ((@holo = EntityList().FindByClassname(holo, "prop_dynamic")) !is null) {
            string holoName = holo.GetEntityName();
            
            // On s'assure que c'est un hologramme lié à Archipelago (contient _holo)
            if (holoName.locate("_holo") != uint(-1)) {
                for (uint i = 0; i < checked_buttons.length(); i++) {
                    string btnName = checked_buttons[i];
                    
                    // Si l'hologramme correspond au check validé (ex: "ratman_den_1" dans "ratman_den_1_142_holo")
                    if (holoName.locate(btnName) != uint(-1)) {
                        CBaseAnimating@ animHolo = cast<CBaseAnimating>(holo);
                        if (animHolo !is null) {
                            animHolo.SetSkin(4); // Skin 4 = Éteint
                        }
                        break;
                    }
                }
            }
        }
    }

} // namespace Archipelago