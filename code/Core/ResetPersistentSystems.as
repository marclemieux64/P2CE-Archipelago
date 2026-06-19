// =============================================================
// Reset Persistent Systems
// =============================================================
// This Module Resets stuff that cannot be reset if something 
// unexpected happen like a crash, closing the game, changing maps by the menu.

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

        // Reset motion blur intensity back to 0.0
        CBaseEntity@ lpp = EntityList().FindByClassname(null, "logic_playerproxy");
        if (lpp is null) {
            @lpp = util::CreateEntityByName("logic_playerproxy");
            if (lpp !is null) lpp.Spawn();
        }
        if (lpp !is null) {
            Variant vBlur;
            vBlur.SetFloat(0.0f);
            lpp.FireInput("SetMotionBlurAmount", vBlur, 0.0f, null, null);
        }

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

        // Reset BTS4 Conveyor Holo ConVars (only if we transitioned away from sp_a2_bts4)
        if (current_map != "sp_a2_bts4") {
            v.SetString("ap_bts4_initial_holo_active 0");
            cmd.FireInput("Command", v, 0.0f, null, null, 0);
            v.SetString("ap_bts4_conveyor1_holo_active 0");
            cmd.FireInput("Command", v, 0.0f, null, null, 0);
        }
        
        ArchipelagoLog("[Archipelago] Persistent systems have been sanitized for the new session.");
    }
}

} // namespace Archipelago
