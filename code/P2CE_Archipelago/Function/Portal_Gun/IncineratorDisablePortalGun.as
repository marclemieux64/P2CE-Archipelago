namespace Archipelago {

void IncineratorDisablePortalGun() {
    CBaseEntity@ trigger = EntityList().FindByName(null, "player_near_portalgun");
    if (trigger !is null) {
        Variant v;
        
        // On récupère "1" ou "0"
        string orangeVal = portalgun_2_disabled ? "1" : "0";
        
        // On demande au trigger d'utiliser VOTRE ServerCommand déjà existante : DisablePortalGun
        // Syntaxe : Output Target:Input:Parameter:Delay:MaxTimes
        string outputStr = "OnStartTouch InitCmd:Command:DisablePortalGun 0 " + orangeVal + ":0.25:-1";
        
        v.SetString(outputStr);
        trigger.FireInput("AddOutput", v, 0.0f, null, null, 0);
    }
}

} // namespace Archipelago
