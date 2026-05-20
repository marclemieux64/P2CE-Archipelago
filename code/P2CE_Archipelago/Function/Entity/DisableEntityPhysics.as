namespace Archipelago {

void DisableEntityPhysics(string entity_name) {
        array<CBaseEntity@> targets = FindEntities(entity_name);
        for (uint i = 0; i < targets.length(); i++) {
            targets[i].KeyValue("movetype", "4");
        }
    }

} // namespace Archipelago
