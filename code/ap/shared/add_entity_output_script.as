/**
 * AddEntityOutputScript - Connects an entity output to a console script.
 */
void AddEntityOutputScript(string target, string output, string script, float delay = 0.0f, int times = -1) {
    array<CBaseEntity@> targets = FindEntities(target);
    for (uint i = 0; i < targets.length(); i++) {
        SafeAddOutput(targets[i], output, "InitCmd", "Command", script, delay, times);
    }
}
