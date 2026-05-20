namespace Archipelago {

/**
 * SafeRemoveEntity - Standard P2CE crash-safe entity removal.
 */
void SafeRemoveEntity(CBaseEntity@ ent) {
    if (ent is null) return;
    Variant v;
    ent.FireInput("Kill", v, 0.0f, null, null, 0);
}

} // namespace Archipelago
