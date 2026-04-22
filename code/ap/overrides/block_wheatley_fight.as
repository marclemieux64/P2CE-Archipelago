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
    
    // Remove the interactive elements
    DeleteEntity("breaker_socket_button", false);
    DeleteEntity("breaker_hint", false);
    
    Msgl("[AP] Wheatley fight blocked. Hint target established.");
}
