// =============================================================
// ARCHIPELAGO LEGACY MAP CHECK (Hologram Spawning)
// =============================================================

namespace Legacy {

void AddMapCheck() {
    if (current_map == "unknown" || current_map == "") return;

    bool isNonElevatorMap = false;
    for (uint i = 0; i < non_elevator_maps.length(); i++) {
        if (non_elevator_maps[i] == current_map) { 
            isNonElevatorMap = true; 
            break; 
        }
    }

    // --- PARTIE 1 : TRIGGERS AU SOL ET RELAYS ---
    if (isNonElevatorMap) {
        // 1. Unnamed Positional Triggers
        CBaseEntity@ tr = null;
        while ((@tr = EntityList().FindByClassname(tr, "trigger_once")) !is null) {
            Vector pos = tr.GetAbsOrigin();
            if (tr.GetEntityName() == "" || current_map == "sp_a1_wakeup") { 
                Vector targetVec;
                QAngle targetAng(0, 0, 0); 
                bool is_target = false;
                bool animate_holo = true; 
                
                // sp_a2_core est redevenu "normal" ici (animé)
                if (current_map == "sp_a2_bts3" && pos.DistTo(Vector(5952, 4624, -1736)) < 2.0f) { is_target = true; targetVec = Vector(5952, 4624, -1736); }
                else if (current_map == "sp_a2_bts4" && pos.DistTo(Vector(-4080, -7232, 6328)) < 2.0f) { is_target = true; targetVec = Vector(-4080, -7232, 6328); }
                else if (current_map == "sp_a2_core" && pos.DistTo(Vector(0, 304, -10438)) < 2.0f) { is_target = true; targetVec = Vector(0, 304, -10438); }
                else if (current_map == "sp_a4_finale1" && pos.DistTo(Vector(-12832, -3040, -112)) < 2.0f) { is_target = true; targetVec = Vector(-12832, -3040, -112); }
                else if (current_map == "sp_a4_finale2" && pos.DistTo(Vector(-3152, -1928, -240)) < 2.0f) { is_target = true; targetVec = Vector(-3152, -1928, -240); }
                
                // Exception : Wakeup
                else if (current_map == "sp_a1_wakeup" && pos.DistTo(Vector(6144, 3456, 904)) < 50.0f) { 
                    is_target = true; 
                    targetVec = Vector(6144, 3456, 904); 
                    targetAng = QAngle(0, 270, 90); 
                    animate_holo = false; // Wakeup = Statique
                }
                // --- CORRECTION POUR SP_A3_PORTAL_INTRO ---
                else if (current_map == "sp_a3_portal_intro") {
                    Vector center = tr.WorldSpaceCenter();
                    
                    // On donne une énorme marge (400) et on vérifie à la fois l'origine et le centre de la boîte
                    if (pos.DistTo(Vector(3839.99, 348.80, 5674.67)) < 400.0f || center.DistTo(Vector(3839.99, 348.80, 5674.67)) < 400.0f) {
                        is_target = true; 
                        // On le force à spawner exactement à vos coordonnées getpos pour qu'il soit bien visible !
                        targetVec = Vector(3839.99, 348.80, 5674.67); 
                    }
                }

                if (is_target) {
                    string uniqueHoloName = "map_check_trigger_holo";
                    CreateAPHologram(targetVec, targetAng, 1.0f, null, "", 0, uniqueHoloName, animate_holo);
                }
            }
        }
        
        // 2. Named Transition Hooks
        array<string> transTargets = { 
         "trigger_transition", "@transition_from_map", "relay_transition"
        };
        
        for (uint s = 0; s < transTargets.length(); s++) {
            CBaseEntity@ t = null;
            while ((@t = EntityList().FindByName(t, transTargets[s])) !is null) {
                CreateAPHologram(t.WorldSpaceCenter(), QAngle(0, 0, 0), 1.0f, null, "", 0, t.GetEntityName() + "map_check_trigger_holo", true);
            }
        }
    } 
    
    // --- PARTIE 2 : ASCENSEURS ---
    // NOUVEAU : On lit cette section si c'est une map d'ascenseur OU si c'est sp_a2_core
    if (!isNonElevatorMap || current_map == "sp_a2_core") {
        
        CBaseEntity@ tEnt = null;
        while ((@tEnt = EntityList().FindByClassname(tEnt, "func_tracktrain")) !is null) {
            string tName = tEnt.GetEntityName();
            if (tName.locate("exit_lift_train") != uint(-1) || tName.locate("departure_elavator") != uint(-1) || tName.locate("departure_elevator") != uint(-1) || tName.locate("exit_elevator_train") != uint(-1)) {
                
                // NOUVEAU : On définit l'animation de l'ascenseur
                bool animate_elevator = true;
                
                // EXCEPTION : Si c'est l'ascenseur de sp_a2_core, il ne tourne pas !
                if (current_map == "sp_a2_core") {
                    animate_elevator = true;
                }

                // On passe 'animate_elevator' à la création de l'hologramme
                CreateAPHologram(Vector(0, 0, 0), QAngle(0, 0, 0), 1.0f, tEnt, "", 0, "map_check_trigger_elevator_holo", animate_elevator);
            }
        }
    }
}

} // namespace Legacy