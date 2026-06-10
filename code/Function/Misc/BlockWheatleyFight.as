namespace Archipelago {

void BlockWheatleyFight() {
        CBaseEntity@ socket = EntityList().FindByName(null, "breaker_socket_button");
        if (socket !is null) {
            Vector place = socket.GetAbsOrigin();
            CBaseEntity@ target = util::CreateEntityByName("info_target_instructor_hint");
            target.KeyValue("targetname", "hint_target_no_potatos");
            target.SetAbsOrigin(place);
            target.Spawn();
        
            DeleteEntity("breaker_socket_button", false);
            DeleteEntity("breaker_hint", false);
        }

        CBaseEntity@ hint = util::CreateEntityByName("env_instructor_hint");
        hint.KeyValue("targetname", "hudhint_no_potatos");
        hint.KeyValue("hint_target", "hint_target_no_potatos");
        hint.KeyValue("hint_static", "0");
        hint.KeyValue("hint_caption", "PotatOS not unlocked");
        hint.KeyValue("hint_icon_onscreen", "icon_alert");
        hint.KeyValue("hint_color", "255 50 50");
        hint.Spawn();

        SafeAddOutput(EntityList().FindByName(null, "trigger_portal_cleanser"), "OnStartTouch", "hudhint_no_potatos", "ShowHint", "", 0.0f, -1);
    }

} // namespace Archipelago
