// =============================================================
// ARCHIPELAGO REMOVE POTAT O S
// =============================================================
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
        CBaseEntity@ cmd = EntityList().FindByName(null, "InitCmd");
        if (cmd !is null) {
            Variant v1; v1.SetString("ent_fire sphere_entrance_potatos_button AddOutput \"OnPressed hudhint_no_potatos:ShowHint:0:-1\"");
            cmd.FireInput("Command", v1, 0.0f, null, null, 0);

            Variant v2; v2.SetString("ent_fire sphere_entrance_potatos_button AddOutput \"OnPressed InitCmd:Command:RemovePotatosFromGun:1.0:-1\"");
            cmd.FireInput("Command", v2, 0.0f, null, null, 0);
        }
    }
    
    // 4. Remove the relay so the player can't progress
    DeleteEntity("sphere_entrance_lift_relay", false); 
    DeleteEntity("potatos_prop", false);
    
    CBaseEntity@ cmd2 = EntityList().FindByName(null, "InitCmd");
    if (cmd2 !is null) {
        Variant v3; v3.SetString("snd_setmixer gladosVO vol 0.0");
        cmd2.FireInput("Command", v3, 0.1f, null, null, 0);
    }
    
    // 5. Ensure she is removed from the gun itself
    RemovePotatosFromGun();
    
    ArchipelagoLog("[AP] PotatOS removal logic applied (with instructor hints).");
}
