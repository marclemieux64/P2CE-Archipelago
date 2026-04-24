// =============================================================
// ARCHIPELAGO SERVER COMMANDS 
// =============================================================

// -------------------------------------------------------------
// UTILITY COMMANDS 
// -------------------------------------------------------------

[ServerCommand("GetMapName", "Prints the current map name")]
void GetMapNameCmd(const CommandArgs@ args) {
    UpdateInternalMapName();
    Msgl("map_name:" + current_map);
}

[ServerCommand("ap_set_current_map", "Internal - Sets the current map name from VScript")]
void APSetCurrentMapCmd(const CommandArgs@ args) {
    if (args !is null && args.ArgC() > 1) {
        current_map = args.Arg(1);
        Msgl("AP-Mod: Map name confirmed from VScript -> " + current_map);
    }
}

[ServerCommand("ap_print_item", "Prints collected item")]
void APPrintItemCmd(const CommandArgs@ args) {
    if (args is null) return;
    string raw = args.GetCommandString();
    uint spaceIdx = raw.locate(" ");
    if (spaceIdx != uint(-1)) {
        string item = raw.substr(int(spaceIdx) + 1).trim();
        Msgl("item_collected:" + item);
    }
}

[ServerCommand("DeleteEntity", "Deletes an entity by name, class, or model")]
void DeleteEntityCmd(const CommandArgs@ args) {
    if (args is null || args.ArgC() < 2) return;
    string target = args.Arg(1);
    bool holo = (args.ArgC() > 2) ? (args.Arg(2) == "1" || args.Arg(2) == "true") : true;
    float scale = (args.ArgC() > 3) ? args.Arg(3).toFloat() : 0.7f;
    DeleteEntity(target, holo, scale);
}

[ServerCommand("ap_finalize_delete", "Internal - Finalizes a delayed entity deletion")]
void APFinalizeDeleteCmd(const CommandArgs@ args) {
    if (args is null || args.ArgC() < 2) return;
    string target = args.Arg(1);
    bool holo = (args.ArgC() > 2) ? (args.Arg(2) == "1" || args.Arg(2) == "true") : true;
    float scale = (args.ArgC() > 3) ? args.Arg(3).toFloat() : 0.7f;
    DeleteEntity(target, holo, scale, true); // Force bypass of delay
}

[ServerCommand("DisableEntityPickup", "Disables pickup for an entity by name, class, or model")]
void DisableEntityPickupCmd(const CommandArgs@ args) {
    if (args is null || args.ArgC() < 2) return;
    DisableEntityPickup(args.Arg(1));
}

[ServerCommand("DisableEntity", "Safely disables an entity via inputs")]
void DisableEntityCmd(const CommandArgs@ args) {
    if (args is null || args.ArgC() < 2) return;
    DisableEntity(args.Arg(1));
}


[ServerCommand("DeleteCoreOnOutput", "Triggers core deletion on entity output (core_name, target_name, output)")]
void DeleteCoreOnOutputCmd(const CommandArgs@ args) {
    if (args !is null && args.ArgC() >= 4) DeleteCoreOnOutput(args.Arg(1), args.Arg(2), args.Arg(3));
}

[ServerCommand("DisablePortalGun", "Disables blue/orange portal firing (1=blue, 2=orange)")]
void DisablePortalGunCmd(const CommandArgs@ args) {
    if (args is null || args.ArgC() < 2) return;
    bool blue = false;
    bool orange = false;
    bool delayed = (args.ArgC() > 3 && args.Arg(3) == "1");

    for (int i = 1; i < args.ArgC(); i++) {
        string a = args.Arg(i);
        if (a == "1" || a == "blue") blue = true;
        if (a == "2" || a == "orange") orange = true;
    }
    DisablePortalGun(blue, orange, delayed);
}

[ServerCommand("ap_add_script", "Internal - Attaches a script output to an entity")]
void APAddScriptCmd(const CommandArgs@ args) {
    if (args is null || args.ArgC() < 4) return;
    string target = args.Arg(1);
    string output = args.Arg(2);
    string script = args.Arg(3);
    float delay = (args.ArgC() > 4) ? args.Arg(4).toFloat() : 0.0f;
    int times = (args.ArgC() > 5) ? args.Arg(5).toInt() : -1;
    AddEntityOutputScript(target, output, script, delay, times);
}

[ServerCommand("ap_add_script_at_pos", "Internal - Attaches script output to entity at position")]
void APAddScriptAtPosCmd(const CommandArgs@ args) {
    if (args is null || args.ArgC() < 6) return;
    Vector pos = Vector(args.Arg(1).toFloat(), args.Arg(2).toFloat(), args.Arg(3).toFloat());
    string cls = args.Arg(4);
    string output = args.Arg(5);
    string script = args.Arg(6);
    float delay = (args.ArgC() > 7) ? args.Arg(7).toFloat() : 0.0f;
    int times = (args.ArgC() > 8) ? args.Arg(8).toInt() : -1;
    AddEntityOutputScriptAtPos(pos, cls, output, script, delay, times);
}

[ServerCommand("ap_debug_triggers", "Lists all relays and triggers in the map for debugging")]
void APDebugTriggersCmd(const CommandArgs@ args) {
    DebugListMapTriggers();
}

// -------------------------------------------------------------
// MAP LOGIC COMMANDS 
// -------------------------------------------------------------

[ServerCommand("ap_print_monitor", "Internal - Prints monitor break check to console")]
void APPrintMonitorCmd(const CommandArgs@ args) {
    if (args !is null && args.ArgC() > 1) {
        Msgl("monitor_break:" + args.Arg(1));
    }
}

[ServerCommand("ap_print_complete_no_exit", "Prints map complete without exiting")]
void APPrintCompleteNoExitCmd(const CommandArgs@ args) {
    PrintMapCompleteNoExit();
}

[ServerCommand("ap_print_complete", "Handles map completion and returns to menu")]
void APPrintCompleteCmd(const CommandArgs@ args) {
    PrintMapComplete();
}

[ServerCommand("ap_block_wheatley_fight", "Internal - Triggers the Wheatley fight block logic")]
void APBlockWheatleyFightCmd(const CommandArgs@ args) {
    BlockWheatleyFight();
}


[ServerCommand("ap_warp_to_menu", "Internal - Warps back to menu")]
void APWarpToMenuCmd(const CommandArgs@ args) {
    CBaseEntity@ cmdEnt = EntityList().FindByName(null, "ap_init_cmd");
    if (cmdEnt !is null) {
        Variant vCmd;
        vCmd.SetString("host_timescale 1.0");
        cmdEnt.FireInput("Command", vCmd, 0.0f, null, null, 0);
    }
    WarpToMenu();
}

[ServerCommand("ap_spawn_holos", "Manually trigger map-specific holograms")]
void ManualHoloSpawnCmd(const CommandArgs@ args) {
    UpdateInternalMapName();
    Msgl("AP-Mod: Manual holo spawn triggered for: " + current_map);
    if (current_map != "unknown" && current_map != "") {
        CreateMapSpecificHolos(current_map);
    } else {
        Msgl("AP-Mod: Failed to spawn - map name is still unknown.");
    }
}

// -------------------------------------------------------------
// BUTTON COMMANDS 
// -------------------------------------------------------------

[ServerCommand("ReportAPButton", "Routes button press")]
void ReportAPButtonCmd(const CommandArgs@ args) {
    if (args is null || args.ArgC() < 2) return;
    RunButtonScenarioCheck(args.Arg(1));
}

[ServerCommand("CreateAPButton", "Main Parser")]
void CreateAPButtonCmd(const CommandArgs@ args) {
    if (args is null) return;
    string raw = args.GetCommandString();
    uint vIdx = raw.locate("Vector");
    if (vIdx == uint(-1)) return;
    string name = raw.substr(0, int(vIdx)).replace("\x22", "").replace("'", "").replace("(", "").replace(",", "").replace("CreateAPButton", "").trim();
    array<float> c = ExtractFloats(raw.substr(int(vIdx)));
    if (c.length() < 7) return;
    SpawnAPButtonLogic(name, Vector(c[0], c[1], c[2]), QAngle(c[3], c[4], c[5]), c[6]);
}

[ServerCommand("AddButtonFrame", "Adds an AP button frame to named pedestal entities")]
void AddButtonFrameCmd(const CommandArgs@ args) {
    if (args !is null && args.ArgC() >= 2) AddButtonFrame(args.Arg(1));
}

[ServerCommand("AddFloorButtonFrame", "Adds an AP frame to floor buttons")]
void AddFloorButtonFrameCmd(const CommandArgs@ args) {
    if (args !is null && args.ArgC() >= 2) AddFloorButtonFrame(args.Arg(1));
}

[ServerCommand("RemoveButtonFrame", "Clears pedestal button AP assets")]
void RemoveButtonFrameCmd(const CommandArgs@ args) {
    RemoveAllButtonFrames();
}

[ServerCommand("RemoveFloorButtonFrame", "Clears floor button AP assets")]
void RemoveFloorButtonFrameCmd(const CommandArgs@ args) {
    RemoveAllFloorButtonFrames();
}

// -------------------------------------------------------------
// HOLOGRAM COMMANDS 
// -------------------------------------------------------------

[ServerCommand("CreateAPHologram", "Creates an AP Hologram")]
void CreateAPHologramCmd(const CommandArgs@ args) {
    if (args is null || args.ArgC() < 4) return;
    string raw = args.GetCommandString();
    array<float> f = ExtractFloats(raw);
    if (f.length() < 7) return;
    CreateAPHologram(Vector(f[0], f[1], f[2]), QAngle(f[3], f[4], f[5]), f[6], "", "", 0);
}

[ServerCommand("AttachHologramToEntity", "Attaches a hologram to named entities")]
void AttachHologramToEntityCmd(const CommandArgs@ args) {
    if (args is null || args.ArgC() < 2) return;
    string search = args.Arg(1);
    string attachment = (args.ArgC() >= 3) ? args.Arg(2) : "";
    float scale = (args.ArgC() >= 4) ? args.Arg(3).toFloat() : 1.0f;
    float offset = (args.ArgC() >= 5) ? args.Arg(4).toFloat() : 20.0f;
    int skin = (args.ArgC() >= 6) ? args.Arg(5).toInt() : 0;
    AttachHologramToEntity(search, attachment, scale, offset, skin);
}

// -------------------------------------------------------------
// TRAP COMMANDS 
// -------------------------------------------------------------

[ServerCommand("CubeConfettiTrap", "Triggers cube confetti trap")]
void CubeConfettiTrapCmd(const CommandArgs@ args) {
    TriggerCubeConfettiTrap();
}




[ServerCommand("MotionBlurTrap", "Triggers motion blur trap")]
void MotionBlurTrapCmd(const CommandArgs@ args) {
    TriggerMotionBlurTrap();
}

[ServerCommand("SlipperyFloorTrap", "Triggers slippery floor trap")]

void SlipperyFloorTrapCmd(const CommandArgs@ args) {
    TriggerSlipperyFloorTrap();
}

[ServerCommand("FizzlePortalTrap", "Triggers fizzle portal trap")]
void FizzlePortalTrapCmd(const CommandArgs@ args) {
    TriggerFizzlePortalTrap();
}

[ServerCommand("DialogTrap", "Triggers dialog trap")]
void DialogTrapCmd(const CommandArgs@ args) {
    if (args !is null && args.ArgC() >= 2) TriggerDialogTrap(args.Arg(1)); else TriggerDialogTrap();
}

[ServerCommand("ButterFingersTrap", "Triggers butter fingers trap")]
void ButterFingersTrapCmd(const CommandArgs@ args) {
    TriggerButterFingersTrap();
}

[ServerCommand("ap_butterfingers_tick", "Internal")]
void APButterFingersTickCmd(const CommandArgs@ args) {
    RunButterFingersTick();
}

[ServerCommand("RemovePotatosFromGun", "Removes PotatOS from the player's portal gun")]
void RemovePotatosFromGunCmd(const CommandArgs@ args) {
    RemovePotatosFromGun();
}

[ServerCommand("RestorePotatosToGun", "Restores PotatOS to the player's portal gun")]
void RestorePotatosToGunCmd(const CommandArgs@ args) {
    RestorePotatosToGun();
}




[ServerCommand("AttachDeathTrigger", "Activates DeathLink health monitoring")]
void AttachDeathTriggerCmd(const CommandArgs@ args) {
    AttachDeathTrigger();
}






