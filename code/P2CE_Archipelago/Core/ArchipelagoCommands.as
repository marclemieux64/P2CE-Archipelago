// =============================================================
// ARCHIPELAGO MAPSPAWN COMMANDS
// =============================================================

[ServerCommand("DeleteEntity", "DeleteEntity command")]
void DeleteEntityLegacyCmd(const CommandArgs@ args) {
    if (args.ArgC() < 2) return;
    string target = args.Arg(1);
    bool create_holo = (args.ArgC() > 2) ? (args.Arg(2) == "1") : true;
    Archipelago::ArchipelagoLog("[AP RECV] DeleteEntity: " + target + " (holo: " + create_holo + ")");
    Archipelago::DeleteEntity(target, create_holo);
}

[ServerCommand("DisablePortalGun", "DisablePortalGun command")]
void DisablePortalGunLegacyCmd(const CommandArgs@ args) {
    if (args.ArgC() < 3) return;
    bool blue = (args.Arg(1) == "1");
    bool orange = (args.Arg(2) == "1");
    Archipelago::ArchipelagoLog("[AP RECV] DisablePortalGun: Blue=" + blue + " Orange=" + orange);
    Archipelago::DisablePortalGun(blue, orange);
}

[ServerCommand("DisableEntityPickup", "DisableEntityPickup command")]
void DisableEntityPickupLegacyCmd(const CommandArgs@ args) {
    if (args.ArgC() < 2) return;
    Archipelago::DisableEntityPickup(args.Arg(1));
}

[ServerCommand("DisableEntityPhysics", "DisableEntityPhysics command")]
void DisableEntityPhysicsLegacyCmd(const CommandArgs@ args) {
    if (args.ArgC() < 2) return;
    Archipelago::DisableEntityPhysics(args.Arg(1));
}

[ServerCommand("AddFloorButtonFrame", "AddFloorButtonFrame command")]
void AddFloorButtonFrameLegacyCmd(const CommandArgs@ args) {
    if (args.ArgC() < 2) return;
    Archipelago::AddFloorButtonFrame(args.Arg(1));
}

[ServerCommand("AddButtonFrame", "AddButtonFrame command")]
void AddButtonFrameLegacyCmd(const CommandArgs@ args) {
    if (args.ArgC() < 2) return;
    Archipelago::AddButtonFrame(args.Arg(1));
}

[ServerCommand("AddTractorBeamFrame", "AddButtonFrame command")]
void AddTractorBeamFrameLegacyCmd(const CommandArgs@ args) {
    if (args.ArgC() < 2) return;
    Archipelago::AddTractorBeamFrame(args.Arg(1));
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

[ServerCommand("DeleteCoreOnOutput", "DeleteCoreOnOutput command")]
void DeleteCoreOnOutputLegacyCmd(const CommandArgs@ args) {
    if (args.ArgC() < 4) return;
    Archipelago::DeleteCoreOnOutput(args.Arg(1), args.Arg(2), args.Arg(3));
}

[ServerCommand("BlockWheatleyFight", "BlockWheatleyFight command")]
void BlockWheatleyFightLegacyCmd(const CommandArgs@ args) {
    Archipelago::BlockWheatleyFight();
}

[ServerCommand("RemovePotatOS", "RemovePotatOS command")]
void RemovePotatOSLegacyCmd(const CommandArgs@ args) {
    Archipelago::RemovePotatOS();
}

[ServerCommand("SetCheckedScreens", "Updates the list of checked monitors")]
void SetCheckedScreensCmd(const CommandArgs@ args) {
    Archipelago::checked_screens.resize(0);
    string fullCmd = args.GetCommandString();
    Archipelago::ArchipelagoLog("AP DEBUG RAW COMMAND: " + fullCmd);

    for (int i = 1; i < args.ArgC(); i++) {
        string arg = args.Arg(i);
        arg = arg.replace("[", "").replace("]", "").replace("\"", "").replace(",", "");
        
        if (arg.length() > 0) {
            if ((arg == "1" || arg == "2") && Archipelago::checked_screens.length() > 0) {
                uint lastIdx = Archipelago::checked_screens.length() - 1;
                string prev = Archipelago::checked_screens.opIndex(lastIdx);
                Archipelago::checked_screens.opIndex(lastIdx) = prev + " " + arg;
                Archipelago::ArchipelagoLog("AP DEBUG: Merged to create -> '" + Archipelago::checked_screens.opIndex(lastIdx) + "'");
            } 
            else {
                Archipelago::checked_screens.insertLast(arg);
                Archipelago::ArchipelagoLog("AP DEBUG: Inserted screen -> '" + arg + "'");
            }
        }
    }
    
    Archipelago::ArchipelagoLog("AP: Checked screens updated (" + Archipelago::checked_screens.length() + " items)");
}

[ServerCommand("DeathLink", "Checks if the player is dead for DeathLink")]
void DeathLinkCmd(const CommandArgs@ args) {
    if (sent_death_link) return;
    CBaseEntity@ player = EntityList().FindByClassname(null, "player");
    if (player !is null && player.GetHealth() <= 0) {
        sent_death_link = true;
        CBaseEntity@ world = EntityList().FindByClassname(null, "worldspawn");
        if (world !is null) {
            Variant v;
            v.SetString("printl(\"send_deathlink " + ::current_map + "\")");
            world.FireInput("RunScriptCode", v, 0.0f, null, null, 0);
        }
    }
}

[ServerCommand("AddWheatleyMonitorBreakCheck", "Runs the automatic monitor check logic")]
void AddWheatleyMonitorBreakCheckCmd(const CommandArgs@ args) {
    Archipelago::AddWheatleyMonitorBreakCheck();
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

[ServerCommand("FinishedMap", "Triggers map completion logic")]
void FinishedMapLegacyCmd(const CommandArgs@ args) {
    Archipelago::ArchipelagoLog("COMMAND: FinishedMap triggered!");
    Archipelago::PrintMapComplete();
}

[ServerCommand("PrintCompleteNoExit", "Prints completion without warping")]
void PrintCompleteNoExitLegacyCmd(const CommandArgs@ args) {
    Archipelago::PrintMapCompleteNoExit();
}

[ServerCommand("WarpToMenu", "Internal - Warps back to menu")]
void WarpToMenuLegacyCmd(const CommandArgs@ args) {
    Archipelago::WarpToMenu();
}

[ServerCommand("RunDelayedInit", "Internal - Runs the delayed initialization sequence")]
void RunDelayedInitLegacyCmd(const CommandArgs@ args) {
    Msgl("=====Archipelago=====");
    Archipelago::UpdateInternalMapName();
    if (::current_map == "unknown" || ::current_map == "") {
        Archipelago::ArchipelagoLog("DelayedInit: Map name unknown, skipping.");
        return;
    }

    Archipelago::ResetPersistentSystems();
    Msgl("Archipelago::ResetPersistentSystems() completed");
    Archipelago::DoMapSpecificSetup();
    Msgl("DoMapSpecificSetup() completed");
    Archipelago::CreateCompleteLevelAlertHook(::current_map);
    Msgl("CreateCompleteLevelAlertHook() completed");
    Archipelago::CreateMapSpecificHolos();
    Msgl("CreateMapSpecificHolos() completed");
    Archipelago::AttachDeathTrigger();
    Msgl("AttachDeathTrigger() completed");
    Archipelago::CallVScript("SendToPanorama(\"ArchipelagoMapNameUpdated\", \"" + ::current_map + "|1\")");
    Msgl("SendToPanorama() completed");
    Archipelago::ArchipelagoLog("DelayedInit complete for: " + ::current_map);
    Msgl("=====================");
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
    
    // CORRECTIF SÉCURITÉ : Recherche partielle si le nom exact échoue à cause du préfixe d'instance
    if (ents.length() == 0) {
        CBaseEntity@ searchEnt = null;
        while ((@searchEnt = EntityList().FindByClassname(searchEnt, "*")) !is null) {
            string entName = searchEnt.GetEntityName().tolower();
            if (entName.locate(target.tolower()) != uint(-1)) {
                ents.insertLast(searchEnt);
            }
        }
    }

    // Affichage clair de la commande dans tes logs console pour débugger
    Archipelago::ArchipelagoLog("[AP RECV] AddScript: target=" + target + " (Trouvé: " + ents.length() + " entités) | Output=" + output + " | Cmd=" + cmd);

    for (uint i = 0; i < ents.length(); i++) {
        Archipelago::SafeAddOutput(ents[i], output, "InitCmd", "Command", cmd, delay, maxTimes);
    }
}

[ServerCommand("ShowStatus", "Manually show the map status HUD")]
void ShowStatusLegacyCmd(const CommandArgs@ args) {
    Archipelago::UpdateInternalMapName();
    Archipelago::CallVScript("SendToPanorama(\"ArchipelagoMapNameUpdated\", \"" + ::current_map + "|1\")");
}

[ServerCommand("RefreshMapName", "Forces a map name update to Panorama")]
void RefreshMapNameLegacyCmd(const CommandArgs@ args) {
    ::current_map = "";
    Archipelago::UpdateInternalMapName();
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
        if (i == index) newBitmask += "1";
        else newBitmask += bitmask.substr(i-1, 1);
    }

    Archipelago::cv_ArchipelagoVitrifiedStatus.SetValue(newBitmask);
    Archipelago::ArchipelagoLog("[AP] Vitrified Door Found: " + index + " | New Bitmask: " + newBitmask);
}

[ServerCommand("PrintItem", "Prints collected item")]
void PrintItemLegacyCmd(const CommandArgs@ args) {
    string raw = args.GetCommandString();
    uint spaceIdx = raw.locate(" ");
    if (spaceIdx != uint(-1)) {
        string item = raw.substr(int(spaceIdx) + 1).trim();
        item = item.replace(".", " ");
        Archipelago::ArchipelagoLog("item_collected:" + item);
    }
}

[ServerCommand("IncineratorDisablePortalGun", "Bridge from VScript/Client")]
void IncineratorDisablePortalGunCmd(const CommandArgs@ args) {
    Archipelago::IncineratorDisablePortalGun();
}

[ServerCommand("ReportAPButton", "Logs a custom AP button press")]
void ReportAPButtonLegacyCmd(const CommandArgs@ args) {
    if (args.ArgC() < 2) return;
    Archipelago::RunButtonScenarioCheck(args.Arg(1));
}

[ServerCommand("AttachHologramToEntity", "Forces a hologram to stick to a moving entity")]
void AttachHologramToEntityLegacyCmd(const CommandArgs@ args) {
    if (args.ArgC() < 6) return;
    Archipelago::ArchipelagoLog("[AP RECV] AttachHologram: " + args.Arg(1));
    Archipelago::AttachHologramToEntity(args.Arg(1), args.Arg(2), args.Arg(3).toFloat(), args.Arg(4).toFloat(), args.Arg(5).toInt());
}

[ServerCommand("RemovePotatosFromGun", "Removes PotatOS from the portal gun and world")]
void RemovePotatosFromGunLegacyCmd(const CommandArgs@ args) {
    Archipelago::ArchipelagoLog("[AP RECV] RemovePotatosFromGun");
    Archipelago::RemovePotatosFromGun();
}

[ServerCommand("SetStatus", "Dummy - Deprecated")]
void SetStatusLegacyCmd(const CommandArgs@ args) {}

[ServerCommand("AddScriptAtPos", "Legacy AddScriptAtPos command")]
void AddScriptAtPosLegacyCmd(const CommandArgs@ args) {
    if (args.ArgC() < 6) return;
    Vector pos(args.Arg(1).toFloat(), args.Arg(2).toFloat(), args.Arg(3).toFloat());
    Archipelago::ArchipelagoLog("[AP RECV] AddScriptAtPos à la position: " + pos.x + " " + pos.y + " " + pos.z);
    Archipelago::AddEntityOutputScriptAtPos(pos, args.Arg(4), args.Arg(5), args.Arg(6), (args.ArgC() > 7 ? args.Arg(7).toFloat() : 0.0f), (args.ArgC() > 8 ? args.Arg(8).toInt() : -1));
}

[ServerCommand("CreateAPButton", "Legacy CreateAPButton command")]
void CreateAPButtonLegacyCmd(const CommandArgs@ args) {
    if (args.ArgC() < 8) return;
    string name = args.Arg(1);
    Vector pos(args.Arg(2).toFloat(), args.Arg(3).toFloat(), args.Arg(4).toFloat());
    QAngle ang(args.Arg(5).toFloat(), args.Arg(6).toFloat(), args.Arg(7).toFloat());
    float scale = (args.ArgC() > 8) ? args.Arg(8).toFloat() : 1.0f;
    int skin = (args.ArgC() > 9) ? args.Arg(9).toInt() : 0;
    
    Archipelago::ArchipelagoLog("[AP RECV] CreateAPButton: " + name);
    Archipelago::CreateAPButton(name, pos, ang, scale, skin);
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

[ServerCommand("CreateClearGel", "Legacy CreateClearGel command")]
void CreateClearGelLegacyCmd(const CommandArgs@ args) {
    if (args.ArgC() < 4) return;
    Vector pos(args.Arg(1).toFloat(), args.Arg(2).toFloat(), args.Arg(3).toFloat());
    float offset = (args.ArgC() > 4) ? args.Arg(4).toFloat() : -100.0f;
    Archipelago::CreateClearGel(pos, offset);
}

[ServerCommand("SpawnPaintBomb", "Legacy SpawnPaintBomb command")]
void SpawnPaintBombLegacyCmd(const CommandArgs@ args) {
    if (args.ArgC() < 4) return;
    Vector pos(args.Arg(1).toFloat(), args.Arg(2).toFloat(), args.Arg(3).toFloat());
    Archipelago::SpawnPaintBomb(pos);
}

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

[ServerCommand("AP_UpdateGunSkin", "Updates the skin of the portal gun safely")]
void AP_UpdateGunSkinCmd(const CommandArgs@ args) {
    if (args.ArgC() < 2) return;
    string skinVal = args.Arg(1);

    CBaseEntity@ worldGun = EntityList().FindByClassname(null, "weapon_portalgun");
    if (worldGun !is null) {
        worldGun.KeyValue("skin", skinVal);
    }

    CBaseEntity@ viewModel = EntityList().FindByClassname(null, "viewmodel");
    if (viewModel !is null) {
        viewModel.KeyValue("skin", skinVal);
    }
}

[ServerCommand("DeleteEntityHolo", "Version compacte sans espace pour les déclencheurs")]
void DeleteEntityHoloCmd(const CommandArgs@ args) {
    if (args.ArgC() < 2) return;
    string target = args.Arg(1);
    Archipelago::DeleteEntity(target, true);
}

[ServerCommand("DisableTriggerAtPos", "Désactive un trigger à une position spécifique")]
void DisableTriggerAtPosCmd(const CommandArgs@ args) {
    if (args.ArgC() < 4) return;
    Vector pos(args.Arg(1).toFloat(), args.Arg(2).toFloat(), args.Arg(3).toFloat());
    
    // Cherche le trigger_once le plus proche dans un rayon de 150 unités
    CBaseEntity@ ent = EntityList().FindByClassnameNearest("trigger_once", pos, 150.0f);
    
    // Si ce n'est pas un trigger_once, on cherche un trigger_multiple par sécurité
    if (ent is null) {
        @ent = EntityList().FindByClassnameNearest("trigger_multiple", pos, 150.0f);
    }

    if (ent !is null) {
        // CORRECTIF COMPILATION : On crée une variable Variant vide pour respecter la signature d'AngelScript
        Variant emptyValue; 
        
        // Structure de l'appel corrigée : Input, Valeur, Délai (float), Activator, Caller
        ent.FireInput("Disable", emptyValue, 0.0f, null, null, 0);
        
        Archipelago::ArchipelagoLog("[AP] DisableTriggerAtPos: Trigger désactivé avec succès à la position " + pos.x + " " + pos.y + " " + pos.z);
    } else {
        Archipelago::ArchipelagoLog("[AP] DisableTriggerAtPos: Aucun trigger trouvé à la position " + pos.x + " " + pos.y + " " + pos.z);
    }
}