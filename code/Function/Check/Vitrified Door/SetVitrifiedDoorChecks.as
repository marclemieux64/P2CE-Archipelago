namespace Archipelago  {
    

void SetVitrifiedStatus(const array<string>@ checkedDoors) {
        checked_vitrified_doors.resize(0);
        for (uint i = 0; i < checkedDoors.length(); i++) {
            checked_vitrified_doors.insertLast("Vitrified Door " + checkedDoors[i]);
        }
        
        // Update active holograms on the map
        CBaseEntity@ holo = null;
        while ((@holo = EntityList().FindByClassname(holo, "prop_dynamic")) !is null) {
            string holoName = holo.GetEntityName().tolower();
            if (holoName.locate("_holo") != uint(-1)) {
                // Find which key in g_vitrified_door_names maps to this hologram
                array<string>@ keys = g_vitrified_door_names.getKeys();
                for (uint k = 0; k < keys.length(); k++) {
                    string key = keys[k];
                    if (key.locate(::current_map + ":") == 0) {
                        string entName = key.substr(::current_map.length() + 1).tolower();
                        string targetHoloName = entName + "_holo";
                        uint locIdx = holoName.locate(targetHoloName);
                        if (holoName == targetHoloName || (locIdx != uint(-1) && (locIdx + targetHoloName.length() == holoName.length()))) {
                            string checkName;
                            g_vitrified_door_names.get(key, checkName);
                            if (checked_vitrified_doors.find(checkName) != -1) {
                                CBaseAnimating@ animHolo = cast<CBaseAnimating>(holo);
                                if (animHolo !is null) {
                                    animHolo.SetSkin(4); // Skin 4 = Checked
                                }
                            }
                        }
                    }
                }
            }
        }
    }

} //namespace Archipelago