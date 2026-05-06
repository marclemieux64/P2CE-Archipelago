// =============================================================
// ARCHIPELAGO INCINERATOR DISABLE PORTAL GUN
// =============================================================
/**
 * IncineratorDisablePortalGun - Replicates the VScript incinerator logic.
 * Disables the portal gun (if required) when the player enters the incinerator.
 */
void IncineratorDisablePortalGun() {
    CBaseEntity@ trigger = EntityList().FindByName(null, "player_near_portalgun");
    if (trigger !is null) {
        Variant v;
        // Arguments: blue=0 (off), orange=(portalgun_2_disabled ? 1 : 0), isDelayed=0
        string orangeVal = portalgun_2_disabled ? "1" : "0";
        v.SetString("OnStartTouch InitCmd:Command:DisablePortalGun 0 " + orangeVal + " 0:0.25:-1");
        trigger.FireInput("AddOutput", v, 0.0f, null, null, 0);
    }
}

