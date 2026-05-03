// =============================================================
// ARCHIPELAGO DISABLE ENTITY PICKUP
// =============================================================
/**
 * DisableEntityPickup - Disables pickup for an entity by name, class, or model.
 */
void DisableEntityPickup(string target) {
    array<CBaseEntity@> targets = FindEntities(target);

    for (uint i = 0; i < targets.length(); i++) {
        CBaseEntity@ t = targets[i];
        if (t is null) continue;
        t.KeyValue("PickupEnabled", "0");
       //ArchipelagoLog("[Archipelago] Disabled pickup for: " + t.GetClassname() + " (" + target + ")");
    }
}

