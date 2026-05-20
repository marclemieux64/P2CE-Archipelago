namespace Archipelago {

void ArchipelagoLog(string msg) {
    // 1. On récupère la valeur de la ConVar de debug
    ConVarRef debugCV("ArchipelagoDebug");
    bool isDebugEnabled = debugCV.GetBool();

    array<string> identifiers = { "map_name:", "monitor_break:", "item_collected:", "button_check:", "map_complete:" };
    for (uint i = 0; i < identifiers.length(); i++) {
        if (msg.locate(identifiers[i]) == 0) {
            // Ces identifiants sont CRITIQUES (probablement pour ton client externe)
            // On les affiche toujours.
            Msg(msg + "\n");
            return;
        }
    }

    // 2. Pour tous les autres messages (le "bruit" de debug), 
    // on ne les affiche que si ArchipelagoDebug est à 1
    if (isDebugEnabled) {
        Msg("[Archipelago] " + msg + "\n");
    }
}

} // namespace Archipelago