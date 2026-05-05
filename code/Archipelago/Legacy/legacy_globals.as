// =============================================================
// ARCHIPELAGO LEGACY GLOBALS
// =============================================================

// --- GLOBAL VARIABLES ---
string current_map = "unknown";

/**
 * ArchipelagoLog - Core logging for legacy functions.
 * Handles raw output for client-critical identifiers.
 */
void ArchipelagoLog(string msg) {
    // These identifiers must be at the very start of the line for the client to parse them
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
 * UpdateInternalMapName - Synchronizes the current map variable.
 */
void UpdateInternalMapName() {
    ConVarRef host_map("host_map");
    if (host_map.IsValid()) {
        string name = host_map.GetString();
        if (name != "" && name != "nomap") {
            current_map = name;
        }
    }
}

/**
 * FindEntities - Utility for locating entities by name or classname.
 */
array<CBaseEntity@> FindEntities(string search) {
    array<CBaseEntity@> results;
    CBaseEntity@ ent = null;
    
    // Search by name
    while ((@ent = EntityList().FindByName(ent, search)) !is null) {
        results.insertLast(ent);
    }
    
    // Search by classname
    @ent = null;
    while ((@ent = EntityList().FindByClassname(ent, search)) !is null) {
        results.insertLast(ent);
    }
    
    return results;
}

/**
 * EntFire - Standard bridge to fire entity inputs via console.
 * Uses quotes around value to support spaces and AddOutput logic.
 */
void EntFire(string target, string input, string value = "", float delay = 0.0f) {
    CBaseEntity@ cmdEnt = EntityList().FindByName(null, "InitCmd");
    if (cmdEnt !is null) {
        Variant v;
        // Format: ent_fire <target> <input> "<value>" <delay>
        v.SetString("ent_fire " + target + " " + input + " \"" + value + "\" " + delay);
        cmdEnt.FireInput("Command", v, 0.0f, null, null, 0);
    }
}

/**
 * EntFire (Overload) - Vector-based search then fire.
 */
void EntFire(Vector pos, string input, string value = "", float delay = 0.0f, string classname = "trigger_once") {
    CBaseEntity@ ent = EntityList().FindByClassnameNearest(classname, pos, 64.0f);
    if (ent !is null) {
        string target = ent.GetEntityName();
        if (target == "") {
            target = classname + "_" + ent.GetEntityIndex();
            ent.KeyValue("targetname", target);
        }
        EntFire(target, input, value, delay);
    }
}
