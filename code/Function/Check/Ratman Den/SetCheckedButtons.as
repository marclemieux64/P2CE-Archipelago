namespace Archipelago {

void SetCheckedButtons(const array<string>@ checkedButtons) {
    if (checkedButtons is null) return;

    // Clear and populate the global array
    checked_buttons.resize(0);
    for (uint i = 0; i < checkedButtons.length(); i++) {
        checked_buttons.insertLast(checkedButtons[i]);
    }

    // Traverse all holograms (prop_dynamic) currently on the map
    CBaseEntity@ holo = null;
    while ((@holo = EntityList().FindByClassname(holo, "prop_dynamic")) !is null) {
        string holoName = holo.GetEntityName();
        
        // Ensure it is an Archipelago hologram
        if (holoName.locate("_holo") != uint(-1)) {
            for (uint i = 0; i < checked_buttons.length(); i++) {
                string btnName = checked_buttons[i];
                
                // If the hologram matches the checked button
                if (holoName.locate(btnName) != uint(-1)) {
                    CBaseAnimating@ animHolo = cast<CBaseAnimating>(holo);
                    if (animHolo !is null) {
                        animHolo.SetSkin(4); // Skin 4 = Checked/Done
                    }
                    break;
                }
            }
        }
    }
}

} // namespace Archipelago