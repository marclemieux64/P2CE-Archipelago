// =============================================================
// ARCHIPELAGO ATTACH HOLOGRAM TO ENTITY
// =============================================================

/**
 * AttachHologramToEntity - Tool to attach holograms to map objects.
 * This is a pure tool: it fetches rules from the registry and applies them.
 */
void AttachHologramToEntity(string entity_name, string attachment_point, float holo_scale, float offset, int skin = 0) {
    // 1. Collect targets via the central search engine
    array<CBaseEntity@> targets = FindEntities(entity_name);
    
    // 2. Process all collected targets
    for (uint i = 0; i < targets.length(); i++) {
        CBaseEntity@ t = targets[i];
        if (t is null) continue;

        string tName = t.GetEntityName();
        // If unnamed, generate a stable internal name for the hologram registry
        if (tName == "") tName = entity_name + "_" + t.GetEntityIndex();
        
        string hName = tName + "_holo";
        
        // 3. Fetch Unified Rules (Single Source of Truth)
        Vector finalPos;
        QAngle finalAng;
        int finalSkin;
        float finalScale;
        bool shouldParent;
        
        GetHologramVisualOverrides(t, finalPos, finalAng, finalSkin, finalScale, shouldParent);
        
        // Manual skin override if specified in the tool call
        if (skin != 0) finalSkin = skin;
        
        // 4. Execute the creation via the stable tool
        CBaseEntity@ parent = shouldParent ? t : null;
        StableCreateAPHologram(finalPos, finalAng, finalScale, "", attachment_point, finalSkin, hName, parent);
    }
}
