// =============================================================
// ARCHIPELAGO DEBUG LOGGING
// =============================================================

namespace Archipelago {

/**
 * Log a message to the console. Critical message headers are always logged,
 * while standard debugging noise is only logged if the debug ConVar is enabled.
 */
void ArchipelagoLog(string msg) {
    // 1. Retrieve the Archipelago Debug ConVar value
    ConVarRef debugCV("cv_Debug");
    bool isDebugEnabled = debugCV.GetBool();

    // 2. Check for critical prefix tags that must always be outputted (for client integrations)
    array<string> identifiers = { "map_name:", "monitor_break:", "item_collected:", "button_check:", "map_complete:" };
    for (uint i = 0; i < identifiers.length(); i++) {
        if (msg.locate(identifiers[i]) == 0) {
            Msg(msg + "\n");
            return;
        }
    }

    // 3. Output debugging messages if debug mode is active
    if (isDebugEnabled) {
        Msg("[Archipelago] " + msg + "\n");
    }
}

} // namespace Archipelago
