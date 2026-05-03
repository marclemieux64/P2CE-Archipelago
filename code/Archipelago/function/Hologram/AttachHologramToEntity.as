// =============================================================
// ARCHIPELAGO ATTACH HOLOGRAM TO ENTITY
// =============================================================
void AttachHologramToEntity(string entity_name, string attachment_point, float holo_scale, float offset, int skin = 0) {
    array<CBaseEntity@> targets;
    CBaseEntity@ ent = null;
    
    // 0. Auto-Class Suppression for dynamic NPCs (Turrets)
    if (entity_name == "npc_portal_turret_floor") {
        bool alreadySuppressed = false;
        for (uint j = 0; j < g_suppressed_classes.length(); j++) {
            if (g_suppressed_classes[j] == entity_name) { alreadySuppressed = true; break; }
        }
        if (!alreadySuppressed) {
            g_suppressed_classes.insertLast(entity_name);
            ArchipelagoLog("[Archipelago] Persistent Class Attachment activated for: " + entity_name);
        }
    }

    // 1. Collect targets
    while ((@ent = EntityList().FindByName(ent, entity_name)) !is null) targets.insertLast(ent);
    @ent = null;
    while ((@ent = EntityList().FindByClassname(ent, entity_name)) !is null) {
        bool isDuplicate = false;
        for (uint i = 0; i < targets.length(); i++) {
            if (targets[i] is ent) { isDuplicate = true; break; }
        }
        if (!isDuplicate) targets.insertLast(ent);
    }
    
    bool isBTS4Turret = (current_map == "sp_a2_bts4" && entity_name == "npc_portal_turret_floor");

    for (uint i = 0; i < targets.length(); i++) {
        CBaseEntity@ t = targets[i];
        
        string tName = t.GetEntityName();
        // If unnamed, generate a stable internal name for the hologram registry
        if (tName == "") tName = entity_name + "_" + t.GetEntityIndex();
        
        string hName = tName + "_holo";
        
        // 2. Fetch Registry Overrides (Unified Logic)
        Vector finalPos;
        QAngle finalAng;
        int finalSkin = skin;
        float finalScale = holo_scale;
        
        // Crucial: We pull from our visual registry!
        GetHologramVisualOverrides(t, finalPos, finalAng, finalSkin, finalScale);
        
        // 3. Create the Hologram using the handle 't' directly as parent
        StableCreateAPHologram(finalPos, finalAng, finalScale, "", attachment_point, finalSkin, hName, t);
    }
}

