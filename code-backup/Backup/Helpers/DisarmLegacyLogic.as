// =============================================================
// ARCHIPELAGO DISARM LEGACY LOGIC
// =============================================================

/**
 * DisarmLegacyLogic - Proactively removes entities from older map versions
 * that contain hardcoded calls to the obsolete 'ppmod' system. 
 */
void DisarmLegacyLogic() {
    array<string> targets = { 
        "ap_logic", "ppmod_relay", "ppmod_init", "logic_auto_ap", "ap_auto_init", "ap_vscript" 
    };
    
    uint count = 0;
    for (uint i = 0; i < targets.length(); i++) {
        array<CBaseEntity@> entities = FindEntities(targets[i]);
        for (uint j = 0; j < entities.length(); j++) {
            entities[j].Remove();
            count++;
        }
    }
    
    if (count > 0) {
        ArchipelagoLog("[Archipelago] Legacy Cleanup: Removed " + count + " hazardous map-based entities.");
    }
}
