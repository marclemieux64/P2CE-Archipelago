namespace Archipelago {

void DisablePortalGun(bool blue, bool orange) {
    CBaseEntity@ gun = EntityList().FindByClassname(null, "weapon_portalgun");
    
    // 1. The 13-second delay specific to map sp_a3_01
    if (current_map == "sp_a3_01") {
        if (gun !is null) {
            Variant vDelay;
            vDelay.SetString("CanFirePortal2 0");
            gun.FireInput("AddOutput", vDelay, 13.0f, null, null, 0); 
        }
    }

    // 2. The Incinerator sequence tracking
    if (current_map == "sp_a2_intro") {
        portalgun_2_disabled = true;
    }

    // 3. THIS WAS MISSING: The actual logic that disables the gun right now!
    if (gun !is null) {
        if (blue) {
            Variant vB; 
            vB.SetString("CanFirePortal1 0");
            gun.FireInput("AddOutput", vB, 0.0f, null, null, 0);
        }
        if (orange) {
            Variant vO; 
            vO.SetString("CanFirePortal2 0");
            gun.FireInput("AddOutput", vO, 0.0f, null, null, 0);
        }
    }
}

} // namespace Archipelago
