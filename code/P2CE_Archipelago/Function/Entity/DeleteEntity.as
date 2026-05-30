namespace Archipelago {

void DeleteEntity(const string&in entity_name, bool create_holo = true) {
    string mapName = ConVarRef("host_map").GetString();
    
    // --- 1. NETTOYAGE ET EXCEPTIONS ---
    string cleanName = entity_name;
    if (cleanName.length() > 0 && cleanName[0] == 64) { 
        cleanName = cleanName.substr(1);
    }

    if (mapName == "sp_a2_bts4") {
        if (entity_name == "npc_portal_turret_floor" || entity_name == "initial_template_turret" || cleanName == "initial_template_turret") {
            g_bInitialTemplateHoloActive = false;
            cv_BTS4_InitialTemplateHoloActive.SetValue(0);
        }
        if (entity_name == "npc_portal_turret_floor" || entity_name == "turret_conveyor_1_template" || cleanName == "turret_conveyor_1_template") {
            g_bConveyor1TemplateHoloActive = false;
            cv_BTS4_Conveyor1TemplateHoloActive.SetValue(0);
        }
    }

    if (entity_name == "potatos_prop" || entity_name == "potatos" || entity_name == "models/props/potatos.mdl") {
        create_holo = false;
    }

    if (entity_name == "trigger_catapult" && ItemInList(mapName, scripted_fling_levels)) {
        Archipelago::ArchipelagoLog("not removing trigger_catapult");
        return;
    }

    // --- 2. RECHERCHE ROBUSTE (Nettoyée) ---
    array<CBaseEntity@> entsToDelete;
    CBaseEntity@ searchEnt = null;
    
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
    } else {
        array<string> searchNames = { entity_name, cleanName, "*" + entity_name + "*", "*" + cleanName + "*" };
        for (uint s = 0; s < searchNames.length(); s++) {
            @searchEnt = null;
            while ((@searchEnt = EntityList().FindByName(searchEnt, searchNames[s])) !is null) {
                bool alreadyIn = false;
                for (uint j = 0; j < entsToDelete.length(); j++) {
                    if (entsToDelete.opIndex(j) is searchEnt) { 
                        alreadyIn = true;
                        break;
                    }
                }
                if (!alreadyIn) entsToDelete.insertLast(searchEnt);
            }
        }
        if (entsToDelete.length() == 0) {
            @searchEnt = null;
            while ((@searchEnt = EntityList().FindByClassname(searchEnt, entity_name)) !is null) {
                entsToDelete.insertLast(searchEnt);
            }
        }
    }

    // --- 3. TRAITEMENT ET SUPPRESSION (UTILISATION DE UTIL::REMOVE) ---
    if (entsToDelete.length() == 0) return;

    for (uint i = 0; i < entsToDelete.length(); i++) {
        CBaseEntity@ ent = entsToDelete.opIndex(i); // Utilisation correcte de opIndex
        if (ent is null) continue;

        if (entity_name == "trigger_catapult") {
            Archipelago::MakeFaithPlateFaulty(ent);
            continue;
        }

        if (create_holo) {
            // ... (Ta logique d'hologramme originale est conservée ici) ...
            string originalName = ent.GetEntityName();
            string holoName;
            Vector spawnPos = ent.GetAbsOrigin();
            
            if (originalName != "") holoName = originalName + "_" + int(spawnPos.x) + "_" + int(spawnPos.y) + "_" + int(spawnPos.z) + "_holo";
            else holoName = ent.GetModelName() + "_" + int(spawnPos.x) + "_" + int(spawnPos.y) + "_" + int(spawnPos.z) + "_holo";

            Vector hPos(0, 0, 0);
            QAngle hAng(0, 0, 0);
            int hSkin = 4;
            float hScale = 1.0f;
            bool hParent = false;
            bool hAbs = false;
            
            Archipelago::GetHologramVisualOverrides(ent, hPos, hAng, hSkin, hScale, hParent, hAbs);
            
            // Suppression sécurisée : util::Remove au lieu de ent.Remove()
            util::Remove(ent); 
            
            // Création de l'holo après suppression pour éviter les conflits d'itérateurs
            CBaseEntity@ holoEnt = Archipelago::CreateAPHologram(spawnPos + hPos, hAng, hScale, null, "", hSkin, holoName);
        } else {
            util::Remove(ent); // Suppression sécurisée
        }
    }
}
} // namespace Archipelago