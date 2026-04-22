void DeleteEntity(string target, bool create_holo = true, float scale = 0.7f) {
    UpdateInternalMapName();
    
    if (target == "trigger_catapult") {
        for (uint i = 0; i < scripted_fling_levels.length(); i++) {
            if (scripted_fling_levels[i] == current_map) {
                Msgl("[AP] AngelScript: Not removing trigger_catapult in " + current_map);
                return;
            }
        }
    }

    array<CBaseEntity@> targets = FindEntities(target);

    for (uint i = 0; i < targets.length(); i++) {
        CBaseEntity@ t = targets[i];
        if (t is null) continue;
        
        if (target == "trigger_catapult" || t.GetClassname() == "trigger_catapult") {
            bool nearPlate = false;
            CBaseEntity@ plate = null;
            while ((@plate = EntityList().FindByClassname(plate, "prop_dynamic")) !is null) {
                string m = plate.GetModelName();
                if (m == "models/props/faith_plate.mdl" || m == "models/props/faith_plate_128.mdl") {
                    if ((plate.GetAbsOrigin() - t.GetAbsOrigin()).Length() <= 40.0f) {
                        nearPlate = true;
                        break;
                    }
                }
            }
            if (!nearPlate) continue;
        }

        if (create_holo) {
            Vector pos = t.GetAbsOrigin();
            QAngle ang = t.GetAbsAngles();
            if (target == "prop_tractor_beam" || t.GetClassname() == "prop_tractor_beam") ang = QAngle(0, 0, 0);
            
            CreateAPHologram(pos, ang, scale, "", "", 4);
        }
        
        t.Remove();
    }
}
