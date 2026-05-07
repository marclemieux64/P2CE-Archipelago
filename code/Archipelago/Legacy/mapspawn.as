// =============================================================
// ARCHIPELAGO LEGACY MAPSPAWN (Converted from Squirrel)
// =============================================================

namespace Legacy {

// Helper: Check if item is in array
    bool ItemInList(string item, array<string> list) {
        for (uint i = 0; i < list.length(); i++) {
            if (list[i] == item) return true;
        }
        return false;
    }

    float DegToRad(float degrees) {
        return degrees * (3.14159f / 180.0f);
    }

    Vector AnglesToForward(QAngle angles) {
        Vector forward;
        AngleVectors(angles, forward);
        return forward;
    }

    Vector AnglesToRight(QAngle angles) {
        Vector forward, right, up;
        AngleVectors(angles, forward, right, up);
        return right;
    }

    Vector AnglesToUp(QAngle angles) {
        Vector forward, right, up;
        AngleVectors(angles, forward, right, up);
        return up;
    }

    array<string> scripted_fling_levels = {"sp_a3_03", "sp_a3_bomb_flings", "sp_a3_transition01", "sp_a3_speed_flings", "sp_a3_end", "sp_a4_jump_polarity" };

void DeleteEntity(const string&in entity_name, bool create_holo = true) {
    string mapName = ConVarRef("host_map").GetString();

    if (entity_name == "trigger_catapult" && ItemInList(mapName, scripted_fling_levels)) {
        Msgl("not removing trigger_catapult");
        return;
    }

    array<CBaseEntity@> entsToDelete;
    CBaseEntity@ searchEnt = null;

    if (entity_name.locate(".mdl") < entity_name.length()) {
        while ((@searchEnt = EntityList().FindByModel(searchEnt, entity_name)) !is null) {
            entsToDelete.insertLast(searchEnt);
        }
    } 
    else {
        // Search by Classname
        while ((@searchEnt = EntityList().FindByClassname(searchEnt, entity_name)) !is null) {
            entsToDelete.insertLast(searchEnt);
        }
        
        // Search by Targetname (Name)
        @searchEnt = null;
        while ((@searchEnt = EntityList().FindByName(searchEnt, entity_name)) !is null) {
            bool alreadyInList = false;
            for (uint i = 0; i < entsToDelete.length(); i++) {
                if (entsToDelete[i] is searchEnt) {
                    alreadyInList = true;
                    break;
                }
            }
            if (!alreadyInList) {
                entsToDelete.insertLast(searchEnt);
            }
        }
    }

    // Apply the logic to all found entities
    for (uint i = 0; i < entsToDelete.length(); i++) {
        
        CBaseEntity@ ent = @entsToDelete[i];

        if (entity_name == "trigger_catapult") {
            Legacy::MakeFaithPlateFaulty(ent);
            continue; 
        }

        if (create_holo) {
            QAngle angles = ent.GetAbsAngles();
            Vector forward;
            AngleVectors(angles, forward);
            
            // Generic offset for other entities (buttons, etc.)
            Vector spawnPos = ent.GetAbsOrigin() + (forward * Vector(-50.0f, -50.0f, -50.0f));
            
            Legacy::CreateAPHologram(spawnPos, angles, 0.7f, null, "", 4);
        }
        
        ent.Remove();
    }
}

void MakeFaithPlateFaulty(CBaseEntity@ trigger) {
    if (trigger is null) return;

    // S'assurer que l'entité est bien une catapulte
    if (trigger.GetClassname() != "trigger_catapult") return;

    // 1. Protection des maps scriptées (Scripted Fling Levels)
    string current_map = ConVarRef("host_map").GetString();
    bool isFlingMap = false;
    
    for (uint f = 0; f < scripted_fling_levels.length(); f++) {
        if (scripted_fling_levels[f] == current_map) { 
            isFlingMap = true; 
            break; 
        }
    }
    
    if (isFlingMap) {
        ArchipelagoLog("[AP DEBUG] Protection Active: Skipping trigger_catapult deletion on scripted fling map " + current_map);
        return; // Remplace le 'continue' vu qu'on est dans une fonction
    }

    // 2. Logique de Stabilisation
    bool foundPlate = false;
    CBaseEntity@ targetPlate = null;
    string targetPlateName = "";
    
    CBaseEntity@ p = null;
    // On augmente le rayon à 256 car sur sp_a2_sphere_peek, 
    // les entités sont parfois plus espacées.
    while ((@p = EntityList().FindInSphere(p, trigger.GetAbsOrigin(), 256.0f)) !is null) {
        string pModel = p.GetModelName().tolower();
        
      // --- VÉRIFICATION DES MODÈLES PRÉCIS ---
        if (pModel == "models/props/faith_plate.mdl" || pModel == "models/props/faith_plate_128.mdl") {
            
            targetPlateName = p.GetEntityName();
            if (targetPlateName == "") {
                targetPlateName = "ap_faith_plate_" + RandomInt(1000, 9999);
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
        // SI ON NE TROUVE PAS DE PLAQUE : 
        // Sur sp_a2_sphere_peek, il y a des triggers de saut qui n'ont pas de plaque visuelle.
        // Au lieu de bloquer le script, on va simplement supprimer le trigger 
        // pour que le joueur ne soit pas propulsé par "rien".
        ArchipelagoLog("[AP DEBUG] No model found for " + trigger.GetEntityIndex() + ". Killing invisible catapult.");
        trigger.FireInput("kill", Variant(), 0.0f, null, null, 0);
        return;
    }
    // 3. Intégration des Feedbacks (Audio & Visuel)
    // A. Feedback Audio
    string sndUid = "ap_cat_snd_" + targetPlateName;
    CBaseEntity@ snd = EntityList().FindByName(null, sndUid);
    if (snd is null) {
        @snd = util::CreateEntityByName("ambient_generic");
        if (snd !is null) {
            snd.KeyValue("targetname", sndUid);
            snd.KeyValue("message", "World.RobotNegInteractPitchedUp");
            snd.KeyValue("spawnflags", "48"); 
            snd.KeyValue("health", "10"); 
            snd.SetAbsOrigin(targetPlate.GetAbsOrigin());
            snd.Spawn();
        }
    }

    // B. Feedback Visuel (Cible pour l'Instructor Hint)
    string targetUid = "ap_hint_target_" + targetPlateName;
    CBaseEntity@ hintTarget = EntityList().FindByName(null, targetUid);
    if (hintTarget is null) {
        @hintTarget = util::CreateEntityByName("info_target_instructor_hint");
        if (hintTarget !is null) {
            hintTarget.KeyValue("targetname", targetUid);
            hintTarget.SetAbsOrigin(targetPlate.GetAbsOrigin());
            hintTarget.Spawn();
        }
    }

    // C. Feedback Visuel (Le Hint en lui-même)
    string hintUid = "ap_hint_" + targetPlateName;
    CBaseEntity@ hint = EntityList().FindByName(null, hintUid);
    if (hint is null) {
        @hint = util::CreateEntityByName("env_instructor_hint");
        if (hint !is null) {
            hint.KeyValue("targetname", hintUid);
            hint.KeyValue("hint_target", targetUid);
            hint.KeyValue("hint_static", "1");
            hint.KeyValue("hint_caption", "#AP_Item_AerialFaithPlate_Hint");
            hint.KeyValue("hint_icon_onscreen", "icon_alert");
            hint.KeyValue("hint_color", "255 50 50");
            hint.KeyValue("hint_timeout", "0");
            hint.KeyValue("hint_range", "0"); 
            hint.Spawn();
        }
    }

    // 4. Trigger de Détection Proxy (Copie les dimensions exactes de la catapulte)
    string proxyUid = "ap_prox_" + trigger.GetEntityIndex();
    CBaseEntity@ proxy = EntityList().FindByName(null, proxyUid);
    
    if (proxy is null) {
        @proxy = util::CreateEntityByName("trigger_multiple");
        if (proxy !is null) {
            proxy.KeyValue("targetname", proxyUid);
            proxy.KeyValue("spawnflags", "1"); // Joueurs uniquement
            proxy.KeyValue("wait", "1.5"); // Se redéclenche toutes les 1.5s
            proxy.SetAbsOrigin(trigger.GetAbsOrigin());
            proxy.SetAbsAngles(trigger.GetAbsAngles());
            
            // Copie l'index du modèle brush (ex: "*123")
            proxy.SetModel(trigger.GetModelName());
            proxy.Spawn();

            // Connecter le proxy aux feedbacks
            SafeAddOutput(proxy, "OnTrigger", hintUid, "ShowHint", "", 0.0f, -1);
            SafeAddOutput(proxy, "OnTrigger", sndUid, "PlaySound", "", 0.0f, -1);

            // Faire clignoter la texture de la plaque (Skin 1 puis retour à 0)
            SafeAddOutput(proxy, "OnTrigger", targetPlateName, "Skin", "1", 0.0f, -1);
            SafeAddOutput(proxy, "OnTrigger", targetPlateName, "Skin", "0", 0.5f, -1);
        }
    }
    trigger.FireInput("kill", Variant(), 0.0f, null, null, 0);
}


    bool portalgun_2_disabled = false;

    void DisablePortalGun(bool blue, bool orange) {
        if (current_map == "sp_a3_01") {
            EntFire("weapon_portalgun", "AddOutput", "CanFirePortal2 0", 13.0f);
        }

        if (current_map == "sp_a2_intro") {
            portalgun_2_disabled = true;
        }

        if (blue) EntFire("weapon_portalgun", "AddOutput", "CanFirePortal1 0");
        if (orange) EntFire("weapon_portalgun", "AddOutput", "CanFirePortal2 0");
    }

    void DisableEntityPickup(string entity_name) {
        array<CBaseEntity@> targets = FindEntities(entity_name);
        for (uint i = 0; i < targets.length(); i++) {
            targets[i].KeyValue("PickupEnabled", "0");
        }
    }

    void DisableEntityPhysics(string entity_name) {
        array<CBaseEntity@> targets = FindEntities(entity_name);
        for (uint i = 0; i < targets.length(); i++) {
            targets[i].KeyValue("movetype", "4");
        }
    }

    void AddFloorButtonFrame(string entity_name) {
        array<CBaseEntity@> targets = FindEntities(entity_name);
        for (uint i = 0; i < targets.length(); i++) {
            CBaseEntity@ ent = targets[i];
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
            string holoName = entity_name + "_" + ent.GetEntityIndex() + "_holo";
            if (EntityList().FindByName(null, holoName) is null) {
                Vector hPos(0, 0, 0);
                QAngle hAng(0, 0, 0);
                int hSkin = 4;
                float hScale = 1.0f;
                bool hParent = true;
                bool hAbs = false;
                Legacy::GetHologramVisualOverrides(ent, hPos, hAng, hSkin, hScale, hParent, hAbs);
                
                Vector finalPos;
                QAngle finalAng;
                CBaseEntity@ finalParent = hParent ? ent : null;
                if (hParent) { finalPos = hPos; finalAng = hAng; } else { 
                    finalPos = position + (AnglesToUp(angles) * hPos.z); // Simple vertical fallback
                    finalAng = hAbs ? hAng : (angles + hAng);
                }

                CreateAPHologram(finalPos, finalAng, hScale, finalParent, "", hSkin, holoName);
            }
      // 3. Spawn the Inert "Dummy" Replacement
        CBaseEntity@ dummy = util::CreateEntityByName("prop_dynamic");
        if (dummy !is null) {
            // We intentionally leave the targetname blank so scripts can't find it
            dummy.KeyValue("model", originalModel);
            dummy.KeyValue("solid", "6"); // Keep VPhysics collisions
            dummy.SetAbsOrigin(position);
            dummy.SetAbsAngles(angles);
            dummy.Spawn();
        }

        // 4. Murder the real, functioning tractor beam
        ent.Remove();
    }
    
    // We completely removed DeleteEntity(entity_name, false) from here!
    // The original tractor beams are already dead and replaced by dummies.
    }

    void AddButtonFrame(string entity_name) {
        array<CBaseEntity@> targets = FindEntities(entity_name);
        for (uint i = 0; i < targets.length(); i++) {
            CBaseEntity@ ent = targets[i];
            Vector position = ent.GetAbsOrigin();
            QAngle angles = ent.GetAbsAngles();
            string originalModel = ent.GetModelName();
        
            CBaseEntity@ box = util::CreateEntityByName("prop_dynamic");
            if (box !is null) {
                box.KeyValue("targetname", entity_name + "_frame");
                box.KeyValue("model", "models/props/archipelago/ap_buttonframe.mdl");
                box.KeyValue("solid", "6");
                box.SetAbsOrigin(position);
                box.SetAbsAngles(angles);
                box.Spawn();
            }
        
            string holoName = entity_name + "_" + ent.GetEntityIndex() + "_holo";
            if (EntityList().FindByName(null, holoName) is null) {
                Vector hPos(0, 0, 0);
                QAngle hAng(0, 0, 0);
                int hSkin = 4;
                float hScale = 0.66f;
                bool hParent = true;
                bool hAbs = false;
                Legacy::GetHologramVisualOverrides(ent, hPos, hAng, hSkin, hScale, hParent, hAbs);

                Vector finalPos;
                QAngle finalAng;
                CBaseEntity@ finalParent = hParent ? ent : null;
                if (hParent) { finalPos = hPos; finalAng = hAng; } else { 
                    finalPos = position + (AnglesToForward(angles) * hPos.x) + (AnglesToUp(angles) * hPos.z);
                    finalAng = hAbs ? hAng : (angles + hAng);
                }

                CreateAPHologram(finalPos, finalAng, hScale, finalParent, "", hSkin, holoName);
            }

           // 3. Spawn the Inert "Dummy" Replacement
        CBaseEntity@ dummy = util::CreateEntityByName("prop_dynamic");
        if (dummy !is null) {
            // We intentionally leave the targetname blank so scripts can't find it
            dummy.KeyValue("model", originalModel);
            dummy.KeyValue("solid", "6"); // Keep VPhysics collisions
            dummy.SetAbsOrigin(position);
            dummy.SetAbsAngles(angles);
            dummy.Spawn();
        }

        // 4. Murder the real, functioning tractor beam
        ent.Remove();
    }
    
    // We completely removed DeleteEntity(entity_name, false) from here!
    // The original tractor beams are already dead and replaced by dummies.
}
        void AddTractorBeamFrame(string entity_name) {
    array<CBaseEntity@> targets = FindEntities(entity_name);
    for (uint i = 0; i < targets.length(); i++) {
        CBaseEntity@ ent = targets[i];
        
        // Save the original properties before we destroy it
        Vector position = ent.GetAbsOrigin();
        QAngle angles = ent.GetAbsAngles();
        string originalModel = ent.GetModelName(); 
    
        // 1. Spawn the custom Archipelago frame
        CBaseEntity@ box = util::CreateEntityByName("prop_dynamic");
        if (box !is null) {
            box.KeyValue("targetname", entity_name + "_frame");
            box.KeyValue("model", "models/props/archipelago/ap_proptractorbeamframe.mdl");
            box.KeyValue("solid", "6");
            box.SetAbsOrigin(position);
            
            QAngle angleOffset(90.0f, 0.0f, 0.0f);
            QAngle finalFrameAngles = angles + angleOffset;
            box.SetAbsAngles(finalFrameAngles);
            
            box.Spawn();
        }
    
        // 2. Spawn the un-parented Hologram
        string holoName = entity_name + "_" + ent.GetEntityIndex() + "_holo";
        if (EntityList().FindByName(null, holoName) is null) {
            Vector hPos(0, 0, 0);
            QAngle hAng(0, 0, 0);
            int hSkin = 0;
            float hScale = 1.0f;
            bool hParent = false; // Always false so it survives
            bool hAbs = false;
            
            // We still get overrides, but we ignore what it says about hParent
            Legacy::GetHologramVisualOverrides(ent, hPos, hAng, hSkin, hScale, hParent, hAbs);

            Vector forward, right, up;
            AngleVectors(angles, forward, right, up);
            
            Vector finalPos = position + (forward * hPos.x) + (right * hPos.y) + (up * hPos.z);
            QAngle finalAng = hAbs ? hAng : (angles + hAng);

            Legacy::CreateAPHologram(finalPos, finalAng, hScale, null, "", hSkin, holoName);
        }

        // 3. Spawn the Inert "Dummy" Replacement
        CBaseEntity@ dummy = util::CreateEntityByName("prop_dynamic");
        if (dummy !is null) {
            // We intentionally leave the targetname blank so scripts can't find it
            dummy.KeyValue("model", originalModel);
            dummy.KeyValue("solid", "6"); // Keep VPhysics collisions
            dummy.SetAbsOrigin(position);
            dummy.SetAbsAngles(angles);
            dummy.Spawn();
        }

        // 4. Murder the real, functioning tractor beam
        ent.Remove();
    }
    
    // We completely removed DeleteEntity(entity_name, false) from here!
    // The original tractor beams are already dead and replaced by dummies.
}

    void DeleteCoreOnOutput(string core_name, string target_name, string output) {
        float delay = 5.0f;
        EntFire(target_name, "AddOutput", output + " InitCmd,Command,DeleteEntity " + core_name + " 0, " + delay + ",-1");
    }

    void BlockWheatleyFight() {
        CBaseEntity@ socket = EntityList().FindByName(null, "breaker_socket_button");
        if (socket !is null) {
            Vector place = socket.GetAbsOrigin();
            CBaseEntity@ target = util::CreateEntityByName("info_target_instructor_hint");
            target.KeyValue("targetname", "hint_target_no_potatos");
            target.SetAbsOrigin(place);
            target.Spawn();
        
            DeleteEntity("breaker_socket_button", false);
            DeleteEntity("breaker_hint", false);
        }

        CBaseEntity@ hint = util::CreateEntityByName("env_instructor_hint");
        hint.KeyValue("targetname", "hudhint_no_potatos");
        hint.KeyValue("hint_target", "hint_target_no_potatos");
        hint.KeyValue("hint_static", "0");
        hint.KeyValue("hint_caption", "PotatOS not unlocked");
        hint.KeyValue("hint_icon_onscreen", "icon_alert");
        hint.KeyValue("hint_color", "255 50 50");
        hint.Spawn();

        SafeAddOutput(EntityList().FindByName(null, "trigger_portal_cleanser"), "OnStartTouch", "hudhint_no_potatos", "ShowHint", "", 0.0f, -1);
    }

    void RemovePotatOS() {
        CBaseEntity@ button = EntityList().FindByName(null, "sphere_entrance_potatos_button");
        if (button !is null) {
            Vector place = button.GetAbsOrigin();
            CBaseEntity@ target = util::CreateEntityByName("info_target_instructor_hint");
            target.KeyValue("targetname", "hint_target_no_potatos");
            target.SetAbsOrigin(place);
            target.Spawn();
        
            DeleteEntity("sphere_entrance_lift_relay", false);
            DeleteEntity("potatos_prop", false);
        }

        CBaseEntity@ hint = util::CreateEntityByName("env_instructor_hint");
        hint.KeyValue("targetname", "hudhint_no_potatos");
        hint.KeyValue("hint_target", "hint_target_no_potatos");
        hint.KeyValue("hint_static", "0");
        hint.KeyValue("hint_caption", "PotatOS not unlocked");
        hint.KeyValue("hint_icon_onscreen", "icon_alert");
        hint.KeyValue("hint_color", "255 50 50");
        hint.Spawn();

        SafeAddOutput(EntityList().FindByName(null, "sphere_entrance_potatos_button"), "OnPressed", "hudhint_no_potatos", "ShowHint", "", 0.0f, -1);
    }

    void RemovePotatosFromGun() {
        ArchipelagoLog("[AP DEBUG] RemovePotatosFromGun: Executing viewmodel and world cleanup.");
        
        // 1. VIEWMODEL: Force removal via the player proxy
        CBaseEntity@ lpp = EntityList().FindByClassname(null, "logic_playerproxy");
        if (lpp is null) {
            @lpp = util::CreateEntityByName("logic_playerproxy");
            if (lpp !is null) { lpp.KeyValue("targetname", "ap_lpp"); lpp.Spawn(); }
        }
        
        if (lpp !is null) {
            lpp.FireInput("RemovePotatosFromPortalgun", Variant(), 0.0f, null, null, 0);
        }

        // 2. WORLD SPACE: Remove any physical representations
        DeleteEntity("potatos_prop", false);
        DeleteEntity("potatos", false);
        DeleteEntity("models/props/potatos.mdl", false);
        
        // 3. VOICE & UI: Silence audio group and subtitles via mixer
        CBaseEntity@ cmd = EntityList().FindByName(null, "InitCmd");
        if (cmd !is null) {
            Variant vMix;
            vMix.SetString("snd_setmixer potatosVO vol 0.0");
            cmd.FireInput("Command", vMix, 0.0f, null, null, 0);
            
            Variant vCapt;
            vCapt.SetString("script MutePotatOSSubtitles(true)");
            cmd.FireInput("Command", vCapt, 0.1f, null, null, 0);

            Variant vStopShock;
            vStopShock.SetString("stopsound playonce/scripted_sequence/glados_potados_shock.wav");
            cmd.FireInput("Command", vStopShock, 0.0f, null, null, 0);
        }
        ArchipelagoLog("[AP DEBUG] RemovePotatosFromGun: Done (Visuals, Mixer & Subtitles silenced).");
    }

    void CreateAPButton(string name, Vector position, QAngle angle, float holo_scale, int skin = 0) {
        string scenarioName = TranslateButtonName(name);

        // Ratman Dens default to skin 0 as requested
        if (scenarioName.locate("rd") == 0) skin = 0;

    // 0. CLEANUP & IDEMPOTENCY
        CBaseEntity@ entCheck = null;
        while ((@entCheck = EntityList().FindInSphere(entCheck, position, 24.0f)) !is null) {
            string cls = entCheck.GetClassname();
            string entName = entCheck.GetEntityName();
            if (entName == scenarioName + "_model" || entName.locate("ap_") == 0) return;
            if (cls.locate("button") != uint(-1) || cls.locate("switch") != uint(-1) || cls.locate("dynamic") != uint(-1)) entCheck.Remove();
        }

        string uid = "ap_" + RandomInt(1000, 9999);
        CBaseEntity@ body = util::CreateEntityByName("prop_dynamic");
        if (body !is null) {
            body.KeyValue("targetname", scenarioName + "_model");
            body.SetModel("models/props/switch001.mdl");
            body.SetAbsOrigin(position);
            body.SetAbsAngles(angle);
            body.Spawn();
        }

        CBaseEntity@ snd_dn = util::CreateEntityByName("ambient_generic");
        if (snd_dn !is null) {
            snd_dn.KeyValue("targetname", uid + "_dn");
            snd_dn.KeyValue("message", "Portal.button_down");
            snd_dn.KeyValue("spawnflags", "48"); 
            snd_dn.SetAbsOrigin(position);
            snd_dn.Spawn();
            snd_dn.SetParent(body);
        }

        CBaseEntity@ snd_up = util::CreateEntityByName("ambient_generic");
        if (snd_up !is null) {
            snd_up.KeyValue("targetname", uid + "_up");
            snd_up.KeyValue("message", "Portal.button_up");
            snd_up.KeyValue("spawnflags", "48"); 
            snd_up.SetAbsOrigin(position);
            snd_up.Spawn();
            snd_up.SetParent(body);
        }

        CBaseEntity@ brain = util::CreateEntityByName("func_rot_button");
        if (brain !is null) {
            brain.KeyValue("targetname", scenarioName);
            brain.KeyValue("spawnflags", "1025");
            brain.KeyValue("wait", "0.5");
        
            SafeAddOutput(brain, "OnPressed", "InitCmd", "Command", "ReportAPButton " + scenarioName, 0.1f, -1);
            SafeAddOutput(brain, "OnPressed", "!parent", "SetAnimation", "down", 0.0f, -1);
            SafeAddOutput(brain, "OnPressed", "!parent", "SetAnimation", "up", 0.5f, -1);
            SafeAddOutput(brain, "OnPressed", uid + "_dn", "PlaySound", "", 0.0f, -1);
            SafeAddOutput(brain, "OnPressed", uid + "_up", "PlaySound", "", 0.5f, -1);
        
            brain.Spawn();
            brain.SetParent(body);
            brain.SetLocalOrigin(Vector(0, 0, 40)); 
        }

        // Use local offset relative to the button body
        Vector localPos = Vector(0, 0, 90.0f);
        QAngle localAng = QAngle(0, 90, 0);
        CreateAPHologram(localPos, localAng, holo_scale, body, "", skin, name);
    }

    CBaseEntity@ CreateAPHologram(Vector position, QAngle angles, float scale, CBaseEntity@ parent = null, string attachment = "", int skin = 0, string name = "", bool animate = true) {
        CBaseEntity@ h = null;

        if (name != "") {
            @h = EntityList().FindByName(null, name);
        }

        if (h !is null) {
            if (h.GetModelName().locate("archipelago_hologram") != uint(-1)) {
                if (Legacy::cv_ArchipelagoDebug.GetBool()) {
                    Legacy::ArchipelagoLog("[AP DEBUG] Updating Hologram '" + name + "' to " + angles.x + " " + angles.y + " " + angles.z);
                }
                h.SetAbsOrigin(position);
                h.SetAbsAngles(angles);
                h.KeyValue("skin", "" + skin);
                h.KeyValue("modelscale", "" + scale);
                return h;
            }
        }

        @h = util::CreateEntityByName("prop_dynamic");
        if (h !is null) {
            h.KeyValue("model", "models/effects/ap/archipelago_hologram.mdl");
            if (name != "") h.KeyValue("targetname", name);
            h.KeyValue("skin", "" + skin);
            h.KeyValue("modelscale", "" + scale);
            h.KeyValue("DefaultAnim", animate ? "idle" : "");

            // Set temporary world position to avoid collision issues at origin
            h.SetAbsOrigin(position);
            h.SetAbsAngles(angles);
            h.Spawn();

            h.SetSolid(SOLID_NONE);
            h.SetMoveType(MOVETYPE_NONE);

            if (parent !is null) {
                h.SetParent(parent);
                h.SetLocalOrigin(position);
                h.SetLocalAngles(angles);
                
                if (attachment != "") {
                    Variant v;
                    v.SetString(attachment);
                    h.FireInput("SetParentAttachment", v, 0.01f, null, null, 0);
                }
            } else {
                h.SetAbsOrigin(position);
                h.SetAbsAngles(angles);
            }
        }
        return h;
    }

    void AttachHologramToEntity(string entity_name, string attachment_point, float holo_scale, float offset, int skin = 0) {
        array<CBaseEntity@> targets = FindEntities(entity_name);
        for (uint i = 0; i < targets.length(); i++) {
            CBaseEntity@ ent = targets[i];
            
            Vector hPos;
            QAngle hAng;
            int hSkin = 0;
            float hScale = 1.0f;
            bool hParent = true;
            bool hAbsolute = false;
            
            Legacy::GetHologramVisualOverrides(ent, hPos, hAng, hSkin, hScale, hParent, hAbsolute);
            
            // Use provided defaults if overrides are zero/empty
            if (hSkin == 0) hSkin = skin;
            if (hScale == 1.0f) hScale = holo_scale;
            
            string name = entity_name + "_" + i;
            ent.KeyValue("targetname", name);
            
            if (hAbsolute) {
                // World aligned, no parent
                Vector worldPos = ent.GetAbsOrigin() + (AnglesToForward(ent.GetAbsAngles()) * (hPos.x + offset)) + (AnglesToRight(ent.GetAbsAngles()) * hPos.y) + (AnglesToUp(ent.GetAbsAngles()) * hPos.z);
                CreateAPHologram(worldPos, hAng, hScale, null, "", hSkin, "");
            } else {
                // Parented
                CreateAPHologram(hPos + Vector(offset, 0, 0), hAng, hScale, ent, attachment_point, hSkin, "");
            }
        }
    }

    void PrintMapName() {
        ArchipelagoLog("map_name:" + current_map);
    }

// --- MAP COMPLETION CHAIN ---

    void PrintMapCompleteNoExit() {
        if (g_has_printed_map_complete) return;
        g_has_printed_map_complete = true;

        UpdateInternalMapName();
        ArchipelagoLog("map_complete:" + current_map);

        if (current_map == "sp_a4_finale4") return;

        CBasePlayer@ player = GetPlayer();
        if (player !is null) {
            Variant v;
            player.FireInput("Disable", v, 0.0f, null, null, 0);
        }
    
        SendToConsole("fadeout 0.2");
    }

    void WaitExecute(string command, float delay, string timerName = "") {
        CBaseEntity@ cmdEnt = EntityList().FindByName(null, "InitCmd");
        if (cmdEnt !is null) {
            Variant v;
            v.SetString(command);
            cmdEnt.FireInput("Command", v, delay, null, null, 0);
            ArchipelagoLog("Scheduled command in " + delay + "s: " + command);
        }
    }
    
    void AddEntityOutputScriptAtPos(Vector pos, string cls, string output, string script, float delay = 0.0f, int times = -1) {
        CBaseEntity@ ent = EntityList().FindByClassnameNearest(cls, pos, 150.0f);
        if (ent !is null) {
            SafeAddOutput(ent, output, "InitCmd", "Command", script, delay, times);
        }
    }

    void PrintMapComplete() {
        if (transition_script_count > 0) {
            transition_script_count--;
            return;
        }
        PrintMapCompleteNoExit();
        WaitExecute("WarpToMenu", 2.0f, "return_to_menu");
    }

    void WarpToMenu() {
        UpdateInternalMapName();
        CallVScript("SendToPanorama(\"Archipelago_WarpToMenu\", \"" + current_map + "\")");
    }

    void CreateCompleteLevelAlertHook(string map) {
        g_has_printed_map_complete = false;
        if (two_trigger_levels.find(map) >= 0) transition_script_count = 1;

    // Standard hooks for non-elevator maps
        if (non_elevator_maps.find(map) >= 0) {
            array<CBaseEntity@> logicScripts = FindEntities("@transition_script");
            for (uint i = 0; i < logicScripts.length(); i++) logicScripts[i].Remove();

            array<string> targets = { "transition_trigger", "trigger_transition", "@transition_from_map", "relay_transition", "ending_relay" };
            for (uint s = 0; s < targets.length(); s++) {
                array<CBaseEntity@> ents = FindEntities(targets[s]);
                for (uint i = 0; i < ents.length(); i++) {
                    SafeAddOutput(ents[i], "OnStartTouch", "InitCmd", "Command", "FinishedMap", 0.0f, -1);
                    SafeAddOutput(ents[i], "OnTrigger", "InitCmd", "Command", "FinishedMap", 0.0f, -1);
                }
            }
        } else {
            array<CBaseEntity@> cls = FindEntities("@transition_from_map");
            for (uint i = 0; i < cls.length(); i++) {
                SafeAddOutput(cls[i], "OnTrigger", "InitCmd", "Command", "FinishedMap", 0.0f, -1);
            }
            DeleteEntity("@exit_teleport", false);
        }
    }

    void DoMapSpecificSetup() {
        if (current_map == "sp_a1_intro3") {
            SafeAddOutput(EntityList().FindByName(null, "portalgun_pickup_trigger"), "OnStartTouch", "InitCmd", "Command", "PrintItem Portal.Gun", 0.0f, -1);
        } else if (current_map == "sp_a2_intro") {
            SafeAddOutput(EntityList().FindByName(null, "player_near_portalgun"), "OnStartTouch", "InitCmd", "Command", "PrintItem Upgraded.Portal.Gun", 0.0f, -1);
        } else if (current_map == "sp_a3_transition01") {
            SafeAddOutput(EntityList().FindByName(null, "sphere_entrance_potatos_button"), "OnPressed", "InitCmd", "Command", "PrintItem PotatOS", 0.0f, -1);
        } else if (current_map == "sp_a2_laser_intro") {
            CBaseEntity@ cmd = EntityList().FindByName(null, "InitCmd");
            if (cmd !is null) {
                // Parent the Emitter & Catcher to the doors so they move when the puzzle is solved
                Variant v1;
                v1.SetString("ent_fire laser_emitter_door_holo SetParent laser_emitter_door:0.8:-1");
                cmd.FireInput("Command", v1, 0.5f, null, null, 0);
                
                Variant v2;
                v2.SetString("ent_fire laser_catcher_door_holo SetParent laser_catcher_door:0.8:-1");
                cmd.FireInput("Command", v2, 0.5f, null, null, 0);
            }
        }
    }

    void CreateMapSpecificHolos() {
        if (current_map == "sp_a1_intro3") CreateAPHologram(Vector(25, 1958, -299), QAngle(0, 0, 0), 0.66f, null, "", 0, "intro3_portalgun_holo"); else if (current_map == "sp_a2_intro") {
            CBaseEntity@ gun = EntityList().FindByName(null, "player_near_portalgun");
            if (gun !is null) CreateAPHologram(gun.GetAbsOrigin(), QAngle(0, 0, 0), 0.66f, null, "", 0, "a2_intro_gun_holo");
        } else if (current_map == "sp_a3_transition01") {
            CBaseEntity@ btn = EntityList().FindByName(null, "sphere_entrance_potatos_button");
            if (btn !is null) CreateAPHologram(btn.GetAbsOrigin(), QAngle(0, 0, 0), 0.66f, null, "", 0, "a3_potatos_button_holo");
        }
    
        AddMapCheck();
        AddVitrifiedDoorChecks(current_map);
        AddWheatleyMonitorChecks(current_map);
    }

    void AddVitrifiedDoorChecks(string map_name) {
        InitLocationRegistries();
    
        array<string>@ keys = g_vitrified_door_names.getKeys();
        for (uint i = 0; i < keys.length(); i++) {
            string key = keys[i];
            if (key.locate(map_name + ":") == 0) {
                string entName = key.substr(map_name.length() + 1);
                string checkName;
                g_vitrified_door_names.get(key, checkName);
            
                CBaseEntity@ ent = EntityList().FindByName(null, entName);
                if (ent !is null) {
                // 1. LOGIC HOOK
                    int doorIndex = 0;
                    if (checkName.locate("Vitrified Door 2") != uint(-1) || entName.locate("button2") != uint(-1)) doorIndex = 2; else if (checkName.locate("Vitrified Door 3") != uint(-1) || entName.locate("button3") != uint(-1)) doorIndex = 3; else if (checkName.locate("Vitrified Door 1") != uint(-1) || entName.locate("button") != uint(-1)) doorIndex = 1; else if (checkName.locate("Vitrified Door 4") != uint(-1)) doorIndex = 4; else if (checkName.locate("Vitrified Door 5") != uint(-1)) doorIndex = 5; else if (checkName.locate("Vitrified Door 6") != uint(-1)) doorIndex = 6;

                    SafeAddOutput(ent, "OnPressed", "InitCmd", "Command", "PrintItem " + checkName, 0.0f, 1);
                
                    if (doorIndex > 0) {
                        SafeAddOutput(ent, "OnPressed", "InitCmd", "Command", "ArchipelagoVitrifiedFound " + doorIndex, 0.0f, 1);
                    }
                    SafeAddOutput(ent, "OnPressed", entName + "_holo", "Skin", "4", 0.0f, 1);
                
                // 3. VISUALS (Local-space via Overrides)
                    Vector hPos(0, 0, 0);
                    QAngle hAng(0, 0, 0);
                    int hSkin = 0;
                    float hScale = 1.0f;
                    bool hParent = true;
                    bool hAbs = false;
                    Legacy::GetHologramVisualOverrides(ent, hPos, hAng, hSkin, hScale, hParent, hAbs);

                    // Check local save state for skin override
                    string bitmask = cv_ArchipelagoVitrifiedStatus.GetString();
                    if (doorIndex > 0 && bitmask.length() >= uint(doorIndex) && bitmask.substr(doorIndex - 1, 1) == "1") {
                        hSkin = 4;
                    }

                    Vector finalPos = ent.GetAbsOrigin() + (AnglesToForward(ent.GetAbsAngles()) * hPos.x) + (AnglesToRight(ent.GetAbsAngles()) * -hPos.y) + (AnglesToUp(ent.GetAbsAngles()) * hPos.z);
                    QAngle finalAng = hAbs ? hAng : (ent.GetAbsAngles() + hAng);

                    CreateAPHologram(finalPos, finalAng, hScale, null, "", hSkin, entName + "_holo", false);
                }
            }
        }
    }

    void AddWheatleyMonitorChecks(string map_name) {
        InitWheatleyMonitorRegistry();
        ArchipelagoLog("[AP DEBUG] Checking monitors for map: " + map_name);
        
        array<string>@ keys = g_monitor_break_names.getKeys();
        for (uint i = 0; i < keys.length(); i++) {
            string key = keys[i];
            if (key.locate(map_name + ":") == 0) {
                string entName = key.substr(map_name.length() + 1);
                string locationID;
                g_monitor_break_names.get(key, locationID);
                ArchipelagoLog("[AP DEBUG] Found registry entry for monitor: " + entName);
                
                CBaseEntity@ ent = EntityList().FindByName(null, entName);
                if (ent !is null) {
                    ArchipelagoLog("[AP DEBUG] Entity " + entName + " successfully found.");
                    string cls = ent.GetClassname();
                    string output = "OnTrigger"; 
                    if (cls == "func_breakable") {
                        output = "OnBreak";
                    } else if (cls.locate("trigger") != uint(-1)) {
                        output = "OnStartTouch";
                    }
                    
                    string safe_id = locationID.replace(" ", ".");
                    Variant v;
                    v.SetString(output + " InitCmd:Command:PrintMonitor " + safe_id + ":0.0:-1");
                    ent.FireInput("AddOutput", v, 0.0f, null, null, 0);

                    // Visuals
                    string holo_name = entName + "_holo";
                    CBaseEntity@ anchor = ent;
                    CBaseEntity@ prop = EntityList().FindByClassnameNearest("prop_dynamic", ent.GetAbsOrigin(), 256.0f);
                    if (prop !is null && (prop.GetModelName().locate("monitor") != uint(-1) || prop.GetModelName().locate("screen") != uint(-1))) {
                        @anchor = prop;
                    }
                    
                    Vector anchorPos = anchor.GetAbsOrigin();
                    ArchipelagoLog("[AP DEBUG] Monitor " + entName + " anchor: " + anchor.GetClassname() + " (" + anchor.GetModelName() + ") at " + anchorPos.x + " " + anchorPos.y + " " + anchorPos.z);

                    Vector hPos(0, 0, 0);
                    QAngle hAng(0, 0, 0);
                    int hSkin = 4;
                    float hScale = 0.7f;
                    bool hParent = true;
                    bool hAbs = false;
                    Legacy::GetHologramVisualOverrides(anchor, hPos, hAng, hSkin, hScale, hParent, hAbs);
                    
                    Vector finalPos = anchor.GetAbsOrigin() + (AnglesToForward(anchor.GetAbsAngles()) * hPos.x) + (AnglesToRight(anchor.GetAbsAngles()) * -hPos.y) + (AnglesToUp(anchor.GetAbsAngles()) * hPos.z);
                    QAngle finalAng = hAbs ? hAng : (anchor.GetAbsAngles() + hAng);

                    CreateAPHologram(finalPos, finalAng, hScale, null, "", hSkin, holo_name);
                    ArchipelagoLog("Monitor Check Restored: " + entName + " at " + finalPos.x + " " + finalPos.y + " " + finalPos.z);
                } else {
                    ArchipelagoLog("[AP DEBUG] FAILED to find monitor entity by name: " + entName);
                }
            }
        }
    }
    void AddToTextQueue(string text, string color = "") { }

} // namespace Legacy
