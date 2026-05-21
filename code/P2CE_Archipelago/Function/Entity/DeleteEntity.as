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

    // --- 2. RECHERCHE ROBUSTE ---
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
    } 
    else {
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

        if (entsToDelete.length() == 0) {
            @searchEnt = null;
            while ((@searchEnt = EntityList().FindByClassname(searchEnt, entity_name)) !is null) {
                entsToDelete.insertLast(searchEnt);
            }
        }
        
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

            // --- ANTI-DOUBLON SÉCURITÉ ---
            string coordSuffix = "_" + int(spawnPos.x) + "_" + int(spawnPos.y) + "_" + int(spawnPos.z) + "_holo";
            CBaseEntity@ existingHolo = null;
            bool alreadyProcessed = false;
            
            // Scan de sécurité : existe-t-il déjà un hologramme pour cette entité ?
            while ((@existingHolo = EntityList().FindByName(existingHolo, holoName)) !is null) {
                alreadyProcessed = true;
                break;
            }

            // Scan de sécurité par proximité : existe-t-il déjà un hologramme de rechange à la même position finale ?
            if (!alreadyProcessed) {
                CBaseEntity@ loopEnt = null;
                while ((@loopEnt = EntityList().FindByClassname(loopEnt, "prop_dynamic")) !is null) {
                    string loopModel = loopEnt.GetModelName().tolower();
                    if (loopModel.locate("archipelago_hologram") != uint(-1)) {
                        if (loopEnt.GetAbsOrigin().DistTo(finalPos) < 2.0f) {
                            alreadyProcessed = true;
                            Archipelago::ArchipelagoLog("[AP] Suppression bloquée : Hologramme déjà présent par proximité à " + loopEnt.GetAbsOrigin().x + " " + loopEnt.GetAbsOrigin().y);
                            break;
                        }
                    }
                }
            }

            if (alreadyProcessed) {
                Archipelago::ArchipelagoLog("[AP] Suppression bloquée : Hologramme déjà traité pour " + holoName);
                ent.Remove();
                continue;
            }

            // --- RECHERCHE ET INTERCEPTION STRICTE PAR CARTE ---
            CBaseEntity@ targetParent = null;
            string targetInstanceKeyword = "";

            string currentClass = ent.GetClassname();
            string currentModel = ent.GetModelName().tolower();
            string currentNameLower = originalName.tolower();

            // Exception 1 : Uniquement sur sp_a2_laser_intro (Lasers)
            if (mapName == "sp_a2_laser_intro") {
                if (currentClass.locate("catcher") != uint(-1) || currentModel.locate("catcher") != uint(-1)) {
                    targetInstanceKeyword = "laser_catcher_door";
                } else if (currentClass.locate("laser") != uint(-1) || currentModel.locate("emitter") != uint(-1)) {
                    targetInstanceKeyword = "laser_emitter_door";
                }
            }
            // Exception 2 : Uniquement sur sp_a4_tb_wall_button (Cube Dropper)
            else if (mapName == "sp_a4_tb_wall_button") {
                if (currentNameLower.locate("dropper") != uint(-1) || currentModel.locate("dropper") != uint(-1)) {
                    targetInstanceKeyword = "dropper_prop";
                }
            }

            // Exécution du scan de l'instance si un mot-clé est actif pour la map courante
            if (targetInstanceKeyword != "") {
                CBaseEntity@ loopEnt = EntityList().First();
                CBaseEntity@ backupParent = null;
                
                while (loopEnt !is null) {
                    string entName = loopEnt.GetEntityName().tolower();
                    if (entName.locate(targetInstanceKeyword) != uint(-1)) {
                        if (loopEnt.GetClassname() == "prop_dynamic") {
                            @targetParent = loopEnt;
                            break;
                        }
                        @backupParent = loopEnt;
                    }
                    @loopEnt = EntityList().Next(loopEnt);
                }
                if (targetParent is null) {
                    @targetParent = backupParent;
                }
            }

            Archipelago::ArchipelagoLog("[AP] Spawning Holo: " + holoName + " | Skin: " + hSkin + " | Scale: " + hScale);
            
            CBaseEntity@ holoEnt = Archipelago::CreateAPHologram(finalPos, finalAng, hScale, null, "", hSkin, holoName);

            if (targetParent !is null && holoEnt !is null) {
                Variant v;
                v.SetEntity(targetParent);
                holoEnt.FireInput("SetParent", v, 0.01f, targetParent, holoEnt);
                
                Variant vOpt;
                vOpt.SetString("panel_attach");
                holoEnt.FireInput("SetParentAttachmentMaintainOffset", vOpt, 0.02f, targetParent, holoEnt);
            }
        }
        
        ent.Remove();
    }
}

} // namespace Archipelago