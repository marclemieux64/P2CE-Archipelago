// =============================================================
// ARCHIPELAGO ENTITY MANAGER (OOP VERSION)
// =============================================================

namespace Archipelago {

class EntityManager {

    EntityManager() {
        // Constructor
    }

    void Initialize() {
        // Initialization hook
    }

    // =============================================================
    // CORE ENTITY MANIPULATION
    // =============================================================

    void DeleteCoreOnOutput(string core_name, string target_name, string output) {
        array<CBaseEntity@> targets = FindEntities(target_name);

        if (targets.length() == 0) {
            ArchipelagoLog("Error: DeleteCoreOnOutput target '" + target_name + "' not found");
            return;
        }

        Variant v;
        // FIX DEFINTIF : Utilisation de guillemets simples (') pour emballer l'argument du modèle.
        // Cela empêche le parseur AddOutput (C++) de Valve de tronquer prématurément la chaîne globale.
        v.SetString(output + " InitCmd:Command:DeleteEntity '" + core_name + "' 1 0.7:5.0:-1");

        for (uint i = 0; i < targets.length(); i++) {
            if (targets[i] is null) continue;
            targets[i].FireInput("AddOutput", v, 0.0f, null, null, 0);
        }
        ArchipelagoLog("Hooked output '" + output + "' on '" + targets.length() + "' entities matched by '" + target_name + "' to delete '" + core_name + "' in 5s");
    }

    void DeleteEntity(string entity_name, bool create_holo = true) {
        string mapName = g_Archipelago.GetCurrentMap();
        
        // 1. Blindage et Nettoyage de la chaîne corrompue
        string cleanName = entity_name.trim();
        
        // Extraction propre si la chaîne a été polluée par des résidus d'outputs
        uint mdlLoc = cleanName.tolower().locate(".mdl");
        if (mdlLoc != uint(-1)) {
            cleanName = cleanName.substr(0, mdlLoc + 4);
        } else {
            uint spaceLoc = cleanName.locate(" ");
            if (spaceLoc != uint(-1)) {
                cleanName = cleanName.substr(0, spaceLoc);
            }
        }

        // Nettoyage agressif de tous les types de guillemets résiduels (ASCII 34 = " et ASCII 39 = ')
        while (cleanName.length() > 0 && (cleanName[0] == 34 || cleanName[0] == 39)) {
            cleanName = cleanName.substr(1);
        }
        while (cleanName.length() > 0 && (cleanName[cleanName.length() - 1] == 34 || cleanName[cleanName.length() - 1] == 39)) {
            cleanName = cleanName.substr(0, cleanName.length() - 1);
        }
        if (cleanName.length() > 0 && cleanName[0] == 64) { // ASCII 64 = '@'
            cleanName = cleanName.substr(1);
        }
        
        if (cleanName.length() == 0) {
            ArchipelagoLog("DeleteEntity: Cleaned name is empty, ignoring deletion.");
            return;
        }

        // Conveyor turret active states
        if (mapName == "sp_a2_bts4") {
            if (cleanName == "npc_portal_turret_floor" || cleanName == "initial_template_turret") {
                g_Archipelago.GetHologramManager().SetInitialTemplateHoloActive(false);
                cv_BTS4InitialHoloActive.SetValue(0);
            }
            if (cleanName == "npc_portal_turret_floor" || cleanName == "turret_conveyor_1_template") {
                g_Archipelago.GetHologramManager().SetConveyor1TemplateHoloActive(false);
                cv_BTS4Conveyor1HoloActive.SetValue(0);
            }
        }

        if (cleanName == "potatos_prop" || cleanName == "potatos" || cleanName == "models/props/potatos.mdl") {
            create_holo = false;
        }

        if (cleanName == "trigger_catapult" && scripted_fling_levels.find(mapName) != -1) {
            ArchipelagoLog("Not removing trigger_catapult because this is a fling map.");
            return;
        }

        // 2. Finding matching entities
        array<CBaseEntity@> entsToDelete;
        CBaseEntity@ searchEnt = null;
        
        if (cleanName.locate(".mdl") != uint(-1)) {
            while ((@searchEnt = EntityList().FindByModel(searchEnt, cleanName)) !is null) {
                entsToDelete.insertLast(searchEnt);
            }
            
            if (entsToDelete.length() == 0) {
                @searchEnt = null;
                while ((@searchEnt = EntityList().FindByModel(searchEnt, cleanName.tolower())) !is null) {
                    entsToDelete.insertLast(searchEnt);
                }
            }
        } 
        else {
            array<string> searchNames = { 
                cleanName, 
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
                    if (!alreadyIn && searchEnt.GetModelName().tolower().locate("archipelago_hologram") == uint(-1))
                        entsToDelete.insertLast(searchEnt);
                }
            }

            if (entsToDelete.length() == 0) {
                @searchEnt = null;
                while ((@searchEnt = EntityList().FindByClassname(searchEnt, cleanName)) !is null) {
                    entsToDelete.insertLast(searchEnt);
                }
            }
            
            if (entsToDelete.length() == 0 && (cleanName.locate("cube") != uint(-1) || cleanName.locate("box") != uint(-1))) {
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
                        if (cleanName.locate("metal_box") != uint(-1) && currentModel.locate("metal_box") != uint(-1)) entsToDelete.insertLast(searchEnt);
                        else if (cleanName.locate("reflection_cube") != uint(-1) && currentModel.locate("reflection_cube") != uint(-1)) entsToDelete.insertLast(searchEnt);
                        else if (cleanName.locate("mp_ball") != uint(-1) && currentModel.locate("mp_ball") != uint(-1)) entsToDelete.insertLast(searchEnt);
                        else if (cleanName.locate("underground_weighted_cube") != uint(-1) && currentModel.locate("underground_weighted_cube") != uint(-1)) entsToDelete.insertLast(searchEnt);
                    }
                }
            }
        }

        // 3. Deleting and Spawning Holograms
        if (entsToDelete.length() == 0) {
            ArchipelagoLog("DeleteEntity: No targets found for " + cleanName);
            return;
        }

        for (uint i = 0; i < entsToDelete.length(); i++) {
            CBaseEntity@ ent = entsToDelete[i];
            if (ent is null) continue;

            if (cleanName == "trigger_catapult") {
                MakeFaithPlateFaulty(ent);
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

                // Prevent duplicates
                CBaseEntity@ existingHolo = null;
                bool alreadyProcessed = false;
                
                while ((@existingHolo = EntityList().FindByName(existingHolo, holoName)) !is null) {
                    alreadyProcessed = true;
                    break;
                }

                if (alreadyProcessed) {
                    ArchipelagoLog("Deletion skipped: Hologram already created for " + holoName);
                    ent.KeyValue("rendermode", "10");
                    Variant killValue;
                    ent.FireInput("Kill", killValue, 0.05f, null, null, 0);
                    continue;
                }

                Vector hPos(0, 0, 0);
                QAngle hAng(0, 0, 0);
                int hSkin = 4;
                float hScale = 1.0f;
                bool hParent = false;
                bool hAbs = false;
                
                g_Archipelago.GetHologramManager().GetHologramVisualOverrides(ent, hPos, hAng, hSkin, hScale, hParent, hAbs);
                if (hScale <= 0.001f) hScale = 1.0f;

                QAngle angles = ent.GetAbsAngles();
                Vector forward, right, up;
                AngleVectors(angles, forward, right, up);
                
                Vector finalPos = spawnPos + (forward * hPos.x) + (right * -hPos.y) + (up * hPos.z);
                QAngle finalAng = angles + hAng;

                // Manual override for lasers/receivers
                string classname = ent.GetClassname().tolower();
                if (classname.locate("env_portal_laser") != uint(-1) || 
                    classname.locate("prop_laser_relay") != uint(-1) || 
                    classname.locate("prop_laser_catcher") != uint(-1)) {
                    
                    hScale = 0.66f;
                    hSkin = 4;

                    if (classname.locate("prop_laser_relay") != uint(-1)) {
                        finalPos = spawnPos + (up * 32.0f);
                    } else {
                        finalPos = spawnPos + (forward * 32.0f);
                    }

                    if (classname.locate("prop_laser_relay") != uint(-1)) {
                        finalAng = angles;
                    } else {
                        VectorAngles(up, forward, finalAng);
                    }
                }

                CBaseEntity@ targetParent = null;
                string targetInstanceKeyword = "";

                string currentClass = ent.GetClassname();
                string currentModel = ent.GetModelName().tolower();
                string currentNameLower = originalName.tolower();

                // Specific map instances overrides
                if (mapName == "sp_a2_laser_intro") {
                    if (currentClass.locate("catcher") != uint(-1) || currentModel.locate("catcher") != uint(-1)) {
                        targetInstanceKeyword = "laser_catcher_door";
                    } else if (currentClass.locate("laser") != uint(-1) || currentModel.locate("emitter") != uint(-1)) {
                        targetInstanceKeyword = "laser_emitter_door";
                    }
                }
                else if (mapName == "sp_a4_tb_wall_button") {
                    if (currentNameLower.locate("dropper") != uint(-1) || currentModel.locate("dropper") != uint(-1)) {
                        targetInstanceKeyword = "dropper_prop";
                    }
                }

                if (targetInstanceKeyword != "") {
                    CBaseEntity@ loopEnt = null;
                    while ((@loopEnt = EntityList().FindByClassname(loopEnt, "prop_dynamic")) !is null) {
                        string entName = loopEnt.GetEntityName().tolower();
                        if (entName.locate(targetInstanceKeyword) != uint(-1)) {
                            @targetParent = loopEnt;
                            break;
                        }
                    }
                    if (targetParent is null) {
                        @loopEnt = EntityList().First();
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
                }

                ArchipelagoLog("Spawning Hologram: " + holoName + " | Skin: " + hSkin + " | Scale: " + hScale);
                CBaseEntity@ holoEnt = CreateAPHologram(finalPos, finalAng, hScale, null, "", hSkin, holoName);

                if (targetParent !is null && holoEnt !is null) {
                    Variant v;
                    v.SetEntity(targetParent);
                    holoEnt.FireInput("SetParent", v, 0.01f, targetParent, holoEnt);
                    
                    Variant vOpt;
                    vOpt.SetString("panel_attach");
                    holoEnt.FireInput("SetParentAttachmentMaintainOffset", vOpt, 0.02f, targetParent, holoEnt);
                }
            }
            
            // PROTECTION RENDU DXVK
            ent.KeyValue("rendermode", "10");
            Variant killValue;
            ent.FireInput("Kill", killValue, 0.10f, null, null, 0);
        }
    }

    void DisableEntityPhysics(string entity_name) {
        array<CBaseEntity@> targets = FindEntities(entity_name);
        for (uint i = 0; i < targets.length(); i++) {
            if (targets[i] is null) continue; // Safety check
            targets[i].KeyValue("movetype", "4"); // Set move type to static physics
        }
    }

    void DisableEntityPickup(string target) {
        string mapName = g_Archipelago.GetCurrentMap();
        if (mapName == "sp_a2_bts4") {
            if (target == "npc_portal_turret_floor" || target == "initial_template_turret") {
                g_Archipelago.GetHologramManager().SetInitialTemplateHoloActive(true);
                cv_BTS4InitialHoloActive.SetValue(1);
            }
            if (target == "npc_portal_turret_floor" || target == "turret_conveyor_1_template") {
                g_Archipelago.GetHologramManager().SetConveyor1TemplateHoloActive(true);
                cv_BTS4Conveyor1HoloActive.SetValue(1);
            }
        }

        array<CBaseEntity@> targets = FindEntities(target);
        for (uint i = 0; i < targets.length(); i++) {
            CBaseEntity@ t = targets[i];
            if (t is null) continue;
            t.KeyValue("PickupEnabled", "0");
        }
    }

    void MakeFaithPlateFaulty(CBaseEntity@ trigger) {
        if (trigger is null) return;
        if (trigger.GetClassname() != "trigger_catapult") return;

        string current_map = g_Archipelago.GetCurrentMap();
        
        for (uint f = 0; f < scripted_fling_levels.length(); f++) {
            if (scripted_fling_levels[f] == current_map) {
                ArchipelagoLog("Fling Map detected: Protection active for " + current_map);
                return; 
            }
        }

        bool foundPlate = false;
        CBaseEntity@ targetPlate = null;
        string targetPlateName = "";
        
        CBaseEntity@ p = null;
        while ((@p = EntityList().FindInSphere(p, trigger.GetAbsOrigin(), 256.0f)) !is null) {
            string pModel = p.GetModelName().tolower();
            if (pModel.locate("faith_plate") != uint(-1) || pModel.locate("launch_arm") != uint(-1)) {
                targetPlateName = p.GetEntityName();
                if (targetPlateName == "") {
                    targetPlateName = "ap_faith_plate_" + trigger.GetEntityIndex();
                    p.KeyValue("targetname", targetPlateName);
                }

                p.KeyValue("solid", "2");
                p.SetSolid(SOLID_BBOX);
                p.SetMoveType(MOVETYPE_PUSH);
                p.FireInput("EnableCollision", Variant(), 0.0f, null, null, 0);

                @targetPlate = p;
                foundPlate = true;
                break;
            }
        }

        if (!foundPlate) {
            ArchipelagoLog("No physical plate found for trigger " + trigger.GetEntityIndex() + ". Skipping.");
            return; 
        }

        string sndUid = "ap_cat_snd_" + targetPlateName;
        CBaseEntity@ snd = util::CreateEntityByName("ambient_generic");
        if (snd !is null) {
            snd.KeyValue("targetname", sndUid);
            snd.KeyValue("message", "World.RobotNegInteractPitchedUp");
            snd.KeyValue("health", "10");
            snd.KeyValue("spawnflags", "48");
            snd.SetAbsOrigin(targetPlate.GetAbsOrigin());
            snd.Spawn();
        }

        string hintUid = "ap_hint_" + targetPlateName;
        CBaseEntity@ hint = util::CreateEntityByName("env_instructor_hint");
        if (hint !is null) {
            hint.KeyValue("targetname", hintUid);
            hint.KeyValue("hint_static", "1");
            hint.KeyValue("hint_caption", "#AP_Item_AerialFaithPlate_Hint");
            hint.KeyValue("hint_icon_onscreen", "icon_alert");
            hint.KeyValue("hint_color", "255 50 50");
            hint.KeyValue("hint_allow_nodraw_target", "1");
            hint.SetAbsOrigin(targetPlate.GetAbsOrigin());
            hint.Spawn();
        }

        CBaseEntity@ proxy = util::CreateEntityByName("trigger_multiple");
        if (proxy !is null) {
            proxy.KeyValue("targetname", "ap_prox_" + trigger.GetEntityIndex());
            proxy.KeyValue("spawnflags", "1");
            proxy.KeyValue("wait", "2");
            proxy.SetAbsOrigin(trigger.GetAbsOrigin());
            proxy.SetModel(trigger.GetModelName());
            proxy.Spawn();

            g_Archipelago.SafeAddOutput(proxy, "OnTrigger", hintUid, "ShowHint", "", 0.0f, -1);
            g_Archipelago.SafeAddOutput(proxy, "OnTrigger", sndUid, "PlaySound", "", 0.0f, -1);
            g_Archipelago.SafeAddOutput(proxy, "OnTrigger", targetPlateName, "Skin", "1", 0.0f, -1);
            g_Archipelago.SafeAddOutput(proxy, "OnTrigger", targetPlateName, "Skin", "0", 0.5f, -1);
        }

        Vector hPos(0, 0, 0);
        QAngle hAng(0, 0, 0);
        int hSkin = 4;
        float hScale = 0.66f;
        bool hParent = true;
        bool hAbs = false;

        g_Archipelago.GetHologramManager().GetHologramVisualOverrides(targetPlate, hPos, hAng, hSkin, hScale, hParent, hAbs);
        
        Vector forward, right, up;
        AngleVectors(targetPlate.GetAbsAngles(), forward, right, up);
        Vector finalPos = targetPlate.GetAbsOrigin() + (forward * hPos.x) + (right * hPos.y) + (up * hPos.z);
        QAngle finalAng = hAbs ? hAng : (targetPlate.GetAbsAngles() + hAng);

        Vector spawnPos = targetPlate.GetAbsOrigin();
        string holoName = targetPlateName + "_" + int(spawnPos.x) + "_" + int(spawnPos.y) + "_" + int(spawnPos.z) + "_holo";

        CBaseEntity@ finalParent = targetPlate;
        bool useAttachment = true;

        if (current_map == "sp_a2_ricochet" && targetPlate.GetModelName().tolower().locate("faith_plate_128") != uint(-1)) {
            CBaseEntity@ clipSearch = null;
            while ((@clipSearch = EntityList().FindInSphere(clipSearch, targetPlate.GetAbsOrigin(), 64.0f)) !is null) {
                if (clipSearch.GetClassname() == "func_clip_vphysics") {
                    @finalParent = clipSearch;
                    useAttachment = false; 
                    break;
                }
            }
        }

        CBaseEntity@ holoEnt = CreateAPHologram(finalPos, finalAng, hScale, null, "", hSkin, holoName);

        if (holoEnt !is null && finalParent !is null) {
            Variant v;
            v.SetEntity(finalParent);
            holoEnt.FireInput("SetParent", v, 0.01f, finalParent, holoEnt);
            
            if (useAttachment) {
                Variant vOpt;
                vOpt.SetString("panel_attach");
                holoEnt.FireInput("SetParentAttachmentMaintainOffset", vOpt, 0.02f, finalParent, holoEnt);
            }
        }

        trigger.KeyValue("rendermode", "10");
        Variant killValue;
        trigger.FireInput("Kill", killValue, 0.05f, null, null, 0);
        ArchipelagoLog("Faith Plate sabotaged: " + holoName);
    }

    void PreventPickupForModel(string model_keyword) {
        CBaseEntity@ prop = null;
        while ((@prop = EntityList().FindByClassname(prop, "prop_physics")) !is null) {
            if (prop.GetModelName().tolower().locate(model_keyword) != uint(-1)) {
                prop.SetMoveType(MOVETYPE_NONE);
            }
        }

        CBaseEntity@ override_prop = null;
        while ((@override_prop = EntityList().FindByClassname(override_prop, "prop_physics_override")) !is null) {
            if (override_prop.GetModelName().tolower().locate(model_keyword) != uint(-1)) {
                override_prop.SetMoveType(MOVETYPE_NONE);
            }
        }
    }

    // =============================================================
    // COMPONENT ATTACHMENTS (BUTTONS AND BEAMS)
    // =============================================================

    void AddTractorBeamFrame(string entity_name) {
        array<CBaseEntity@> targets = FindEntities(entity_name);
        for (uint i = 0; i < targets.length(); i++) {
            CBaseEntity@ ent = targets[i];
            if (ent is null) continue;

            Vector position = ent.GetAbsOrigin();
            QAngle angles = ent.GetAbsAngles();
            string originalModel = ent.GetModelName(); 
        
            Vector forward, right, up;
            AngleVectors(angles, forward, right, up);
    
            CBaseEntity@ box = util::CreateEntityByName("prop_dynamic");
            if (box !is null) {
                box.KeyValue("targetname", entity_name + "_frame");
                box.KeyValue("model", "models/props/archipelago/ap_proptractorbeamframe.mdl");
                box.KeyValue("solid", "6");
            
                float forwardOffset = 3.0f;
                float rightOffset = 0.0f;
                float upOffset = 0.0f;

                if (g_Archipelago.GetCurrentMap() == "sp_a4_finale2" && ent.GetEntityName() != "crusher_ride_tbeam") {
                    forwardOffset = -30.0f; 
                    rightOffset = 0.0f; 
                    upOffset = 0.0f; 
                }

                Vector frameOffsetPos = position + (forward * forwardOffset) + (right * rightOffset) + (up * upOffset);
                box.SetAbsOrigin(frameOffsetPos);
            
                QAngle angleOffset(90.0f, 0.0f, 0.0f);
                QAngle finalFrameAngles = angles + angleOffset;
                box.SetAbsAngles(finalFrameAngles);
                box.Spawn();
            }
    
            string holoName = entity_name + "_" + ent.GetEntityIndex() + "_holo";
            if (EntityList().FindByName(null, holoName) is null) {
                Vector hPos(0, 0, 0);
                QAngle hAng(0, 0, 0);
                int hSkin = 0;
                float hScale = 1.0f;
                bool hParent = false; 
                bool hAbs = false;
            
                g_Archipelago.GetHologramManager().GetHologramVisualOverrides(ent, hPos, hAng, hSkin, hScale, hParent, hAbs);
            
                if (g_Archipelago.GetCurrentMap() == "sp_a4_finale2" && ent.GetEntityName() != "crusher_ride_tbeam") {
                    hPos = Vector(47.0f, 0.0f, 0.0f);
                }

                Vector finalPos = position + (forward * hPos.x) + (right * hPos.y) + (up * hPos.z);
                QAngle finalAng = hAbs ? hAng : (angles + hAng);

                CreateAPHologram(finalPos, finalAng, hScale, null, "", hSkin, holoName);
            }

            CBaseEntity@ dummy = util::CreateEntityByName("prop_dynamic");
            if (dummy !is null) {
                dummy.KeyValue("model", originalModel);
                dummy.KeyValue("solid", "6"); 
                dummy.SetAbsOrigin(position);
                dummy.SetAbsAngles(angles);
                dummy.Spawn();
            }

            ent.KeyValue("rendermode", "10");
            Variant killValue;
            ent.FireInput("Kill", killValue, 0.05f, null, null, 0);
        }
    }

    void AddButtonFrame(string entity_name) {
        string mapName = g_Archipelago.GetCurrentMap();
        array<CBaseEntity@> targets = FindEntities(entity_name);
        
        CBaseEntity@ targetParent = null;
        bool useAutoParent = (mapName == "sp_a2_sphere_peek");

        for (uint i = 0; i < targets.length(); i++) {
            CBaseEntity@ ent = targets[i];
            if (ent is null) continue;

            if (useAutoParent) {
                @targetParent = ent.GetMoveParent();
            }
            else if (mapName == "sp_a4_tb_wall_button") {
                CBaseEntity@ loopEnt = null;
                while ((@loopEnt = EntityList().FindByClassname(loopEnt, "prop_dynamic")) !is null) {
                    string entName = loopEnt.GetEntityName().tolower();
                    if (entName.locate("dropper_prop") != uint(-1)) {
                        @targetParent = loopEnt;
                        break;
                    }
                }
                if (targetParent is null) {
                    @loopEnt = EntityList().First();
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
            }

            Vector position = ent.GetAbsOrigin();
            QAngle angles = ent.GetAbsAngles();
            string originalModel = ent.GetModelName();
        
            if (mapName == "sp_a2_sphere_peek") {
                position.z += 4.0f; 
            }

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
        
            string holoName = entity_name + "_" + ent.GetEntityIndex() + "_holo";
            if (EntityList().FindByName(null, holoName) is null) {
                Vector hPos(0, 0, 0);
                QAngle hAng(0, 0, 0);
                int hSkin = 4;
                float hScale = 0.66f;
                bool hParent = true;
                bool hAbs = false;
                g_Archipelago.GetHologramManager().GetHologramVisualOverrides(ent, hPos, hAng, hSkin, hScale, hParent, hAbs);

                if (mapName == "sp_a2_sphere_peek") {
                    hPos.z += 4.0f; 
                }

                if (mapName == "sp_a3_bomb_flings") {
                    hParent = false;                  
                    hPos = Vector(0.0f, 0.0f, 70.0f); 
                    hAng = angles;                    
                    hScale = 0.66f;                 
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

                if (mapName == "sp_a3_bomb_flings") {
                    finalAng = hAng;
                }

                CreateAPHologram(finalPos, finalAng, hScale, finalParent, "", hSkin, holoName);
            }

            ent.KeyValue("rendermode", "10");
            Variant killValue;
            ent.FireInput("Kill", killValue, 0.05f, null, null, 0);
        }
    }

    void AddFloorButtonFrame(string entity_name) {
        array<CBaseEntity@> targets = FindEntities(entity_name);
        for (uint i = 0; i < targets.length(); i++) {
            CBaseEntity@ ent = targets[i];
            if (ent is null) continue;

            Vector position = ent.GetAbsOrigin();
            QAngle angles = ent.GetAbsAngles();
            string originalModel = ent.GetModelName();

            CBaseEntity@ box = util::CreateEntityByName("prop_dynamic");
            if (box !is null) {
                box.KeyValue("targetname", entity_name + "_frame");
                box.KeyValue("model", "models/props/archipelago/ap_floorbuttonframe.mdl");
                box.KeyValue("solid", "6");
                box.SetAbsOrigin(position);
                box.SetAbsAngles(angles);
                box.Spawn();
            }

            CBaseEntity@ dummy = util::CreateEntityByName("prop_dynamic");
            if (dummy !is null) {
                dummy.KeyValue("model", originalModel);
                dummy.KeyValue("solid", "6"); 
                dummy.SetAbsOrigin(position);
                dummy.SetAbsAngles(angles);
                dummy.Spawn();
            }

            string holoName = entity_name + "_" + ent.GetEntityIndex() + "_holo";
            if (EntityList().FindByName(null, holoName) is null) {
                Vector hPos(0, 0, 0);
                QAngle hAng(0, 0, 0);
                int hSkin = 4;
                float hScale = 1.0f;
                bool hParent = true;
                bool hAbs = false;
                g_Archipelago.GetHologramManager().GetHologramVisualOverrides(ent, hPos, hAng, hSkin, hScale, hParent, hAbs);
                
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

                CreateAPHologram(finalPos, finalAng, hScale, finalParent, "", hSkin, holoName);
            }

            ent.KeyValue("rendermode", "10");
            Variant killValue;
            ent.FireInput("Kill", killValue, 0.05f, null, null, 0);
        }
    }

    // =============================================================
    // GEL AND PAINTS MANAGEMENT
    // =============================================================

    void CreateClearGel(Vector position, float offset = -100.0f) {
        CBaseEntity@ gel = util::CreateEntityByName("prop_paint_bomb");
        if (gel !is null) {
            position.z += offset;
            gel.SetAbsOrigin(position);
            gel.KeyValue("paint_type", 3); 
            gel.Spawn();
        }
    }

    void RemoveGel(Vector position, string filter = "", string object_name = "") {
        CBaseEntity@ ent = null;
        float bestScore = 999999.0f;

        CBaseEntity@ searchEnt = EntityList().First();
        while (searchEnt !is null) {
            string name = searchEnt.GetEntityName();
            string cls = searchEnt.GetClassname();

            if (name.locate("_holo") == uint(-1) && cls != "player") {
                bool classMatch = (filter == "" || filter == "null" || cls.locate(filter) != uint(-1));
                
                if (classMatch) {
                    bool nameMatch = (object_name == "" || object_name == "null" || name == object_name || name.locate(object_name) != uint(-1));
                    float dist = (searchEnt.GetAbsOrigin() - position).Length();

                    if (nameMatch || dist <= 15.0f) {
                        float score;
                        if (nameMatch && dist <= 15.0f) {
                            score = dist; 
                        } else if (nameMatch && dist > 15.0f) {
                            score = 1000.0f + dist; 
                        } else {
                            score = 5000.0f + dist; 
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

        string safeName = (object_name != "" && object_name != "null") ? object_name : filter;
        if (safeName == "") safeName = "unknown_gel";
        string holoName = safeName + "_" + int(position.x) + "_" + int(position.y) + "_" + int(position.z) + "_holo";

        if (ent !is null) {
            string cls = ent.GetClassname();
            string originalName = ent.GetEntityName();

            ent.KeyValue("targetname", holoName); 

            Vector hPos(0, 0, 0);
            QAngle hAng(0, 0, 0);
            int hSkin = 4;
            float hScale = 1.0f;
            bool hParent = false;
            bool hAbs = false;
            g_Archipelago.GetHologramManager().GetHologramVisualOverrides(ent, hPos, hAng, hSkin, hScale, hParent, hAbs);

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
                finalPos = basePos + (AnglesToForward(spawnAng) * hPos.x) + (AnglesToRight(spawnAng) * -hPos.y) + (AnglesToUp(spawnAng) * hPos.z);
                finalAng = spawnAng + hAng;
            }

            CreateAPHologram(finalPos, finalAng, hScale, null, "", hSkin, holoName);
            
            ent.KeyValue("rendermode", "10");
            Variant killValue;
            ent.FireInput("Kill", killValue, 0.05f, null, null, 0);
        }
    }

    void LockButtonByName(string entity_name) {
        CBaseEntity@ pEntity = null;
        while ((@pEntity = EntityList().FindByName(pEntity, entity_name)) !is null) {
            Variant emptyValue;
            pEntity.FireInput("Lock", emptyValue, 0.0f, null, null, 0);
            pEntity.KeyValue("m_bLocked", 1);
            
            ArchipelagoLog("Locked button by name: " + entity_name);

            string holoName = entity_name + "_holo";
            Vector localPos(0, 0, 25); 
            QAngle localAng(0, 0, 0); 
            float holoScale = 0.66f;

            CreateAPHologram(localPos, localAng, holoScale, pEntity, "", 4, holoName, true);

            string hintCaption = "";
            if (entity_name == "pump_machine_white_button") {
                hintCaption = "#Archipelago_Hint_NoWhiteGel";
            } else if (entity_name == "pump_machine_blue_button") {
                hintCaption = "#Archipelago_Hint_NoBlueGel";
            } else if (entity_name == "pump_machine_orange_button") {
                hintCaption = "#Archipelago_Hint_NoOrangeGel";
            }

            string hintName = "hudhint_" + entity_name;

            CBaseEntity@ hint = util::CreateEntityByName("env_instructor_hint");
            if (hint !is null) {
                hint.KeyValue("targetname", hintName);
                hint.KeyValue("hint_target", entity_name);
                hint.KeyValue("hint_static", "0"); 
                hint.KeyValue("hint_caption", hintCaption); 
                hint.KeyValue("hint_icon_onscreen", "icon_alert");
                hint.KeyValue("hint_color", "255 50 50"); 
                hint.KeyValue("hint_forcecaption", "1"); 
                hint.Spawn();
            }

            g_Archipelago.SafeAddOutput(pEntity, "OnUseLocked", hintName, "ShowHint", "", 0.0f, -1);
        }
    }

    // =============================================================
    // PORTAL GUN AND POTATOS STATUS MODIFICATIONS
    // =============================================================

    void DisablePortalGun(bool blue, bool orange) {
        CBaseEntity@ gun = EntityList().FindByClassname(null, "weapon_portalgun");
        
        if (g_Archipelago.GetCurrentMap() == "sp_a3_01") {
            if (gun !is null) {
                Variant vDelay;
                vDelay.SetString("CanFirePortal2 0");
                gun.FireInput("AddOutput", vDelay, 13.0f, null, null, 0); 
            }
        }

        if (g_Archipelago.GetCurrentMap() == "sp_a2_intro") {
            g_Archipelago.SetPortalGun2Disabled(true);
        }

        if (gun !is null) {
            if (blue) {
                Variant vB; 
                vB.SetString("CanFirePortal1 0");
                gun.FireInput("AddOutput", vB, 0.0f, null, null, 0);
            }
            if (orange) {
                Variant vO; 
                vO.SetString("CanFirePortal2 0");
                gun.FireInput("AddOutput", vO, 0.0f, null, null, 0);
            }
        }
    }

    void IncineratorDisablePortalGun() {
        CBaseEntity@ trigger = EntityList().FindByName(null, "player_near_portalgun");
        if (trigger !is null) {
            Variant v;
            string orangeVal = g_Archipelago.IsPortalGun2Disabled() ? "1" : "0";
            
            string outputStr = "OnStartTouch InitCmd:Command:DisablePortalGun 0 " + orangeVal + ":0.25:-1";
            v.SetString(outputStr);
            trigger.FireInput("AddOutput", v, 0.0f, null, null, 0);
        }
    }

    void RemovePotatOS() {
        ArchipelagoLog("RemovePotatOS: Disabling elevator, removing PotatOS Prop.");
        
        CBaseEntity@ button = EntityList().FindByName(null, "sphere_entrance_potatos_button");
        if (button !is null) {
            Vector place = button.GetAbsOrigin();
            
            CBaseEntity@ instructorTarget = util::CreateEntityByName("info_target_instructor_hint");
            if (instructorTarget !is null) {
                instructorTarget.KeyValue("targetname", "hint_target_no_potatos");
                instructorTarget.SetAbsOrigin(place);
                instructorTarget.Spawn();
            }
        
            DeleteEntity("sphere_entrance_lift_relay", false);
            string[] potatosEntities = { "potatos_prop", "potatos", "models/props/potatos.mdl" };
            
            for (uint i = 0; i < potatosEntities.length(); i++) {
                string nameOrModel = potatosEntities[i];
                array<CBaseEntity@> targets;
                CBaseEntity@ ent = null;
                
                if (nameOrModel.locate(".mdl") != uint(-1)) {
                    while ((@ent = EntityList().FindByModel(ent, nameOrModel)) !is null) {
                        targets.insertLast(ent);
                    }
                } else {
                    while ((@ent = EntityList().FindByName(ent, nameOrModel)) !is null) {
                        targets.insertLast(ent);
                    }
                }
                
                for (uint j = 0; j < targets.length(); j++) {
                    CBaseEntity@ target = targets[j];
                    if (target !is null) {
                        target.KeyValue("rendermode", "10");
                        
                        string holoName = target.GetEntityName();
                        if (holoName == "") {
                            holoName = "potatos_holo_" + i + "_" + j; 
                        } else {
                            holoName = holoName + "_holo";
                        }
                        
                        CreateAPHologram(Vector(0, 0, 0), QAngle(0, 0, 0), 0.3f, target, "", 4, holoName, false);
                    }
                }
            }
        }

        CBaseEntity@ hint = util::CreateEntityByName("env_instructor_hint");
        if (hint !is null) {
            hint.KeyValue("targetname", "hudhint_no_potatos");
            hint.KeyValue("hint_target", "hint_target_no_potatos");
            hint.KeyValue("hint_static", "0");
            hint.KeyValue("hint_caption", "PotatOS not unlocked");
            hint.KeyValue("hint_icon_onscreen", "icon_alert");
            hint.KeyValue("hint_color", "255 50 50");
            hint.Spawn();
        }

        g_Archipelago.SafeAddOutput(EntityList().FindByName(null, "sphere_entrance_potatos_button"), "OnPressed", "hudhint_no_potatos", "ShowHint", "", 0.0f, -1);
        
        g_Archipelago.CallVScript("MutePotatOSSubtitles(true)");
    }

    void RemovePotatosFromGun() {
        ArchipelagoLog("RemovePotatosFromGun: Executing viewmodel and world cleanup.");
        
        CBaseEntity@ lpp = EntityList().FindByClassname(null, "logic_playerproxy");
        if (lpp is null) {
            @lpp = util::CreateEntityByName("logic_playerproxy");
            if (lpp !is null) { 
                lpp.KeyValue("targetname", "ap_lpp"); 
                lpp.Spawn(); 
            }
        }
        
        if (lpp !is null) {
            lpp.FireInput("RemovePotatosFromPortalgun", Variant(), 0.0f, null, null, 0);
        }

        string[] potatosEntities = { "potatos_prop", "potatos", "models/props/potatos.mdl" };
        for (uint i = 0; i < potatosEntities.length(); i++) {
            string nameOrModel = potatosEntities[i];
            array<CBaseEntity@> targets;
            CBaseEntity@ ent = null;
            
            if (nameOrModel.locate(".mdl") != uint(-1)) {
                while ((@ent = EntityList().FindByModel(ent, nameOrModel)) !is null) {
                    targets.insertLast(ent);
                }
            } else {
                while ((@ent = EntityList().FindByName(ent, nameOrModel)) !is null) {
                    targets.insertLast(ent);
                }
            }
            
            for (uint j = 0; j < targets.length(); j++) {
                CBaseEntity@ target = targets[j];
                if (target !is null) {
                    target.KeyValue("rendermode", "10");
                    
                    string holoName = target.GetEntityName();
                    if (holoName == "") holoName = "potatos_holo_" + i + "_" + j; else holoName = holoName + "_holo";
                    
                    CreateAPHologram(Vector(0, 0, 0), QAngle(0, 0, 0), 0.3f, target, "", 4, holoName, false);
                }
            }
        }
        
        g_Archipelago.CallVScript("MutePotatOSSubtitles(true)");
        ArchipelagoLog("RemovePotatosFromGun execution finished.");
    }
}

} // namespace Archipelago