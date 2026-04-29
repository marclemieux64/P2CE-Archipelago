/**
 * ParseMath - Handles simple inline math like "320-65".
 */
float ParseMath(string val) {
    if (val.length() == 0) return 0.0f;
    uint m = val.locate("-", 1);
    if (m != uint(-1)) return val.substr(0, int(m)).toFloat() - val.substr(int(m + 1)).toFloat();
    uint p = val.locate("+", 1);
    if (p != uint(-1)) return val.substr(0, int(p)).toFloat() + val.substr(int(p + 1)).toFloat();
    return val.toFloat();
}

/**
 * ExtractFloats - Snatches all float-like values from a string.
 */
array<float> ExtractFloats(string raw) {
    string clean = raw.replace("Vector", " ").replace("QAngle", " ").replace("(", " ").replace(")", " ").replace(",", " ").replace("\x22", " ");
    array<string>@ parts = clean.split(" ");
    array<float> results;
    for (uint i = 0; i < parts.length(); i++) {
        string t = parts[i].trim();
        if (t.length() > 0) results.insertLast(ParseMath(t));
    }
    return results;
}

/**
 * APDebugSprayersCmd - Prints diagnostic info for all gel dispensers.
 */
[ServerCommand("ap_debug_sprayers", "Diagnostics for paint sprayers")]
void APDebugSprayersCmd(const CommandArgs@ args) {
    Msgl("[AP] --- SPRAYER DIAGNOSTICS ---");
    CBaseEntity@ ent = EntityList().First();
    int count = 0;
    while (@ent !is null) {
        string cls = ent.GetClassname();
        string name = ent.GetEntityName();
        if (cls == "info_paint_sprayer" || cls == "paint_sphere" || name.locate("paint") != uint(-1) || name.locate("sprayer") != uint(-1)) {
            count++;
            Vector pos = ent.GetAbsOrigin();
            Msgl("[AP] Sprayer [" + ent.GetEntityIndex() + "] Class: " + cls + " | Name: '" + name + "' | Pos: " + pos.x + " " + pos.y + " " + pos.z);
            
            // Look for a nearby hologram
            bool hasHolo = false;
            CBaseEntity@ h = EntityList().First();
            while (@h !is null) {
                if (h.GetClassname() == "prop_dynamic" && h.GetModelName().locate("hologram") != uint(-1)) {
                    float dist = (h.GetAbsOrigin() - ent.GetAbsOrigin()).Length();
                    if (dist < 100.0f) { hasHolo = true; break; }
                }
                @h = EntityList().Next(h);
            }
            Msgl("[AP]   -> Holo Detected: " + (hasHolo ? "YES" : "NO"));
        }
        @ent = EntityList().Next(ent);
    }
    Msgl("[AP] Found " + count + " gel-related entities.");
}

// -------------------------------------------------------------
// CORE ARCHIPELAGO COMMANDS
// -------------------------------------------------------------

[ServerCommand("ReportAPButton", "Routes button press")]
void ReportAPButtonCmd(const CommandArgs@ args) {
    if (args is null || args.ArgC() < 2) return;
    RunButtonScenarioCheck(args.Arg(1));
}

[ServerCommand("CreateAPButton", "Spawns custom buttons")]
void CreateAPButtonCmd(const CommandArgs@ args) {
    if (args is null) return;
    string raw = args.GetCommandString();
    uint vIdx = raw.locate("Vector");
    if (vIdx == uint(-1)) return;

    string name = raw.substr(0, int(vIdx)).replace("\x22", "").replace("'", "").replace("(", "").replace(",", "").replace("CreateAPButton", "").trim();
    array<float> c = ExtractFloats(raw.substr(int(vIdx)));
    
    if (c.length() >= 7) {
        SpawnAPButtonLogic(name, Vector(c[0], c[1], c[2]), QAngle(c[3], c[4], c[5]), c[6]);
    }
}

[ServerCommand("DeleteEntity", "Removes entities and optionally spawns a hologram")]
void DeleteEntityCmd(const CommandArgs@ args) {
    if (args.ArgC() < 2) return;
    string target = args.Arg(1);
    bool create_holo = (args.ArgC() > 2) ? (args.Arg(2) == "1") : true;
    float scale = (args.ArgC() > 3) ? args.Arg(3).toFloat() : 0.7f;
    DeleteEntity(target, create_holo, scale);
}

[ServerCommand("ap_dump_holos", "Prints all active Archipelago holograms in the map")]
void DumpAPHolosCmd(const CommandArgs@ args) {
    CBaseEntity@ holo = null;
    int count = 0;
    Msgl("============================================");
    Msgl("   ARCHIPELAGO HOLOGRAM REGISTRY DUMP");
    Msgl("============================================");
    while ((@holo = EntityList().FindByClassname(holo, "prop_dynamic")) !is null) {
        if (holo.GetModelName().locate("archipelago_hologram") != uint(-1)) {
            string hName = holo.GetEntityName();
            Vector hPos = holo.GetAbsOrigin();
            QAngle hAng = holo.GetAbsAngles();
            Msgl(" > Holo [" + count + "] Name: '" + hName + "'");
            Msgl("   Pos: Vector(" + hPos.x + ", " + hPos.y + ", " + hPos.z + ")");
            Msgl("   Ang: QAngle(" + hAng.x + ", " + hAng.y + ", " + hAng.z + ")");
            count++;
        }
    }
    Msgl("============================================");
    Msgl(" Total Holograms active: " + count);
    Msgl("============================================");
}

[ServerCommand("DeleteCoreOnOutput", "Queues core deletion for a specific entity output")]
void DeleteCoreOnOutputCmd(const CommandArgs@ args) {
    if (args.ArgC() < 4) return;
    DeleteCoreOnOutput(args.Arg(1), args.Arg(2), args.Arg(3));
}

[ServerCommand("AddButtonFrame", "Adds frame/hologram to a pedestal button")]
void AddButtonFrameCmd(const CommandArgs@ args) {
    if (args.ArgC() < 2) return;
    AddButtonFrame(args.Arg(1));
}

[ServerCommand("AddFloorButtonFrame", "Adds frame/hologram to a floor button")]
void AddFloorButtonFrameCmd(const CommandArgs@ args) {
    if (args.ArgC() < 2) return;
    AddFloorButtonFrame(args.Arg(1));
}

[ServerCommand("DisablePortalGun", "Disables specific portals on the player gun")]
void DisablePortalGunCmd(const CommandArgs@ args) {
    if (args.ArgC() < 3) return;
    bool blue = (args.Arg(1) == "1");
    bool orange = (args.Arg(2) == "1");
    DisablePortalGun(blue, orange);
}

[ServerCommand("DisableEntityPickup", "Global lock on generic entity picking up")]
void DisableEntityPickupCmd(const CommandArgs@ args) {
    if (args.ArgC() < 2) return;
    DisableEntityPickup(args.Arg(1));
}

[ServerCommand("AttachHologramToEntity", "Forces a hologram to stick to a moving entity")]
void AttachHologramToEntityCmd(const CommandArgs@ args) {
    if (args.ArgC() < 6) return;
    AttachHologramToEntity(args.Arg(1), args.Arg(2), args.Arg(3).toFloat(), args.Arg(4).toFloat(), args.Arg(5).toInt());
}

[ServerCommand("ap_spawn_holos", "One-time map hologram initialization")]
void APSpawnHolosCmd(const CommandArgs@ args) {
    UpdateInternalMapName();
    CreateMapSpecificHolos(current_map);
}

[ServerCommand("FinishedMap", "Triggers map completion logic")]
void APPrintCompleteCmd(const CommandArgs@ args) {
    PrintMapComplete();
}

[ServerCommand("ap_print_complete_no_exit", "Triggers map completion logic without exiting")]
void APPrintCompleteNoExitCmd(const CommandArgs@ args) {
    PrintMapCompleteNoExit();
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

[ServerCommand("ap_print_monitor", "Internal - Prints monitor break check to console")]
void APPrintMonitorCmd(const CommandArgs@ args) {
    if (args is null) return;
    string raw = args.GetCommandString();
    
    uint spaceIdx = raw.locate(" ");
    if (spaceIdx != uint(-1)) {
        string check = raw.substr(int(spaceIdx) + 1).trim();
        check = check.replace(".", " "); // Restore spaces from periods
        
        // Suppression check: Don't print if already reported this session
        if (g_reported_monitors.find(check) >= 0) return;
        g_reported_monitors.insertLast(check);

        Msgl("monitor_break:" + check);

        // Map-Specific Monitor Teleports
        HandleMonitorWarp(check);
    }
}

[ServerCommand("AddWheatleyMonitorBreakCheck", "Manually triggers Wheatley monitor break check setup")]
void AddWheatleyMonitorBreakCheckCmd(const CommandArgs@ args) {
    UpdateInternalMapName();
    AddWheatleyMonitorBreakCheck(current_map);
}

[ServerCommand("RemovePotatOS", "Removes PotatOS and establishes instructor hints")]
void APRemovePotatOSCmd(const CommandArgs@ args) {
    RemovePotatOS();
}

[ServerCommand("InciniratorDisablePortalGun", "Bridge from VScript/Client")]
void InciniratorDisablePortalGunCmd(const CommandArgs@ args) {
    IncineratorDisablePortalGun();
}

[ServerCommand("BlockWheatleyFight", "Blocks the Wheatley fight and establishes instructor hints")]
void APBlockWheatleyFightCmd(const CommandArgs@ args) {
    BlockWheatleyFight();
}

[ServerCommand("ap_hologram_offset", "Nudges the nearest hologram: ap_hologram_offset x y z")]
void APHologramOffsetCmd(const CommandArgs@ args) {
    if (args.ArgC() < 4) return;
    float x = args.Arg(1).toFloat();
    float y = args.Arg(2).toFloat();
    float z = args.Arg(3).toFloat();
    
    // 1. Find nearest hologram
    CBaseEntity@ nearest = null;
    float minDist = 999999.0f;
    CBaseEntity@ ent = null;
    
    CBaseEntity@ player = EntityList().FindByClassname(null, "player");
    if (player is null) {
        Msgl("[AP] Error: Could not find player to calculate nudge distance.");
        return;
    }
    Vector pPos = player.GetAbsOrigin();

    while ((@ent = EntityList().FindByClassname(ent, "prop_dynamic")) !is null) {
        if (ent.GetModelName().locate("archipelago_hologram") != uint(-1)) {
            float d = (ent.GetAbsOrigin() - pPos).Length();
            if (d < minDist) {
                minDist = d;
                @nearest = ent;
            }
        }
    }

    if (nearest !is null && minDist < 300.0f) {
        Vector newPos = nearest.GetAbsOrigin() + Vector(x, y, z);
        nearest.SetAbsOrigin(newPos);
        Msgl("[AP] Nudged '" + nearest.GetEntityName() + "' to: " + newPos.x + " " + newPos.y + " " + newPos.z);
    } else {
        Msgl("[AP] No hologram near enough to nudge (limit 300 units).");
    }
}

[ServerCommand("ap_hologram_rotate", "Rotates the nearest hologram: ap_hologram_rotate p y r")]
void APHologramRotateCmd(const CommandArgs@ args) {
    if (args.ArgC() < 4) return;
    float p = args.Arg(1).toFloat();
    float y = args.Arg(2).toFloat();
    float r = args.Arg(3).toFloat();

    CBaseEntity@ nearest = null;
    float minDist = 999999.0f;
    CBaseEntity@ ent = null;
    CBaseEntity@ player = EntityList().FindByClassname(null, "player");
    if (player is null) {
        Msgl("[AP] Error: Rotate tool could not find player.");
        return;
    }
    Vector pPos = player.GetAbsOrigin();

    int foundCount = 0;
    while ((@ent = EntityList().FindByClassname(ent, "prop_dynamic")) !is null) {
        if (ent.GetModelName().locate("archipelago_hologram") != uint(-1)) {
            foundCount++;
            float d = (ent.GetAbsOrigin() - pPos).Length();
            if (d < minDist) {
                minDist = d;
                @nearest = ent;
            }
        }
    }

    if (nearest !is null && minDist < 300.0f) {
        QAngle angles = nearest.GetAbsAngles();
        angles.x += p;
        angles.y += y;
        angles.z += r;
        nearest.SetAbsAngles(angles);
        Msgl("[AP] Rotated '" + nearest.GetEntityName() + "' to: " + angles.x + " " + angles.y + " " + angles.z);
    } else {
        Msgl("[AP] No hologram near enough to rotate (Evaluated " + foundCount + " candidates). Distance: " + (nearest !is null ? string(minDist) : "N/A"));
    }
}

[ServerCommand("RemovePotatosFromGun", "Removes PotatOS from the gun")]
void RemovePotatosFromGunCmd(const CommandArgs@ args) {
    RemovePotatosFromGun();
}

[ServerCommand("RestorePotatosToGun", "Restores PotatOS to the gun")]
void RestorePotatosToGunCmd(const CommandArgs@ args) {
    RestorePotatosToGun();
}

[ServerCommand("RestoreCatapults", "Re-enables all Aerial Faith Plates")]
void RestoreCatapultsCmd(const CommandArgs@ args) {
    CBaseEntity@ catapult = null;
    while ((@catapult = EntityList().FindByClassname(catapult, "trigger_catapult")) !is null) {
        string catName = catapult.GetEntityName();
        
        // Exception for sp_a2_sphere_peek
        if (current_map == "sp_a2_sphere_peek" && catName == "catapult2_up") {
            // Keep disabled, but proceed to delete the hologram
        } else {
            catapult.FireInput("Enable", Variant(), 0.0f, null, null, 0);
        }

        string holoName = catName + "_holo";
        if (catName == "") holoName = "trigger_catapult_holo";
        
        CBaseEntity@ holo = null;
        while ((@holo = EntityList().FindByName(holo, holoName)) !is null) {
            holo.FireInput("Kill", Variant(), 0.0f, null, null, 0);
        }
    }

    CBaseEntity@ plate = null;
    while ((@plate = EntityList().FindByClassname(plate, "prop_dynamic")) !is null) {
        if (plate.GetModelName().locate("faith_plate") != uint(-1)) {
            Variant vSkin;
            vSkin.SetString("0");
            plate.FireInput("Skin", vSkin, 0.0f, null, null, 0);
        }
    }

    int disabledCount = 0;
    CBaseEntity@ catCheck = null;
    while ((@catCheck = EntityList().FindByClassname(catCheck, "trigger_catapult")) !is null) {
        string cName = catCheck.GetEntityName();
        string hName = cName + "_holo";
        if (cName == "") hName = "trigger_catapult_holo";
        
        CBaseEntity@ holoCheck = EntityList().FindByName(null, hName);
        if (holoCheck !is null || (current_map == "sp_a2_sphere_peek" && cName == "catapult2_up")) {
            disabledCount++;
        }
    }

    CBaseEntity@ ent = null;
    while ((@ent = EntityList().Next(ent)) !is null) {
        string n = ent.GetEntityName();
        if (n.locate("ap_cat_snd_") == 0 || n.locate("ap_hint_") == 0 || n.locate("ap_hint_target_") == 0) {
            ent.FireInput("Kill", Variant(), 0.0f, null, null, 0);
        }
        
        if (n.locate("ap_cat_timer") == 0 && disabledCount == 0) {
            ent.FireInput("Kill", Variant(), 0.0f, null, null, 0);
        }
    }
}

[ServerCommand("ap_catapult_effect_check", "Plays sound and sets skin to 1 if player is near a disabled catapult")]
void APCatapultEffectCheckCmd(const CommandArgs@ args) {
    CBaseEntity@ player = EntityList().FindByClassname(null, "player");
    if (player is null) return;
    
    Vector pPos = player.GetAbsOrigin();
    CBaseEntity@ catapult = null;
    
    while ((@catapult = EntityList().FindByClassname(catapult, "trigger_catapult")) !is null) {
        string catName = catapult.GetEntityName();
        string holoName = catName + "_holo";
        if (catName == "") holoName = "trigger_catapult_holo";
        CBaseEntity@ holo = EntityList().FindByName(null, holoName);
        if (holo is null) {
            if (current_map == "sp_a2_sphere_peek" && catName == "catapult2_up") {
                // Keep checking even without the hologram!
            } else {
                continue;
            }
        }
        
        float distToPlayer = (catapult.GetAbsOrigin() - pPos).Length();
        
        CBaseEntity@ plate = null;
        while ((@plate = EntityList().FindByClassname(plate, "prop_dynamic")) !is null) {
            if (plate.GetModelName().locate("faith_plate") != uint(-1)) {
                float distToPlate = (plate.GetAbsOrigin() - catapult.GetAbsOrigin()).Length();
                if (distToPlate < 128.0f) {
                    Vector pMins, pMaxs;
                    player.ComputeWorldSpaceSurroundingBox(pMins, pMaxs);
                    
                    Vector catMins, catMaxs;
                    catapult.ComputeWorldSpaceSurroundingBox(catMins, catMaxs);
                    
                    // Expand bounds slightly
                    catMins.x -= 5.0f;
                    catMins.y -= 5.0f;
                    catMins.z -= 5.0f;
                    catMaxs.x += 5.0f;
                    catMaxs.y += 5.0f;
                    catMaxs.z += 5.0f;
                    
                    bool isTouching = (distToPlayer < 80.0f) &&
                        (pMins.x <= catMaxs.x && pMaxs.x >= catMins.x) &&
                            (pMins.y <= catMaxs.y && pMaxs.y >= catMins.y) &&
                                (pMins.z <= catMaxs.z && pMaxs.z >= catMins.z);

                    if (isTouching) {
                        Variant vSkin1;
                        vSkin1.SetString("1");
                        plate.FireInput("Skin", vSkin1, 0.0f, null, null, 0);
                        
                        Variant vSkin0;
                        vSkin0.SetString("0");
                        plate.FireInput("Skin", vSkin0, 0.5f, null, null, 0);
                        
                        CBaseEntity@ snd = EntityList().FindByName(null, "ap_cat_snd_" + plate.GetEntityName());
                        if (snd !is null) {
                            snd.FireInput("PlaySound", Variant(), 0.0f, null, null, 0);
                        }
                        
                        CBaseEntity@ hint = EntityList().FindByName(null, "ap_hint_" + plate.GetEntityName());
                        if (hint !is null) {
                            hint.FireInput("ShowHint", Variant(), 0.0f, null, null, 0);
                        }
                        ap_last_hinted_catapult = plate.GetEntityName();
                    } else {
                        Variant vSkin;
                        vSkin.SetString("0");
                        plate.FireInput("Skin", vSkin, 0.0f, null, null, 0);
                        
                        if (ap_last_hinted_catapult == plate.GetEntityName()) {
                            CBaseEntity@ hint = EntityList().FindByName(null, "ap_hint_" + plate.GetEntityName());
                            if (hint !is null) {
                                hint.FireInput("EndHint", Variant(), 2.0f, null, null, 0);
                            }
                            ap_last_hinted_catapult = "";
                        }
                    }
                    break;
                }
            }
        }
    }
}

[ServerCommand("ap_restore_catapults", "Alias for RestoreCatapults")]
void APRestoreCatapultsCmd(const CommandArgs@ args) {
    RestoreCatapultsCmd(args);
}

[ServerCommand("ap_debug_scanall", "Scans for all Archipelago-relevant checks in the map")]
void APDebugScanAllCmd(const CommandArgs@ args) {
    int count = 0;
    CBaseEntity@ ent = null;
    Msgl("[AP] Scanning for all items (lasers, bridges, turrets, sprayers, etc)...");
    
    while ((@ent = EntityList().Next(ent)) !is null) {
        string cls = ent.GetClassname();
        string name = ent.GetEntityName();
        string model = ent.GetModelName();
        
        bool isCheck = false;
        if (cls.locate("laser") != uint(-1) || name.locate("laser") != uint(-1)) isCheck = true;
        if (cls.locate("paint") != uint(-1) || name.locate("paint") != uint(-1)) isCheck = true;
        if (cls.locate("bridge") != uint(-1) || cls == "prop_wall_projector") isCheck = true;
        if (cls.locate("turret") != uint(-1)) isCheck = true;
        if (cls.locate("button") != uint(-1)) isCheck = true;
        if (cls.locate("dropper") != uint(-1) || name.locate("dropper") != uint(-1)) isCheck = true;

        if (isCheck) {
            count++;
            Vector pos = ent.GetAbsOrigin();
            Msgl("  > [" + count + "] [" + cls + "] " + (name == "" ? "(unnamed)" : name));
            Msgl("    - Pos: " + pos.x + " " + pos.y + " " + pos.z);
            if (model != "") Msgl("    - Model: " + model);
        }
    }
    
    Msgl("[AP] Scan complete. Found " + count + " relevant entities.");
}

[ServerCommand("ap_debug_find", "Tests the FindEntities function")]
void APDebugFindCmd(const CommandArgs@ args) {
    if (args.ArgC() < 2) {
        Msgl("Usage: ap_debug_find <search_string>");
        return;
    }
    
    string search = args.Arg(1);
    Msgl("[AP] Testing FindEntities for: " + search);
    
    array<CBaseEntity@> targets = FindEntities(search);
    Msgl("Found " + targets.length() + " result(s):");
    
    for (uint i = 0; i < targets.length(); i++) {
        CBaseEntity@ t = targets[i];
        Msgl("  > [" + (i + 1) + "] [" + t.GetClassname() + "] " + t.GetEntityName());
        Msgl("    - Pos: " + t.GetAbsOrigin().x + " " + t.GetAbsOrigin().y + " " + t.GetAbsOrigin().z);
    }
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
