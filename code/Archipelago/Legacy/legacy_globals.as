// =============================================================
// ARCHIPELAGO LEGACY GLOBALS
// =============================================================

// --- GLOBALS (TRUE GLOBAL SCOPE) ---
string current_map = "unknown";
int transition_script_count = 0;
bool g_has_printed_map_complete = false;
bool g_bSentDeathLink = false;

namespace Legacy {

// --- CONVARS & REFS ---
    ConVar cv_ArchipelagoDebug("ArchipelagoDebug", "0");
    ConVarRef host_map("host_map");

// --- BOOLEANS ---
    // Moved to global scope

// --- INTEGERS ---
    dictionary g_vitrified_door_names;
    dictionary g_monitor_registry;
    ConVar cv_ArchipelagoVitrifiedStatus("ArchipelagoVitrifiedStatus", "000000", FCVAR_ARCHIVE);
    int g_ButterFingersTicks = 0;

// --- STRINGS ---
    // Moved to global scope

// --- ARRAYS ---
    array<string> two_trigger_levels = { "sp_a1_intro1", "sp_a4_finale3" };
    array<string> non_elevator_maps = { 
        "sp_a1_intro1", "sp_a1_intro7", "sp_a1_wakeup", "sp_a2_turret_intro", "sp_a2_bts1", 
        "sp_a2_bts2", "sp_a2_bts3", "sp_a2_bts4", "sp_a2_bts5", "sp_a2_bts6", "sp_a2_core", 
        "sp_a3_00", "sp_a3_01", "sp_a4_laser_platform", "sp_a3_portal_intro", "sp_a4_finale1", 
        "sp_a4_finale2", "sp_a4_finale3", "sp_a4_finale4" 
    };
    array<string> g_suppressed_entities;
    array<string> g_suppressed_classes;
    array<string> g_reported_monitors;
    array<int> g_processed_turret_indices;
    array<int> g_processed_entity_indices;
array<string> trap_colors = { "255 0 0", "0 255 0", "0 0 255", "255 255 0", "255 0 255", "0 255 255" };
/**
 * ArchipelagoLog - Core logging for legacy functions.
 */
    void ArchipelagoLog(string msg) {
        array<string> identifiers = { "map_name:", "monitor_break:", "item_collected:", "button_check:", "map_complete:" };
        for (uint i = 0; i < identifiers.length(); i++) {
            if (msg.locate(identifiers[i]) == 0) {
                Msg(msg + "\n");
                return;
            }
        }
        Msg("[Archipelago] " + msg + "\n");
    }

/**
 * UpdateInternalMapName - Safely grabs the current map name from the engine.
 */
    void UpdateInternalMapName() {
        if (host_map.IsValid()) {
            string detected = host_map.GetString();
            if (detected != "" && detected != "nomap" && detected != "unknown") {
                if (current_map != detected) {
                    current_map = detected; 
                    ArchipelagoLog("map_name:" + current_map);
                    CallVScript("SendToPanorama(\"ArchipelagoMapNameUpdated\", \"" + current_map + "|0\")");
                }
            }
        }
    }

/**
 * CallVScript - Generic bridge to call VScript from AngelScript.
 */
    void CallVScript(string code) {
        CBaseEntity@ scriptEnt = util::CreateEntityByName("logic_script");
        if (scriptEnt !is null) {
            scriptEnt.Spawn();
            Variant vPayload;
            vPayload.SetString(code);
            scriptEnt.FireInput("RunScriptCode", vPayload, 0.0f, null, null, 0);
            Variant vKill;
            scriptEnt.FireInput("Kill", vKill, 0.1f, null, null, 0);
        } else {
            ArchipelagoLog("[Archipelago] Error: CallVScript failed to create logic_script");
        }
    }

/**
 * FindEntities - Proximity and name-based scanning for hooks.
 */
/**
 * FindEntities - Robust search helper that handles Name, Class, Model, Target, and 
 * Keyword-based fallback for complex items like Frankenturrets.
 */
    array<CBaseEntity@> FindEntities(string search) {
    // 1. STRIP WHITESPACE & QUOTES
        while (search.length() > 0 && (search[0] == 34 || search[0] == 39 || search[0] == 32)) search = search.substr(1);
        while (search.length() > 0 && (search[search.length() - 1] == 34 || search[search.length() - 1] == 39 || search[search.length() - 1] == 32)) search = search.substr(0, search.length() - 1);

    // 1.0 FINALE 4 NAME MAPPING
        if (current_map == "sp_a4_finale4") {
            if (search == "@core01") search = "core1_display"; else if (search == "@core02") search = "core2_display"; else if (search == "@core03") search = "core3_display"; else if (search == "core3") search = "core3_display"; else if (search == "core1") search = "core1_display"; else if (search == "core2") search = "core2_display";
        }

        array<CBaseEntity@> targets;
        CBaseEntity@ ent = null;
    
        if (search == "") return targets;
        string lowerSearch = search.tolower();
    
    // GLOBAL EXCLUSION: factory_target must never be processed
        if (lowerSearch.locate("factory_target") != uint(-1)) return targets;

    // 1.1 PRIMARY PASS (Exact Match / Name)
        while ((@ent = EntityList().FindByName(ent, search)) !is null) {
            string name = ent.GetEntityName();
            if (lowerSearch.locate("archipelago_hologram") != uint(-1) || name.tolower().locate("_holo") == uint(-1)) {
                targets.insertLast(ent);
            }
        }
    
        if (targets.length() > 0) return targets;

    // 1.2 SECONDARY PASS (Classname Match)
        @ent = null;
        while ((@ent = EntityList().FindByClassname(ent, search)) !is null) {
            string name = ent.GetEntityName();
            if (lowerSearch.locate("archipelago_hologram") != uint(-1) || name.tolower().locate("_holo") == uint(-1)) {
                targets.insertLast(ent);
            }
        }

        if (targets.length() > 0) return targets;

    // 1.3 MODEL PATH PASS
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

    // Fallback: Turrets check prop_dynamic
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
    
        if (isCoreRequest) {
            // Logic handled per-entity inside the loop
        }

        @ent = EntityList().First();
        while (@ent !is null) {
            string name = ent.GetEntityName();
            string cls = ent.GetClassname();
            string model = ent.GetModelName().tolower();

            if (isCoreRequest) {
                if (cls == "npc_personality_sphere") {
                    string cSub = "";
                    if (lowerSearch.locate("1") != uint(-1)) cSub = "core1"; else if (lowerSearch.locate("2") != uint(-1)) cSub = "core2"; else if (lowerSearch.locate("3") != uint(-1)) cSub = "core3";
                    
                    if (cSub != "" && name.locate(cSub) != uint(-1)) targets.insertLast(ent); else if (cSub == "") targets.insertLast(ent);
                }
            } else if (isHologramRequest) {
                if (model.locate("archipelago_hologram") != uint(-1)) {
                    targets.insertLast(ent);
                }
            } else {
                bool match = false;
                string lCls = cls.tolower();
                if (lowerSearch == "cube" && (lCls.locate("cube") != uint(-1) || model.locate("metal_box") != uint(-1) || model.locate("box") != uint(-1))) match = true; else if (lowerSearch == "button" && (lCls.locate("button") != uint(-1))) match = true; else if (lowerSearch == "monster" && (lCls.locate("monster_box") != uint(-1))) match = true;
            
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

/**
 * SafeRemoveEntity - Standard P2CE crash-safe entity removal.
 */
    void SafeRemoveEntity(CBaseEntity@ ent) {
        if (ent is null) return;
        Variant v;
        ent.FireInput("Kill", v, 0.0f, null, null, 0);
    }

/**
 * SafeAddOutput - Connects an entity output using KeyValue instead of FireInput('AddOutput').
 * This bypasses the engine's "Admin Command" security restrictions and is more reliable.
 */
    void SafeAddOutput(CBaseEntity@ ent, string output, string target, string input, string param = "", float delay = 0.0f, int maxTimes = -1) {
        if (ent is null) return;
        
        // Format: "target:input:parameter:delay:maxTimes"
        Variant v;
        v.SetString(output + " " + target + ":" + input + ":" + param + ":" + delay + ":" + maxTimes);
        ent.FireInput("AddOutput", v, 0.0f, null, null, 0);
    }

/**
 * SendToConsole - Wrapper for point_servercommand execution.
 */
    void SendToConsole(string command) {
        CBaseEntity@ cmd = EntityList().FindByName(null, "InitCmd");
        if (cmd !is null) {
            Variant v;
            v.SetString(command);
            cmd.FireInput("Command", v, 0.0f, null, null, 0);
        }
    }

/**
 * EntFire - Legacy wrapper for direct entity I/O.
 */
    void EntFire(string target, string input, string value = "", float delay = 0.0f) {
        array<CBaseEntity@> entities = FindEntities(target);
        for (uint i = 0; i < entities.length(); i++) {
            Variant v;
            v.SetString(value);
            entities[i].FireInput(input, v, delay, null, null, 0);
        }
    }

/**
 * EntFire - Positional overload for direct entity I/O.
 */
    void EntFire(Vector pos, string input, string value = "", float delay = 0.0f, string cls = "") {
        CBaseEntity@ target = null;
        if (cls != "" && cls != "*") {
            @target = EntityList().FindByClassnameNearest(cls, pos, 100.0f);
        } else {
        // Fallback: Manual proximity search for any entity type
            float minDist = 100.0f;
            CBaseEntity@ ent = EntityList().First();
            while (@ent !is null) {
                float d = (ent.GetAbsOrigin() - pos).Length();
                if (d < minDist) {
                    @target = ent;
                    minDist = d;
                }
                @ent = EntityList().Next(ent);
            }
        }
    
        if (target !is null) {
            Variant v;
            v.SetString(value);
            target.FireInput(input, v, delay, null, null, 0);
        }
    }

/**
 * CreateLPP - Logic Player Proxy initialization.
 */
    void CreateLPP() {
        CBaseEntity@ lpp = EntityList().FindByClassname(null, "logic_playerproxy");
        if (lpp is null) {
            @lpp = util::CreateEntityByName("logic_playerproxy");
            if (lpp !is null) {
                lpp.KeyValue("targetname", "lpp"); 
                lpp.Spawn();
            }
        }
    }

/**
 * GetPlayer - Helper to find the local player.
 */
    CBasePlayer@ GetPlayer() {
        return cast<CBasePlayer>(EntityList().FindByClassname(null, "player"));
    }

    void InitVitrifiedDoorRegistry() {
        g_vitrified_door_names.deleteAll();
        g_vitrified_door_names["sp_a3_03:dummy_chamber_button"] = "Vitrified Door 1";
        g_vitrified_door_names["sp_a3_03:dummy_chamber_button2"] = "Vitrified Door 2";
        g_vitrified_door_names["sp_a3_03:dummy_chamber_button3"] = "Vitrified Door 3";
        g_vitrified_door_names["sp_a3_transition01:dummy_chamber_button"] = "Vitrified Door 4";
        g_vitrified_door_names["sp_a3_transition01:dummy_chamber_button2"] = "Vitrified Door 5";
        g_vitrified_door_names["sp_a3_transition01:dummy_chamber_button3"] = "Vitrified Door 6";
    }


void InitWheatleyMonitorRegistry() {
    g_monitor_registry.deleteAll();
    // Format: "map_name:relay_name" -> "Archipelago Location Name"
    g_monitor_registry.set("sp_a4_tb_intro:monitor1-relay_break", "sp_a4_tb_intro");
    g_monitor_registry.set("sp_a4_tb_trust_drop:monitor1-relay_break", "sp_a4_tb_trust_drop");
    g_monitor_registry.set("sp_a4_tb_wall_button:wheatley_monitor-relay_break", "sp_a4_tb_wall_button");
    g_monitor_registry.set("sp_a4_tb_polarity:monitor1-relay_break", "sp_a4_tb_polarity");
    g_monitor_registry.set("sp_a4_tb_catch:monitor1-relay_break", "sp_a4_tb_catch 1");
    g_monitor_registry.set("sp_a4_tb_catch:monitor2-relay_break", "sp_a4_tb_catch 2");
    g_monitor_registry.set("sp_a4_stop_the_box:wheatley_monitor-relay_break", "sp_a4_stop_the_box");
    g_monitor_registry.set("sp_a4_laser_catapult:wheatley_monitor_1-relay_break", "sp_a4_laser_catapult");
    g_monitor_registry.set("sp_a4_laser_platform:wheatley_monitor_1-relay_break", "sp_a4_laser_platform");
    g_monitor_registry.set("sp_a4_speed_tb_catch:wheatley_monitor-relay_break", "sp_a4_speed_tb_catch");
    g_monitor_registry.set("sp_a4_jump_polarity:wheatley_monitor_1-relay_break", "sp_a4_jump_polarity");
    g_monitor_registry.set("sp_a4_finale3:wheatley_screen-relay_break", "sp_a4_finale3");
}

    void InitLocationRegistries() {
        InitVitrifiedDoorRegistry();
        InitWheatleyMonitorRegistry();
    }

/**
 * TranslateButtonName - Maps user-friendly names to internal IDs for AP buttons.
 */
    string TranslateButtonName(string originalName) {
        string clean = originalName.trim();
        if (clean == "Ratman Den 1") return "rd1";
        if (clean == "Ratman Den 2") return "rd2";
        if (clean == "Ratman Den 3") return "rd3";
        if (clean == "Ratman Den 4") return "rd4";
        if (clean == "Ratman Den 5") return "rd5";
        if (clean == "Ratman Den 6") return "rd6";
        if (clean == "Ratman Den 7") return "rd7";
        return (clean.length() > 0) ? clean : "ap_btn"; 
    }

/**
 * RunButtonScenarioCheck - Formats and prints button verification status for server.
 */
    void RunButtonScenarioCheck(string buttonName) {
        buttonName = buttonName.trim();
        if (buttonName == "rd1") ArchipelagoLog("button_check:Ratman Den 1"); else if (buttonName == "rd2") ArchipelagoLog("button_check:Ratman Den 2"); else if (buttonName == "rd3") ArchipelagoLog("button_check:Ratman Den 3"); else if (buttonName == "rd4") ArchipelagoLog("button_check:Ratman Den 4"); else if (buttonName == "rd5") ArchipelagoLog("button_check:Ratman Den 5"); else if (buttonName == "rd6") ArchipelagoLog("button_check:Ratman Den 6"); else if (buttonName == "rd7") ArchipelagoLog("button_check:Ratman Den 7"); else ArchipelagoLog("button_check:unknown_" + buttonName);
    }

} // namespace Legacy
