/**
 * AddEntityOutputScriptAtPos - Connects an entity output to a console script by position.
 */
void AddEntityOutputScriptAtPos(Vector pos, string cls, string output, string script, float delay = 0.0f, int times = -1) {
    CBaseEntity@ ent = EntityList().FindByClassnameNearest(cls, pos, 150.0f);
    if (ent !is null) {
        SafeAddOutput(ent, output, "InitCmd", "Command", script, delay, times);
    }
}
