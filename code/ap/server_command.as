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
    bool orange = (args.Arg(2) == "2");
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

[ServerCommand("ap_print_complete", "Triggers map completion logic")]
void APPrintCompleteCmd(const CommandArgs@ args) {
    PrintMapComplete();
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

[ServerCommand("ap_debug_scansprayers", "Scans for all paint sprayers in the map")]
void APDebugScanSprayersCmd(const CommandArgs@ args) {
    int count = 0;
    CBaseEntity@ ent = null;
    Msgl("[AP] Scanning for paint sprayers/bombs...");
    
    while ((@ent = EntityList().Next(ent)) !is null) {
        string classname = ent.GetClassname();
        string name = ent.GetEntityName();
        
        bool isSprayer = (classname == "info_paint_sprayer" || classname == "prop_paint_bomb" || name.locate("paint_sprayer") != uint(-1));
        
        if (isSprayer) {
            count++;
            Vector pos = ent.GetAbsOrigin();
            QAngle ang = ent.GetAbsAngles();
            Msgl("  > [" + count + "] " + classname + " | Name: " + name);
            Msgl("    - Pos: " + pos.x + " " + pos.y + " " + pos.z);
            Msgl("    - Ang: " + ang.x + " " + ang.y + " " + ang.z);
        }
    }
    
    Msgl("[AP] Scan complete. Found " + count + " gel-related entities.");
}
