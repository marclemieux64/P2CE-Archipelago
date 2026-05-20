namespace Archipelago {

void DeleteEntity(const string&in entity_name, bool create_holo = true) {
    string mapName = ConVarRef("host_map").GetString();
    
    // --- 1. NETTOYAGE ET EXCEPTIONS ---
    string cleanName = entity_name;
    
    if (cleanName.length() > 0 && cleanName[0] == 64) { 
        cleanName = cleanName.substr(1);
    }

    if (entity_name == "potatos_prop" || entity_name == "potatos" || entity_name == "models/props/potatos.mdl") {
        create_holo = false;
    }

    if (entity_name == "trigger_catapult" && ItemInList(mapName, scripted_fling_levels)) {
        Archipelago::ArchipelagoLog("not removing trigger_catapult");
        return;
    }

    // --- 2. RECHERCHE ROBUSTE ---
    array<CBaseEntity@> entsToDelete;
    CBaseEntity@ searchEnt = null;

    // A. Recherche par Modèle 3D (.mdl) direct
    if (entity_name.locate(".mdl") != uint(-1)) {
        while ((@searchEnt = EntityList().FindByModel(searchEnt, entity_name)) !is null) {
            entsToDelete.insertLast(searchEnt);
        }
        
        if (entsToDelete.length() == 0) {
            @searchEnt = null;
            while ((@searchEnt = EntityList().FindByModel(searchEnt, entity_name.tolower())) !is null) {
                entsToDelete.insertLast(searchEnt);
            }
        }
    } 
    else {
        // B. Recherche par Nom (Original, Nettoyé, et avec Wildcards natifs pour s'affranchir des préfixes d'instances)
        array<string> searchNames = { 
            entity_name, 
            cleanName, 
            "*" + entity_name + "*", 
            "*" + cleanName + "*" 
        };
        
        for (uint s = 0; s < searchNames.length(); s++) {
            @searchEnt = null;
            while ((@searchEnt = EntityList().FindByName(searchEnt, searchNames[s])) !is null) {
                bool alreadyIn = false;
                for (uint j = 0; j < entsToDelete.length(); j++) {
                    if (entsToDelete[j] is searchEnt) { 
                        alreadyIn = true;
                        break; 
                    }
                }
                if (!alreadyIn) entsToDelete.insertLast(searchEnt);
            }
        }

        // C. Recherche par Classname générique fourni (si aucun nom n'a matché)
        if (entsToDelete.length() == 0) {
            @searchEnt = null;
            while ((@searchEnt = EntityList().FindByClassname(searchEnt, entity_name)) !is null) {
                entsToDelete.insertLast(searchEnt);
            }
        }
        
        // D. FILET DE SÉCURITÉ : Uniquement pour les cubes anonymes
        if (entsToDelete.length() == 0 && (entity_name.locate("cube") != uint(-1) || entity_name.locate("box") != uint(-1))) {
            @searchEnt = null;
            while ((@searchEnt = EntityList().FindByClassname(searchEnt, "prop_weighted_cube")) !is null) {
                bool alreadyIn = false;
                for (uint j = 0; j < entsToDelete.length(); j++) {
                    if (entsToDelete[j] is searchEnt) { 
                        alreadyIn = true;
                        break; 
                    }
                }
                if (!alreadyIn) {
                    string currentModel = searchEnt.GetModelName().tolower();
                    if (entity_name.locate("metal_box") != uint(-1) && currentModel.locate("metal_box") != uint(-1)) entsToDelete.insertLast(searchEnt);
                    else if (entity_name.locate("reflection_cube") != uint(-1) && currentModel.locate("reflection_cube") != uint(-1)) entsToDelete.insertLast(searchEnt);
                    else if (entity_name.locate("mp_ball") != uint(-1) && currentModel.locate("mp_ball") != uint(-1)) entsToDelete.insertLast(searchEnt);
                    else if (entity_name.locate("underground_weighted_cube") != uint(-1) && currentModel.locate("underground_weighted_cube") != uint(-1)) entsToDelete.insertLast(searchEnt);
                }
            }
        }
    }

    // --- 3. TRAITEMENT ET SUPPRESSION ---
    if (entsToDelete.length() == 0) {
        Archipelago::ArchipelagoLog("[AP] DeleteEntity: No targets found for " + entity_name);
        return;
    }

    for (uint i = 0; i < entsToDelete.length(); i++) {
        CBaseEntity@ ent = @entsToDelete[i];
        if (ent is null) continue;

        if (entity_name == "trigger_catapult") {
            Archipelago::MakeFaithPlateFaulty(ent);
            continue;
        }

        if (create_holo) {
            string originalName = ent.GetEntityName();
            string holoName;
            Vector spawnPos = ent.GetAbsOrigin();

            if (originalName != "") {
                holoName = originalName + "_" + int(spawnPos.x) + "_" + int(spawnPos.y) + "_" + int(spawnPos.z) + "_holo";
            } else {
                string shortModelName = ent.GetModelName();
                int lastSlash = -1;
                int len = shortModelName.length();
                for (int c = len - 1; c >= 0; c--) {
                    if (shortModelName[c] == 47) { 
                        lastSlash = c;
                        break;
                    }
                }
                if (lastSlash != -1) {
                    shortModelName = shortModelName.substr(lastSlash + 1);
                }

                holoName = shortModelName + "_" + int(spawnPos.x) + "_" + int(spawnPos.y) + "_" + int(spawnPos.z) + "_holo";
            }

            Vector hPos(0, 0, 0);
            QAngle hAng(0, 0, 0);
            int hSkin = 4;
            float hScale = 1.0f;
            bool hParent = false;
            bool hAbs = false;

            Archipelago::GetHologramVisualOverrides(ent, hPos, hAng, hSkin, hScale, hParent, hAbs);
            if (hScale <= 0.001f) hScale = 1.0f;

            QAngle angles = ent.GetAbsAngles();
            Vector forward, right, up;
            AngleVectors(angles, forward, right, up);
            Vector finalPos = spawnPos + (forward * hPos.x) + (right * hPos.y) + (up * hPos.z);
            QAngle finalAng = hAbs ? hAng : (angles + hAng);

            Archipelago::ArchipelagoLog("[AP] Spawning Holo: " + holoName + " | Skin: " + hSkin + " | Scale: " + hScale);
            Archipelago::CreateAPHologram(finalPos, finalAng, hScale, null, "", hSkin, holoName);
        }
        
        ent.Remove();
    }
}

} // namespace Archipelago