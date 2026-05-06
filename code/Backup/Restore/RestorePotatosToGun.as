// =============================================================
// ARCHIPELAGO RESTORE POTATOS TO GUN
// =============================================================

void RestorePotatosToGun() {
    CBaseEntity@ cmd = EntityList().FindByName(null, "InitCmd");
    if (cmd !is null) {
        Variant v1; v1.SetString("upgrade_potatogun");
        cmd.FireInput("Command", v1, 0.0f, null, null, 0);

        Variant v2; v2.SetString("snd_setmixer potatosVO vol 0.4");
        cmd.FireInput("Command", v2, 0.1f, null, null, 0);

        Variant v3; v3.SetString("snd_setmixer gladosVO vol 0.7");
        cmd.FireInput("Command", v3, 0.1f, null, null, 0);
    }
    CallVScript("MutePotatOSSubtitles(false)");
}
