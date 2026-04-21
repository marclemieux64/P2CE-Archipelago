/**
 * HandleMapCompletion - Performs map-wide cleanup and triggers the warp to menu.
 */
void HandleMapCompletion() {
    Msgl("map_complete:" + current_map);
    
    // Annihiler les transitions natives
    CBaseEntity@ script = EntityList().FindByName(null, "@transition_script");
    if (script !is null) script.Remove();
    
    CBaseEntity@ badCmd = EntityList().FindByName(null, "servercommand");
    if (badCmd !is null) badCmd.Remove();
    
    CBaseEntity@ changelevel = null;
    while ((@changelevel = EntityList().FindByClassname(changelevel, "trigger_changelevel")) !is null) {
        changelevel.Remove();
    }
    
    // Appel à Panorama
    WarpToMenu();
}
