// =============================================================
// ENTITY SEARCH UTILITIES
// =============================================================

namespace Archipelago {

/**
 * FindEntities - Search helper that handles Classname, Model Name, target name patterns,
 * and specific fallback scenarios for conveyor belts or GLaDOS cores.
 */
array<CBaseEntity@> FindEntities(string search) {
    // 1. Strip surrounding quotes and whitespace
    while (search.length() > 0 && (search[0] == 34 || search[0] == 39 || search[0] == 32)) search = search.substr(1);
    while (search.length() > 0 && (search[search.length() - 1] == 34 || search[search.length() - 1] == 39 || search[search.length() - 1] == 32)) search = search.substr(0, search.length() - 1);

    // Finale 4 core name redirection
    string currentMap = g_Archipelago.GetCurrentMap();
    if (currentMap == "sp_a4_finale4") {
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

    // Conveyor turrets exception for sp_a2_bts4
    if (currentMap == "sp_a2_bts4" && (search == "initial_template_turret" || search == "turret_conveyor_1_template")) {
        CBaseEntity@ checkEnt = EntityList().First();
        while (@checkEnt !is null) {
            if (IsConveyorTurret(checkEnt)) {
                string name = checkEnt.GetEntityName();
                bool isConveyor1 = false;
                float dist = checkEnt.GetAbsOrigin().DistTo(Vector(1824, -7024, 6655.830f));
                if (name.locate("turret_conveyor_1") != uint(-1) || dist < 300.0f) {
                    isConveyor1 = true;
                }

                if (search == "turret_conveyor_1_template") {
                    if (isConveyor1) {
                        targets.insertLast(checkEnt);
                    }
                } else {
                    if (!isConveyor1) {
                        targets.insertLast(checkEnt);
                    }
                }
            }
            @checkEnt = EntityList().Next(checkEnt);
        }
        return targets;
    }
    
    string lowerSearch = search.tolower();

    // Prevent searching factory targets
    if (lowerSearch.locate("factory_target") != uint(-1)) return targets;

    // Name search pass
    while ((@ent = EntityList().FindByName(ent, search)) !is null) {
        string name = ent.GetEntityName();
        if (lowerSearch.locate("archipelago_hologram") != uint(-1) || name.tolower().locate("_holo") == uint(-1)) {
            targets.insertLast(ent);
        }
    }
    
    if (targets.length() > 0) return targets;

    // Classname search pass
    @ent = null;
    while ((@ent = EntityList().FindByClassname(ent, search)) !is null) {
        string name = ent.GetEntityName();
        if (lowerSearch.locate("archipelago_hologram") != uint(-1) || name.tolower().locate("_holo") == uint(-1)) {
            targets.insertLast(ent);
        }
    }

    if (targets.length() > 0) return targets;

    // Model name search pass
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

    // Floor turrets checking prop_dynamic
    if (search == "npc_portal_turret_floor") {
        @ent = null;
        while ((@ent = EntityList().FindByClassname(ent, "prop_dynamic")) !is null) {
            if (ent.GetModelName().tolower().locate("npcs/turret/turret.mdl") != uint(-1)) {
                targets.insertLast(ent);
            }
        }
    }

    if (targets.length() > 0) return targets;

    // Keywords fallback search
    bool isCoreRequest = (lowerSearch.locate("core") != uint(-1) || lowerSearch.locate("fact") != uint(-1) || lowerSearch.locate("faulty") != uint(-1));
    bool isHologramRequest = (lowerSearch.locate("archipelago_hologram") != uint(-1));

    @ent = EntityList().First();
    while (@ent !is null) {
        string name = ent.GetEntityName();
        string cls = ent.GetClassname();
        string model = ent.GetModelName().tolower();

        if (isCoreRequest) {
            if (cls == "npc_personality_sphere") {
                string cSub = "";
                if (lowerSearch.locate("1") != uint(-1)) cSub = "core1"; 
                else if (lowerSearch.locate("2") != uint(-1)) cSub = "core2"; 
                else if (lowerSearch.locate("3") != uint(-1)) cSub = "core3";
                
                if (cSub != "" && name.locate(cSub) != uint(-1)) targets.insertLast(ent); 
                else if (cSub == "") targets.insertLast(ent);
            }
        } else if (isHologramRequest) {
            if (model.locate("archipelago_hologram") != uint(-1)) {
                targets.insertLast(ent);
            }
        } else {
            bool match = false;
            string lCls = cls.tolower();
            if (lowerSearch == "cube" && (lCls.locate("cube") != uint(-1) || model.locate("metal_box") != uint(-1) || model.locate("box") != uint(-1))) match = true; 
            else if (lowerSearch == "button" && (lCls.locate("button") != uint(-1))) match = true; 
            else if (lowerSearch == "monster" && (lCls.locate("monster_box") != uint(-1))) match = true;
        
            if (match) {
                if (lowerSearch.locate("archipelago_hologram") != uint(-1) || name.tolower().locate("_holo") == uint(-1)) {
                    targets.insertLast(ent);
                }
            }
        }

        @ent = EntityList().Next(ent);
    }

    return targets;
}

} // namespace Archipelago
