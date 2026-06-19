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

[ServerCommand("LockButtonByName", "LockButtonByName command")]
void LockButtonByNameCmd(const CommandArgs@ args) 
{
    // Vérification qu'au moins un argument (le nom de l'entité) a été fourni
    if (args.ArgC() < 2) return;
    
    // Appel direct de la fonction globale d'exécution
    Archipelago::LockButtonByName(args.Arg(1));
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
            } else {
                Archipelago::checked_screens.insertLast(arg);
                Archipelago::ArchipelagoLog("AP DEBUG: Inserted screen -> '" + arg + "'");
            }
        }
    }
    
    Archipelago::ArchipelagoLog("AP: Checked screens updated (" + Archipelago::checked_screens.length() + " items)");
}

[ServerCommand("AddWheatleyMonitorBreakCheck", "Runs the automatic monitor check logic")]
void AddWheatleyMonitorBreakCheckCmd(const CommandArgs@ args) {
    Archipelago::AddWheatleyMonitorBreakCheck();
}

[ServerCommand("AddCameraCheck", "Runs the automatic camera check logic")]
void AddCameraCheckCmd(const CommandArgs@ args) {
    Archipelago::AddCameraCheck();
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
    // FIX : On envoie toujours le nom de la map à Panorama, mais on lui passe l'état de la ConVar en paramètre.
    // "0" signifie que le HUD est activé (il doit clignoter 5s), "1" signifie qu'il est éteint.
    ConVarRef showHUDConVar("ap_show_map_status_hud");
    int hudMode = (showHUDConVar.IsValid()) ? showHUDConVar.GetInt() : 0;
    
    Archipelago::CallVScript("SendToPanorama(\"ArchipelagoMapNameUpdated\", \"" + ::current_map + "|" + hudMode + "\")");
    Msgl("SendToPanorama() completed with HUD Mode: " + hudMode);
    Archipelago::SkipElevatorRide();
    Msgl("SkipElevatorRide() completed");
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
    // Verification safety net: Do not allow keybind execution if the option is toggled off
    ConVarRef showHUDConVar("ap_show_map_status_hud");
    if (!showHUDConVar.IsValid() || showHUDConVar.GetInt() == 1) {
        return; 
    }

    Archipelago::UpdateInternalMapName();
    Archipelago::CallVScript("SendToPanorama(\"ArchipelagoMapNameUpdated\", \"" + ::current_map + "|0\")");
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
        string arg = args.Arg(i);
        arg = arg.replace("[", "").replace("]", "").replace("\"", "").replace(",", "");
        if (arg.length() > 0) {
            checkedDoors.insertLast(arg);
        }
    }
    Archipelago::SetVitrifiedStatus(checkedDoors);
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

[ServerCommand("AP_BTS4_ConveyorTick", "Conveyor turret ticking logic for sp_a2_bts4")]
void AP_BTS4_ConveyorTickCmd(const CommandArgs@ args) {
    Archipelago::AP_BTS4_ConveyorTick();
}

[ServerCommand("Finale2TurretTick", "Finale 2 turret ticking logic to restore skins")]
void Finale2_TurretTickCmd(const CommandArgs@ args) {
    Archipelago::Finale2TurretTick();
}

[ServerCommand("RemovePotatosFromGun", "Removes PotatOS from the portal gun and world")]
void RemovePotatosFromGunLegacyCmd(const CommandArgs@ args) {
    Archipelago::ArchipelagoLog("[AP RECV] RemovePotatosFromGun");
    Archipelago::RemovePotatosFromGun();
}

[ServerCommand("SetStatus", "Dummy - Deprecated")]
void SetStatusLegacyCmd(const CommandArgs@ args) { }

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
    
    Archipelago::CreateAPButton(name, pos, ang, scale, skin);
}

[ServerCommand("SetCheckedButtons", "Updates the list of checked buttons")]
void SetCheckedButtonsCmd(const CommandArgs@ args) {
    array<string> checkedButtons;

    for (int i = 1; i < args.ArgC(); i++) {
        string arg = args.Arg(i);
        // Nettoyage standard des caractères parasites résiduels
        arg = arg.replace("[", "").replace("]", "").replace("\"", "").replace(",", "");
        
        if (arg.length() > 0) {
            // On insère chaque identifiant de bouton individuellement et en minuscules
            checkedButtons.insertLast(arg.tolower());
            Archipelago::ArchipelagoLog("AP DEBUG: Inserted button -> '" + arg.tolower() + "'");
        }
    }
    
    Archipelago::ArchipelagoLog("AP: Checked buttons updated (" + checkedButtons.length() + " items)");
    Archipelago::SetCheckedButtons(checkedButtons);
}

[ServerCommand("SetCheckedCameras", "Updates the list of checked cameras")]
void SetCheckedCamerasCmd(const CommandArgs@ args) {
    Archipelago::checked_cameras.resize(0);

    for (int i = 1; i < args.ArgC(); i++) {
        string arg = args.Arg(i);
        arg = arg.replace("[", "").replace("]", "").replace("\"", "").replace(",", "");
        
        if (arg.length() > 0) {
            Archipelago::checked_cameras.insertLast(arg.tolower());
            Archipelago::ArchipelagoLog("AP DEBUG: Inserted camera -> '" + arg.tolower() + "'");
        }
    }
    
    Archipelago::ArchipelagoLog("AP: Checked cameras updated (" + Archipelago::checked_cameras.length() + " items)");
    Archipelago::SetCheckedCameras();
}

[ServerCommand("SetCheckedPickup", "Disables or hides physical items if already checked in Archipelago")]
void SetCheckedPickupCmd(const CommandArgs@ args) {
    if (args.ArgC() < 2) return;

    // Récupération et conversion en minuscules de l'argument d'item (ex: portal_gun_1)
    string itemPayload = args.Arg(1).tolower();
    
    // Utilisation de la variable globale existante de ton mod passée en minuscules
    string currentMap = ::current_map.tolower();

    // 1. Emplacement : Portal Gun 1 (Chambre 03 - sp_a1_intro3)
    if (currentMap == "sp_a1_intro3" && itemPayload.locate("portal_gun_1") != uint(-1)) {
        CBaseEntity@ holo = EntityList().FindByName(null, "intro3_portalgun_holo");
        if (holo !is null) {
            CBaseAnimating@ animHolo = cast<CBaseAnimating>(holo);
            if (animHolo !is null) {
                animHolo.SetSkin(4); // Changement du skin à 4 (Fait)
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
                animHolo.SetSkin(4); // Changement du skin à 4 (Fait)
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
                animHolo.SetSkin(4); // Changement du skin à 4 (Fait)
            }
        }
        return;
    }
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

[ServerCommand("UpdateHologramsVisibility", "Updates the visibility of all holograms based on settings")]
void AP_UpdateHologramsVisibilityCmd(const CommandArgs@ args) {
    Archipelago::UpdateHologramsVisibility();
}

[ServerCommand("CheckDeathLinkQueue", "Gère la détection de la mort locale du joueur")]
void CheckDeathLinkQueueCmd(const CommandArgs@ args) {
    CBaseEntity@ player = EntityList().FindByClassname(null, "player");
    if (player is null) return;

    int health = player.GetHealth();

    if (health <= 0) {
        if (is_faking_death) {
            sent_death_link = true; 
            return;
        }

        if (!sent_death_link) {
            sent_death_link = true;
            CBaseEntity@ world = EntityList().FindByClassname(null, "worldspawn");
            if (world !is null) {
                Variant v;
                v.SetString("printl(\"send_deathlink " +::current_map + "\")");
                world.FireInput("RunScriptCode", v, 0.0f, null, null, 0);
            }
        }
        return;
    }

    if (health > 0) {
        if (sent_death_link && !is_faking_death) {
            sent_death_link = false;
        }
        if (is_faking_death && health >= 100) {
            is_faking_death = false;
            sent_death_link = false;
            Archipelago::ArchipelagoLog("[AP] Joueur réapparu. Sécurité DeathLink désactivée.");
        }
    }
}

[ServerCommand("AP_PingReady", "Vérifie si le jeu est prêt à exécuter un événement")]
void AP_PingReadyCmd(const CommandArgs@ args) {
    CBaseEntity@ player = EntityList().FindByClassname(null, "player");
    if (player is null) return; // Si on est au menu ou en chargement, l'entité n'existe pas -> Pas de réponse

    int health = player.GetHealth();
    // Si le joueur est en vie et actif sur la map, on renvoie le feu vert à Python via Netcon
    if (health > 0) {
        Msgl("deathlink_pong_ready");
    }
}

[ServerCommand("AP_SetMutedDeath", "Active ou désactive la protection d'écho de mort")]
void AP_SetMutedDeathCmd(const CommandArgs@ args) {
    if (args.ArgC() < 2) return;
    is_faking_death = (args.Arg(1) == "1");
    Archipelago::ArchipelagoLog("[AP] is_faking_death mis à : " + (is_faking_death ? "TRUE" : "FALSE"));
}
