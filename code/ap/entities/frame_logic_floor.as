void AddFloorButtonFrame(string search_term) {
    array<CBaseEntity@> targets = FindEntities(search_term);

    // Process targets
    for (uint i = 0; i < targets.length(); i++) {
        CBaseEntity@ target = targets[i];
        Vector position = target.GetAbsOrigin();
        QAngle angles = target.GetAbsAngles();
        
        // Spawn Archipelago Frame
        CBaseEntity@ box = util::CreateEntityByName("prop_dynamic");
        if (box !is null) {
            box.SetModel("models/props/archipelago/ap_floorbuttonframe.mdl");
            box.SetAbsOrigin(position);
            box.SetAbsAngles(angles);
            box.KeyValue("solid", "6"); 
            box.Spawn();
            box.SetSolid(SOLID_VPHYSICS);
        }

        // Lock and disable the original button to prevent interaction
        target.FireInput("Lock", Variant(), 0.0f, null, null, 0);
    }

    // Call bridge for hologram (1.0 scale, 40px vertical offset, skin 4)
    AttachHologramToEntity(search_term, "", 1.0f, 80.0f, 4);
}
