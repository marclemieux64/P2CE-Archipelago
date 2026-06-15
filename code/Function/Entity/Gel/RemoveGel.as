namespace Archipelago {

void RemoveGel(Vector position, string filter = "", string object_name = "") {
        CBaseEntity@ ent = null;
        float bestScore = 999999.0f;

        // 1. RECHERCHE HYBRIDE (VScript Fallback + Falling Bombs)
        CBaseEntity@ searchEnt = EntityList().First();
        while (searchEnt !is null) {
            string name = searchEnt.GetEntityName();
            string cls = searchEnt.GetClassname();

            // On ignore nos propres hologrammes et le joueur
            if (name.locate("_holo") == uint(-1) && cls != "player") {
                bool classMatch = (filter == "" || filter == "null" || cls.locate(filter) != uint(-1));
                
                if (classMatch) {
                    bool nameMatch = (object_name == "" || object_name == "null" || name == object_name || name.locate(object_name) != uint(-1));
                    float dist = (searchEnt.GetAbsOrigin() - position).Length();

                    if (nameMatch || dist <= 15.0f) {
                        float score;
                        if (nameMatch && dist <= 15.0f) {
                            score = dist; // Le candidat parfait
                        } else if (nameMatch && dist > 15.0f) {
                            score = 1000.0f + dist; // Bombe de gel qui tombe
                        } else {
                            score = 5000.0f + dist; // Fallback VScript (Classe ok, position ok)
                        }

                        if (score < bestScore) {
                            bestScore = score;
                            @ent = searchEnt;
                        }
                    }
                }
            }
            @searchEnt = EntityList().Next(searchEnt);
        }

        // --- GÉNÉRATION DU NOM UNIQUE CONSTANT ---
        string safeName = (object_name != "" && object_name != "null") ? object_name : filter;
        if (safeName == "") safeName = "unknown_gel";
        string holoName = safeName + "_" + int(position.x) + "_" + int(position.y) + "_" + int(position.z) + "_holo";

        // 2. EXÉCUTION STRICTE (Pas de Failsafe)
        if (ent !is null) {
            string cls = ent.GetClassname();
            string originalName = ent.GetEntityName();

            // Renommage temporaire pour lire les overrides par coordonnées
            ent.KeyValue("targetname", holoName); 

            Vector hPos(0, 0, 0);
            QAngle hAng(0, 0, 0);
            int hSkin = 4;
            float hScale = 1.0f;
            bool hParent = false;
            bool hAbs = false;
            Archipelago::GetHologramVisualOverrides(ent, hPos, hAng, hSkin, hScale, hParent, hAbs);

            // Restauration du nom
            ent.KeyValue("targetname", originalName);

            Vector basePos = ent.GetAbsOrigin();
            if (cls == "prop_paint_bomb" || cls == "point_template" || cls == "paint_sphere") {
                basePos = position;
            }

            QAngle spawnAng = ent.GetAbsAngles();
            Vector finalPos;
            QAngle finalAng;

            if (hAbs) {
                finalPos = hPos;
                finalAng = hAng;
            } else {
                finalPos = basePos + (Archipelago::AnglesToForward(spawnAng) * hPos.x) + (Archipelago::AnglesToRight(spawnAng) * -hPos.y) + (Archipelago::AnglesToUp(spawnAng) * hPos.z);
                finalAng = spawnAng + hAng;
            }

            Archipelago::CreateAPHologram(finalPos, finalAng, hScale, null, "", hSkin, holoName);
            ent.Remove();
        }
    }

} // namespace Archipelago
