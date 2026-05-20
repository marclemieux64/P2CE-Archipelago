namespace Archipelago {

void AddFloorButtonFrame(string entity_name) {
        array<CBaseEntity@> targets = FindEntities(entity_name);
        for (uint i = 0; i < targets.length(); i++) {
            CBaseEntity@ ent = targets[i];
            Vector position = ent.GetAbsOrigin();
            QAngle angles = ent.GetAbsAngles();
            string originalModel = ent.GetModelName();

            // 1. Spawn le cadre personnalisé
            CBaseEntity@ box = util::CreateEntityByName("prop_dynamic");
            if (box !is null) {
                box.KeyValue("targetname", entity_name + "_frame");
                box.KeyValue("model", "models/props/archipelago/ap_floorbuttonframe.mdl");
                box.KeyValue("solid", "6");
                box.SetAbsOrigin(position);
                box.SetAbsAngles(angles);
                box.Spawn();
            }

            // 2. Spawn le Faux Bouton Inerte (Dummy) EN PREMIER
            CBaseEntity@ dummy = util::CreateEntityByName("prop_dynamic");
            if (dummy !is null) {
                // Pas de targetname pour le cacher des scripts
                dummy.KeyValue("model", originalModel);
                dummy.KeyValue("solid", "6"); 
                dummy.SetAbsOrigin(position);
                dummy.SetAbsAngles(angles);
                dummy.Spawn();
            }

            // 3. Spawn l'Hologramme et l'attacher au DUMMY
            string holoName = entity_name + "_" + ent.GetEntityIndex() + "_holo";
            if (EntityList().FindByName(null, holoName) is null) {
                Vector hPos(0, 0, 0);
                QAngle hAng(0, 0, 0);
                int hSkin = 4;
                float hScale = 1.0f;
                bool hParent = true;
                bool hAbs = false;
                Archipelago::GetHologramVisualOverrides(ent, hPos, hAng, hSkin, hScale, hParent, hAbs);
                
                Vector finalPos;
                QAngle finalAng;
                
                // CRUCIAL : Si on parente, on l'attache au Dummy qui va survivre !
                CBaseEntity@ finalParent = hParent ? dummy : null;
                
                if (hParent) { 
                    finalPos = hPos; 
                    finalAng = hAng; 
                } else { 
                    // Mathématiques parfaites réparées
                    finalPos = position + (AnglesToForward(angles) * hPos.x) + (AnglesToRight(angles) * -hPos.y) + (AnglesToUp(angles) * hPos.z);
                    finalAng = hAbs ? hAng : (angles + hAng);
                }

                CreateAPHologram(finalPos, finalAng, hScale, finalParent, "", hSkin, holoName);
            }

            // 4. Détruire le vrai bouton fonctionnel (L'hologramme survit car il est sur le Dummy)
            ent.Remove();
        }
    }

} // namespace Archipelago
