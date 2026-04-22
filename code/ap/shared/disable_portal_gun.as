/**
 * DisablePortalGun - Disables firing capability for portals.
 */
void DisablePortalGun(bool blue, bool orange, bool isDelayedCall = false) {
    if (!isDelayedCall) {
        if (current_map == "sp_a3_01") {
            // Delay disabling orange portal for 13s for the acquisition animation
            WaitExecute("DisablePortalGun 0 1 1", 13.0f, "disable_portalgun2_sp_a3_01");
        }

        if (current_map == "sp_a2_intro") {
            portalgun_2_disabled = true;
        }
    }

    array<CBaseEntity@> guns = FindEntities("weapon_portalgun");
    for (uint i = 0; i < guns.length(); i++) {
        if (blue) guns[i].KeyValue("CanFirePortal1", "0");
        if (orange) guns[i].KeyValue("CanFirePortal2", "0");
    }
    Msgl("[AP] Portal Gun restricted: Blue=" + (blue ? "Off" : "NoChange") + " Orange=" + (orange ? "Off" : "NoChange"));
}
