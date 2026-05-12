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


/**
 * ResetPersistentSystems - Forces global engine and player states back to defaults.
 * Called during map init to prevent trap effects from surviving reloads/save-loads.
 */
void ResetPersistentSystems() {
   
    CBaseEntity@ cmd = EntityList().FindByName(null, "InitCmd");
    if (cmd !is null) {
        Variant v;
        

        // Reset Visuals (Motion Blur Trap)
        v.SetString("sv_friction 4");
        cmd.FireInput("Command", v, 30.0f, null, null, 0);
        
        v.SetString("ent_fire !player AddOutput \"friction 1\"");
        cmd.FireInput("Command", v, 0.1f, null, null, 0);
        
        // Reset Visuals (Motion Blur Trap)
        v.SetString("mat_motion_blur_enabled 1"); // Assuming default is 1
        cmd.FireInput("Command", v, 0.0f, null, null, 0);

        // Réinitialisation du PostProcess (pour retirer le brouillard résiduel)
        v.SetString("con_log_channel_mode 0");
        cmd.FireInput("Command", v, 0.1f, null, null, 0); // Léger délai
         // Réinitialisation du PostProcess (pour retirer le brouillard résiduel)
        v.SetString("con_log_severity_mode 0");
        cmd.FireInput("Command", v, 0.1f, null, null, 0); // Léger délai

        // Reset Sound Mixers (PotatOS Silence restoration)
        v.SetString("snd_setmixer potatosVO vol 0.4");
        cmd.FireInput("Command", v, 0.0f, null, null, 0);
        v.SetString("snd_setmixer gladosVO vol 0.7");
        cmd.FireInput("Command", v, 0.0f, null, null, 0);

        CallVScript("MutePotatOSSubtitles(false)");



        
        ArchipelagoLog("[Archipelago] Persistent systems have been sanitized for the new session.");
    }
}



void AttachDeathTrigger() {
        sent_death_link = false; // Réinitialise à chaque chargement de map

        // Création du timer natif
        CBaseEntity@ timer = util::CreateEntityByName("logic_timer");
        if (timer !is null) {
            timer.KeyValue("targetname", "ap_deathlink_timer");
            timer.KeyValue("RefireTime", "0.5"); // Check 2 fois par seconde (plus réactif)
            
            // Format d'output Source : Target \x1B Input \x1B Parameter \x1B Delay \x1B MaxFires
            // On utilise l'entité "InitCmd" pour lancer notre ServerCommand
            string payload = "InitCmd\x1BCommand\x1BDeathLink\x1B0\x1B-1";
            timer.KeyValue("OnTimer", payload);
            
            timer.Spawn();
            
            // Activation du timer
            Variant empty;
            timer.FireInput("Enable", empty, 0.0f, null, null, 0);
        }

        Msgl("DeathLink active");
    }

void DeleteEntity(const string&in entity_name, bool create_holo = true) {
    string mapName = ConVarRef("host_map").GetString();

    // --- 1. NETTOYAGE ET EXCEPTIONS ---
    string cleanName = entity_name;
    
    // Correction pour AngelScript : On vérifie si le premier caractère est '@'
    if (cleanName.length() > 0 && cleanName[0] == 64) { // 64 est le code ASCII pour '@'
        cleanName = cleanName.substr(1);
    }

    if (entity_name == "potatos_prop" || entity_name == "potatos" || entity_name == "models/props/potatos.mdl") {
        create_holo = false;
    }

    if (entity_name == "trigger_catapult" && ItemInList(mapName, scripted_fling_levels)) {
        Legacy::ArchipelagoLog("not removing trigger_catapult");
        return;
    }

    // --- 2. RECHERCHE ROBUSTE ---
    array<CBaseEntity@> entsToDelete;
    CBaseEntity@ searchEnt = null;

    if (entity_name.locate(".mdl") != uint(-1)) {
        while ((@searchEnt = EntityList().FindByModel(searchEnt, entity_name)) !is null) {
            entsToDelete.insertLast(searchEnt);
        }
    } 
    else {
        // On cherche par le nom original (@core01) ET le nom propre (core01)
        array<string> searchNames = { entity_name, cleanName };
        for (uint s = 0; s < searchNames.length(); s++) {
            @searchEnt = null;
            while ((@searchEnt = EntityList().FindByName(searchEnt, searchNames[s])) !is null) {
                bool alreadyIn = false;
                for (uint j = 0; j < entsToDelete.length(); j++) {
                    if (entsToDelete[j] is searchEnt) { alreadyIn = true; break; }
                }
                if (!alreadyIn) entsToDelete.insertLast(searchEnt);
            }
        }

        // Si on n'a toujours rien, on cherche par Classname
        if (entsToDelete.length() == 0) {
            @searchEnt = null;
            while ((@searchEnt = EntityList().FindByClassname(searchEnt, entity_name)) !is null) {
                entsToDelete.insertLast(searchEnt);
            }
        }
    }

    // --- 3. TRAITEMENT ET SUPPRESSION ---
    if (entsToDelete.length() == 0) {
        Legacy::ArchipelagoLog("[AP] DeleteEntity: No targets found for " + entity_name);
        return;
    }

    for (uint i = 0; i < entsToDelete.length(); i++) {
        CBaseEntity@ ent = @entsToDelete[i];

        if (entity_name == "trigger_catapult") {
            Legacy::MakeFaithPlateFaulty(ent);
            continue; 
        }

        if (create_holo) {
            string originalName = ent.GetEntityName();
            string holoName = (originalName != "") ? originalName + "_holo" : entity_name + "_holo";

            // --- CORRECTION ICI ---
            Vector hPos(0, 0, 0);
            QAngle hAng(0, 0, 0);
            int hSkin = 4;
            float hScale = 1.0f; // ON FORCE 1.0 PAR DÉFAUT
            bool hParent = false;
            bool hAbs = false;

            // On appelle tes règles (qui peuvent ou non changer le hScale)
            Legacy::GetHologramVisualOverrides(ent, hPos, hAng, hSkin, hScale, hParent, hAbs);

            // Sécurité supplémentaire : si après l'override le scale est toujours suspect
            if (hScale <= 0.001f) hScale = 1.0f; 

            QAngle angles = ent.GetAbsAngles();
            Vector spawnPos = ent.GetAbsOrigin();
            Vector finalPos;
            QAngle finalAng;
            
            if (hAbs) {
                finalPos = hPos;
                finalAng = hAng;
            } else {
                finalPos = spawnPos + (AnglesToForward(angles) * hPos.x) + (AnglesToRight(angles) * -hPos.y) + (AnglesToUp(angles) * hPos.z);
                finalAng = angles + hAng;
            }

            Legacy::ArchipelagoLog("[AP] Spawning Holo: " + holoName + " | Skin: " + hSkin + " | Scale: " + hScale);
            Legacy::CreateAPHologram(finalPos, finalAng, hScale, null, "", hSkin, holoName);
        }
        
        ent.Remove();
    }
}

void MakeFaithPlateFaulty(CBaseEntity@ trigger) {
    if (trigger is null) return;
    if (trigger.GetClassname() != "trigger_catapult") return;

    string current_map = ConVarRef("host_map").GetString();
    
    // Vérification de la liste des Fling Maps (protection des triggers système)
    for (uint f = 0; f < scripted_fling_levels.length(); f++) {
        if (scripted_fling_levels[f] == current_map) {
            Legacy::ArchipelagoLog("[AP] Fling Map detected: Protection active for " + current_map);
            return; 
        }
    }

    bool foundPlate = false;
    CBaseEntity@ targetPlate = null;
    string targetPlateName = "";
    
    CBaseEntity@ p = null;
    // On augmente le rayon à 256 pour les grandes zones de propulsion
    while ((@p = EntityList().FindInSphere(p, trigger.GetAbsOrigin(), 256.0f)) !is null) {
        string pModel = p.GetModelName().tolower();
        
        // Recherche plus flexible du modèle de la plaque
        if (pModel.locate("faith_plate") != uint(-1)) {
            targetPlateName = p.GetEntityName();
            if (targetPlateName == "") {
                targetPlateName = "ap_faith_plate_" + trigger.GetEntityIndex();
                p.KeyValue("targetname", targetPlateName);
            }

     // Force physical solidity (Legacy Archi "Win" logic)
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
        // C'est un "fling trigger" invisible : on le laisse intact
        Legacy::ArchipelagoLog("[AP] No physical plate found for trigger " + trigger.GetEntityIndex() + ". Skipping.");
        return; 
    }

    // --- CRÉATION DU SABOTAGE ---
    
    // Audio : On place le son sur la plaque
    string sndUid = "ap_cat_snd_" + targetPlateName;
    CBaseEntity@ snd = util::CreateEntityByName("ambient_generic");
    if (snd !is null) {
        snd.KeyValue("targetname", sndUid);
        snd.KeyValue("message", "World.RobotNegInteractPitchedUp");
        snd.KeyValue("health", "10"); // Volume
        snd.KeyValue("spawnflags", "48"); // Start Silent + Is NOT Looping
        snd.SetAbsOrigin(targetPlate.GetAbsOrigin());
        snd.Spawn();
    }

    // Hint Visuel
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

    // Proxy Trigger : On copie la taille exacte de l'original
    CBaseEntity@ proxy = util::CreateEntityByName("trigger_multiple");
    if (proxy !is null) {
        proxy.KeyValue("targetname", "ap_prox_" + trigger.GetEntityIndex());
        proxy.KeyValue("spawnflags", "1"); // Clients (Players) only
        proxy.KeyValue("wait", "2"); // Évite de spammer le bip
        proxy.SetAbsOrigin(trigger.GetAbsOrigin());
        proxy.SetModel(trigger.GetModelName()); // Copie la forme du trigger original
        proxy.Spawn();

        SafeAddOutput(proxy, "OnTrigger", hintUid, "ShowHint", "", 0.0f, -1);
        SafeAddOutput(proxy, "OnTrigger", sndUid, "PlaySound", "", 0.0f, -1);

        SafeAddOutput(proxy, "OnTrigger", targetPlateName, "Skin", "1", 0.0f, -1);
        SafeAddOutput(proxy, "OnTrigger", targetPlateName, "Skin", "0", 0.5f, -1);
    }

    // On retire la fonction de propulsion
    trigger.Remove();
    Legacy::ArchipelagoLog("[AP] Faith Plate sabotaged: " + targetPlateName);
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

void PreventPickupForModel(string model_keyword) {
    // 1. Recherche dans les objets physiques normaux
    CBaseEntity@ prop = null;
    while ((@prop = EntityList().FindByClassname(prop, "prop_physics")) !is null) {
        if (prop.GetModelName().tolower().locate(model_keyword) != uint(-1)) {
            // Retire la physique dynamique, ce qui désactive instantanément la surbrillance et le ramassage
            prop.SetMoveType(MOVETYPE_NONE);
        }
    }

    // 2. Recherche dans les objets physiques forcés (override)
    CBaseEntity@ override_prop = null;
    while ((@override_prop = EntityList().FindByClassname(override_prop, "prop_physics_override")) !is null) {
        if (override_prop.GetModelName().tolower().locate(model_keyword) != uint(-1)) {
            // Retire la physique dynamique
            override_prop.SetMoveType(MOVETYPE_NONE);
        }
    }
}


  void DisableEntityPickup(string target) {
    array<CBaseEntity@> targets = FindEntities(target);

    for (uint i = 0; i < targets.length(); i++) {
        CBaseEntity@ t = targets[i];
        if (t is null) continue;
        t.KeyValue("PickupEnabled", "0");
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
    array<CBaseEntity@> targets = FindEntities(target_name);

    if (targets.length() == 0) {
        ArchipelagoLog("[Archipelago] Error: DeleteCoreOnOutput target '" + target_name + "' not found");
        return;
    }

    Variant v;
    // Command format: DeleteEntity <name> <holo> <scale>
    // Changed holo flag to 1 to ensure cores hitting Wheatley get holograms
    v.SetString(output + " InitCmd:Command:DeleteEntity " + core_name + " 1 0.7:5.0:-1");

    for (uint i = 0; i < targets.length(); i++) {
        targets[i].FireInput("AddOutput", v, 0.0f, null, null, 0);
    }
    ArchipelagoLog("[Archipelago] Hooked output '" + output + "' on '" + targets.length() + "' entities matched by '" + target_name + "' to delete '" + core_name + "' in 5s");
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

   void IncineratorDisablePortalGun() {
        CBaseEntity@ trigger = EntityList().FindByName(null, "player_near_portalgun");
        if (trigger !is null) {
            Variant v;
            // Arguments: blue=0 (off), orange=(portalgun_2_disabled ? 1 : 0), isDelayed=0
        string orangeVal = portalgun_2_disabled ? "1" : "0";
        v.SetString("OnStartTouch InitCmd:Command:DisablePortalGun 0 " + orangeVal + " 0:0.25:-1");
        trigger.FireInput("AddOutput", v, 0.0f, null, null, 0);
    }
}

void RemovePotatOS() {
     ArchipelagoLog("[AP DEBUG] RemovePotatOS: Disabling elevator,removing potatOs Prop.");
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
        
        // --- NEW: Silence GLaDOSVO exclusively here ---
        CBaseEntity@ cmd = EntityList().FindByName(null, "InitCmd");
        if (cmd !is null) {
            Variant vMixG;
            vMixG.SetString("snd_setmixer GLaDOSVO vol 0.0");
            cmd.FireInput("Command", vMixG, 0.0f, null, null, 0);
        }

        RemovePotatosFromGun();
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
            CallVScript("MutePotatOSSubtitles(true)");
            
           
        }
        ArchipelagoLog("[AP DEBUG] RemovePotatosFromGun: Done (Visuals, Mixer & Subtitles silenced).");
    }

    void CreateAPButton(string name, Vector position, QAngle angle, float holo_scale, int skin = 0) {
        string scenarioName = TranslateButtonName(name);

        if (scenarioName.locate("rd") == 0) skin = 0;

        array<CBaseEntity@> entsToRemove;
        CBaseEntity@ entCheck = null;
        
        while ((@entCheck = EntityList().FindInSphere(entCheck, position, 24.0f)) !is null) {
            string cls = entCheck.GetClassname();
            string entName = entCheck.GetEntityName();
            
            if (entName == scenarioName + "_model" || entName.locate("ap_") == 0) return;
            
            if (cls.locate("button") != uint(-1) || cls.locate("switch") != uint(-1) || cls.locate("dynamic") != uint(-1)) {
                entsToRemove.insertLast(entCheck); 
            }
        }

        for (uint i = 0; i < entsToRemove.length(); i++) {
            entsToRemove[i].Remove();
        }

        string uid = "ap_" + RandomInt(1000, 9999);
        
        CBaseEntity@ body = util::CreateEntityByName("prop_dynamic");
        if (body !is null) {
            body.KeyValue("targetname", scenarioName + "_model");
            body.SetModel("models/props/switch001.mdl");
            body.KeyValue("solid", "6");
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
            
            // L'ASTUCE : On lui donne un modèle pour que le moteur "accepte" de calculer ses collisions...
            brain.SetModel("models/props/switch001.mdl");
            // ... Mais on le rend 100% invisible pour qu'on ne voie que votre prop_dynamic !
            brain.KeyValue("rendermode", "10");
        
            SafeAddOutput(brain, "OnPressed", "InitCmd", "Command", "ReportAPButton " + scenarioName, 0.1f, -1);
            SafeAddOutput(brain, "OnPressed", "!parent", "SetAnimation", "down", 0.0f, -1);
            SafeAddOutput(brain, "OnPressed", "!parent", "SetAnimation", "up", 0.5f, -1);
            SafeAddOutput(brain, "OnPressed", uid + "_dn", "PlaySound", "", 0.0f, -1);
            SafeAddOutput(brain, "OnPressed", uid + "_up", "PlaySound", "", 0.5f, -1);
        
            // ON ÉCRASE LA TAILLE DU MODÈLE : On le force à être un cube
            brain.SetSolid(SOLID_BBOX);
            
            // VOTRE CUBE GÉANT : Va de -30 à +30 = Un gros cube de 60x60x60 !
            brain.SetCollisionBounds(Vector(-30.0f, -30.0f, -30.0f), Vector(30.0f, 30.0f, 30.0f));
            
            brain.Spawn();
            brain.SetParent(body);
            
            // On centre ce cube géant exactement au milieu du plastique
            brain.SetLocalOrigin(Vector(0, 0, 0)); 
        }

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

        // FIX : Spawner à un endroit sûr avant le parentage
        if (parent !is null) {
            h.SetAbsOrigin(parent.GetAbsOrigin()); // On spawn sur le parent (SÛR)
            h.SetAbsAngles(parent.GetAbsAngles());
        } else {
            h.SetAbsOrigin(position); // Spawn absolu normal
            h.SetAbsAngles(angles);
        }
        
        h.Spawn(); // L'entité survit à 100%

        h.SetSolid(SOLID_NONE);
        h.SetMoveType(MOVETYPE_NONE);

        if (parent !is null) {
            h.SetParent(parent);
            h.SetLocalOrigin(position); // On applique ton offset (30, 0, 100)
            h.SetLocalAngles(angles);
            
            if (attachment != "") {
                Variant v;
                v.SetString(attachment);
                h.FireInput("SetParentAttachment", v, 0.01f, null, null, 0);
            }
        }
    }
    return h;
}

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
        Legacy::GetHologramVisualOverrides(ent, hPos, hAng, hSkin, hScale, hParent, hAbsolute);
        
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
            Vector worldPos = ent.GetAbsOrigin() + (Legacy::AnglesToForward(ent.GetAbsAngles()) * finalOffset.x) + (Legacy::AnglesToRight(ent.GetAbsAngles()) * -finalOffset.y) + (Legacy::AnglesToUp(ent.GetAbsAngles()) * finalOffset.z);
            Legacy::CreateAPHologram(worldPos, hAng, hScale, null, "", hSkin, holoName);
        } else {
            // Parenté locale
            Legacy::CreateAPHologram(finalOffset, hAng, hScale, ent, attachment_point, hSkin, holoName);
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
    
    // Initialisation du compteur pour les maps à double trigger
    if (two_trigger_levels.find(map) >= 0) {
        transition_script_count = 1;
    }

    // --- RESTAURATION : Le scan des triggers anonymes (Fixes spécifiques par map) ---
    // On crée un tableau avec les deux types de triggers à chercher
    array<string> triggerClasses = {"trigger_once", "trigger_multiple"};
    
    for (uint i = 0; i < triggerClasses.length(); i++) {
        CBaseEntity@ tr = null;
        while ((@tr = EntityList().FindByClassname(tr, triggerClasses[i])) !is null) {
            if (tr.GetEntityName() == "") { 
                Vector pos = tr.GetAbsOrigin();
                bool is_target = false;

                // CORRECTION : La chaîne des 'else if' est maintenant parfaite
                if (map == "sp_a2_bts3" && pos.DistTo(Vector(5952, 4624, -1736)) < 2.0f) is_target = true;
                else if (map == "sp_a2_bts4" && pos.DistTo(Vector(-4080, -7232, 6328)) < 2.0f) is_target = true;
                else if (map == "sp_a2_core" && pos.DistTo(Vector(0, 304, -10438)) < 2.0f) is_target = true;
                else if (map == "sp_a4_finale1" && pos.DistTo(Vector(-12832, -3040, -112)) < 2.0f) is_target = true;
                else if (map == "sp_a4_finale2" && pos.DistTo(Vector(-3152, -1928, -240)) < 2.0f) is_target = true;

                if (is_target) {
                    SafeAddOutput(tr, "OnStartTouch", "InitCmd", "Command", "FinishedMap", 0.0f, -1);
                }
            }
        }
    }

    // --- RESTAURATION : Logique finale spéciale pour sp_a4_finale4 ---
    if (map == "sp_a4_finale4") {
        array<CBaseEntity@> relays = FindEntities("ending_relay");
        for (uint i = 0; i < relays.length(); i++) {
            SafeAddOutput(relays[i], "OnTrigger", "InitCmd", "Command", "PrintCompleteNoExit", 0.0f, -1);
        }
    } 
    // --- LOGIQUE NON-ELEVATOR (Méthode Moderne) ---
    else if (non_elevator_maps.find(map) >= 0) {
        // Empêche le jeu de faire un "hot-swap"
        array<CBaseEntity@> logicScripts = FindEntities("@transition_script");
        for (uint i = 0; i < logicScripts.length(); i++) {
            logicScripts[i].Remove();
        }

        // CORRECTION : Les doublons ont été retirés !
        array<string> targets = { "transition_trigger", "relay_transition", "ending_relay", "potatos_end_relay" };
        for (uint s = 0; s < targets.length(); s++) {
            array<CBaseEntity@> ents = FindEntities(targets[s]);
            for (uint i = 0; i < ents.length(); i++) {
                SafeAddOutput(ents[i], "OnStartTouch", "InitCmd", "Command", "FinishedMap", 0.0f, -1);
                SafeAddOutput(ents[i], "OnTrigger", "InitCmd", "Command", "FinishedMap", 0.0f, -1);
            }
        }
    } 
    // --- LOGIQUE ELEVATOR (Avec Restauration du hook) ---
    else {
        array<CBaseEntity@> cls = FindEntities("@transition_from_map");
        for (uint i = 0; i < cls.length(); i++) {
            SafeAddOutput(cls[i], "OnTrigger", "InitCmd", "Command", "FinishedMap", 0.0f, -1);
        }
        
        DeleteEntity("@exit_teleport", false);
    }
}

    void DoMapSpecificSetup() {
    if (current_map == "sp_a1_intro3") {
        // Portal Gun pickup trigger (Primary - by Vector)
        AddEntityOutputScriptAtPos(Vector(25, 1958, -299), "trigger_once", "OnStartTouch", "PrintItem Portal Gun", 0.0f, 1);
        // Portal Gun pickup trigger (Backup for speedrun pickup)
        AddEntityOutputScriptAtPos(Vector(-704, 1856, -32), "trigger_multiple", "OnStartTouch", "PrintItem Portal Gun", 0.0f, 1);
        
    } else if (current_map == "sp_a1_intro4") {
        // Remplacement magique de la bouteille
        PreventPickupForModel("water_bottle.mdl");

    } else if (current_map == "sp_a2_intro") {
        // Upgraded Portal Gun (By Name)
        CBaseEntity@ gun_trigger = EntityList().FindByName(null, "player_near_portalgun");
        if (gun_trigger !is null) {
            SafeAddOutput(gun_trigger, "OnStartTouch", "InitCmd", "Command", "PrintItem Upgraded Portal Gun", 0.0f, 1);
        }
        // Upgraded Portal Gun (Backup - by Vector)
        AddEntityOutputScriptAtPos(Vector(-360, 440, -10680), "trigger_once", "OnStartTouch", "PrintItem Upgraded Portal Gun", 0.0f, 1);
        
    } else if (current_map == "sp_a2_trust_fling") {
        // Remplacement magique de la boîte et de la bouteille
        PreventPickupForModel("food_can_open.mdl");
        PreventPickupForModel("water_bottle.mdl");
        } else if (current_map == "sp_a3_transition01") {
        CBaseEntity@ potatos_btn = EntityList().FindByName(null, "sphere_entrance_potatos_button");
        if (potatos_btn !is null) {
            // On envoie les DEUX commandes à la console en même temps
            SafeAddOutput(potatos_btn, "OnPressed", "InitCmd", "Command", "PrintItem PotatOS; RemovePotatosFromGun", 0.0f, -1);
            
            potatos_btn.FireInput("Unlock", Variant(), 1.0f, null, null, 0);
        }
    } else if (current_map == "sp_a2_laser_intro") {
        CBaseEntity@ cmd = EntityList().FindByName(null, "InitCmd");
        if (cmd !is null) {
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
                    bool hParent = false;
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

dictionary screen_names;
        array<string> checked_screens;

        void InitMonitorData() {
            // Sécurité : on ne remplit le dictionnaire que s'il est vide
            if (!screen_names.isEmpty()) return;

            dictionary sp_a4_tb_intro; sp_a4_tb_intro.set("monitor1-relay_break", "sp_a4_tb_intro");
            screen_names.set("sp_a4_tb_intro", sp_a4_tb_intro);

            dictionary sp_a4_tb_trust_drop; sp_a4_tb_trust_drop.set("monitor1-relay_break", "sp_a4_tb_trust_drop");
            screen_names.set("sp_a4_tb_trust_drop", sp_a4_tb_trust_drop);

            dictionary sp_a4_tb_wall_button; sp_a4_tb_wall_button.set("wheatley_monitor-relay_break", "sp_a4_tb_wall_button");
            screen_names.set("sp_a4_tb_wall_button", sp_a4_tb_wall_button);

            dictionary sp_a4_tb_polarity; sp_a4_tb_polarity.set("monitor1-relay_break", "sp_a4_tb_polarity");
            screen_names.set("sp_a4_tb_polarity", sp_a4_tb_polarity);

            dictionary sp_a4_tb_catch; 
            sp_a4_tb_catch.set("monitor1-relay_break", "sp_a4_tb_catch 1");
            sp_a4_tb_catch.set("monitor2-relay_break", "sp_a4_tb_catch 2");
            screen_names.set("sp_a4_tb_catch", sp_a4_tb_catch);

            dictionary sp_a4_stop_the_box; sp_a4_stop_the_box.set("wheatley_monitor-relay_break", "sp_a4_stop_the_box");
            screen_names.set("sp_a4_stop_the_box", sp_a4_stop_the_box);

            dictionary sp_a4_laser_catapult; sp_a4_laser_catapult.set("wheatley_monitor_1-relay_break", "sp_a4_laser_catapult");
            screen_names.set("sp_a4_laser_catapult", sp_a4_laser_catapult);

            dictionary sp_a4_laser_platform; sp_a4_laser_platform.set("wheatley_monitor_1-relay_break", "sp_a4_laser_platform");
            screen_names.set("sp_a4_laser_platform", sp_a4_laser_platform);

            dictionary sp_a4_speed_tb_catch; sp_a4_speed_tb_catch.set("wheatley_monitor-relay_break", "sp_a4_speed_tb_catch");
            screen_names.set("sp_a4_speed_tb_catch", sp_a4_speed_tb_catch);

            dictionary sp_a4_jump_polarity; sp_a4_jump_polarity.set("wheatley_monitor_1-relay_break", "sp_a4_jump_polarity");
            screen_names.set("sp_a4_jump_polarity", sp_a4_jump_polarity);

            dictionary sp_a4_finale3; sp_a4_finale3.set("wheatley_screen-relay_break", "sp_a4_finale3");
            screen_names.set("sp_a4_finale3", sp_a4_finale3);
        }

void AddWheatleyMonitorBreakCheck() {
            InitMonitorData(); 

            string map_name = current_map;
            ArchipelagoLog("AP DEBUG: Running check for map: '" + map_name + "'");

            if (!screen_names.exists(map_name)) {
                ArchipelagoLog("AP DEBUG: Map '" + map_name + "' NOT found in dictionary.");
                return;
            }

            dictionary@ map_screens;
            screen_names.get(map_name, @map_screens);

            if (map_screens is null) return;

            CBaseEntity@ relay = null;
            while ((@relay = EntityList().FindByClassname(relay, "logic_relay")) !is null) {
                string name = relay.GetEntityName();

                if (map_screens.exists(name)) {
                    string check_name;
                    map_screens.get(name, check_name);

                    // --- 1. OUTPUT SQUIRREL (Le Printl) ---
                    string scriptCode = "printl(\"monitor_break:" + check_name + "\")";
                    string payloadPrint = "worldspawn\x1BRunScriptCode\x1B" + scriptCode + "\x1B0\x1B-1";
                    relay.KeyValue("OnTrigger", payloadPrint);

                    // --- 2. OUTPUT ANGELSCRIPT (La Téléportation) ---
                    // On utilise InitCmd pour lancer une commande custom "AP_WarpMonitor" avec un délai de 0.1s
                    string payloadWarp = "InitCmd\x1BCommand\x1BWarpMonitor " + check_name + "\x1B0.1\x1B-1";
                    relay.KeyValue("OnTrigger", payloadWarp);

                    string payloadSkin = name + "_holo\x1BSkin\x1B4\x1B0.1\x1B-1";
                    relay.KeyValue("OnTrigger", payloadSkin);

                    int skin = 0;
                    uint count = checked_screens.length();
                    for (uint i = 0; i < count; i++) {
                        if (checked_screens.opIndex(i) == check_name) {
                            skin = 4;
                            break;
                        }
                    }

                    // Calcul de l'offset local pour l'hologramme
                    QAngle angles = relay.GetAbsAngles();
                    float forwardOffset = 0.0f; 
                    float rightOffset = -20.0f;
                    float upOffset = 50.0f;

                    Vector forwardVec = Legacy::AnglesToForward(angles);
                    Vector rightVec = Legacy::AnglesToRight(angles);
                    Vector upVec = Legacy::AnglesToUp(angles);

                    Vector finalPos = relay.GetAbsOrigin() + 
                                      (forwardVec * forwardOffset) + 
                                      (rightVec * rightOffset) + 
                                      (upVec * upOffset);

                    Legacy::CreateAPHologram(finalPos, angles, 1.0f, null, "", skin, name + "_holo");
                    
                    Msgl("AP: Attached check '" + check_name + "' to relay '" + name + "'");
                }
            }
        }

/**
 * HandleMonitorWarp - Checks for specific monitor IDs that should trigger a player teleport.
 */
void HandleMonitorWarp(string monitorID) {
    CBaseEntity@ player = EntityList().FindByClassname(null, "player");
    if (player is null) return;

    Vector targetPos;
    QAngle targetAng;
    bool shouldWarp = false;

    if (monitorID == "sp_a4_tb_trust_drop") {
        targetPos = Vector(317, 1154, 800);
        targetAng = QAngle(0, -90, 0);
        shouldWarp = true;
    } else if (monitorID == "sp_a4_tb_catch 1") {
        // Changement : on évite le 0.0 absolu qui peut bugger sur certaines maps
        targetPos = Vector(10.0, -1260.0, -80.0); 
        targetAng = QAngle(0, 90, 0);
        shouldWarp = true;
    } else if (monitorID == "sp_a4_finale3") {
        targetPos = Vector(7, -235, -173);
        targetAng = QAngle(0, 180, 0);
        shouldWarp = true;
    }

if (shouldWarp) {
        CBaseEntity@ cam = util::CreateEntityByName("point_viewcontrol");
        if (cam !is null) {
            cam.SetAbsOrigin(targetPos);
            cam.SetAbsAngles(targetAng);
            cam.KeyValue("spawnflags", "140"); // 4 (Freeze) + 8 (Infinite) + 128 (All Players)
            cam.Spawn();

            Variant empty;
            
            // 1. On prend le contrôle de la vue
            cam.FireInput("Enable", empty, 0.0f, player, player);
            
            // 2. On téléporte le joueur sur la caméra (Position + Vue !)
            cam.FireInput("TeleportToView", empty, 0.02f, player, player);
            
            // 3. On rend le contrôle au joueur
            cam.FireInput("Disable", empty, 0.1f, player, player);
            
            // 4. On nettoie l'entité
            cam.FireInput("Kill", empty, 0.2f, null, null);
            
            // Sécurité physique
            player.SetAbsVelocity(Vector(0, 0, 0));
        }
    }
}

void RemoveGel(Vector position, string filter = "", string object_name = "") {
        float radius = 64.0f; 
        CBaseEntity@ ent = null;
        bool found = false;

        // 1. PRIORITÉ : Recherche par nom (pour les entités logiques sans volume)
        if (object_name != "" && object_name != "null") {
            @ent = EntityList().FindByName(null, object_name);
            if (ent !is null) {
                if ((ent.GetAbsOrigin() - position).Length() < 128.0f) {
                    found = true;
                }
            }
        }

        // 2. FALLBACK : Recherche par sphère (si le nom n'a pas suffi)
        if (!found) {
            @ent = null; 
            while ((@ent = EntityList().FindInSphere(ent, position, radius)) !is null) {
                string className = ent.GetClassname();
                string targetName = ent.GetEntityName();

                bool classMatch = (filter == "" || filter == "null" || className == filter);
                bool nameMatch = (object_name == "" || object_name == "null" || targetName == object_name);

                if (classMatch && nameMatch) {
                    found = true;
                    break; 
                }
            }
        }

        // 3. EXÉCUTION AVEC LE SYSTÈME D'OVERRIDES
        if (found && ent !is null) {
            // RÉCUPÉRATION DU NOM DE L'ENTITÉ
            string originalName = ent.GetEntityName();
            if (originalName == "" || originalName == "null") {
                originalName = ent.GetClassname();
            }

            string holoName = originalName + "_holo";

            // --- LECTURE DES RÈGLES (isGel s'appliquera ici) ---
            Vector hPos(0, 0, 0);
            QAngle hAng(0, 0, 0);
            int hSkin = 4;
            float hScale = 1.0f;
            bool hParent = false;
            bool hAbs = false;

            Legacy::GetHologramVisualOverrides(ent, hPos, hAng, hSkin, hScale, hParent, hAbs);

            // --- CALCUL DE LA POSITION MONDIALE FINALE ---
            Vector spawnPos = ent.GetAbsOrigin();
            QAngle spawnAng = ent.GetAbsAngles();
            Vector finalPos;
            QAngle finalAng;

            if (hAbs) {
                finalPos = hPos;
                finalAng = hAng;
            } else {
                // On calcule le décalage local demandé par GetHologramVisualOverrides
                finalPos = spawnPos + (Legacy::AnglesToForward(spawnAng) * hPos.x) + (Legacy::AnglesToRight(spawnAng) * -hPos.y) + (Legacy::AnglesToUp(spawnAng) * hPos.z);
                finalAng = spawnAng + hAng;
            }

            // Création de l'hologramme SANS PARENT (null) car l'entité va être détruite !
            Legacy::CreateAPHologram(finalPos, finalAng, hScale, null, "", hSkin, holoName);
            
            // Suppression de l'entité d'origine
            ent.Remove();
            
            // Note: J'ai utilisé ArchipelagoLog (ou Msg selon ce que vous préférez)
            ArchipelagoLog("AP: Replaced " + originalName + " with " + holoName + " at " + spawnPos.x + " " + spawnPos.y);
        }
    }


    void CreateClearGel(Vector position, float offset = -100.0f) {
        CBaseEntity@ gel = util::CreateEntityByName("prop_paint_bomb");
        if (gel !is null) {
            position.z += offset;
            gel.SetAbsOrigin(position);
            gel.KeyValue("paint_type", 3);
            gel.Spawn();
        }
    }

    void SpawnPaintBomb(Vector position) {
        CBaseEntity@ gel = util::CreateEntityByName("prop_paint_bomb");
        if (gel !is null) {
            gel.SetAbsOrigin(position);
            gel.Spawn();
        }
    }
} //namespace Legacy 
