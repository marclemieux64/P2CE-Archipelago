// =============================================================
// ARCHIPELAGO DELETE ENTITY
// =============================================================

/**
 * DeleteEntity - Tool to remove map objects and replace them with holograms.
 * This is a pure tool: it identifies targets and executes the transformation 
 * based on centralized rules in GetHologramVisualOverrides.
 */
void DeleteEntity(string target, bool create_holo = true, float scale = 0.7f, bool ignore_delay = false) {
    UpdateInternalMapName();
    
    // 1. Collect targets via the central search engine
    array<CBaseEntity@> targets = FindEntities(target);

    for (uint i = 0; i < targets.length(); i++) {
        CBaseEntity@ t = targets[i];
        if (t is null) continue;

        string classname = t.GetClassname();
        string tName = t.GetEntityName();
        int entIdx = t.GetEntityIndex();

        // 0. SPECIAL PROTECTION RULES (Synchronized with mapspawn.nut)
        
        // A. Scripted Fling Levels Protection
        if (classname == "trigger_catapult") {
            bool isFlingMap = false;
            for (uint f = 0; f < scripted_fling_levels.length(); f++) {
                if (scripted_fling_levels[f] == current_map) { isFlingMap = true; break; }
            }
            if (isFlingMap) {
                ArchipelagoLog("[AP DEBUG] Protection Active: Skipping trigger_catapult deletion on scripted fling map " + current_map);
                continue;
            }
            
            // B. Faith Plate Item Handling (Modular Item Logic)
            HandleFaithPlateLock(t);
        }

        // C. DUPLICATE PREVENTION: Use the master registry
        if (g_processed_entity_indices.find(entIdx) != -1) continue;
        g_processed_entity_indices.insertLast(entIdx);

        // 2. Fetch Unified Rules (Single Source of Truth)
        Vector hPos;
        QAngle hAng;
        int hSkin;
        float hScale;
        bool shouldParent;
        GetHologramVisualOverrides(t, hPos, hAng, hSkin, hScale, shouldParent);
        
        // 3. Handle Transformation
        if (create_holo) {
            string hName = (tName != "") ? (tName + "_holo") : (classname + "_" + entIdx + "_holo");
            hName = hName.replace("@", "");
            
            // Parent logic determined by the central rules
            CBaseEntity@ parentEnt = shouldParent ? t.GetMoveParent() : null;
            StableCreateAPHologram(hPos, hAng, hScale, "", "", hSkin, hName, parentEnt);
        }

        // 4. Cleanup/Disabling (Tool level execution)
        if (classname == "trigger_catapult") {
            t.FireInput("Disable", Variant(), 0.0f, null, null, 0);
        } else if (classname == "npc_portal_turret_floor" || t.GetModelName().tolower().locate("npcs/turret/turret.mdl") != uint(-1)) {
            DisableEntityPickup(tName != "" ? tName : "turret_" + entIdx);
        } else if (classname.locate("core") != uint(-1) || t.GetModelName().tolower().locate("personality_sphere") != uint(-1)) {
            t.FireInput("Disable", Variant(), 0.0f, null, null, 0);
            t.FireInput("DisableDraw", Variant(), 0.0f, null, null, 0);
        } else {
            t.Remove();
        }
    }
}

