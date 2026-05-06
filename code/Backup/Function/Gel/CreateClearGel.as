// =============================================================
// ARCHIPELAGO CREATE CLEAR GEL
// =============================================================
/**
 * CreateClearGel - Spawns a water paint bomb to scrub floor gel.
 */
void CreateClearGel(Vector pos, float offset = -100.0f) {
    CBaseEntity@ bomb = util::CreateEntityByName("prop_paint_bomb");
    if (bomb !is null) {
        ArchipelagoLog("[AP] CreateClearGel: Successfully created prop_paint_bomb at " + pos.x + " " + pos.y + " " + pos.z);
        Vector spawnPos = pos;
        spawnPos.z += offset + 10.0f; // Shift up slightly to avoid floor clipping
        bomb.SetAbsOrigin(spawnPos);
        
        string uniqueName = "ap_cleargel_bomb_" + bomb.GetEntityIndex();
        bomb.KeyValue("targetname", uniqueName);
        bomb.KeyValue("model", "models/error.mdl"); // Dummy model to avoid warnings
        bomb.KeyValue("paint_type", "4"); // Erase/Clear is 4 for bombs
        bomb.KeyValue("BombType", "1"); // Wet bomb for better visual
        bomb.Spawn();
        
        // Use point_servercommand to trigger the explosion and cleanup
        CBaseEntity@ cmd = EntityList().FindByName(null, "InitCmd");
        if (cmd !is null) {
            Variant vExplode;
            vExplode.SetString("ent_fire " + uniqueName + " Explode");
            cmd.FireInput("Command", vExplode, 0.2f, null, null, 0);

            // Safety kill in case explosion fails
            Variant vKill;
            vKill.SetString("ent_fire " + uniqueName + " Kill");
            cmd.FireInput("Command", vKill, 1.0f, null, null, 0);

            Variant vClear;
            vClear.SetString("removeallpaint");
            cmd.FireInput("Command", vClear, 1.0f, null, null, 0);
        }
    } else {
        ArchipelagoLog("[AP] ERROR: CreateClearGel failed to create prop_paint_bomb!");
    }
}

