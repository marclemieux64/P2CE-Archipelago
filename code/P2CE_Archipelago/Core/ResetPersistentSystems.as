namespace Archipelago {

void ResetPersistentSystems() {
   
    CBaseEntity@ cmd = EntityList().FindByName(null, "InitCmd");
    if (cmd !is null) {
        Variant v;
        

        // Reset Visuals (Motion Blur Trap)
        v.SetString("sv_friction 4");
        cmd.FireInput("Command", v, 30.0f, null, null, 0);
        
        v.SetString("ent_fire !player AddOutput \"friction 1\"");
        cmd.FireInput("Command", v, 0.1f, null, null, 0);
        
        // Reset Visuals (Motion Blur Trap)
        v.SetString("mat_motion_blur_enabled 1"); // Assuming default is 1
        cmd.FireInput("Command", v, 0.0f, null, null, 0);

        // Réinitialisation du PostProcess (pour retirer le brouillard résiduel)
        v.SetString("con_log_channel_mode 0");
        cmd.FireInput("Command", v, 0.1f, null, null, 0); // Léger délai
         // Réinitialisation du PostProcess (pour retirer le brouillard résiduel)
        v.SetString("con_log_severity_mode 0");
        cmd.FireInput("Command", v, 0.1f, null, null, 0); // Léger délai

        // Reset Sound Mixers (PotatOS Silence restoration)
        v.SetString("snd_setmixer potatosVO vol 0.4");
        cmd.FireInput("Command", v, 0.0f, null, null, 0);
        v.SetString("snd_setmixer gladosVO vol 0.7");
        cmd.FireInput("Command", v, 0.0f, null, null, 0);

        CallVScript("MutePotatOSSubtitles(false)");



        
        ArchipelagoLog("[Archipelago] Persistent systems have been sanitized for the new session.");
    }
}

} // namespace Archipelago
