/**
 * HandleMonitorWarp - Checks for specific monitor IDs that should trigger a player teleport.
 */
void HandleMonitorWarp(string monitorID) {
    CBaseEntity@ player = EntityList().FindByClassname(null, "player");
    if (player is null) return;

    // Placeholder coordinates - Update these with the real values
    if (monitorID == "sp_a4_tb_trust_drop") {
        player.SetAbsOrigin(Vector(-12832, -3040, -112)); 
        player.SetAbsAngles(QAngle(0, 180, 0)); 
    } else if (monitorID == "sp_a4_tb_catch 1") {
        player.SetAbsOrigin(Vector(4, -1264, -95));
        player.SetAbsAngles(QAngle(0, 90, 0)); 
    } else if (monitorID == "sp_a4_finale3") {
        player.SetAbsOrigin(Vector(7, -235, -193));
        player.SetAbsAngles(QAngle(0, 180, 0)); // 
    }
}
