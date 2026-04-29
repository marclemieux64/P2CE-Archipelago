void CreateMapSpecificHolos(string current_map) {
    // 1. Spatially defined map holograms
    if (current_map == "sp_a1_intro3") {
        CreateAPHologram(Vector(25, 1958, -267), QAngle(0, 0, 0), 0.66f, "", "", 0, "portal_gun_spawner_holo");
    } else if (current_map == "sp_a2_intro") {
        CBaseEntity@ gun_trigger = EntityList().FindByName(null, "player_near_portalgun");
        if (gun_trigger !is null) {
            Vector pos = gun_trigger.GetAbsOrigin();
            pos.z += 32.0f;
            CreateAPHologram(pos, QAngle(0, 0, 0), 0.66f, "", "", 0, "player_near_portalgun_holo");
        } else {
            Msgl("AP-Mod: Warning - Could not find 'player_near_portalgun' to spawn hologram.");
        }
    } else if (current_map == "sp_a3_transition01") {
        CBaseEntity@ potato_button = EntityList().FindByName(null, "sphere_entrance_potatos_button");
        if (potato_button !is null) {
            Vector pos = potato_button.GetAbsOrigin();
            pos.z += 32.0f;
            CreateAPHologram(pos, QAngle(0, 0, 0), 0.66f, "", "", 0, "sphere_entrance_potatos_button_holo");
        } else {
            Msgl("AP-Mod: Warning - Could not find 'sphere_entrance_potatos_button' to spawn hologram.");
        }
    } else if (current_map == "sp_a1_intro7") {
        CBaseEntity@ ent = null;
        while ((@ent = EntityList().FindByClassname(ent, "prop_dynamic")) !is null) {
            if (ent.GetModelName().locate("turret_01.mdl") != uint(-1)) {
                Vector hPos;
                QAngle hAng;
                int hSkin;
                float hScale;
                GetHologramVisualOverrides(ent, hPos, hAng, hSkin, hScale);
                
                string tName = ent.GetEntityName();
                string hName = (tName != "") ? (tName + "_holo") : "turret_holo";
                CreateAPHologram(hPos, hAng, hScale, "", "", hSkin, hName);
            }
        }
    }
    
    // 3. Kill any legacy map-based triggers that try to call 'ppmod'
    DisarmLegacyLogic();
}
