// =============================================================
// ARCHIPELAGO SERVER COMMAND
// =============================================================



/**
 * APDebugSprayersCmd - Prints diagnostic info for all gel dispensers.
 */
[ServerCommand("DebugSprayers", "Diagnostics for paint sprayers")]
void DebugSprayersCmd(const CommandArgs@ args) {
    ArchipelagoLog("[Archipelago] --- SPRAYER DIAGNOSTICS ---");
    CBaseEntity@ ent = EntityList().First();
    int count = 0;
    while (@ent !is null) {
        string cls = ent.GetClassname();
        string name = ent.GetEntityName();
        if (cls == "info_paint_sprayer" || cls == "paint_sphere" || name.locate("paint") != uint(-1) || name.locate("sprayer") != uint(-1)) {
            count++;
            Vector pos = ent.GetAbsOrigin();
            ArchipelagoLog("[Archipelago] Sprayer [" + ent.GetEntityIndex() + "] Class: " + cls + " | Name: '" + name + "' | Pos: " + pos.x + " " + pos.y + " " + pos.z);
            
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
            ArchipelagoLog("[Archipelago]   -> Holo Detected: " + (hasHolo ? "YES" : "NO"));
        }
        @ent = EntityList().Next(ent);
    }
    ArchipelagoLog("[Archipelago] Found " + count + " gel-related entities.");
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
        CreateAPButton(name, Vector(c[0], c[1], c[2]), QAngle(c[3], c[4], c[5]), c[6]);
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

[ServerCommand("RemoveGel", "Removes gel sprayer/entity and clears floor: RemoveGel x y z [type] [name] [create_holo]")]
void RemoveGelCmd(const CommandArgs@ args) {
    if (args.ArgC() < 4) return;
    Vector pos(args.Arg(1).toFloat(), args.Arg(2).toFloat(), args.Arg(3).toFloat());
    string type = (args.ArgC() > 4) ? args.Arg(4) : "";
    string name = (args.ArgC() > 5) ? args.Arg(5) : "";
    bool createHolo = (args.ArgC() > 6) ? (args.Arg(6).toInt() != 0) : true;
    RemoveGel(pos, type, name, createHolo);
}

[ServerCommand("CreateClearGel", "Spawns a water paint bomb to clear gel: CreateClearGel x y z [offset]")]
void CreateClearGelCmd(const CommandArgs@ args) {
    if (args.ArgC() < 4) return;
    Vector pos(args.Arg(1).toFloat(), args.Arg(2).toFloat(), args.Arg(3).toFloat());
    float offset = (args.ArgC() > 4) ? args.Arg(4).toFloat() : -100.0f;
    CreateClearGel(pos, offset);
}

[ServerCommand("GlobalDeleteClass", "Mark a class for persistent deletion/hologram replacement")]
void GlobalDeleteClassCmd(const CommandArgs@ args) {
    if (args.ArgC() < 2) return;
    string cls = args.Arg(1);
    
    // Avoid duplicates
    for (uint i = 0; i < g_suppressed_classes.length(); i++) {
        if (g_suppressed_classes[i] == cls) return;
    }
    
    g_suppressed_classes.insertLast(cls);
    ArchipelagoLog("[Archipelago] Persistent suppression enabled for class: " + cls);
}

[ServerCommand("DumpHolos", "Prints all active Archipelago holograms in the map")]
void DumpAPHolosCmd(const CommandArgs@ args) {
    CBaseEntity@ holo = null;
    int count = 0;
    ArchipelagoLog("============================================");
    ArchipelagoLog("   ARCHIPELAGO HOLOGRAM REGISTRY DUMP");
    ArchipelagoLog("============================================");
    while ((@holo = EntityList().FindByClassname(holo, "prop_dynamic")) !is null) {
        if (holo.GetModelName().locate("archipelago_hologram") != uint(-1)) {
            string hName = holo.GetEntityName();
            Vector hPos = holo.GetAbsOrigin();
            QAngle hAng = holo.GetAbsAngles();
            ArchipelagoLog(" > Holo [" + count + "] Name: '" + hName + "'");
            ArchipelagoLog("   Pos: Vector(" + hPos.x + ", " + hPos.y + ", " + hPos.z + ")");
            ArchipelagoLog("   Ang: QAngle(" + hAng.x + ", " + hAng.y + ", " + hAng.z + ")");
            count++;
        }
    }
    ArchipelagoLog("============================================");
    ArchipelagoLog(" Total Holograms active: " + count);
    ArchipelagoLog("============================================");
}

[ServerCommand("DeleteCoreOnOutput", "Queues core deletion for a specific entity output")]
void DeleteCoreOnOutputCmd(const CommandArgs@ args) {
    if (args.ArgC() < 4) return;
    DeleteCoreOnOutput(args.Arg(1), args.Arg(2), args.Arg(3));
}

[ServerCommand("AddScript", "Connects an entity output to a console script")]
void AddScriptCmd(const CommandArgs@ args) {
    if (args.ArgC() < 4) return;
    AddEntityOutputScript(args.Arg(1), args.Arg(2), args.Arg(3), (args.ArgC() > 4 ? args.Arg(4).toFloat() : 0.0f), (args.ArgC() > 5 ? args.Arg(5).toInt() : -1));
}

[ServerCommand("AddScriptAtPos", "Connects an entity output to a console script by position")]
void AddScriptAtPosCmd(const CommandArgs@ args) {
    if (args.ArgC() < 6) return;
    Vector pos(args.Arg(1).toFloat(), args.Arg(2).toFloat(), args.Arg(3).toFloat());
    AddEntityOutputScriptAtPos(pos, args.Arg(4), args.Arg(5), args.Arg(6), (args.ArgC() > 7 ? args.Arg(7).toFloat() : 0.0f), (args.ArgC() > 8 ? args.Arg(8).toInt() : -1));
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





[ServerCommand("SetStatus", "Live refresh of all Archipelago visual states")]
void SetStatusCmd(const CommandArgs@ args) {
    if (args is null || args.ArgC() < 2) return;
    
    if (cv_ArchipelagoDebug.GetBool()) {
        ArchipelagoLog("[Archipelago] SetStatus received: C=" + args.ArgC() + " 1=" + args.Arg(1) + " 2=" + args.Arg(2) + " 6=" + args.Arg(6));
    }

    g_map_status = args.Arg(1).toInt();
    
    if (args.ArgC() >= 3) {
        g_ratman_status = args.Arg(2).toInt();
    }

    if (args.ArgC() >= 4) {
        g_portal_gun_status = args.Arg(3).toInt();
    }

    if (args.ArgC() > 4) g_potatos_status = args.Arg(4).toInt();
    
    if (args.ArgC() >= 6) {
        g_wheatley_status = args.Arg(5).toInt();
    }
    
    if (args.ArgC() >= 7) {
        g_map_symbols = args.Arg(6);
    }
    
    RefreshAllAPHolograms();
}

[ServerCommand("ArchipelagoShowStatus", "Manually show the map status HUD")]
void ArchipelagoShowStatusCmd(const CommandArgs@ args) {
    RefreshAllAPHolograms();
    // This command is primarily intercepted by Panorama
}

[ServerCommand("DisableEntityPhysics", "Freezes an entity in place")]
void DisableEntityPhysicsCmd(const CommandArgs@ args) {
    if (args.ArgC() < 2) return;
    string target = args.Arg(1);
    
    CBaseEntity@ ent = null;
    while ((@ent = EntityList().FindByName(ent, target)) !is null) {
        ent.SetMoveType(MOVETYPE_NONE);
        ArchipelagoLog("[Archipelago] Physics disabled for: " + target);
    }
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

[ServerCommand("SpawnHolos", "One-time map hologram initialization")]
void SpawnHolosCmd(const CommandArgs@ args) {
    UpdateInternalMapName();
    CreateMapSpecificHolos(current_map);
}

[ServerCommand("FinishedMap", "Triggers map completion logic")]
void PrintCompleteCmd(const CommandArgs@ args) {
    PrintMapComplete();
}

[ServerCommand("PrintCompleteNoExit", "Triggers map completion logic without exiting")]
void PrintCompleteNoExitCmd(const CommandArgs@ args) {
    PrintMapCompleteNoExit();
}

[ServerCommand("WarpToMenu", "Internal - Warps back to menu")]
void WarpToMenuCmd(const CommandArgs@ args) {
    CBaseEntity@ cmdEnt = EntityList().FindByName(null, "InitCmd");
    if (cmdEnt !is null) {
        Variant vCmd;
        vCmd.SetString("host_timescale 1.0");
        cmdEnt.FireInput("Command", vCmd, 0.0f, null, null, 0);
    }
    WarpToMenu();
}

[ServerCommand("ShowStatus", "Toggle Archipelago Map Status HUD")]
void ShowStatusCmd(const CommandArgs@ args) {
    UpdateInternalMapName();
    CallVScript("SendToPanorama(\"ArchipelagoMapNameUpdated\", \"" + current_map + "|1\")");
}

[ServerCommand("RefreshMapName", "Forces a map name update to Panorama")]
void RefreshMapNameCmd(const CommandArgs@ args) {
    // Force reset the cached name to ensure the event fires
    current_map = ""; 
    UpdateInternalMapName();
    CallVScript("SendToPanorama(\"ArchipelagoMapNameUpdated\", \"" + current_map + "|1\")");
}

[ServerCommand("PrintItem", "Prints collected item")]
void PrintItemCmd(const CommandArgs@ args) {
    if (args is null) return;
    string raw = args.GetCommandString();
    uint spaceIdx = raw.locate(" ");
    if (spaceIdx != uint(-1)) {
        string item = raw.substr(int(spaceIdx) + 1).trim();
        ArchipelagoLog("item_collected:" + item);
    }
}

[ServerCommand("PrintMonitor", "Internal - Prints monitor break check to console")]
void PrintMonitorCmd(const CommandArgs@ args) {
    if (args is null) return;
    string raw = args.GetCommandString();
    
    uint spaceIdx = raw.locate(" ");
    if (spaceIdx != uint(-1)) {
        string check = raw.substr(int(spaceIdx) + 1).trim();
        check = check.replace(".", " "); // Restore spaces from periods
        
        // Suppression check: Don't print if already reported this session
        if (g_reported_monitors.find(check) >= 0) return;
        g_reported_monitors.insertLast(check);

        ArchipelagoLog("monitor_break:" + check);
        RefreshAllAPHolograms();

        // Map-Specific Monitor Teleports
        HandleMonitorWarp(check);
    }
}

[ServerCommand("AddWheatleyMonitorBreakCheck", "Manually triggers Wheatley monitor break check setup")]
void AddWheatleyMonitorBreakCheckCmd(const CommandArgs@ args) {
    UpdateInternalMapName();
    AddWheatleyMonitorBreakCheck(current_map);
}



[ServerCommand("RainbowTick", "Internal master tick for rainbow effects")]
void RainbowTickCmd(const CommandArgs@ args) {
    RunRainbowTick();
}

[ServerCommand("Rainbow", "Toggles rainbow color swap effect for all entities")]
void RainbowCmd(const CommandArgs@ args) {
    g_rainbow_active = !g_rainbow_active;
    
    CBaseEntity@ oldTimer = EntityList().FindByName(null, "RainbowTimer");
    if (oldTimer !is null) oldTimer.Remove();
    
    if (g_rainbow_active) {
        ArchipelagoLog("[Archipelago] Rainbow Mode Activated!");
        CBaseEntity@ timer = util::CreateEntityByName("logic_timer");
        if (timer !is null) {
            timer.KeyValue("targetname", "RainbowTimer");
            timer.KeyValue("RefireTime", "0.015");
            timer.Spawn();
            
            Variant v;
            v.SetString("OnTimer InitCmd:Command:RainbowTick:0.0:-1");
            timer.FireInput("AddOutput", v, 0.0f, null, null);
        }
    } else {
        ArchipelagoLog("[Archipelago] Rainbow Mode Deactivated!");
        Variant vDefault;
        vDefault.SetString("255 255 255");
        
        Variant vLaserDefault;
        vLaserDefault.SetString("255 0 0 255");

        CBaseEntity@ ent = EntityList().First();
        while (@ent !is null) {
            string cls = ent.GetClassname();
            if (cls == "prop_weighted_cube") {
                ent.FireInput("Color", vDefault, 0.0f, null, null);
            } else if (cls == "env_portal_laser") {
                ent.FireInput("SetBeamColor", vLaserDefault, 0.0f, null, null);
            }
            @ent = EntityList().Next(ent);
        }
    }
}

[ServerCommand("RainbowCubes", "Alias master command toggle")]
void RainbowCubesCmd(const CommandArgs@ args) {
    RainbowCmd(args);
}

[ServerCommand("RainbowLasers", "Alias master command toggle")]
void RainbowLasersCmd(const CommandArgs@ args) {
    RainbowCmd(args);
}

[ServerCommand("RemovePotatOS", "Removes PotatOS and establishes instructor hints")]
void RemovePotatOSCmd(const CommandArgs@ args) {
    RemovePotatOS();
}

[ServerCommand("InciniratorDisablePortalGun", "Bridge from VScript/Client")]
void InciniratorDisablePortalGunCmd(const CommandArgs@ args) {
    IncineratorDisablePortalGun();
}

[ServerCommand("BlockWheatleyFight", "Blocks the Wheatley fight and establishes instructor hints")]
void BlockWheatleyFightCmd(const CommandArgs@ args) {
    BlockWheatleyFight();
}

[ServerCommand("HologramOffset", "Nudges the nearest hologram: HologramOffset x y z")]
void HologramOffsetCmd(const CommandArgs@ args) {
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
        ArchipelagoLog("[Archipelago] Error: Could not find player to calculate nudge distance.");
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
        ArchipelagoLog("[Archipelago] Nudged '" + nearest.GetEntityName() + "' to: " + newPos.x + " " + newPos.y + " " + newPos.z);
    } else {
        ArchipelagoLog("[Archipelago] No hologram near enough to nudge (limit 300 units).");
    }
}

[ServerCommand("HologramRotate", "Rotates the nearest hologram: HologramRotate p y r")]
void HologramRotateCmd(const CommandArgs@ args) {
    if (args.ArgC() < 4) return;
    float p = args.Arg(1).toFloat();
    float y = args.Arg(2).toFloat();
    float r = args.Arg(3).toFloat();

    CBaseEntity@ nearest = null;
    float minDist = 999999.0f;
    CBaseEntity@ ent = null;
    CBaseEntity@ player = EntityList().FindByClassname(null, "player");
    if (player is null) {
        ArchipelagoLog("[Archipelago] Error: Rotate tool could not find player.");
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
        ArchipelagoLog("[Archipelago] Rotated '" + nearest.GetEntityName() + "' to: " + angles.x + " " + angles.y + " " + angles.z);
    } else {
        ArchipelagoLog("[Archipelago] No hologram near enough to rotate (Evaluated " + foundCount + " candidates). Distance: " + (nearest !is null ? string(minDist) : "N/A"));
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
    RestoreCatapults();
}

[ServerCommand("CatapultEffectCheck", "Plays sound and sets skin to 1 if player is near a disabled catapult")]
void CatapultEffectCheckCmd(const CommandArgs@ args) {
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
            // Try indexed name too
            holoName = catName + "_" + catapult.GetEntityIndex() + "_holo";
            @holo = EntityList().FindByName(null, holoName);
        }

        if (holo is null) {
            if (current_map == "sp_a2_sphere_peek" && catName == "catapult2_up") {
                // Known exception
            } else {
                // If it's a catapult, we should probably still check proximity even if holo is missing
                // but let's at least not hard-fail if we have a valid catapult entity
            }
        }

        CBaseEntity@ plate = null;
        while ((@plate = EntityList().FindByClassname(plate, "prop_dynamic")) !is null) {
            if (plate.GetModelName().locate("faith_plate") != uint(-1)) {
                float distToPlate = (plate.GetAbsOrigin() - catapult.GetAbsOrigin()).Length();
                if (distToPlate < 128.0f) {
                    float distToPlayer = (plate.GetAbsOrigin() - pPos).Length();
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
                    
                    bool isTouching = (distToPlayer < 120.0f);

                    if (isTouching) {
                        ArchipelagoLog("[Archipelago] Catapult proximity detected for " + plate.GetEntityName());
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
                        last_hinted_catapult = plate.GetEntityName();
                    } else {
                        Variant vSkin;
                        vSkin.SetString("0");
                        plate.FireInput("Skin", vSkin, 0.0f, null, null, 0);
                        
                        if (last_hinted_catapult == plate.GetEntityName()) {
                            CBaseEntity@ hint = EntityList().FindByName(null, "ap_hint_" + plate.GetEntityName());
                            if (hint !is null) {
                                hint.FireInput("EndHint", Variant(), 2.0f, null, null, 0);
                            }
                            last_hinted_catapult = "";
                        }
                    }
                    break;
                }
            }
        }
    }
}

[ServerCommand("RestoreCatapultsAlias", "Alias for RestoreCatapults")]
void RestoreCatapultsAliasCmd(const CommandArgs@ args) {
    RestoreCatapultsCmd(args);
}

[ServerCommand("DebugScanAll", "Scans for all Archipelago-relevant checks in the map")]
void DebugScanAllCmd(const CommandArgs@ args) {
    int count = 0;
    CBaseEntity@ ent = null;
    ArchipelagoLog("[Archipelago] Scanning for all items (lasers, bridges, turrets, sprayers, etc)...");
    
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
            ArchipelagoLog("  > [" + count + "] [" + cls + "] " + (name == "" ? "(unnamed)" : name));
            ArchipelagoLog("    - Pos: " + pos.x + " " + pos.y + " " + pos.z);
            if (model != "") ArchipelagoLog("    - Model: " + model);
        }
    }
    
    ArchipelagoLog("[Archipelago] Scan complete. Found " + count + " relevant entities.");
}

[ServerCommand("DebugFind", "Tests the FindEntities function")]
void DebugFindCmd(const CommandArgs@ args) {
    if (args.ArgC() < 2) {
        ArchipelagoLog("Usage: DebugFind <search_string>");
        return;
    }
    
    string search = args.Arg(1);
    ArchipelagoLog("[Archipelago] Testing FindEntities for: " + search);
    
    array<CBaseEntity@> targets = FindEntities(search);
    ArchipelagoLog("Found " + targets.length() + " result(s):");
    
    for (uint i = 0; i < targets.length(); i++) {
        CBaseEntity@ t = targets[i];
        ArchipelagoLog("  > [" + (i + 1) + "] [" + t.GetClassname() + "] " + t.GetEntityName());
        ArchipelagoLog("    - Pos: " + t.GetAbsOrigin().x + " " + t.GetAbsOrigin().y + " " + t.GetAbsOrigin().z);
    }
}

// -------------------------------------------------------------
// HEARTBEAT COMMANDS
// -------------------------------------------------------------

[ServerCommand("DeathlinkTick", "Internal mod deathlink heartbeat")]
void DeathlinkTickCmd(const CommandArgs@ args) {
    RunDeathLinkTick();
}

[ServerCommand("GameStatusTick", "Internal mod game status heartbeat")]
void GameStatusTickCmd(const CommandArgs@ args) {
    RunGameStatusTickCommand(args);
}

[ServerCommand("RunDelayedInit", "Runs one-time map setup")]
void RunDelayedInitCmd(const CommandArgs@ args) {
    RunDelayedInitialization();
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
    float duration = (args !is null && args.ArgC() >= 2) ? args.Arg(1).toFloat() : 20.0f;
    TriggerMotionBlurTrap(duration);
}

[ServerCommand("SlipperyFloorTrap", "Triggers slippery floor trap")]
void SlipperyFloorTrapCmd(const CommandArgs@ args) {
    float duration = (args !is null && args.ArgC() >= 2) ? args.Arg(1).toFloat() : 15.0f;
    TriggerSlipperyFloorTrap(duration);
}

[ServerCommand("FizzlePortalTrap", "Triggers fizzle portal trap")]
void FizzlePortalTrapCmd(const CommandArgs@ args) {
    TriggerFizzlePortalTrap();
}

[ServerCommand("DialogTrap", "Triggers dialog trap")]
void DialogTrapCmd(const CommandArgs@ args) {
    string scene = (args !is null && args.ArgC() >= 2) ? args.Arg(1) : "";
    float duration = (args !is null && args.ArgC() >= 3) ? args.Arg(2).toFloat() : 15.0f;
    TriggerDialogTrap(scene, duration);
}

[ServerCommand("ButterFingersTrap", "Triggers butter fingers trap")]
void ButterFingersTrapCmd(const CommandArgs@ args) {
    float duration = (args !is null && args.ArgC() >= 2) ? args.Arg(1).toFloat() : 30.0f;
    TriggerButterFingersTrap(duration);
}

[ServerCommand("ButterfingersTick", "Internal")]
void ButterFingersTickCmd(const CommandArgs@ args) {
    RunButterFingersTick();
}
[ServerCommand("CheckBridgeLockout", "Checks if the bridge is present and locks the ratman door accordingly")]
void CheckBridgeLockoutCmd(const CommandArgs@ args) {
    if (current_map != "sp_a2_pull_the_rug") return;
    
    CBaseEntity@ door = EntityList().FindByName(null, "ratman_lockoff_door");
    CBaseEntity@ bridge = EntityList().FindByClassname(null, "prop_wall_projector");
    
    if (bridge !is null) {
        // Bridge IS present
        if (door !is null) {
            Variant v;
            door.FireInput("Open", v, 0.0f, null, null, 0);
            
            // Clean up hints
            CBaseEntity@ hint = EntityList().FindByName(null, "ratman_door_hint");
            if (hint !is null) hint.Remove();
            CBaseEntity@ target = EntityList().FindByName(null, "ratman_door_hint_target");
            if (target !is null) target.Remove();
        }
    } else {
        // Bridge is MISSING
        if (door !is null) {
            Variant v;
            door.FireInput("Close", v, 0.0f, null, null, 0);
            
            // Setup hint if it doesn't exist
            CBaseEntity@ hint = EntityList().FindByName(null, "ratman_door_hint");
            if (hint is null) {
                CBaseEntity@ hintTarget = util::CreateEntityByName("info_target_instructor_hint");
                if (hintTarget !is null) {
                    hintTarget.KeyValue("targetname", "ratman_door_hint_target");
                    hintTarget.SetAbsOrigin(door.GetAbsOrigin() + Vector(0, 0, 50));
                    hintTarget.Spawn();
                }
                
                CBaseEntity@ hintObj = util::CreateEntityByName("env_instructor_hint");
                if (hintObj !is null) {
                    hintObj.KeyValue("targetname", "ratman_door_hint");
                    hintObj.KeyValue("hint_target", "ratman_door_hint_target");
                    hintObj.KeyValue("hint_caption", "You don't have the Hard Light Bridges");
                    hintObj.KeyValue("hint_icon_onscreen", "icon_alert");
                    hintObj.KeyValue("hint_color", "255 50 50");
                    hintObj.KeyValue("hint_static", "0");
                    hintObj.KeyValue("hint_timeout", "0");
                    hintObj.KeyValue("hint_range", "300"); 
                    hintObj.Spawn();
                    hintObj.FireInput("ShowHint", Variant(), 0.01f, null, null, 0);
                }
            }
        }
    }
}
[ServerCommand("SpawnHologramAtCrosshair", "Spawns a hologram at the crosshair")]
void SpawnHologramAtCrosshairCmd(const CommandArgs@ args) {
    CBaseEntity@ pEnt = EntityList().FindByClassname(null, "player");
    if (pEnt is null) return;
    CBasePlayer@ player = cast<CBasePlayer>(pEnt);
    if (player is null) return;
    
    Vector start = player.EyePosition();
    QAngle angles = player.EyeAngles();
    Vector forward;
    AngleVectors(angles, forward);
    Vector end = start + (forward * 2000.0f);
    
    trace_t tr;
    util::TraceLine(start, end, 0x1, pEnt, 0, tr);
    
    if (tr.fraction < 1.0f) {
        int skin = (args.ArgC() > 1) ? args.Arg(1).toInt() : 0;
        string name = (args.ArgC() > 2) ? args.Arg(2) : "manual_holo";
        
        Vector hitPos = start + (forward * 2000.0f * tr.fraction);
        StableCreateAPHologram(hitPos, QAngle(0, 0, 0), 1.0f, "", "", skin, name);
        ArchipelagoLog("Spawned hologram at crosshair. Skin: " + skin);
    }
}
