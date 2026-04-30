/**
 * ResetPersistentSystems - Forces global engine and player states back to defaults.
 * Called during map init to prevent trap effects from surviving reloads/save-loads.
 */
void ResetPersistentSystems() {
    // 1. Reset AngelScript Global Ticks
    g_ButterFingersTicks = 0;

    g_bSentDeathLink = false;
    g_suppressed_entities.resize(0);
    g_suppressed_classes.resize(0);
    g_reported_monitors.resize(0);


    // 2. Reset Engine ConVars and Player Attributes via ServerCommand
    CBaseEntity@ cmd = EntityList().FindByName(null, "ap_init_cmd");
    if (cmd !is null) {
        Variant v;
        
        // Reset Friction (Slippery Floor Trap)
        v.SetString("sv_friction 4");
        cmd.FireInput("Command", v, 0.0f, null, null, 0);
        
        v.SetString("ent_fire !player AddOutput \"friction 1\"");
        cmd.FireInput("Command", v, 0.1f, null, null, 0);

        // Reset Physics/Gravity (Prevention)
        v.SetString("sv_gravity 600");
        cmd.FireInput("Command", v, 0.0f, null, null, 0);
        
        // Reset Visuals (Motion Blur Trap)
        v.SetString("mat_motion_blur_enabled 1"); // Assuming default is 1
        cmd.FireInput("Command", v, 0.0f, null, null, 0);

        // Reset Sound Mixers (PotatOS Silence restoration)
        v.SetString("snd_setmixer potatosVO vol 0.4");
        cmd.FireInput("Command", v, 0.0f, null, null, 0);
        v.SetString("snd_setmixer gladosVO vol 0.7");
        cmd.FireInput("Command", v, 0.0f, null, null, 0);
        
        Msgl("[AP] Persistent systems have been sanitized for the new session.");
    }
}
