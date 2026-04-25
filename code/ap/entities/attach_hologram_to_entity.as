void AttachHologramToEntity(string entity_name, string attachment_point, float holo_scale, float offset, int skin = 0) {
    array<CBaseEntity@> targets;
    CBaseEntity@ ent = null;
    
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
    
    for (uint i = 0; i < targets.length(); i++) {
        CBaseEntity@ t = targets[i];
        
        string tName = entity_name + "_attached_" + i;
        t.KeyValue("targetname", tName);
        
        // 2. Fetch Registry Overrides (Unified Logic)
        Vector finalPos;
        QAngle finalAng;
        int finalSkin = skin;
        float finalScale = holo_scale;
        
        // Crucial: We pull from our visual registry!
        GetHologramVisualOverrides(t, finalPos, finalAng, finalSkin, finalScale);
        
        // If the registry didn't find a map-specific override, 
        // we keep the 'Attachment' default style but use registry's suggested skin/scale
        
        // 3. Create the Hologram
        // We use the registry results (finalPos, finalAng)
        CreateAPHologram(finalPos, finalAng, finalScale, tName, attachment_point, finalSkin, tName + "_holo");
    }
}
