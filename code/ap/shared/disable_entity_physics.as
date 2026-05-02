/**
 * DisableEntityPhysics - Changes an entity's movement type to static/frozen.
 */
void DisableEntityPhysics(string target) {
    array<CBaseEntity@> targets = FindEntities(target);
    for (uint i = 0; i < targets.length(); i++) {
        if (targets[i] !is null) {
            targets[i].KeyValue("movetype", "0"); 
            ArchipelagoLog("[Archipelago] Disabled physics for: " + targets[i].GetClassname() + " (" + target + ")");
        }
    }
}
