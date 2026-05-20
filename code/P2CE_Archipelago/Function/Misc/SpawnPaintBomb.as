namespace Archipelago {

void SpawnPaintBomb(Vector position) {
        CBaseEntity@ gel = util::CreateEntityByName("prop_paint_bomb");
        if (gel !is null) {
            gel.SetAbsOrigin(position);
            gel.Spawn();
        }
    }
} // namespace Archipelago
