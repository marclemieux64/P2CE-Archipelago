// =============================================================
// ARCHIPELAGO FIND ENTITIES
// =============================================================

/**
 * FindEntities - Robust search helper that handles Name, Class, Model, Target, and 
 * Keyword-based fallback for complex items like Frankenturrets.
 */
array<CBaseEntity@> FindEntities(string search) {
    // 1. STRIP WHITESPACE & QUOTES
    while (search.length() > 0 && (search[0] == 34 || search[0] == 39 || search[0] == 32)) search = search.substr(1);
    while (search.length() > 0 && (search[search.length()-1] == 34 || search[search.length()-1] == 39 || search[search.length()-1] == 32)) search = search.substr(0, search.length()-1);

    // 1.0 FINALE 4 NAME MAPPING
    if (current_map == "sp_a4_finale4") {
        if (search == "@core01") search = "core1_display";
        else if (search == "@core02") search = "core2_display";
        else if (search == "@core03") search = "core3_display";
        else if (search == "core3") search = "core3_display";
        else if (search == "core1") search = "core1_display";
        else if (search == "core2") search = "core2_display";
    }

    array<CBaseEntity@> targets;
    CBaseEntity@ ent = null;
    
    if (search == "") return targets;
    string lowerSearch = search.tolower();
    
    // GLOBAL EXCLUSION: factory_target and its variants must never be processed
    if (lowerSearch.locate("factory_target") != uint(-1)) return targets;

    // 1.1 PRIMARY PASS (Exact Match / Name)
    while ((@ent = EntityList().FindByName(ent, search)) !is null) {
        // Only exclude holograms if we are NOT specifically searching for them
        if (lowerSearch.locate("archipelago_hologram") != uint(-1) || ent.GetEntityName().locate("_holo") == uint(-1)) {
            targets.insertLast(ent);
        }
    }
    
    if (targets.length() > 0) return targets;

    // 1.2 MODEL PATH PASS (If it looks like a path)
    if (search.locate("/") != uint(-1) || search.locate("\\") != uint(-1) || search.locate(".mdl") != uint(-1)) {
        @ent = EntityList().First();
        while (@ent !is null) {
            if (ent.GetModelName().tolower() == lowerSearch) {
                targets.insertLast(ent);
            }
            @ent = EntityList().Next(ent);
        }
        if (targets.length() > 0) return targets;
    }

    // 1.3 CLASSNAME PASS
    @ent = null;
    while ((@ent = EntityList().FindByClassname(ent, search)) !is null) {
        // SPECIAL CASE: Floor Turrets must match the model
        if (search == "npc_portal_turret_floor") {
            if (ent.GetModelName().tolower().locate("npcs/turret/turret.mdl") == uint(-1)) continue;
        }
        targets.insertLast(ent);
    }
    
    // Fallback: If we search for turrets, also check prop_dynamic for sabotaged turrets
    if (search == "npc_portal_turret_floor") {
        @ent = null;
        while ((@ent = EntityList().FindByClassname(ent, "prop_dynamic")) !is null) {
            if (ent.GetModelName().tolower().locate("npcs/turret/turret.mdl") != uint(-1)) {
                targets.insertLast(ent);
            }
        }
    }

    if (targets.length() > 0) return targets;

    // 2. KEYWORD & CORES FALLBACK
    bool isCoreRequest = (lowerSearch.locate("core") != uint(-1) || lowerSearch.locate("fact") != uint(-1) || lowerSearch.locate("faulty") != uint(-1));
    bool isHologramRequest = (lowerSearch.locate("archipelago_hologram") != uint(-1));
    
    string coreDigit = "";
    if (isCoreRequest) {
        if (lowerSearch.locate("1") != uint(-1)) coreDigit = "1";
        else if (lowerSearch.locate("2") != uint(-1)) coreDigit = "2";
        else if (lowerSearch.locate("3") != uint(-1)) coreDigit = "3";
    }

    @ent = EntityList().First();
    while (@ent !is null) {
        string name = ent.GetEntityName().tolower();
        string cls = ent.GetClassname().tolower();
        string model = ent.GetModelName().tolower();
        
        // Skip holograms unless we are explicitly looking for them
        if (!isHologramRequest && name.locate("_holo") != uint(-1)) { @ent = EntityList().Next(ent); continue; }

        if (isCoreRequest) {
            bool nameMatch = (name.locate("core") != uint(-1) || name.locate("fact") != uint(-1));
            bool modelMatch = (model.locate("personality_core") != uint(-1) || model.locate("personality_sphere") != uint(-1));

            if (nameMatch || modelMatch) {
                if (coreDigit != "" && name.locate(coreDigit) != uint(-1)) targets.insertLast(ent);
                else if (coreDigit == "") targets.insertLast(ent);
            }
        } else if (isHologramRequest) {
            if (model.locate("archipelago_hologram") != uint(-1)) {
                targets.insertLast(ent);
            }
        } else {
            bool match = false;
            if (lowerSearch == "cube" && (cls.locate("cube") != uint(-1) || model.locate("metal_box") != uint(-1) || model.locate("box") != uint(-1))) match = true;
            else if (lowerSearch == "button" && (cls.locate("button") != uint(-1))) match = true;
            else if (lowerSearch == "monster" && (cls.locate("monster_box") != uint(-1))) match = true;
            
            if (match) targets.insertLast(ent);
        }

        @ent = EntityList().Next(ent);
    }

    return targets;
}
