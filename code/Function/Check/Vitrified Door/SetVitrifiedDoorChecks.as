namespace Archipelago  {
    

void SetVitrifiedStatus(string bitmask) {
        cv_ArchipelagoVitrifiedStatus.SetValue(bitmask);
        
        // Update active holograms on the map
        for (int doorIndex = 1; doorIndex <= 6; doorIndex++) {
            if (bitmask.length() >= uint(doorIndex) && bitmask.substr(doorIndex - 1, 1) == "1") {
                string entName = "";
                if (::current_map == "sp_a3_03") {
                    if (doorIndex == 1) entName = "dummy_chamber_button";
                    else if (doorIndex == 2) entName = "dummy_chamber_button2";
                    else if (doorIndex == 3) entName = "dummy_chamber_button3";
                } else if (::current_map == "sp_a3_transition01") {
                    if (doorIndex == 4) entName = "dummy_chamber_button";
                    else if (doorIndex == 5) entName = "dummy_chamber_button2";
                    else if (doorIndex == 6) entName = "dummy_chamber_button3";
                }
                
                if (entName != "") {
                    CBaseEntity@ holo = EntityList().FindByName(null, entName + "_holo");
                    if (holo !is null) {
                        CBaseAnimating@ animHolo = cast<CBaseAnimating>(holo);
                        if (animHolo !is null) {
                            animHolo.SetSkin(4); // Skin 4 = Checked
                        }
                    }
                }
            }
        }
    }

} //namespace Archipelago