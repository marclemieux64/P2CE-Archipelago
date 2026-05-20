namespace Archipelago {

void AttachHologramToEntity(string entity_name, string attachment_point, float holo_scale, float offset, int skin = 0) {
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
        
        // Nom unique pour permettre l'UPDATE dans CreateAPHologram
        string holoName = entity_name + "_" + ent.GetEntityIndex() + "_holo";

        // Application de l'offset vertical (Z)
        Vector verticalOffset(0, 0, offset);
        Vector finalOffset = hPos + verticalOffset;

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
