namespace Archipelago {

void AttachHologramToEntity(string entity_name, string attachment_point, float holo_scale, float offset, int skin = 0) {
    if (current_map == "sp_a2_bts4") {
        if (entity_name == "npc_portal_turret_floor" || entity_name == "initial_template_turret") {
            g_bInitialTemplateHoloActive = true;
            cv_BTS4_InitialTemplateHoloActive.SetValue(1);
        }
        if (entity_name == "npc_portal_turret_floor" || entity_name == "turret_conveyor_1_template") {
            g_bConveyor1TemplateHoloActive = true;
            cv_BTS4_Conveyor1TemplateHoloActive.SetValue(1);
        }
    }


    array<CBaseEntity@> targets = FindEntities(entity_name);
    
    for (uint i = 0; i < targets.length(); i++) {
        // Utilisation de @ pour le pointeur d'entité
        CBaseEntity@ ent = targets[i]; 
        if (ent is null) continue;



        // Déclarations explicites pour éviter les erreurs d'expression
        Vector hPos(0, 0, 0);
        QAngle hAng(0, 0, 0);
        int hSkin = 0;
        float hScale = 1.0f;
        bool hParent = true;
        bool hAbsolute = false;
        
        // Appel aux overrides (centralisé dans HologramOverrides.as)
        Archipelago::GetHologramVisualOverrides(ent, hPos, hAng, hSkin, hScale, hParent, hAbsolute);
        
        // Priorité aux paramètres Archipelago (si non nuls)
        if (hSkin == 0) hSkin = skin;
        if (hScale == 1.0f) hScale = holo_scale;
        
        // Application de l'offset vertical (Z)
        Vector verticalOffset(0, 0, offset);
        Vector finalOffset = hPos + verticalOffset;

        // Clean targetname for the hologram (no dynamic &XXXX or _XXX unique suffix)
        string cleanName = ent.GetEntityName();
        if (cleanName.locate("&") != uint(-1)) {
            cleanName = cleanName.substr(0, cleanName.locate("&"));
        }
        if (cleanName == "") {
            cleanName = entity_name;
        }
        string holoName = cleanName + "_" + ent.GetEntityIndex() + "_holo";

        if (hAbsolute) {
            // Calcul de position mondiale
            Vector worldPos = ent.GetAbsOrigin() + (Archipelago::AnglesToForward(ent.GetAbsAngles()) * finalOffset.x) + (Archipelago::AnglesToRight(ent.GetAbsAngles()) * -finalOffset.y) + (Archipelago::AnglesToUp(ent.GetAbsAngles()) * finalOffset.z);
            Archipelago::CreateAPHologram(worldPos, hAng, hScale, null, "", hSkin, holoName);
        } else {
            // Parenté locale
            Archipelago::CreateAPHologram(finalOffset, hAng, hScale, ent, attachment_point, hSkin, holoName);
        }
    }
}

} // namespace Archipelago
