/**
 * DebugListMapTriggers - Lists core puzzle logic entities for debugging.
 */
void DebugListMapTriggers() {
    Msgl("----------------------------------------------");
    Msgl(">>> ARCHIPELAGO: DEBUG MAP TRIGGERS");
    Msgl("----------------------------------------------");
    
    array<string> classes = { "logic_relay", "trigger_once", "trigger_multiple", "trigger_transition", "trigger_changelevel", "logic_script" };
    uint count = 0;
    
    for (uint i = 0; i < classes.length(); i++) {
        CBaseEntity@ ent = null;
        while ((@ent = EntityList().FindByClassname(ent, classes[i])) !is null) {
            string name = ent.GetEntityName();
            if (name == "") name = "(unnamed)";
            Msgl("[DEBUG] ENT: " + name + " [" + classes[i] + "] at " + ent.GetAbsOrigin().x + "," + ent.GetAbsOrigin().y + "," + ent.GetAbsOrigin().z);
            count++;
        }
    }
    
    Msgl("----------------------------------------------");
    Msgl(">>> TOTAL ENTITIES FOUND: " + count);
    Msgl("----------------------------------------------");
}
