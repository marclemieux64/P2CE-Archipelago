// =============================================================
// ARCHIPELAGO LOG
// =============================================================

/**
 * APLog - Toggable console output that bypasses the "silent" point_servercommand behavior.
 */
void ArchipelagoLog(const string&in msg) {
    // Critical tracking messages must always be printed for the Archipelago client to see
    // Client identifiers (must stay at the start of the line for parsing)
    array<string> identifiers = { "map_name:", "monitor_break:", "item_collected:", "button_check:", "map_complete:" };
    for (uint i = 0; i < identifiers.length(); i++) {
        if (msg.locate(identifiers[i]) == 0) {
            // 1. Print the raw message for the Archipelago Client to parse
            Msg(msg + "\n");
            
            // 2. Print a colored version for the User's console (\x09 = Light Blue)
            Msg("\x09" + msg + "\n");
            return;
        }
    }

    if (msg.locate("[AP DEBUG]") != uint(-1)) {
        Msg("\x09" + msg + "\n");
        return;
    }

    // Use a reference to check the toggle safely during early initialization
    ConVarRef debug("ArchipelagoDebug");
    if (debug.IsValid() && debug.GetBool()) {
        string prefix = (msg.locate("[Archipelago]") == 0) ? "" : "[Archipelago] ";
        Msg(prefix + msg + "\n");
    }
}