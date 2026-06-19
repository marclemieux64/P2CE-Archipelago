namespace Archipelago {

void SetCheckedCameras(const array<string>&in parsedCameras) {
    // Populate the global checked cameras array
    checked_cameras.resize(0);
    for (uint i = 0; i < parsedCameras.length(); i++) {
        checked_cameras.insertLast(parsedCameras[i]);
    }

    // We iterate through all holograms on the map
    CBaseEntity@ holo = null;
    while ((@holo = EntityList().FindByClassname(holo, "prop_dynamic")) !is null) {
        string holoName = holo.GetEntityName().tolower();
        if (holoName.locate("camera_check_holo_") == 0) {
            // This is a camera hologram.
            // Let's get its static camera ID.
            string camID = holoName.substr(18); // e.g., "sp_a1_intro3_1"
            
            // Check if this camera ID is in checked_cameras (lowercase comparison)
            bool isChecked = false;
            for (uint i = 0; i < checked_cameras.length(); i++) {
                if (checked_cameras[i] == camID) {
                    isChecked = true;
                    break;
                }
            }
            if (isChecked) {
                CBaseAnimating@ animHolo = cast<CBaseAnimating>(holo);
                if (animHolo !is null) {
                    animHolo.SetSkin(4); // Skin 4 = Checked/Done
                }
            }
        }
    }
}

} // namespace Archipelago
