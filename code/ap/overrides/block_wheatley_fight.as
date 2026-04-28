/**
 * BlockWheatleyFight - Prevents the Wheatley fight from triggering by 
 * removing the breaker socket and replacing it with a static hint target.
 */
void BlockWheatleyFight() {
    CBaseEntity@ button = EntityList().FindByName(null, "breaker_socket_button");
    if (button is null) {
        Msgl("[AP] BlockWheatleyFight: No breaker socket found, skipping.");
        return;
    }
    
    Vector pos = button.GetAbsOrigin();
    
    // Create the hint target for the instructor
    CBaseEntity@ hint = util::CreateEntityByName("info_target_instructor_hint");
    if (hint !is null) {
        hint.KeyValue("targetname", "hint_target_no_potatos");
        hint.Spawn();
        hint.SetAbsOrigin(pos);
    }
    
    // Create the instructor hint
    CBaseEntity@ hintObj = util::CreateEntityByName("env_instructor_hint");
    if (hintObj !is null) {
        hintObj.KeyValue("targetname", "hudhint_no_potatos");
        hintObj.KeyValue("hint_target", "hint_target_no_potatos");
        hintObj.KeyValue("hint_static", "0");
        hintObj.KeyValue("hint_caption", "PotatOS not unlocked");
        hintObj.KeyValue("hint_icon_onscreen", "icon_alert");
        hintObj.KeyValue("hint_color", "255 50 50");
        hintObj.Spawn();
    }

    // Trigger hint on cleanser touch
    CBaseEntity@ cmd = EntityList().FindByName(null, "ap_init_cmd");
    if (cmd !is null) {
        Variant v;
        v.SetString("ent_fire trigger_portal_cleanser AddOutput \"OnStartTouch hudhint_no_potatos:ShowHint:0:-1\"");
        cmd.FireInput("Command", v, 0.0f, null, null, 0);
    }
    
    // Remove the interactive elements
    DeleteEntity("breaker_socket_button", false);
    DeleteEntity("breaker_hint", false);
    
    Msgl("[AP] Wheatley fight blocked. Hint target established.");
}
