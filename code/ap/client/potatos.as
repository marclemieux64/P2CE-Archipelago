void RemovePotatOS() {
    CBaseEntity@ button = EntityList().FindByName(null, "sphere_entrance_potatos_button");
    if (button !is null) {
        Vector pos = button.GetAbsOrigin();
        
        // 1. Create the hint target for the instructor
        CBaseEntity@ target = util::CreateEntityByName("info_target_instructor_hint");
        if (target !is null) {
            target.KeyValue("targetname", "hint_target_no_potatos");
            target.Spawn();
            target.SetAbsOrigin(pos);
        }
        
        // 2. Create the actual instructor hint
        CBaseEntity@ hint = util::CreateEntityByName("env_instructor_hint");
        if (hint !is null) {
            hint.KeyValue("targetname", "hudhint_no_potatos");
            hint.KeyValue("hint_target", "hint_target_no_potatos");
            hint.KeyValue("hint_static", "0");
            hint.KeyValue("hint_caption", "PotatOS not unlocked");
            hint.KeyValue("hint_icon_onscreen", "icon_alert");
            hint.KeyValue("hint_color", "255 50 50");
            hint.Spawn();
        }
                // 3. Force the button to show the hint when pressed and remove the potatOS again
        Fire("ent_fire sphere_entrance_potatos_button AddOutput \"OnPressed hudhint_no_potatos:ShowHint:0:-1\"");
        Fire("ent_fire sphere_entrance_potatos_button AddOutput \"OnPressed ap_init_cmd:Command:RemovePotatosFromGun:1.0:-1\"");
    }
    
    // 4. Remove the relay so the player can't progress
    DeleteEntity("sphere_entrance_lift_relay", false); 
    DeleteEntity("potatos_prop", false);
    Fire("snd_setmixer gladosVO vol 0.0", 0.1f);
    
    // 5. Ensure she is removed from the gun itself
    RemovePotatosFromGun();
    
    Msgl("[AP] PotatOS removal logic applied (with instructor hints).");
}

void Fire(string cmd, float d = 0.0f) { 
    CBaseEntity@ c = EntityList().FindByName(null, "ap_init_cmd");
    if (c !is null) { Variant v; v.SetString(cmd); c.FireInput("Command", v, d, null, null, 0); }
}

void RemovePotatosFromGun() {
    Fire("ent_fire weapon_portalgun AddOutput \"showingpotatos 0\"", 0.05f);
    
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

    Fire("snd_setmixer potatosVO vol 0.0", 0.1f);
    CallVScript("MutePotatOSSubtitles(true)");
}

void RestorePotatosToGun() {
    Fire("upgrade_potatogun");
    Fire("snd_setmixer potatosVO vol 0.4", 0.1f);
    Fire("snd_setmixer gladosVO vol 0.7", 0.1f);
    CallVScript("MutePotatOSSubtitles(false)");
}
