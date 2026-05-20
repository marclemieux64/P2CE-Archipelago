// =============================================================
// ARCHIPELAGO DISABLE PORTAL GUN
// =============================================================
/**
 * DisablePortalGun - Disables firing capability for portals.
 */
void DisablePortalGun(bool blue, bool orange, bool isDelayedCall = false) {
    if (!isDelayedCall) {
        if (current_map == "sp_a3_01") {
            // Delay disabling orange portal for 13s for the acquisition animation
            CBaseEntity@ cmdEnt = EntityList().FindByName(null, "InitCmd");
            if (cmdEnt !is null) {
                Variant v;
                v.SetString("DisablePortalGun 0 1 1");
                cmdEnt.FireInput("Command", v, 13.0f, null, null, 0);
            }
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
    ArchipelagoLog("[Archipelago] Portal Gun restricted: Blue=" + (blue ? "Off" : "NoChange") + " Orange=" + (orange ? "Off" : "NoChange"));
}

