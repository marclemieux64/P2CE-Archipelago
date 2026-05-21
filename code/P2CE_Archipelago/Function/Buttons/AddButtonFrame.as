namespace Archipelago {

void AddButtonFrame(string entity_name) {
        string mapName = ConVarRef("host_map").GetString();
        array<CBaseEntity@> targets = FindEntities(entity_name);
        
        // --- RECHERCHE DU PARENT D'INSTANCE (SP_A4_TB_WALL_BUTTON UNIQUEMENT) ---
        CBaseEntity@ targetParent = null;
        if (mapName == "sp_a4_tb_wall_button") {
            CBaseEntity@ loopEnt = EntityList().First();
            while (loopEnt !is null) {
                string entName = loopEnt.GetEntityName().tolower();
                if (entName.locate("dropper_prop") != uint(-1)) {
                    if (loopEnt.GetClassname() == "prop_dynamic") {
                        @targetParent = loopEnt;
                        break;
                    }
                }
                @loopEnt = EntityList().Next(loopEnt);
            }
        }

        for (uint i = 0; i < targets.length(); i++) {
            CBaseEntity@ ent = targets[i];
            if (ent is null) continue;

            Vector position = ent.GetAbsOrigin();
            QAngle angles = ent.GetAbsAngles();
            string originalModel = ent.GetModelName();
        
            // 1. Spawn le cadre
            CBaseEntity@ box = util::CreateEntityByName("prop_dynamic");
            if (box !is null) {
                box.KeyValue("targetname", entity_name + "_frame");
                box.KeyValue("model", "models/props/archipelago/ap_buttonframe.mdl");
                box.KeyValue("solid", "6");
                box.SetAbsOrigin(position);
                box.SetAbsAngles(angles);
                box.Spawn();
                
                // Si on a un parent de carte mobile, on soude le cadre dessus en conservant son décalage
                if (targetParent !is null) {
                    Variant v;
                    v.SetEntity(targetParent);
                    box.FireInput("SetParent", v, 0.01f, targetParent, box);
                }
            }

            // 2. Spawn le Faux Bouton Inerte (Dummy) EN PREMIER
            CBaseEntity@ dummy = util::CreateEntityByName("prop_dynamic");
            if (dummy !is null) {
                dummy.KeyValue("model", originalModel);
                dummy.KeyValue("solid", "6"); 
                dummy.SetAbsOrigin(position);
                dummy.SetAbsAngles(angles);
                dummy.Spawn();
                
                // Si on a un parent de carte mobile, on soude aussi le dummy dessus
                if (targetParent !is null) {
                    Variant v;
                    v.SetEntity(targetParent);
                    dummy.FireInput("SetParent", v, 0.01f, targetParent, dummy);
                }
            }
        
            // 3. Spawn l'Hologramme et l'attacher au DUMMY
            string holoName = entity_name + "_" + ent.GetEntityIndex() + "_holo";
            if (EntityList().FindByName(null, holoName) is null) {
                Vector hPos(0, 0, 0);
                QAngle hAng(0, 0, 0);
                int hSkin = 4;
                float hScale = 0.66f;
                bool hParent = true;
                bool hAbs = false;
                Archipelago::GetHologramVisualOverrides(ent, hPos, hAng, hSkin, hScale, hParent, hAbs);

                Vector finalPos;
                QAngle finalAng;
                
                // Si l'environnement bouge, le dummy est déjà parenté au décor mobile. 
                // Lier l'hologramme au dummy (`finalParent = dummy`) crée une hiérarchie parfaite !
                CBaseEntity@ finalParent = hParent ? dummy : null;

                if (hParent) { 
                    finalPos = hPos; 
                    finalAng = hAng; 
                } else { 
                    finalPos = position + (AnglesToForward(angles) * hPos.x) + (AnglesToRight(angles) * -hPos.y) + (AnglesToUp(angles) * hPos.z);
                    finalAng = hAbs ? hAng : (angles + hAng);
                }

                CreateAPHologram(finalPos, finalAng, hScale, finalParent, "", hSkin, holoName);
            }

            // 4. Détruire le vrai bouton fonctionnel
            ent.Remove();
        }
    }

} // namespace Archipelago