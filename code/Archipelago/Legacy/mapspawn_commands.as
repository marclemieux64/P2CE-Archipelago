// =============================================================
// ARCHIPELAGO LEGACY MAPSPAWN COMMANDS
// =============================================================

namespace Legacy {

[ServerCommand("DeleteEntity", "Legacy DeleteEntity command")]
void DeleteEntityLegacyCmd(const CommandArgs@ args) {
    if (args.ArgC() < 2) return;
    string target = args.Arg(1);
    bool create_holo = (args.ArgC() > 2) ? (args.Arg(2) == "1") : true;
    Legacy::ArchipelagoLog("[AP RECV] DeleteEntity: " + target + " (holo: " + create_holo + ")");
    Legacy::DeleteEntity(target, create_holo);
}

[ServerCommand("DisablePortalGun", "Legacy DisablePortalGun command")]
void DisablePortalGunLegacyCmd(const CommandArgs@ args) {
    if (args.ArgC() < 3) return;
    bool blue = (args.Arg(1) == "1");
    bool orange = (args.Arg(2) == "1");
    Legacy::ArchipelagoLog("[AP RECV] DisablePortalGun: Blue=" + blue + " Orange=" + orange);
    Legacy::DisablePortalGun(blue, orange);
}

[ServerCommand("DisableEntityPickup", "Legacy DisableEntityPickup command")]
void DisableEntityPickupLegacyCmd(const CommandArgs@ args) {
    if (args.ArgC() < 2) return;
    Legacy::DisableEntityPickup(args.Arg(1));
}

[ServerCommand("DisableEntityPhysics", "Legacy DisableEntityPhysics command")]
void DisableEntityPhysicsLegacyCmd(const CommandArgs@ args) {
    if (args.ArgC() < 2) return;
    Legacy::DisableEntityPhysics(args.Arg(1));
}

[ServerCommand("AddFloorButtonFrame", "Legacy AddFloorButtonFrame command")]
void AddFloorButtonFrameLegacyCmd(const CommandArgs@ args) {
    if (args.ArgC() < 2) return;
    Legacy::AddFloorButtonFrame(args.Arg(1));
}

[ServerCommand("AddButtonFrame", "Legacy AddButtonFrame command")]
void AddButtonFrameLegacyCmd(const CommandArgs@ args) {
    if (args.ArgC() < 2) return;
    Legacy::AddButtonFrame(args.Arg(1));
}

[ServerCommand("AddTractorBeamFrame", "Legacy AddButtonFrame command")]
void AddTractorBeamFrameLegacyCmd(const CommandArgs@ args) {
    if (args.ArgC() < 2) return;
    Legacy::AddTractorBeamFrame(args.Arg(1));
}

[ServerCommand("MakeFaithPlateFaulty", "Legacy MakeFaithPlateFaulty command")]
void MakeFaithPlateFaultyLegacyCmd(const CommandArgs@ args) {
    if (args.ArgC() < 2) return;

    // On récupère le nom passé par la console
    string entName = args.Arg(1);

    // On cherche l'entité correspondante
    CBaseEntity@ target = EntityList().FindByName(null, entName);
    if (target is null) @target = EntityList().FindByClassname(null, entName);

    // Si on l'a trouvée, on lance la fonction
    if (target !is null) {
        Legacy::MakeFaithPlateFaulty(target);
    }
}

[ServerCommand("DeleteCoreOnOutput", "Legacy DeleteCoreOnOutput command")]
void DeleteCoreOnOutputLegacyCmd(const CommandArgs@ args) {
    if (args.ArgC() < 4) return;
    Legacy::DeleteCoreOnOutput(args.Arg(1), args.Arg(2), args.Arg(3));
}

[ServerCommand("BlockWheatleyFight", "Legacy BlockWheatleyFight command")]
void BlockWheatleyFightLegacyCmd(const CommandArgs@ args) {
    Legacy::BlockWheatleyFight();
}

[ServerCommand("RemovePotatOS", "Legacy RemovePotatOS command")]
void RemovePotatOSLegacyCmd(const CommandArgs@ args) {
    Legacy::RemovePotatOS();
}


[ServerCommand("FinishedMap", "Triggers map completion logic")]
void FinishedMapLegacyCmd(const CommandArgs@ args) {
    Legacy::ArchipelagoLog("COMMAND: FinishedMap triggered!");
    Legacy::PrintMapComplete();
}

[ServerCommand("PrintCompleteNoExit", "Prints completion without warping")]
void PrintCompleteNoExitLegacyCmd(const CommandArgs@ args) {
    Legacy::PrintMapCompleteNoExit();
}

[ServerCommand("WarpToMenu", "Internal - Warps back to menu")]
void WarpToMenuLegacyCmd(const CommandArgs@ args) {
    Legacy::WarpToMenu();
}

[ServerCommand("RunDelayedInit", "Internal - Runs the delayed initialization sequence")]
void RunDelayedInitLegacyCmd(const CommandArgs@ args) {
    // 1. On met à jour le nom interne une seule fois
    Legacy::UpdateInternalMapName();

    // 2. Validation
    if (::current_map == "unknown" || ::current_map == "") {
        Legacy::ArchipelagoLog("DelayedInit: Map name unknown, skipping.");
        return;
    }

    // 3. Setup (Une seule fois avec le nom validé)
    Legacy::DoMapSpecificSetup();
    Legacy::CreateCompleteLevelAlertHook(::current_map);
    Legacy::CreateMapSpecificHolos();
    
    Legacy::ArchipelagoLog("DelayedInit complete for: " + ::current_map);
}
[ServerCommand("AddScript", "Connects an entity output to a console command")]
void AddScriptLegacyCmd(const CommandArgs@ args) {
    if (args.ArgC() < 4) return;
    string target = args.Arg(1);
    string output = args.Arg(2);
    string cmd = args.Arg(3);
    float delay = (args.ArgC() > 4) ? args.Arg(4).toFloat() : 0.0f;
    int maxTimes = (args.ArgC() > 5) ? args.Arg(5).toInt() : -1;
    
    array<CBaseEntity@> ents = Legacy::FindEntities(target);
    for (uint i = 0; i < ents.length(); i++) {
        Legacy::SafeAddOutput(ents[i], output, "InitCmd", "Command", cmd, delay, maxTimes);
    }
}

[ServerCommand("ShowStatus", "Manually show the map status HUD")]
void ShowStatusLegacyCmd(const CommandArgs@ args) {
    Legacy::UpdateInternalMapName();
    Legacy::CallVScript("SendToPanorama(\"ArchipelagoMapNameUpdated\", \"" + ::current_map + "|1\")");
}

[ServerCommand("RefreshMapName", "Forces a map name update to Panorama")]
void RefreshMapNameLegacyCmd(const CommandArgs@ args) {
    ::current_map = ""; 
    Legacy::UpdateInternalMapName();
}

[ServerCommand("ArchipelagoVitrifiedFound", "Internal - Updates the local vitrified door bitmask")]
void ArchipelagoVitrifiedFoundLegacyCmd(const CommandArgs@ args) {
    if (args.ArgC() < 2) return;
    int index = args.Arg(1).toInt();
    if (index < 1 || index > 6) return;

    string bitmask = Legacy::cv_ArchipelagoVitrifiedStatus.GetString();
    if (bitmask.length() < 6) bitmask = "000000";

    string newBitmask = "";
    for (int i = 1; i <= 6; i++) {
        if (i == index) newBitmask += "1";
        else newBitmask += bitmask.substr(i-1, 1);
    }

    Legacy::cv_ArchipelagoVitrifiedStatus.SetValue(newBitmask);
    Legacy::ArchipelagoLog("[AP] Vitrified Door Found: " + index + " | New Bitmask: " + newBitmask);
}

[ServerCommand("PrintItem", "Prints collected item")]
void PrintItemLegacyCmd(const CommandArgs@ args) {
    string raw = args.GetCommandString();
    uint spaceIdx = raw.locate(" ");
    if (spaceIdx != uint(-1)) {
        string item = raw.substr(int(spaceIdx) + 1).trim();
        Legacy::ArchipelagoLog("[AP RECV] PrintItem: " + item);
        Legacy::ArchipelagoLog("item_collected:" + item);
    }
}

[ServerCommand("PrintMonitor", "Internal - Prints monitor break check to console")]
void PrintMonitorLegacyCmd(const CommandArgs@ args) {
    string raw = args.GetCommandString();
    uint spaceIdx = raw.locate(" ");
    if (spaceIdx != uint(-1)) {
        string check = raw.substr(int(spaceIdx) + 1).trim();
        check = check.replace(".", " ");
        
        if (Legacy::g_reported_monitors.find(check) >= 0) return;
        Legacy::g_reported_monitors.insertLast(check);

        Legacy::ArchipelagoLog("monitor_break:" + check);
        HandleMonitorWarp(check);
    }
}

[ServerCommand("ReportAPButton", "Logs a custom AP button press")]
void ReportAPButtonLegacyCmd(const CommandArgs@ args) {
    if (args.ArgC() < 2) return;
    Legacy::RunButtonScenarioCheck(args.Arg(1));
}

[ServerCommand("AttachHologramToEntity", "Forces a hologram to stick to a moving entity")]
void AttachHologramToEntityLegacyCmd(const CommandArgs@ args) {
    if (args.ArgC() < 6) return;
    Legacy::ArchipelagoLog("[AP RECV] AttachHologram: " + args.Arg(1));
    Legacy::AttachHologramToEntity(args.Arg(1), args.Arg(2), args.Arg(3).toFloat(), args.Arg(4).toFloat(), args.Arg(5).toInt());
}

[ServerCommand("RemovePotatosFromGun", "Removes PotatOS from the portal gun and world")]
void RemovePotatosFromGunLegacyCmd(const CommandArgs@ args) {
    Legacy::ArchipelagoLog("[AP RECV] RemovePotatosFromGun");
    Legacy::RemovePotatosFromGun();
}

/* [ServerCommand("AddWheatleyMonitorBreakCheck", "Manually triggers Wheatley monitor break check setup")]
void AddWheatleyMonitorBreakCheckLegacyCmd(const CommandArgs@ args) {
    Legacy::AddWheatleyMonitorChecks(::current_map);
} */

[ServerCommand("SetStatus", "Dummy - Deprecated")]
void SetStatusLegacyCmd(const CommandArgs@ args) {}

[ServerCommand("ap_report_map", "Dummy - Deprecated")]
void ap_report_mapLegacyCmd(const CommandArgs@ args) {}

[ServerCommand("SetCheckedScreens", "Synchronizes the list of already-broken Wheatley monitors")]
void SetCheckedScreensLegacyCmd(const CommandArgs@ args) {
    Legacy::ArchipelagoLog("[AP RECV] Syncing " + (args.ArgC() - 1) + " checked screens.");
    for (int i = 1; i < args.ArgC(); i++) {
        string screenName = args.Arg(i);
        if (Legacy::g_reported_monitors.find(screenName) < 0) {
            Legacy::g_reported_monitors.insertLast(screenName);
        }
    }
}

[ServerCommand("AddScriptAtPos", "Legacy AddScriptAtPos command")]
void AddScriptAtPosLegacyCmd(const CommandArgs@ args) {
    if (args.ArgC() < 6) return;
    Vector pos(args.Arg(1).toFloat(), args.Arg(2).toFloat(), args.Arg(3).toFloat());
    Legacy::AddEntityOutputScriptAtPos(pos, args.Arg(4), args.Arg(5), args.Arg(6), (args.ArgC() > 7 ? args.Arg(7).toFloat() : 0.0f), (args.ArgC() > 8 ? args.Arg(8).toInt() : -1));
}

[ServerCommand("CreateAPButton", "Legacy CreateAPButton command")]
void CreateAPButtonLegacyCmd(const CommandArgs@ args) {
    if (args.ArgC() < 8) return;
    string name = args.Arg(1);
    Vector pos(args.Arg(2).toFloat(), args.Arg(3).toFloat(), args.Arg(4).toFloat());
    QAngle ang(args.Arg(5).toFloat(), args.Arg(6).toFloat(), args.Arg(7).toFloat());
    float scale = (args.ArgC() > 8) ? args.Arg(8).toFloat() : 1.0f;
    int skin = (args.ArgC() > 9) ? args.Arg(9).toInt() : 0;
    
    Legacy::ArchipelagoLog("[AP RECV] CreateAPButton: " + name);
    Legacy::CreateAPButton(name, pos, ang, scale, skin);
}

[ServerCommand("RemoveGel", "Legacy RemoveGel command")]
void RemoveGelLegacyCmd(const CommandArgs@ args) {
    if (args.ArgC() < 4) return;
    Vector pos(args.Arg(1).toFloat(), args.Arg(2).toFloat(), args.Arg(3).toFloat());
    string filter = (args.ArgC() > 4) ? args.Arg(4) : "";
    string name = (args.ArgC() > 5) ? args.Arg(5) : "";
    Legacy::RemoveGel(pos, filter, name);
}

[ServerCommand("CreateClearGel", "Legacy CreateClearGel command")]
void CreateClearGelLegacyCmd(const CommandArgs@ args) {
    if (args.ArgC() < 4) return;
    Vector pos(args.Arg(1).toFloat(), args.Arg(2).toFloat(), args.Arg(3).toFloat());
    float offset = (args.ArgC() > 4) ? args.Arg(4).toFloat() : -100.0f;
    Legacy::CreateClearGel(pos, offset);
}

[ServerCommand("SpawnPaintBomb", "Legacy SpawnPaintBomb command")]
void SpawnPaintBombLegacyCmd(const CommandArgs@ args) {
    if (args.ArgC() < 4) return;
    Vector pos(args.Arg(1).toFloat(), args.Arg(2).toFloat(), args.Arg(3).toFloat());
    Legacy::SpawnPaintBomb(pos);
}

 [ServerCommand("CubeConfettiTrap", "Triggers cube confetti trap")]
void CubeConfettiTrapCmd(const CommandArgs@ args) {
    TriggerCubeConfettiTrap();
}

 [ServerCommand("MotionBlurTrap", "Triggers motion blur trap")]
void MotionBlurTrapCmd(const CommandArgs@ args) {
    float duration = (args !is null && args.ArgC() >= 2) ? args.Arg(1).toFloat() : 20.0f;
    Legacy::TriggerMotionBlurTrap(duration);
}

[ServerCommand("SlipperyFloorTrap", "Triggers slippery floor trap")]
void SlipperyFloorTrapCmd(const CommandArgs@ args) {
    float duration = (args !is null && args.ArgC() >= 2) ? args.Arg(1).toFloat() : 15.0f;
    Legacy::TriggerSlipperyFloorTrap(duration);
}

 [ServerCommand("FizzlePortalTrap", "Triggers fizzle portal trap")]
void FizzlePortalTrapCmd(const CommandArgs@ args) {
    Legacy::TriggerFizzlePortalTrap();
}

[ServerCommand("DialogTrap", "Triggers dialog trap")]
void DialogTrapCmd(const CommandArgs@ args) {
    string scene = (args !is null && args.ArgC() >= 2) ? args.Arg(1) : "";
    float duration = (args !is null && args.ArgC() >= 3) ? args.Arg(2).toFloat() : 15.0f;
    Legacy::TriggerDialogTrap(scene, duration);
}

[ServerCommand("ButterFingersTrap", "Triggers butter fingers trap")]
void ButterFingersTrapCmd(const CommandArgs@ args) {
    // Si aucun argument n'est fourni, duration sera 30.0f
    float duration = (args !is null && args.ArgC() >= 2) ? args.Arg(1).toFloat() : 30.0f;
    
    // Maintenant cette ligne compilera car Legacy::ButterFingersTrap(float) existe !
    Legacy::ButterFingersTrap(duration);
}




} // namespace Legacy
