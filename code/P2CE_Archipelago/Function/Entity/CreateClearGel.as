namespace Archipelago {

void CreateClearGel(Vector position, float offset = -100.0f) {
        CBaseEntity@ gel = util::CreateEntityByName("prop_paint_bomb");
        if (gel !is null) {
            position.z += offset;
            gel.SetAbsOrigin(position);
            gel.KeyValue("paint_type", 3);
            gel.Spawn();
        }
    }

} // namespace Archipelago
