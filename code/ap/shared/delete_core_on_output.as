/**
 * DeleteCoreOnOutput - Native implementation of core deletion hook.
 * Adds an output to target_name that triggers DeleteEntity command after 5s.
 */
void DeleteCoreOnOutput(string core_name, string target_name, string output) {
    array<CBaseEntity@> targets = FindEntities(target_name);

    if (targets.length() == 0) {
        ArchipelagoLog("[Archipelago] Error: DeleteCoreOnOutput target '" + target_name + "' not found");
        return;
    }

    Variant v;
    // Command format: DeleteEntity <name> <holo> <scale>
    v.SetString(output + " InitCmd:Command:DeleteEntity " + core_name + " 0 0.7:5.0:-1");

    for (uint i = 0; i < targets.length(); i++) {
        targets[i].FireInput("AddOutput", v, 0.0f, null, null, 0);
    }
    ArchipelagoLog("[Archipelago] Hooked output '" + output + "' on '" + targets.length() + "' entities matched by '" + target_name + "' to delete '" + core_name + "' in 5s");
}
