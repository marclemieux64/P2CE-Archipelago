/**
 * RemoveGel - Port of VScript RemoveGel logic.
 * Locates an entity near a position and destroys it, then clears any floor gel.
 */
void RemoveGel(Vector pos, string object_type = "", string object_name = "", bool createHolo = true) {
    CBaseEntity@ nearest = null;
    float radius = 10.0f; // Slightly larger radius for reliability in AS
    float minDist = radius;
    
    if (object_type != "") {
        CBaseEntity@ ent = null;
        while ((@ent = EntityList().FindByClassname(ent, object_type)) !is null) {
            float d = (ent.GetAbsOrigin() - pos).Length();
            if (d <= minDist) {
                if (object_name == "" || ent.GetEntityName() == object_name) {
                    @nearest = ent;
                    minDist = d;
                }
            }
        }
    } else {
        // Generic search by proximity if no type specified
        CBaseEntity@ ent = EntityList().First();
        while (@ent !is null) {
            float d = (ent.GetAbsOrigin() - pos).Length();
            if (d <= minDist) {
                 if (object_name == "" || ent.GetEntityName() == object_name) {
                    @nearest = ent;
                    minDist = d;
                }
            }
            @ent = EntityList().Next(ent);
        }
    }

    if (nearest !is null) {
        ArchipelagoLog("[Archipelago] Removing gel entity '" + nearest.GetEntityName() + "' (" + nearest.GetClassname() + ")");
        
        // Spawn a replacement hologram before removing the entity
        if (createHolo) {
            Vector hPos;
            QAngle hAng;
            int hSkin;
            float hScale;
            
            // Fetch correct visuals (pitch, offset, scale) for this specific entity type
            GetHologramVisualOverrides(nearest, hPos, hAng, hSkin, hScale);
            
            string hName = nearest.GetEntityName() + "_holo";
            StableCreateAPHologram(hPos, hAng, hScale, "", "", 1, hName);
        }
        
        nearest.Remove();
    }

    // Always attempt to clear floor gel at this position
    CreateClearGel(pos, 0.0f);
}

/**
 * CreateClearGel - Spawns a water paint bomb to scrub floor gel.
 */
void CreateClearGel(Vector pos, float offset = -100.0f) {
    CBaseEntity@ bomb = util::CreateEntityByName("prop_paint_bomb");
    if (bomb !is null) {
        Vector spawnPos = pos;
        spawnPos.z += offset;
        bomb.SetAbsOrigin(spawnPos);
        bomb.KeyValue("paint_type", "3"); // Water/Clear
        bomb.Spawn();
        
        // Force explosion to apply the clearing effect
        bomb.FireInput("Explode", Variant(), 0.02f, null, null, 0);
    }
}
