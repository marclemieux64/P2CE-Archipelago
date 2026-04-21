/**
 * HandleMapCompletion - Performs map-wide cleanup and triggers the warp to menu.
 */
void HandleMapCompletion() {
    Msgl("map_complete:" + current_map);
    
    // Annihiler les transitions natives (Scripts et Relais connus)
    array<string> clearNames = { 
        "@transition_script", "servercommand", "@command", 
        "hack_transition_command", "knockout_start",
        "potatos_end_relay", "@transition_from_map" 
    };
    for (uint i = 0; i < clearNames.length(); i++) {
        array<CBaseEntity@> ents = FindEntities(clearNames[i]);
        for (uint j = 0; j < ents.length(); j++) ents[j].Remove();
    }
    
    // Supprimer TOUS les déclencheurs de changement de niveau par classe
    array<string> clearClasses = { "trigger_changelevel", "point_servercommand", "logic_changeloader" };
    for (uint i = 0; i < clearClasses.length(); i++) {
        CBaseEntity@ ent = null;
        while ((@ent = EntityList().FindByClassname(ent, clearClasses[i])) !is null) {
            ent.Remove();
        }
    }
    
    // Appel à Panorama
    WarpToMenu();
}
