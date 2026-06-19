// =============================================================
// ARCHIPELAGO SERVER COMMANDS
// =============================================================

// This file is used to declare server commands so python can call them via the netcon

// --- Helper Functions ---
string CleanArg(const string&in arg) {
    return arg.replace("[", "").replace("]", "").replace("\"", "").replace(",", "");
}

// =============================================================
// --- CORE ---
// =============================================================

[ServerCommand("RunDelayedInit", "Internal - Runs the delayed initialization sequence")]
void RunDelayedInitLegacyCmd(const CommandArgs@ args) {
    Msgl("=====Archipelago=====");
    Archipelago::UpdateInternalMapName();
    if (Archipelago::current_map == "unknown" || Archipelago::current_map == "") {
        Archipelago::ArchipelagoLog("DelayedInit: Map name unknown, skipping.");
        return;
    }
    // Reset Effect of trap, gpotatos mute, and make sure the console will output text correctly
    Archipelago::ResetPersistentSystems();
    Msgl("Archipelago::ResetPersistentSystems() completed");
    Archipelago::DoMapSpecificSetup();
    Msgl("DoMapSpecificSetup() completed");
    // Set level transition trigger to output completion message
    Archipelago::CreateCompleteLevelAlertHook(Archipelago::current_map);
    Msgl("CreateCompleteLevelAlertHook() completed");
    Archipelago::CreateMapSpecificHolos();
    Msgl("CreateMapSpecificHolos() completed");
    // Spawn the module to detect player death used for deathlink
    Archipelago::AttachDeathTrigger();
    Msgl("AttachDeathTrigger() completed");
    // Check if we show the Map status HUD
    ConVarRef showHUDConVar("ap_show_map_status_hud");
    int hudMode = (showHUDConVar.IsValid()) ? showHUDConVar.GetInt() : 0;
    // Tell panorama the current map
    Archipelago::CallVScript("SendToPanorama(\"ArchipelagoMapNameUpdated\", \"" + Archipelago::current_map + "|" + hudMode + "\")");
    Msgl("SendToPanorama() completed with HUD Mode: " + hudMode);
    // Invoke the elevator ride skip module (module manages the activation of it)
    Archipelago::SkipElevatorRide();
    Msgl("SkipElevatorRide() completed");
    Archipelago::ArchipelagoLog("DelayedInit complete for: " + Archipelago::current_map);
    Msgl("=====================");
}

[ServerCommand("RefreshMapName", "Forces a map name update to Panorama")]
void RefreshMapNameLegacyCmd(const CommandArgs@ args) {
    Archipelago::current_map = "";
    Archipelago::UpdateInternalMapName();
}

// =============================================================
// --- CHECK ---
// =============================================================

[ServerCommand("AddWheatleyMonitorBreakCheck", "Runs the automatic monitor check logic")]
void AddWheatleyMonitorBreakCheckCmd(const CommandArgs@ args) {
    Archipelago::AddWheatleyMonitorBreakCheck();
}

[ServerCommand("PrintMapComplete", "Print Map Completion")]
void PrintMapCompleteCmd(const CommandArgs@ args) {
    Archipelago::PrintMapComplete();
}

[ServerCommand("PrintCompleteNoExit", "Prints completion without warping (used for final 4)")]
void PrintCompleteNoExitLegacyCmd(const CommandArgs@ args) {
    Archipelago::PrintMapCompleteNoExit();
}

[ServerCommand("SetCheckedButtons", "Updates the list of checked buttons")]
void SetCheckedButtonsCmd(const CommandArgs@ args) {
    array<string> checkedButtons;

    for (int i = 1; i < args.ArgC(); i++) {
        string arg = CleanArg(args.Arg(i));
        if (arg.length() > 0) {
            checkedButtons.insertLast(arg.tolower());
            Archipelago::ArchipelagoLog("AP DEBUG: Inserted button -> '" + arg.tolower() + "'");
        }
    }
    
    Archipelago::ArchipelagoLog("AP: Checked buttons updated (" + checkedButtons.length() + " items)");
    Archipelago::SetCheckedButtons(checkedButtons);
}

[ServerCommand("ReportAPButton", "Logs a custom AP button press")]
void ReportAPButtonLegacyCmd(const CommandArgs@ args) {
    if (args.ArgC() < 2) return;
    Archipelago::RunButtonScenarioCheck(args.Arg(1));
}

[ServerCommand("CreateAPButton", "Legacy CreateAPButton command")]
void CreateAPButtonLegacyCmd(const CommandArgs@ args) {
    if (args.ArgC() < 8) return;
    string name = args.Arg(1);
    Vector pos(args.Arg(2).toFloat(), args.Arg(3).toFloat(), args.Arg(4).toFloat());
    QAngle ang(args.Arg(5).toFloat(), args.Arg(6).toFloat(), args.Arg(7).toFloat());
    float scale = (args.ArgC() > 8) ? args.Arg(8).toFloat() : 1.0f;
    int skin = (args.ArgC() > 9) ? args.Arg(9).toInt() : 0;
    
    Archipelago::CreateAPButton(name, pos, ang, scale, skin);
}

[ServerCommand("ArchipelagoVitrifiedFound", "Internal - Updates the local vitrified door bitmask")]
void ArchipelagoVitrifiedFoundLegacyCmd(const CommandArgs@ args) {
    if (args.ArgC() < 2) return;
    int index = args.Arg(1).toInt();
    if (index < 1 || index > 6) return;

    string bitmask = Archipelago::cv_ArchipelagoVitrifiedStatus.GetString();
    if (bitmask.length() < 6) bitmask = "000000";

    string newBitmask = "";
    for (int i = 1; i <= 6; i++) {
        if (i == index) newBitmask += "1"; else newBitmask += bitmask.substr(i - 1, 1);
    }

    Archipelago::cv_ArchipelagoVitrifiedStatus.SetValue(newBitmask);
    Archipelago::ArchipelagoLog("[AP] Vitrified Door Found: " + index + " | New Bitmask: " + newBitmask);

    string checkName = "Vitrified Door " + index;
    if (Archipelago::checked_vitrified_doors.find(checkName) == -1) {
        Archipelago::checked_vitrified_doors.insertLast(checkName);
    }
}

[ServerCommand("SetVitrifiedStatus", "Updates the local vitrified door checked list and hologram skins")]
void SetVitrifiedStatusCmd(const CommandArgs@ args) {
    array<string> checkedDoors;
    for (int i = 1; i < args.ArgC(); i++) {
        string arg = CleanArg(args.Arg(i));
        if (arg.length() > 0) {
            checkedDoors.insertLast(arg);
        }
    }
    Archipelago::SetVitrifiedStatus(checkedDoors);
}

[ServerCommand("AddCameraCheck", "Runs the automatic camera check logic")]
void AddCameraCheckCmd(const CommandArgs@ args) {
    Archipelago::AddCameraCheck();
}

[ServerCommand("SetCheckedCameras", "Updates the list of checked cameras")]
void SetCheckedCamerasCmd(const CommandArgs@ args) {
    array<string> checkedCameras;

    for (int i = 1; i < args.ArgC(); i++) {
        string arg = CleanArg(args.Arg(i));
        if (arg.length() > 0) {
            checkedCameras.insertLast(arg.tolower());
            Archipelago::ArchipelagoLog("AP DEBUG: Inserted camera -> '" + arg.tolower() + "'");
        }
    }
    
    Archipelago::ArchipelagoLog("AP: Checked cameras updated (" + checkedCameras.length() + " items)");
    Archipelago::SetCheckedCameras(checkedCameras);
}

[ServerCommand("SetCheckedScreens", "Updates the list of checked monitors")]
void SetCheckedScreensCmd(const CommandArgs@ args) {
    array<string> checkedScreens;
    string fullCmd = args.GetCommandString();
    Archipelago::ArchipelagoLog("AP DEBUG RAW COMMAND: " + fullCmd);

    for (int i = 1; i < args.ArgC(); i++) {
        string arg = CleanArg(args.Arg(i));
        if (arg.length() > 0) {
            if ((arg == "1" || arg == "2") && checkedScreens.length() > 0) {
                uint lastIdx = checkedScreens.length() - 1;
                string prev = checkedScreens[lastIdx];
                checkedScreens[lastIdx] = prev + " " + arg;
                Archipelago::ArchipelagoLog("AP DEBUG: Merged to create -> '" + checkedScreens[lastIdx] + "'");
            } else {
                checkedScreens.insertLast(arg);
                Archipelago::ArchipelagoLog("AP DEBUG: Inserted screen -> '" + arg + "'");
            }
        }
    }
    
    Archipelago::ArchipelagoLog("AP: Checked screens updated (" + checkedScreens.length() + " items)");
    Archipelago::SetCheckedScreens(checkedScreens);
}

[ServerCommand("SetCheckedPickup", "Disables or hides physical items if already checked in Archipelago")]
void SetCheckedPickupCmd(const CommandArgs@ args) {
    if (args.ArgC() < 2) return;

    string itemPayload = args.Arg(1).tolower();
    string currentMap = Archipelago::current_map.tolower();

    // 1. Emplacement : Portal Gun 1 (Chambre 03 - sp_a1_intro3)
    if (currentMap == "sp_a1_intro3" && itemPayload.locate("portal_gun_1") != uint(-1)) {
        CBaseEntity@ holo = EntityList().FindByName(null, "intro3_portalgun_holo");
        if (holo !is null) {
            CBaseAnimating@ animHolo = cast<CBaseAnimating>(holo);
            if (animHolo !is null) {
                animHolo.SetSkin(4); // Skin 4 (Fait)
            }
        }
        return;
    }

    // 2. Emplacement : Portal Gun 2 (Incinerator - sp_a2_intro)
    if (currentMap == "sp_a2_intro" && itemPayload.locate("portal_gun_2") != uint(-1)) {
        CBaseEntity@ holo = EntityList().FindByName(null, "a2_intro_gun_holo");
        if (holo !is null) {
            CBaseAnimating@ animHolo = cast<CBaseAnimating>(holo);
            if (animHolo !is null) {
                animHolo.SetSkin(4); // Skin 4 (Fait)
            }
        }
        return;
    }

    // 3. Emplacement : PotatOS (Chambre de transition - sp_a3_transition01)
    if (currentMap == "sp_a3_transition01" && itemPayload.locate("potatos") != uint(-1)) {
        CBaseEntity@ holo = EntityList().FindByName(null, "a3_potatos_button_holo");
        if (holo !is null) {
            CBaseAnimating@ animHolo = cast<CBaseAnimating>(holo);
            if (animHolo !is null) {
                animHolo.SetSkin(4); // Skin 4 (Fait)
            }
        }
        return;
    }
}

// =============================================================
// --- ENTITY ---
// =============================================================

[ServerCommand("AddTractorBeamFrame", "AddButtonFrame command")]
void AddTractorBeamFrameLegacyCmd(const CommandArgs@ args) {
    if (args.ArgC() < 2) return;
    Archipelago::AddTractorBeamFrame(args.Arg(1));
}

[ServerCommand("DeleteCoreOnOutput", "DeleteCoreOnOutput command")]
void DeleteCoreOnOutputLegacyCmd(const CommandArgs@ args) {
    if (args.ArgC() < 4) return;
    Archipelago::DeleteCoreOnOutput(args.Arg(1), args.Arg(2), args.Arg(3));
}

[ServerCommand("DeleteEntity", "DeleteEntity command")]
void DeleteEntityLegacyCmd(const CommandArgs@ args) {
    if (args.ArgC() < 2) return;
    string target = args.Arg(1);
    bool create_holo = (args.ArgC() > 2) ? (args.Arg(2) == "1") : true;
    Archipelago::ArchipelagoLog("[AP RECV] DeleteEntity: " + target + " (holo: " + create_holo + ")");
    Archipelago::DeleteEntity(target, create_holo);
}

[ServerCommand("DeleteEntityHolo", "Version compacte sans espace pour les déclencheurs")]
void DeleteEntityHoloCmd(const CommandArgs@ args) {
    if (args.ArgC() < 2) return;
    string target = args.Arg(1);
    Archipelago::DeleteEntity(target, true);
}

[ServerCommand("DisableEntityPhysics", "DisableEntityPhysics command")]
void DisableEntityPhysicsLegacyCmd(const CommandArgs@ args) {
    if (args.ArgC() < 2) return;
    Archipelago::DisableEntityPhysics(args.Arg(1));
}

[ServerCommand("DisableEntityPickup", "DisableEntityPickup command")]
void DisableEntityPickupLegacyCmd(const CommandArgs@ args) {
    if (args.ArgC() < 2) return;
    Archipelago::DisableEntityPickup(args.Arg(1));
}

[ServerCommand("MakeFaithPlateFaulty", "MakeFaithPlateFaulty command")]
void MakeFaithPlateFaultyLegacyCmd(const CommandArgs@ args) {
    if (args.ArgC() < 2) return;
    
    string entName = args.Arg(1);
    Archipelago::ArchipelagoLog("[AP RECV] MakeFaithPlateFaulty: " + entName); 

    CBaseEntity@ target = EntityList().FindByName(null, entName);
    if (target is null) @target = EntityList().FindByClassname(null, entName);
    if (target !is null) {
        Archipelago::MakeFaithPlateFaulty(target);
    }
}

// --- BUTTONS ---

[ServerCommand("AddButtonFrame", "AddButtonFrame command")]
void AddButtonFrameLegacyCmd(const CommandArgs@ args) {
    if (args.ArgC() < 2) return;
    Archipelago::AddButtonFrame(args.Arg(1));
}

[ServerCommand("AddFloorButtonFrame", "AddFloorButtonFrame command")]
void AddFloorButtonFrameLegacyCmd(const CommandArgs@ args) {
    if (args.ArgC() < 2) return;
    Archipelago::AddFloorButtonFrame(args.Arg(1));
}

// --- GEL ---

[ServerCommand("CreateClearGel", "Legacy CreateClearGel command")]
void CreateClearGelLegacyCmd(const CommandArgs@ args) {
    if (args.ArgC() < 4) return;
    Vector pos(args.Arg(1).toFloat(), args.Arg(2).toFloat(), args.Arg(3).toFloat());
    float offset = (args.ArgC() > 4) ? args.Arg(4).toFloat() : -100.0f;
    Archipelago::CreateClearGel(pos, offset);
}

[ServerCommand("RemoveGel", "Legacy RemoveGel command")]
void RemoveGelLegacyCmd(const CommandArgs@ args) {
    if (args.ArgC() < 4) return;
    float x = args.Arg(1).toFloat();
    float y = args.Arg(2).toFloat();
    float z = args.Arg(3).toFloat();
    Vector pos(x, y, z);
    string filter = (args.ArgC() > 4) ? args.Arg(4) : "";
    string name = (args.ArgC() > 5) ? args.Arg(5) : "";
    Archipelago::RemoveGel(pos, filter, name);
}

[ServerCommand("LockButtonByName", "LockButtonByName command")]
void LockButtonByNameCmd(const CommandArgs@ args) {
    if (args.ArgC() < 2) return;
    Archipelago::LockButtonByName(args.Arg(1));
}

// =============================================================
// --- HOLOGRAM ---
// =============================================================

[ServerCommand("UpdateHologramsVisibility", "Updates the visibility of all holograms based on settings")]
void AP_UpdateHologramsVisibilityCmd(const CommandArgs@ args) {
    Archipelago::UpdateHologramsVisibility();
}

[ServerCommand("AttachHologramToEntity", "Forces a hologram to stick to a moving entity")]
void AttachHologramToEntityLegacyCmd(const CommandArgs@ args) {
    if (args.ArgC() < 6) return;
    Archipelago::ArchipelagoLog("[AP RECV] AttachHologram: " + args.Arg(1));
    Archipelago::AttachHologramToEntity(args.Arg(1), args.Arg(2), args.Arg(3).toFloat(), args.Arg(4).toFloat(), args.Arg(5).toInt());
}

[ServerCommand("AP_BTS4_ConveyorTick", "Conveyor turret ticking logic for sp_a2_bts4")]
void AP_BTS4_ConveyorTickCmd(const CommandArgs@ args) {
    Archipelago::AP_BTS4_ConveyorTick();
}

[ServerCommand("Finale2TurretTick", "Finale 2 turret ticking logic to restore skins")]
void Finale2_TurretTickCmd(const CommandArgs@ args) {
    Archipelago::Finale2TurretTick();
}

// =============================================================
// --- MISC ---
// =============================================================

[ServerCommand("AddScriptAtPos", "Legacy AddScriptAtPos command")]
void AddScriptAtPosLegacyCmd(const CommandArgs@ args) {
    if (args.ArgC() < 6) return;
    Vector pos(args.Arg(1).toFloat(), args.Arg(2).toFloat(), args.Arg(3).toFloat());
    Archipelago::ArchipelagoLog("[AP RECV] AddScriptAtPos at position: " + pos.x + " " + pos.y + " " + pos.z);
    Archipelago::AddEntityOutputScriptAtPos(pos, args.Arg(4), args.Arg(5), args.Arg(6), (args.ArgC() > 7 ? args.Arg(7).toFloat() : 0.0f), (args.ArgC() > 8 ? args.Arg(8).toInt() : -1));
}

[ServerCommand("BlockWheatleyFight", "BlockWheatleyFight command")]
void BlockWheatleyFightLegacyCmd(const CommandArgs@ args) {
    Archipelago::BlockWheatleyFight();
}

[ServerCommand("WarpMonitor", "Warps player on monitor break")]
void WarpMonitorCmd(const CommandArgs@ args) {
    if (args.ArgC() < 2) return;
    string monitorID = args.Arg(1);
    if (args.ArgC() >= 3) {
        monitorID += " " + args.Arg(2);
    }
    
    Archipelago::HandleMonitorWarp(monitorID);
}

[ServerCommand("SpawnPaintBomb", "Legacy SpawnPaintBomb command")]
void SpawnPaintBombLegacyCmd(const CommandArgs@ args) {
    if (args.ArgC() < 4) return;
    Vector pos(args.Arg(1).toFloat(), args.Arg(2).toFloat(), args.Arg(3).toFloat());
    Archipelago::SpawnPaintBomb(pos);
}

[ServerCommand("WarpToMenu", "Internal - Warps back to menu")]
void WarpToMenuLegacyCmd(const CommandArgs@ args) {
    Archipelago::WarpToMenu();
}

[ServerCommand("AddScript", "Connects an entity output to a console command")]
void AddScriptLegacyCmd(const CommandArgs@ args) {
    if (args.ArgC() < 4) return;
    string target = args.Arg(1);
    string output = args.Arg(2);
    string cmd = args.Arg(3);
    float delay = (args.ArgC() > 4) ? args.Arg(4).toFloat() : 0.0f;
    int maxTimes = (args.ArgC() > 5) ? args.Arg(5).toInt() : -1;
    
    array<CBaseEntity@> ents = Archipelago::FindEntities(target);
    
    if (ents.length() == 0) {
        CBaseEntity@ searchEnt = null;
        while ((@searchEnt = EntityList().FindByClassname(searchEnt, "*")) !is null) {
            string entName = searchEnt.GetEntityName().tolower();
            if (entName.locate(target.tolower()) != uint(-1)) {
                ents.insertLast(searchEnt);
            }
        }
    }

    Archipelago::ArchipelagoLog("[AP RECV] AddScript: target=" + target + " (Found: " + ents.length() + " entities) | Output=" + output + " | Cmd=" + cmd);

    for (uint i = 0; i < ents.length(); i++) {
        Archipelago::SafeAddOutput(ents[i], output, "InitCmd", "Command", cmd, delay, maxTimes);
    }
}

[ServerCommand("CheckCameraPhysicsTick", "Evaluates physical security camera falling loops natively")]
void CheckCameraPhysicsTickCmd(const CommandArgs@ args) {
    Archipelago::CheckCameraPhysicsTick();
}

[ServerCommand("CheckElevatorRide", "Evaluates elevator Z-level changes periodically via timer")]
void CheckElevatorRideCmd(const CommandArgs@ args) {
    Archipelago::CheckElevatorRide();
}

[ServerCommand("ShowStatus", "Manually show the map status HUD")]
void ShowStatusLegacyCmd(const CommandArgs@ args) {
    ConVarRef showHUDConVar("ap_show_map_status_hud");
    if (!showHUDConVar.IsValid() || showHUDConVar.GetInt() == 1) {
        return; 
    }

    Archipelago::UpdateInternalMapName();
    Archipelago::CallVScript("SendToPanorama(\"ArchipelagoMapNameUpdated\", \"" + Archipelago::current_map + "|0\")");
}

[ServerCommand("DisableTriggerAtPos", "Disables a trigger at a specific position")]
void DisableTriggerAtPosCmd(const CommandArgs@ args) {
    if (args.ArgC() < 4) return;
    Vector pos(args.Arg(1).toFloat(), args.Arg(2).toFloat(), args.Arg(3).toFloat());
    
    CBaseEntity@ ent = EntityList().FindByClassnameNearest("trigger_once", pos, 150.0f);
    if (ent is null) {
        @ent = EntityList().FindByClassnameNearest("trigger_multiple", pos, 150.0f);
    }

    if (ent !is null) {
        Variant emptyValue; 
        ent.FireInput("Disable", emptyValue, 0.0f, null, null, 0);
        Archipelago::ArchipelagoLog("[AP] DisableTriggerAtPos: Trigger disabled successfully at position " + pos.x + " " + pos.y + " " + pos.z);
    } else {
        Archipelago::ArchipelagoLog("[AP] DisableTriggerAtPos: No trigger found at position " + pos.x + " " + pos.y + " " + pos.z);
    }
}

[ServerCommand("CheckDeathLinkQueue", "Handles local player death detection")]
void CheckDeathLinkQueueCmd(const CommandArgs@ args) {
    CBaseEntity@ player = EntityList().FindByClassname(null, "player");
    if (player is null) return;

    int health = player.GetHealth();

    // --- CASE 1: THE PLAYER IS DEAD ---
    if (health <= 0) {
        if (Archipelago::is_processing_remote_death) {
            Archipelago::sent_death_link = true; 
            return;
        }

        if (!Archipelago::sent_death_link) {
            Archipelago::sent_death_link = true;
            CBaseEntity@ world = EntityList().FindByClassname(null, "worldspawn");
            if (world !is null) {
                Variant v;
                v.SetString("printl(\"send_deathlink " + Archipelago::current_map + "\")");
                world.FireInput("RunScriptCode", v, 0.0f, null, null, 0);
            }
        }
        return;
    }

    // --- CASE 2: THE PLAYER IS ALIVE ---
    if (health > 0) {
        if (Archipelago::sent_death_link && !Archipelago::is_processing_remote_death) {
            Archipelago::sent_death_link = false;
        }
        
        if (Archipelago::is_processing_remote_death && health >= 100) {
            Archipelago::is_processing_remote_death = false;
            Archipelago::sent_death_link = false;
            Archipelago::ArchipelagoLog("[AP] Player respawned. DeathLink safety disabled.");
        }
    }
}

[ServerCommand("PingGameServer", "Verifies if the game server is ready")]
void PingGameServerCmd(const CommandArgs@ args) {
    CBaseEntity@ player = EntityList().FindByClassname(null, "player");
    if (player is null) return;

    int health = player.GetHealth();
    if (health > 0) {
        Msgl("deathlink_pong_ready");
    }
}

[ServerCommand("SetMutedDeath", "Enables or disables death echo protection")]
void SetMutedDeathCmd(const CommandArgs@ args) {
    if (args.ArgC() < 2) return;
    
    Archipelago::is_processing_remote_death = (args.Arg(1) == "1");
    Archipelago::ArchipelagoLog("[AP] is_processing_remote_death set to: " + (Archipelago::is_processing_remote_death ? "TRUE" : "FALSE"));
}

[ServerCommand("ap_sync_settings", "Syncs Archipelago settings from Panorama to Server")]
void SyncSettingsCmd(const CommandArgs@ args) {
    if (args.ArgC() < 6) return;
    ConVarRef cv_SkipBirdScene("cv_SkipBirdScene");
    if (cv_SkipBirdScene.IsValid()) cv_SkipBirdScene.SetValue(args.Arg(0));

    ConVarRef cv_SkipCeilingScene("cv_SkipCeilingScene");
    if (cv_SkipCeilingScene.IsValid()) cv_SkipCeilingScene.SetValue(args.Arg(1));

    ConVarRef cv_SkipIntroContainerScene("cv_SkipIntroContainerScene");
    if (cv_SkipIntroContainerScene.IsValid()) cv_SkipIntroContainerScene.SetValue(args.Arg(2));

    ConVarRef cv_SkipElavatorRide("cv_SkipElavatorRide");
    if (cv_SkipElavatorRide.IsValid()) cv_SkipElavatorRide.SetValue(args.Arg(3));

    ConVarRef ap_hide_holograms("ap_hide_holograms");
    if (ap_hide_holograms.IsValid()) ap_hide_holograms.SetValue(args.Arg(4));

    ConVarRef ap_show_map_status_hud("ap_show_map_status_hud");
    if (ap_show_map_status_hud.IsValid()) ap_show_map_status_hud.SetValue(args.Arg(5));

    Archipelago::UpdateHologramsVisibility();
}

[ServerCommand("PrintItem", "Prints collected item (ex: Portal gun and PotatOS)")]
void PrintItemLegacyCmd(const CommandArgs@ args) {
    string raw = args.GetCommandString();
    uint spaceIdx = raw.locate(" ");
    if (spaceIdx != uint(-1)) {
        string item = raw.substr(int(spaceIdx) + 1).trim();
        item = item.replace(".", " ");
        Archipelago::ArchipelagoLog("item_collected:" + item);
    }
}

// =============================================================
// --- PORTAL GUN ---
// =============================================================

[ServerCommand("DisablePortalGun", "DisablePortalGun command")]
void DisablePortalGunLegacyCmd(const CommandArgs@ args) {
    if (args.ArgC() < 3) return;
    bool blue = (args.Arg(1) == "1");
    bool orange = (args.Arg(2) == "1");
    Archipelago::ArchipelagoLog("[AP RECV] DisablePortalGun: Blue=" + blue + " Orange=" + orange);
    Archipelago::DisablePortalGun(blue, orange);
}

[ServerCommand("IncineratorDisablePortalGun", "Bridge from VScript/Client")]
void IncineratorDisablePortalGunCmd(const CommandArgs@ args) {
    Archipelago::IncineratorDisablePortalGun();
}

// =============================================================
// --- POTATOS ---
// =============================================================

[ServerCommand("RemovePotatOS", "RemovePotatOS command")]
void RemovePotatOSLegacyCmd(const CommandArgs@ args) {
    Archipelago::RemovePotatOS();
}

[ServerCommand("RemovePotatosFromGun", "Removes PotatOS from the portal gun and world")]
void RemovePotatosFromGunLegacyCmd(const CommandArgs@ args) {
    Archipelago::ArchipelagoLog("[AP RECV] RemovePotatosFromGun");
    Archipelago::RemovePotatosFromGun();
}

// =============================================================
// --- TRAPS ---
// =============================================================

[ServerCommand("CubeConfettiTrap", "Triggers cube confetti trap")]
void CubeConfettiTrapCmd(const CommandArgs@ args) {
    Archipelago::TriggerCubeConfettiTrap();
}

[ServerCommand("MotionBlurTrap", "Triggers motion blur trap")]
void MotionBlurTrapCmd(const CommandArgs@ args) {
    float duration = (args !is null && args.ArgC() >= 2) ? args.Arg(1).toFloat() : 20.0f;
    Archipelago::TriggerMotionBlurTrap(duration);
}

[ServerCommand("SlipperyFloorTrap", "Triggers slippery floor trap")]
void SlipperyFloorTrapCmd(const CommandArgs@ args) {
    float duration = (args !is null && args.ArgC() >= 2) ? args.Arg(1).toFloat() : 60.0f;
    Archipelago::TriggerSlipperyFloorTrap(duration);
}

[ServerCommand("FizzlePortalTrap", "Triggers fizzle portal trap")]
void FizzlePortalTrapCmd(const CommandArgs@ args) {
    Archipelago::TriggerFizzlePortalTrap();
}

[ServerCommand("DialogTrap", "Triggers dialog trap")]
void DialogTrapCmd(const CommandArgs@ args) {
    string scene = (args !is null && args.ArgC() >= 2) ? args.Arg(1) : "";
    float duration = (args !is null && args.ArgC() >= 3) ? args.Arg(2).toFloat() : 15.0f;
    Archipelago::TriggerDialogTrap(scene, duration);
}

[ServerCommand("ButterFingersTrap", "Triggers butter fingers trap")]
void ButterFingersTrapCmd(const CommandArgs@ args) {
    float duration = (args !is null && args.ArgC() >= 2) ? args.Arg(1).toFloat() : 30.0f;
    Archipelago::ButterFingersTrap(duration);
}