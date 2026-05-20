namespace Archipelago {

void RemovePotatosFromGun() {
        ArchipelagoLog("[AP DEBUG] RemovePotatosFromGun: Executing viewmodel and world cleanup.");
        
        // 1. VIEWMODEL: Force removal via the player proxy
        CBaseEntity@ lpp = EntityList().FindByClassname(null, "logic_playerproxy");
        if (lpp is null) {
            @lpp = util::CreateEntityByName("logic_playerproxy");
            if (lpp !is null) { lpp.KeyValue("targetname", "ap_lpp"); lpp.Spawn(); }
        }
        
        if (lpp !is null) {
            lpp.FireInput("RemovePotatosFromPortalgun", Variant(), 0.0f, null, null, 0);
        }

        // 2. WORLD SPACE: Remove any physical representations
        DeleteEntity("potatos_prop", false);
        DeleteEntity("potatos", false);
        DeleteEntity("models/props/potatos.mdl", false);
        
        // 3. VOICE & UI: Silence audio group and subtitles via mixer
        CBaseEntity@ cmd = EntityList().FindByName(null, "InitCmd");
        if (cmd !is null) {
            Variant vMix;
            vMix.SetString("snd_setmixer potatosVO vol 0.0");
            cmd.FireInput("Command", vMix, 0.0f, null, null, 0);
            CallVScript("MutePotatOSSubtitles(true)");
            
           
        }
        ArchipelagoLog("[AP DEBUG] RemovePotatosFromGun: Done (Visuals, Mixer & Subtitles silenced).");
    }

} // namespace Archipelago
