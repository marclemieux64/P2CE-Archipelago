namespace Archipelago {

    void SetCheckedCameras() {
        // We iterate through all holograms on the map
        CBaseEntity@ holo = null;
        while ((@holo = EntityList().FindByClassname(holo, "prop_dynamic")) !is null) {
            string holoName = holo.GetEntityName();
            if (holoName.locate("camera_check_holo_") == 0) {
                // This is a camera hologram.
                // Let's get its entity index.
                string indexStr = holoName.substr(18); // after "camera_check_holo_"
                int entIndex = indexStr.toInt();
                if (entIndex >= 0 && entIndex < int(g_CameraIdentifiers.length())) {
                    string camID = g_CameraIdentifiers[entIndex]; // e.g., "sp_a1_intro3_1"
                    // Check if this camera ID is in checked_cameras (lowercase comparison)
                    bool isChecked = false;
                    for (uint i = 0; i < checked_cameras.length(); i++) {
                        if (checked_cameras[i] == camID.tolower()) {
                            isChecked = true;
                            break;
                        }
                    }
                    if (isChecked) {
                        CBaseAnimating@ animHolo = cast<CBaseAnimating>(holo);
                        if (animHolo !is null) {
                            animHolo.SetSkin(4); // Skin 4 = Éteint/Done
                        }
                    }
                }
            }
        }
    }

} // namespace Archipelago
