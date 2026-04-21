void AttachHologramToEntity(string entity_name, string attachment_point, float holo_scale, float offset, int skin = 0) {
    array<CBaseEntity@> targets;
    CBaseEntity@ ent = null;
    
    // 1. Collect targets by Name
    while ((@ent = EntityList().FindByName(ent, entity_name)) !is null) targets.insertLast(ent);
    
    // 2. Collect targets by Class
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
        Vector position = t.GetAbsOrigin();
        QAngle angles = t.GetAbsAngles();
        
        string tName = entity_name + "_attached_" + i;
        t.KeyValue("targetname", tName);
        
        Vector fwd, right, up;
        AngleVectors(angles, fwd, right, up);
        Vector newPos = position + (up * offset);
        
        CreateAPHologram(newPos, angles, holo_scale, tName, attachment_point, skin, tName + "_holo");
    }
}
