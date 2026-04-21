/**
 * AddEntityOutputScriptAtPos - Connects an entity output to a console script by position.
 */
void AddEntityOutputScriptAtPos(Vector pos, string cls, string output, string script, float delay = 0.0f, int times = -1) {
    CBaseEntity@ ent = EntityList().FindByClassnameNearest(cls, pos, 150.0f);
    if (ent !is null) {
        Variant v;
        v.SetString(output + " ap_init_cmd:Command:script " + script + ":" + delay + ":" + times);
        ent.FireInput("AddOutput", v, 0.0f, null, null, 0);
    }
}
