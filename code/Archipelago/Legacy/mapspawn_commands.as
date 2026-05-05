// =============================================================
// ARCHIPELAGO LEGACY SERVER COMMANDS
// =============================================================
// Wrappers for functions in mapspawn.as to allow console execution.
// =============================================================

[ServerCommand("DeleteEntity", "Legacy DeleteEntity command")]
void DeleteEntityLegacyCmd(const CommandArgs@ args) {
    if (args.ArgC() < 2) return;
    string target = args.Arg(1);
    bool create_holo = (args.ArgC() > 2) ? (args.Arg(2) == "1") : true;
    DeleteEntity(target, create_holo);
}

[ServerCommand("DisablePortalGun", "Legacy DisablePortalGun command")]
void DisablePortalGunLegacyCmd(const CommandArgs@ args) {
    if (args.ArgC() < 3) return;
    bool blue = (args.Arg(1) == "1");
    bool orange = (args.Arg(2) == "1");
    DisablePortalGun(blue, orange);
}

[ServerCommand("DisableEntityPickup", "Legacy DisableEntityPickup command")]
void DisableEntityPickupLegacyCmd(const CommandArgs@ args) {
    if (args.ArgC() < 2) return;
    DisableEntityPickup(args.Arg(1));
}

[ServerCommand("DisableEntityPhysics", "Legacy DisableEntityPhysics command")]
void DisableEntityPhysicsLegacyCmd(const CommandArgs@ args) {
    if (args.ArgC() < 2) return;
    DisableEntityPhysics(args.Arg(1));
}

[ServerCommand("AddFloorButtonFrame", "Legacy AddFloorButtonFrame command")]
void AddFloorButtonFrameLegacyCmd(const CommandArgs@ args) {
    if (args.ArgC() < 2) return;
    AddFloorButtonFrame(args.Arg(1));
}

[ServerCommand("AddButtonFrame", "Legacy AddButtonFrame command")]
void AddButtonFrameLegacyCmd(const CommandArgs@ args) {
    if (args.ArgC() < 2) return;
    AddButtonFrame(args.Arg(1));
}

[ServerCommand("DeleteCoreOnOutput", "Legacy DeleteCoreOnOutput command")]
void DeleteCoreOnOutputLegacyCmd(const CommandArgs@ args) {
    if (args.ArgC() < 4) return;
    DeleteCoreOnOutput(args.Arg(1), args.Arg(2), args.Arg(3));
}

[ServerCommand("BlockWheatleyFight", "Legacy BlockWheatleyFight command")]
void BlockWheatleyFightLegacyCmd(const CommandArgs@ args) {
    BlockWheatleyFight();
}

[ServerCommand("RemovePotatOS", "Legacy RemovePotatOS command")]
void RemovePotatOSLegacyCmd(const CommandArgs@ args) {
    RemovePotatOS();
}

[ServerCommand("RemovePotatosFromGun", "Legacy RemovePotatosFromGun command")]
void RemovePotatosFromGunLegacyCmd(const CommandArgs@ args) {
    RemovePotatosFromGun();
}

[ServerCommand("SetCheckedScreens", "Legacy SetCheckedScreens command")]
void SetCheckedScreensLegacyCmd(const CommandArgs@ args) {
    // Note: This expects a simple list of strings separated by spaces
    array<string> screens;
    for (int i = 1; i < args.ArgC(); i++) {
        screens.insertLast(args.Arg(i));
    }
    SetCheckedScreens(screens);
}

[ServerCommand("AddWheatleyMonitorBreakCheck", "Legacy AddWheatleyMonitorBreakCheck command")]
void AddWheatleyMonitorBreakCheckLegacyCmd(const CommandArgs@ args) {
    AddWheatleyMonitorBreakCheck();
}

[ServerCommand("AddVitrifiedDoorChecks", "Legacy AddVitrifiedDoorChecks command")]
void AddVitrifiedDoorChecksLegacyCmd(const CommandArgs@ args) {
    AddVitrifiedDoorChecks();
}

[ServerCommand("CreateAPButton", "Legacy CreateAPButton command")]
void CreateAPButtonLegacyCmd(const CommandArgs@ args) {
    if (args.ArgC() < 6) return;
    string name = args.Arg(1);
    Vector pos(args.Arg(2).toFloat(), args.Arg(3).toFloat(), args.Arg(4).toFloat());
    QAngle ang(args.Arg(5).toFloat(), args.Arg(6).toFloat(), args.Arg(7).toFloat());
    float scale = (args.ArgC() > 8) ? args.Arg(8).toFloat() : 1.0f;
    int skin = (args.ArgC() > 9) ? args.Arg(9).toInt() : 0;
    CreateAPButton(name, pos, ang, scale, skin);
}

[ServerCommand("AttachHologramToEntity", "Legacy AttachHologramToEntity command")]
void AttachHologramToEntityLegacyCmd(const CommandArgs@ args) {
    if (args.ArgC() < 5) return;
    string ent = args.Arg(1);
    string attachment = args.Arg(2);
    float scale = args.Arg(3).toFloat();
    float offset = args.Arg(4).toFloat();
    int skin = (args.ArgC() > 5) ? args.Arg(5).toInt() : 0;
    AttachHologramToEntity(ent, attachment, scale, offset, skin);
}

[ServerCommand("RemoveGel", "Legacy RemoveGel command")]
void RemoveGelLegacyCmd(const CommandArgs@ args) {
    if (args.ArgC() < 4) return;
    float x = args.Arg(1).toFloat();
    float y = args.Arg(2).toFloat();
    float z = args.Arg(3).toFloat();
    string type = (args.ArgC() > 4) ? args.Arg(4) : "";
    string name = (args.ArgC() > 5) ? args.Arg(5) : "";
    RemoveGel(x, y, z, type, name);
}

[ServerCommand("CreateClearGel", "Legacy CreateClearGel command")]
void CreateClearGelLegacyCmd(const CommandArgs@ args) {
    if (args.ArgC() < 4) return;
    Vector pos(args.Arg(1).toFloat(), args.Arg(2).toFloat(), args.Arg(3).toFloat());
    float offset = (args.ArgC() > 4) ? args.Arg(4).toFloat() : -100.0f;
    CreateClearGel(pos, offset);
}

[ServerCommand("PrintMapName", "Legacy PrintMapName command")]
void PrintMapNameLegacyCmd(const CommandArgs@ args) {
    PrintMapName();
}

[ServerCommand("FinishedMap", "Legacy FinishedMap command")]
void FinishedMapLegacyCmd(const CommandArgs@ args) {
    PrintMapComplete();
}

[ServerCommand("ExitToMenu", "Legacy ExitToMenu command")]
void ExitToMenuLegacyCmd(const CommandArgs@ args) {
    ExitToMenu();
}

[ServerCommand("InciniratorDisablePortalGun", "Legacy InciniratorDisablePortalGun command")]
void InciniratorDisablePortalGunLegacyCmd(const CommandArgs@ args) {
    InciniratorDisablePortalGun();
}

[ServerCommand("DoMapSpecificSetup", "Legacy DoMapSpecificSetup command")]
void DoMapSpecificSetupLegacyCmd(const CommandArgs@ args) {
    DoMapSpecificSetup();
}

[ServerCommand("CreateMapSpecificHolos", "Legacy CreateMapSpecificHolos command")]
void CreateMapSpecificHolosLegacyCmd(const CommandArgs@ args) {
    CreateMapSpecificHolos();
}

[ServerCommand("RunDelayedInit", "Legacy full delayed initialization command")]
void RunDelayedInitLegacyCmd(const CommandArgs@ args) {
    bool was_unknown = (current_map == "unknown" || current_map == "");
    UpdateInternalMapName();
    
    if (was_unknown && current_map != "unknown" && current_map != "") {
        ArchipelagoLog("map_name:" + current_map);
    }
    
    DoMapSpecificSetup();
    CreateMapSpecificHolos();
}

[ServerCommand("RefreshMapName", "Prints map name for client")]
void RefreshMapNameLegacyCmd(const CommandArgs@ args) {
    UpdateInternalMapName();
    ArchipelagoLog("map_name:" + current_map);
}

[ServerCommand("ap_report_map", "UI-driven map report")]
void ReportMapCmd(const CommandArgs@ args) {
    if (args.ArgC() < 2) return;
    current_map = args.Arg(1);
    ArchipelagoLog("map_name:" + current_map);
    
    // Also trigger initialization since we definitely have a map now
    DoMapSpecificSetup();
    CreateMapSpecificHolos();
}
[ServerCommand("PrintMonitor", "Legacy PrintMonitor command")]
void PrintMonitorLegacyCmd(const CommandArgs@ args) {
    if (args.ArgC() < 2) return;
    string monitor = args.Arg(1);
    // Revert internal dots back to spaces for the Python client
    monitor = monitor.replace(".", " ");
    ArchipelagoLog("monitor_break:" + monitor);
}

[ServerCommand("PrintItem", "Legacy PrintItem command")]
void PrintItemLegacyCmd(const CommandArgs@ args) {
    if (args.ArgC() < 2) return;
    string item = args.Arg(1);
    item = item.replace(".", " ");
    ArchipelagoLog("item_collected:" + item);
}

[ServerCommand("PrintButton", "Legacy PrintButton command")]
void PrintButtonLegacyCmd(const CommandArgs@ args) {
    if (args.ArgC() < 2) return;
    string button = args.Arg(1);
    button = button.replace(".", " ");
    ArchipelagoLog("button_check:" + button);
}
