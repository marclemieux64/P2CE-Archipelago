namespace Archipelago {

void MakeFaithPlateFaulty(CBaseEntity@ trigger) {
    if (trigger is null) return;
    if (trigger.GetClassname() != "trigger_catapult") return;

    string current_map = ConVarRef("host_map").GetString();
    
    // Vérification de la liste des Fling Maps
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
        Archipelago::ArchipelagoLog("[AP] No physical plate found for trigger " + trigger.GetEntityIndex() + ". Skipping.");
        return; 
    }

    // --- CRÉATION DU SABOTAGE ---
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

        SafeAddOutput(proxy, "OnTrigger", hintUid, "ShowHint", "", 0.0f, -1);
        SafeAddOutput(proxy, "OnTrigger", sndUid, "PlaySound", "", 0.0f, -1);
        SafeAddOutput(proxy, "OnTrigger", targetPlateName, "Skin", "1", 0.0f, -1);
        SafeAddOutput(proxy, "OnTrigger", targetPlateName, "Skin", "0", 0.5f, -1);
    }

    // --- CRÉATION DE L'HOLOGRAMME CORRIGÉ ---
    Vector hPos(0, 0, 0);
    QAngle hAng(0, 0, 0);
    int hSkin = 4;
    float hScale = 0.66f;
    bool hParent = true;
    bool hAbs = false;

    Archipelago::GetHologramVisualOverrides(targetPlate, hPos, hAng, hSkin, hScale, hParent, hAbs);
    
    Vector forward, right, up;
    AngleVectors(targetPlate.GetAbsAngles(), forward, right, up);
    Vector finalPos = targetPlate.GetAbsOrigin() + (forward * hPos.x) + (right * hPos.y) + (up * hPos.z);
    QAngle finalAng = hAbs ? hAng : (targetPlate.GetAbsAngles() + hAng);

    Vector spawnPos = targetPlate.GetAbsOrigin();
    string holoName = targetPlateName + "_" + int(spawnPos.x) + "_" + int(spawnPos.y) + "_" + int(spawnPos.z) + "_holo";

    // ÉTAPE CRUCIALE : On passe 'null' comme parent initial pour figer les coordonnées MONDIALES réelles
    CBaseEntity@ holoEnt = Archipelago::CreateAPHologram(finalPos, finalAng, hScale, null, "", hSkin, holoName);

    // ÉTAPE D'ANCRAGE : On lie l'objet à chaud avec préservation stricte de la matrice du monde
    if (holoEnt !is null && targetPlate !is null) {
        Variant v;
        v.SetEntity(targetPlate);
        holoEnt.FireInput("SetParent", v, 0.01f, targetPlate, holoEnt);
        
        // Soudure sur l'attachement d'os d'animation mobile
        Variant vOpt;
        vOpt.SetString("panel_attach");
        holoEnt.FireInput("SetParentAttachmentMaintainOffset", vOpt, 0.02f, targetPlate, holoEnt);
    }

    // Suppression du trigger original en dernier
    trigger.Remove();
    Archipelago::ArchipelagoLog("[AP] Faith Plate sabotaged with fixed world-aligned Holo: " + holoName);
}

} // namespace Archipelago