namespace Archipelago {

void HandleMonitorWarp(string monitorID) {
    CBaseEntity@ player = EntityList().FindByClassname(null, "player");
    if (player is null) return;

    // Check if the player is falling (negative vertical velocity) to prevent warp when on solid ground
    Vector vel = player.GetAbsVelocity();
    if (vel.z >= -30.0f) {
        ArchipelagoLog("AP DEBUG: Player is not falling (vel.z = " + vel.z + "), skipping warp.");
        return;
    }

    Vector targetPos;
    QAngle targetAng;
    bool shouldWarp = false;

    if (monitorID == "sp_a4_tb_trust_drop") {
        targetPos = Vector(317, 1154, 800);
        targetAng = QAngle(0, -90, 0);
        shouldWarp = true;
    } else if (monitorID == "sp_a4_tb_catch 1") {
        // Changement : on évite le 0.0 absolu qui peut bugger sur certaines maps
        targetPos = Vector(10.0, -1260.0, -80.0); 
        targetAng = QAngle(0, 90, 0);
        shouldWarp = true;
    } else if (monitorID == "sp_a4_finale3") {
        targetPos = Vector(7, -235, -173);
        targetAng = QAngle(0, 180, 0);
        shouldWarp = true;
    }

if (shouldWarp) {
        CBaseEntity@ cam = util::CreateEntityByName("point_viewcontrol");
        if (cam !is null) {
            cam.SetAbsOrigin(targetPos);
            cam.SetAbsAngles(targetAng);
            cam.KeyValue("spawnflags", "140"); // 4 (Freeze) + 8 (Infinite) + 128 (All Players)
            cam.Spawn();

            Variant empty;
            
            // 1. On prend le contrôle de la vue
            cam.FireInput("Enable", empty, 0.0f, player, player);
            
            // 2. On téléporte le joueur sur la caméra (Position + Vue !)
            cam.FireInput("TeleportToView", empty, 0.02f, player, player);
            
            // 3. On rend le contrôle au joueur
            cam.FireInput("Disable", empty, 0.1f, player, player);
            
            // 4. On nettoie l'entité
            cam.FireInput("Kill", empty, 0.2f, null, null);
            
            // Sécurité physique
            player.SetAbsVelocity(Vector(0, 0, 0));
        }
    }
}

} // namespace Archipelago
