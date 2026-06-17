namespace Archipelago {

// Global flags to track falling state per unique entity index
array<bool> g_CameraFallingDetected(util::GetMaxEntities(), false);

// Tableau global pour stocker la position d'origine exacte de chaque caméra au chargement
array<Vector> g_CameraInitialPositions(util::GetMaxEntities(), Vector(0, 0, 0));

// Tableau global pour stocker la chaîne d'identification finale de chaque caméra
array<string> g_CameraIdentifiers(util::GetMaxEntities(), "");

bool MatchPos2D(Vector pos, float targetX, float targetY) {
    float dx = pos.x - targetX;
    float dy = pos.y - targetY;
    return (dx * dx + dy * dy) < 10000.0f; // tolerance of 100 units (100^2 = 10000)
}

// Fonction pour déterminer l'ID unique et permanent d'une caméra selon ses coordonnées
string GetCameraUniqueID(string map, Vector pos) {
    if (map == "sp_a1_intro3") {
        if (MatchPos2D(pos, -1472.0f, 2528.0f)) return "1";
    }
    else if (map == "sp_a1_intro4") {
        if (MatchPos2D(pos, -596.0f, 256.0f)) return "1";
        if (MatchPos2D(pos, 160.0f, 0.0f)) return "2"; 
        if (MatchPos2D(pos, 40.0f, -656.0f)) return "3"; 
    }
    else if (map == "sp_a1_intro6") {
        if (MatchPos2D(pos, 464.0f, -256.0f)) return "1";
        if (MatchPos2D(pos, 320.0f, -288.0f)) return "2";
        if (MatchPos2D(pos, 1436.0f, -384.0f)) return "3";
    }
    else if (map == "sp_a2_intro") {
        if (MatchPos2D(pos, -32.0f, 576.0f)) return "1";
    }
    else if (map == "sp_a2_laser_stairs") {
        if (MatchPos2D(pos, 232.0f, -480.0f)) return "1";
    }
    else if (map == "sp_a2_dual_lasers") {
        if (MatchPos2D(pos, 122.0f, 352.0f)) return "1";
    }
    else if (map == "sp_a2_catapult_intro") {
        if (MatchPos2D(pos, -224.0f, 864.0f)) return "1";
        if (MatchPos2D(pos, 96.0f, -1440.0f)) return "2";
    }
    else if (map == "sp_a2_fizzler_intro") {
        if (MatchPos2D(pos, 368.0f, 96.0f)) return "1";
    }
    else if (map == "sp_a2_bridge_intro") {
        if (MatchPos2D(pos, 280.0f, -896.0f)) return "1";
    }
    else if (map == "sp_a2_bridge_the_gap") {
        if (MatchPos2D(pos, -448.0f, -32.0f)) return "1";
    }
    else if (map == "sp_a2_turret_intro") {
        if (MatchPos2D(pos, 576.0f, -1415.0f)) return "1";
        if (MatchPos2D(pos, 1152.0f, -296.0f)) return "2";
    }
    else if (map == "sp_a2_laser_relays") {
        if (MatchPos2D(pos, -704.0f, -1014.0f)) return "1";
    }
    else if (map == "sp_a2_turret_blocker") {
        if (MatchPos2D(pos, -302.0f, 384.0f)) return "1";
        if (MatchPos2D(pos, 336.0f, 640.0f)) return "2";
    }
    else if (map == "sp_a2_laser_vs_turret") {
        if (MatchPos2D(pos, 384.0f, -288.0f)) return "1";
    }
    else if (map == "sp_a2_pull_the_rug") {
        if (MatchPos2D(pos, 320.0f, -160.0f)) return "1";
    }
    else if (map == "sp_a2_laser_chaining") {
        if (MatchPos2D(pos, -384.0f, -480.0f)) return "1";
    }
    else if (map == "sp_a2_triple_laser") {
        if (MatchPos2D(pos, 7456.0f, -5998.0f)) return "1";
    }

    // Fallback de sécurité
    return "unk";
}

// Unique fonction d'initialisation et de configuration globale pour les caméras
void AddCameraCheck() {
    if (current_map == "unknown") return;

    // Reset tracking flag states completely for a fresh map load session
    for (int i = 0; i < util::GetMaxEntities(); i++) {
        g_CameraFallingDetected[i] = false;
        g_CameraInitialPositions[i] = Vector(0, 0, 0);
        g_CameraIdentifiers[i] = "";
    }

    // Boucle pour trouver toutes les caméras existantes au chargement de la map et y attacher un hologramme
    CBaseEntity@ camera = null;
    while ((@camera = EntityList().FindByClassname(camera, "npc_security_camera")) !is null) {
        int entIndex = camera.GetEntityIndex();
        Vector camPos = camera.GetAbsOrigin();

        // Déterminer l'identifiant permanent basé sur la map et la coordonnée
        string camID = GetCameraUniqueID(current_map, camPos);
        
        // FIX: Si la caméra n'est pas explicitement enregistrée dans notre table de coordonnées, 
        // on l'ignore complètement pour éviter les fausses entités décoratives (comme sur pull_the_rug)
        if (camID == "unk") continue;

        string holoName = "camera_check_holo_" + current_map + "_" + camID;
        g_CameraInitialPositions[entIndex] = camPos;
        g_CameraIdentifiers[entIndex] = current_map + "_" + camID;

        // On vérifie si l'hologramme pour cette caméra spécifique existe déjà pour éviter les doublons
        if (EntityList().FindByName(null, holoName) is null) {
            QAngle camAng = camera.GetAbsAngles();

            // =============================================================
            // CONFIGURATION DE L'HOLOGRAMME (Taille, Positions et Angles)
            // =============================================================
            float holoScale = 0.6f;       // Modifie cette valeur pour la taille
            
            // Offsets de Position Locale
            float forwardOffset = 35.0f;  // Devant / Derrière la caméra
            float rightOffset = 0.0f;     // Droite / Gauche de la caméra
            float upOffset = -15.0f;      // Au-dessus / En-dessous de la caméra

            // Offsets d'Angle Local (en degrés)
            float pitchOffset = 90.0f;    // Rotation X (Inclinaison haut / bas)
            float yawOffset = 0.0f;       // Rotation Y (Pivot gauche / droite)
            float rollOffset = 0.0f;      // Rotation Z (Roulis / Inclinaison côté)

            // Calcul des vecteurs directionnels selon les angles d'origine de la caméra
            Vector forwardVec = Archipelago::AnglesToForward(camAng);
            Vector rightVec = Archipelago::AnglesToRight(camAng);
            Vector upVec = Archipelago::AnglesToUp(camAng);

            // Position finale combinée avec les offsets de position
            Vector finalPos = camPos + 
                              (forwardVec * forwardOffset) + 
                              (rightVec * rightOffset) + 
                              (upVec * upOffset);

            // Calcul de l'orientation finale combinée avec les offsets d'angle
            QAngle finalAng(camAng.x + pitchOffset, camAng.y + yawOffset, camAng.z + rollOffset);

            // Détermination du skin selon l'état de complétion Archipelago
            int skin = 0;
            string lowerCamID = g_CameraIdentifiers[entIndex].tolower();
            for (uint i = 0; i < checked_cameras.length(); i++) {
                if (checked_cameras[i] == lowerCamID) {
                    skin = 4;
                    break;
                }
            }
            Archipelago::CreateAPHologram(finalPos, finalAng, holoScale, null, "", skin, holoName);
        }
    }

    // Spawn tracking infrastructure natively using a logic_timer infrastructure
    CBaseEntity@ existingTimer = EntityList().FindByName(null, "archipelago_camera_timer");
    if (existingTimer is null) {
        CBaseEntity@ timer = util::CreateEntityByName("logic_timer");
        if (timer !is null) {
            timer.KeyValue("targetname", "archipelago_camera_timer");
            timer.KeyValue("RefireTime", "0.05"); // Evaluates physics 20 times a second
            
            // Format split using \x1B to target our global function callback explicitly
            string payload = "InitCmd\x1BCommand\x1BCheckCameraPhysicsTick\x1B0\x1B-1";
            timer.KeyValue("OnTimer", payload);
            
            timer.Spawn();

            // Enable the tracking cycle loop
            Variant empty;
            timer.FireInput("Enable", empty, 0.0f, null, null, 0);
        }
    }
}

// Main tracking logic called by the logic_timer output event via the server command
void CheckCameraPhysicsTick() {
    CBaseEntity@ camera = null;
    while ((@camera = EntityList().FindByClassname(camera, "npc_security_camera")) !is null) {
        int entIndex = camera.GetEntityIndex();
        
        // Skip checking if this specific camera index was already handled ou non-initialisée
        if (g_CameraFallingDetected[entIndex] || g_CameraIdentifiers[entIndex] == "") continue;

        // 1. Check if the movement type changed to physics simulation
        bool isPhysicsMove = (camera.GetMoveType() == MOVETYPE_VPHYSICS);

        // 2. Fetch native physics velocities to handle optimization sleep states
        Vector vel = camera.GetAbsVelocity();
        IPhysicsObject@ physObj = camera.GetPhysicsObject();
        if (physObj !is null) {
            physObj.Wake();
            
            Vector physVel, physAngVel;
            physObj.GetVelocity(physVel, physAngVel);
            
            if (physVel.LengthSqr() > vel.LengthSqr()) {
                vel = physVel;
            }
        }

        // If it transitioned to a physics state or has an active down force, it's falling
        if ((isPhysicsMove && vel.z < -5.0f) || vel.z < -20.0f) {
            g_CameraFallingDetected[entIndex] = true;

            // Sortie compacte : Renvoie camera_knocked:nommap_idcamera
            Msgl("camera_knocked:" + g_CameraIdentifiers[entIndex]);
        }
    }
}

} // namespace Archipelago