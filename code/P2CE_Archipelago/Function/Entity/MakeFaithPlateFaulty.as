namespace Archipelago {

void MakeFaithPlateFaulty(CBaseEntity@ trigger) {
    if (trigger is null) return;
    if (trigger.GetClassname() != "trigger_catapult") return;

    string current_map = ConVarRef("host_map").GetString();
    
    // Vérification de la liste des Fling Maps (protection des triggers système)
    for (uint f = 0; f < scripted_fling_levels.length(); f++) {
        if (scripted_fling_levels[f] == current_map) {
            Archipelago::ArchipelagoLog("[AP] Fling Map detected: Protection active for " + current_map);
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
        Archipelago::ArchipelagoLog("[AP] No physical plate found for trigger " + trigger.GetEntityIndex() + ". Skipping.");
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
    Archipelago::ArchipelagoLog("[AP] Faith Plate sabotaged: " + targetPlateName);
}


// La fonction de base
bool portalgun_2_disabled = false;

} // namespace Archipelago
