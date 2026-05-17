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
                
                if (current_map == "sp_a2_bts3" && pos.DistTo(Vector(5952, 4624, -1736)) < 2.0f) { is_target = true; targetVec = Vector(5952, 4624, -1736); }
                else if (current_map == "sp_a1_intro1" && pos.DistTo(Vector(-9728, -2976, -576)) < 2.0f) { is_target = true; targetVec = Vector(-9728, -2976, -550); }
                else if (current_map == "sp_a1_intro2" && pos.DistTo(Vector(-8448, -4448, -576)) < 2.0f) { is_target = true; targetVec = Vector(-8448, -4448, -550); }
                else if (current_map == "sp_a1_intro4" && pos.DistTo(Vector(-5504, -4064, -256)) < 2.0f) { is_target = true; targetVec = Vector(-5504, -4064, -220); }
                else if (current_map == "sp_a1_intro5" && pos.DistTo(Vector(-3904, -3456, -384)) < 2.0f) { is_target = true; targetVec = Vector(-3904, -3456, -350); }
                else if (current_map == "sp_a1_intro6" && pos.DistTo(Vector(-1024, -3456, -384)) < 2.0f) { is_target = true; targetVec = Vector(-1024, -3456, -350); }
                else if (current_map == "sp_a1_wakeup" && pos.DistTo(Vector(-512, 1088, 192)) < 2.0f) { is_target = true; targetVec = Vector(-512, 1088, 220); }
                else if (current_map == "sp_a2_intro" && pos.DistTo(Vector(192, 128, -128)) < 2.0f) { is_target = true; targetVec = Vector(192, 128, -90); }

                if (is_target) {
                    CreateAPHologram(targetVec, targetAng, 1.0f, null, "", 0, tr.GetEntityName() + "map_check_trigger_holo", animate_holo);
                }
            }
        }

        // 2. Named Relays (Transition Targets)
        string[] transTargets = { "transition_logic_relay", "relay_exit_opened", "elevator_entry_relay", "end_relay" };
        for (uint s = 0; s < transTargets.length(); s++) {
            CBaseEntity@ t = null;
            while ((@t = EntityList().FindByName(t, transTargets[s])) !is null) {
                CreateAPHologram(t.WorldSpaceCenter(), QAngle(0, 0, 0), 1.0f, null, "", 0, t.GetEntityName() + "map_check_trigger_holo", true);
            }
        }
    } 
    
    // --- PARTIE 2 : ASCENSEURS ---
    if (!isNonElevatorMap || current_map == "sp_a2_core") {
        CBaseEntity@ tEnt = null;
        while ((@tEnt = EntityList().FindByClassname(tEnt, "func_tracktrain")) !is null) {
            string tName = tEnt.GetEntityName();
            if (tName.locate("exit_lift_train") != uint(-1) || tName.locate("departure_elavator") != uint(-1) || tName.locate("departure_elevator") != uint(-1) || tName.locate("exit_elevator_train") != uint(-1)) {
                
                bool animate_elevator = true;
                if (current_map == "sp_a2_core") {
                    animate_elevator = true;
                }

                CreateAPHologram(Vector(0, 0, 0), QAngle(0, 0, 0), 1.0f, tEnt, "", 0, "map_check_trigger_elevator_holo", animate_elevator);
            }
        }
    }

   // --- PARTIE 3 : MOON PORTAL SPRITE (sp_a4_finale4) ---
    if (current_map == "sp_a4_finale4") {
        CBaseEntity@ moon = EntityList().FindByName(null, "sprite_moon_portal"); 
        if (moon !is null) {
            Vector pos = moon.GetAbsOrigin(); 
            
            // --- RÉGLAGES DES OFFSETS ---
            float offsetX = -85.0f; // Ajustez pour éviter le Z-fighting (clignotement)
            float offsetY = 25.0f;   
            float offsetZ = 0.0f;   
            
            pos.x += offsetX;
            pos.y += offsetY;
            pos.z += offsetZ;

            // --- RÉGLAGE DE LA TAILLE (SCALE) ---
            float holoScale = 2.0f; // 1.0f est la taille normale, 2.0f est le double, etc.

            // --- ORIENTATION MANUELLE ---
            // Basé sur vos tests : Pitch 0, Yaw -277, Roll 90
            QAngle fixed_ang(0.0f, -277.0f, 90.0f); 

            // Création de l'hologramme
            // Paramètres : position, angles, scale, parent, attachment, animation_index, name, animate
            CreateAPHologram(pos, fixed_ang, holoScale, null, "", 0, "moon_holo", false);
        }
    }
} 

} // Legacy