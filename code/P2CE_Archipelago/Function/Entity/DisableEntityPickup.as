namespace Archipelago {

void DisableEntityPickup(string target) {
    array<CBaseEntity@> targets = FindEntities(target);

    for (uint i = 0; i < targets.length(); i++) {
        CBaseEntity@ t = targets[i];
        if (t is null) continue;
        t.KeyValue("PickupEnabled", "0");
    }
}

} // namespace Archipelago
