// =============================================================
// ARCHIPELAGO REMOVE POTATOS FROM GUN
// =============================================================
void RemovePotatosFromGun() {
    CBaseEntity@ cmd = EntityList().FindByName(null, "InitCmd");
    if (cmd !is null) {
        Variant v1; v1.SetString("ent_fire weapon_portalgun AddOutput \"showingpotatos 0\"");
        cmd.FireInput("Command", v1, 0.05f, null, null, 0);
    }
    
    // Use logic_playerproxy for reliable removal (the standard input method)
    CBaseEntity@ proxy = EntityList().FindByClassname(null, "logic_playerproxy");
    if (proxy is null) {
        @proxy = util::CreateEntityByName("logic_playerproxy");
        if (proxy !is null) proxy.Spawn();
    }
    CBaseEntity@ player = EntityList().FindByClassname(null, "player");
    if (proxy !is null) {
        Variant v;
        proxy.FireInput("RemovePotatosFromPortalgun", v, 0.0f, player, player, 0);
    }

    if (cmd !is null) {
        Variant v2; v2.SetString("snd_setmixer potatosVO vol 0.0");
        cmd.FireInput("Command", v2, 0.1f, null, null, 0);
    }
    CallVScript("MutePotatOSSubtitles(true)");
}

