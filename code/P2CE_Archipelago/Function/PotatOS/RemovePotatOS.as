namespace Archipelago {

void RemovePotatOS() {
     ArchipelagoLog("[AP DEBUG] RemovePotatOS: Disabling elevator,removing potatOs Prop.");
        CBaseEntity@ button = EntityList().FindByName(null, "sphere_entrance_potatos_button");
        if (button !is null) {
            Vector place = button.GetAbsOrigin();
            CBaseEntity@ target = util::CreateEntityByName("info_target_instructor_hint");
            target.KeyValue("targetname", "hint_target_no_potatos");
            target.SetAbsOrigin(place);
            target.Spawn();
        
            DeleteEntity("sphere_entrance_lift_relay", false);
            DeleteEntity("potatos_prop", false);
        }

        CBaseEntity@ hint = util::CreateEntityByName("env_instructor_hint");
        hint.KeyValue("targetname", "hudhint_no_potatos");
        hint.KeyValue("hint_target", "hint_target_no_potatos");
        hint.KeyValue("hint_static", "0");
        hint.KeyValue("hint_caption", "PotatOS not unlocked");
        hint.KeyValue("hint_icon_onscreen", "icon_alert");
        hint.KeyValue("hint_color", "255 50 50");
        hint.Spawn();

        SafeAddOutput(EntityList().FindByName(null, "sphere_entrance_potatos_button"), "OnPressed", "hudhint_no_potatos", "ShowHint", "", 0.0f, -1);
        
        // --- NEW: Silence GLaDOSVO exclusively here ---
        CBaseEntity@ cmd = EntityList().FindByName(null, "InitCmd");
        if (cmd !is null) {
            Variant vMixG;
            vMixG.SetString("snd_setmixer GLaDOSVO vol 0.0");
            cmd.FireInput("Command", vMixG, 0.0f, null, null, 0);
        }

        RemovePotatosFromGun();
    }

} // namespace Archipelago
