namespace Archipelago {

void AddButtonFrame(string entity_name) {
        string mapName = ConVarRef("host_map").GetString();
        array<CBaseEntity@> targets = FindEntities(entity_name);
        
        // --- RECHERCHE DU PARENT D'INSTANCE ---
        CBaseEntity@ targetParent = null;
        bool useAutoParent = (mapName == "sp_a2_sphere_peek");

        for (uint i = 0; i < targets.length(); i++) {
            CBaseEntity@ ent = targets[i];
            if (ent is null) continue;

            // Détection du parent s'il existe sur l'entité originale (requis pour les plateformes mobiles)
            if (useAutoParent) {
                @targetParent = ent.GetMoveParent();
            }
            else if (mapName == "sp_a4_tb_wall_button") {
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

            Vector position = ent.GetAbsOrigin();
            QAngle angles = ent.GetAbsAngles();
            string originalModel = ent.GetModelName();
        
            // --- OFFSET VERTICAL SÉCURISÉ POUR SP_A2_SPHERE_PEEK ---
            if (mapName == "sp_a2_sphere_peek") {
                position.z += 4.0f; // Ajustement vertical de 4 unités pour le cadre et le dummy
            }

            // 1. Spawn le cadre
            CBaseEntity@ box = util::CreateEntityByName("prop_dynamic");
            if (box !is null) {
                box.KeyValue("targetname", entity_name + "_frame");
                box.KeyValue("model", "models/props/archipelago/ap_buttonframe.mdl");
                box.KeyValue("solid", "6");
                box.SetAbsOrigin(position);
                box.SetAbsAngles(angles);
                box.Spawn();
                
                if (targetParent !is null) {
                    Variant v;
                    v.SetEntity(targetParent);
                    box.FireInput("SetParent", v, 0.01f, targetParent, box);
                }
            }

            // 2. Spawn le Faux Bouton Inerte (Dummy)
            CBaseEntity@ dummy = util::CreateEntityByName("prop_dynamic");
            if (dummy !is null) {
                dummy.KeyValue("model", originalModel);
                dummy.KeyValue("solid", "6"); 
                dummy.SetAbsOrigin(position);
                dummy.SetAbsAngles(angles);
                dummy.Spawn();
                
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

                // --- OFFSET VERTICAL DE L'HOLOGRAMME POUR SP_A2_SPHERE_PEEK ---
                if (mapName == "sp_a2_sphere_peek") {
                    hPos.z += 4.0f; // Ajustement vertical de 4 unités pour l'hologramme
                }

                // --- EXCEPTION MANUELLE STRICTE POUR SP_A3_BOMB_FLINGS ---
                if (mapName == "sp_a3_bomb_flings") {
                    hParent = false;                  // Désactive le parentage qui cause le 180 0 0
                    hPos = Vector(0.0f, 0.0f, 70.0f); // Position standard devant un bouton mural
                    hAng = angles;                    // Récupère l'orientation du bouton original
                    hAng.x += 0.0f; 
                    hScale = 0.66f;                 // Aligne la rotation face au joueur
                }

                Vector finalPos;
                QAngle finalAng;
                CBaseEntity@ finalParent = hParent ? dummy : null;

                if (hParent) { 
                    finalPos = hPos; 
                    finalAng = hAng; 
                } else { 
                    finalPos = position + (AnglesToForward(angles) * hPos.x) + (AnglesToRight(angles) * -hPos.y) + (AnglesToUp(angles) * hPos.z);
                    finalAng = hAbs ? hAng : (angles + hAng);
                }

                // Ré-ajustement de finalAng pour l'exception afin d'éviter qu'il soit écrasé par le bloc standard
                if (mapName == "sp_a3_bomb_flings") {
                    finalAng = hAng;
                }

                CreateAPHologram(finalPos, finalAng, hScale, finalParent, "", hSkin, holoName);
            }

            // 4. Détruire le vrai bouton fonctionnel
            ent.Remove();
        }
    }

} // namespace Archipelago