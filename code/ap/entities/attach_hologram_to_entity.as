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
        string classname = t.GetClassname();
        
        string tName = entity_name + "_attached_" + i;
        t.KeyValue("targetname", tName);
        
        Vector fwd, right, up;
        AngleVectors(angles, fwd, right, up);
        
        Vector newPos;
        if (classname == "prop_tractor_beam") {
            // Using target.Forward() directly is much safer for tractor beams.
            // 75 units of padding (95 total) for that perfect gap.
            newPos = position + (t.Forward() * (offset + 75.0f));
            
            // Sync orientation with the frame's +90 pitch adjustment
            angles.x += 90.0f;
        } else {
            // Use the entity's local Up vector for standard buttons
            // This ensures ceiling and wall buttons work properly!
            newPos = position + (t.Up() * offset);
        }
        
        CreateAPHologram(newPos, angles, holo_scale, tName, attachment_point, skin, tName + "_holo");
    }
}
