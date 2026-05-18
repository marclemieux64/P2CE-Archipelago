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

        // --- 3. PLACEMENTS MANUELS FORCÉS (Infaillible) ---
        if (current_map == "sp_a1_intro7") {
            CreateAPHologram(Vector(-2208.0f, 376.0f, 1310.0f), QAngle(0, 0, 0), 1.0f, null, "", 0, "sp_a1_intro7_map_check_holo", true);
        }
        else if (current_map == "sp_a1_wakeup") {
            CreateAPHologram(Vector(6165.0f, 3456.0f, 904.0f), QAngle(0, -90.0f, 90.0f), 1.0f, null, "", 0, "sp_a1_wakeup_map_check_holo", false);
        }
        else if (current_map == "sp_a2_turret_intro") {
            CreateAPHologram(Vector(-352.380f, 392.0f, -206.0f), QAngle(0, 0, 0), 1.0f, null, "", 0, "sp_a2_turret_intro_map_check_holo", true);
        }
        else if (current_map == "sp_a2_bts1") {
            CreateAPHologram(Vector(1264.0f, -1344.0f, -390.0f), QAngle(0, 0, 0), 1.0f, null, "", 0, "sp_a2_bts1_map_check_holo", true);
        }
        else if (current_map == "sp_a2_bts2") {
            CreateAPHologram(Vector(2208.0f, 1896.0f, 688.0f), QAngle(0, 0, 0), 1.0f, null, "", 0, "sp_a2_bts2_map_check_holo", true);
        }
        else if (current_map == "sp_a2_bts3") {
            CreateAPHologram(Vector(5952.0f, 4624.0f, -1736.0f), QAngle(0, 0, 0), 1.0f, null, "", 0, "sp_a2_bts3_map_check_holo", true);
        }
        else if (current_map == "sp_a2_bts4") {
            CreateAPHologram(Vector(-4080.0f, -7232.0f, 6328.0f), QAngle(0, 0, 0), 1.0f, null, "", 0, "sp_a2_bts4_map_check_holo", true);
        }
        else if (current_map == "sp_a2_bts5") {
            CreateAPHologram(Vector(1592.840f, 512.986f, 4492.260f), QAngle(0, 90.0f, 0), 1.0f, null, "", 0, "sp_a2_bts5_map_check_holo", false);
        }
        else if (current_map == "sp_a2_bts6") {
            CreateAPHologram(Vector(-2656.0f, -5120.0f, 5228.0f), QAngle(0, 90.0f, 0), 1.0f, null, "", 0, "sp_a2_bts6_map_check_holo", false);
        }
       else if (current_map == "sp_a3_00") {
            // Find the specific moving tracktrain section
            CBaseEntity@ shaft = EntityList().FindByName(null, "shaft_section_10");
            
            // Strictly require the shaft to exist. No static fallbacks to ruin the illusion!
            if (shaft !is null) {
                // Vector and Angle are LOCAL offsets relative to the center of "shaft section 10".
                Vector localPos(0.0f, 0.0f, 350.0f);
                QAngle localAng(0.0f, 0.0f, 90.0f);
                
                // Spawn and parent it directly to the shaft
                CreateAPHologram(localPos, localAng, 1.5f, shaft, "", 0, "sp_a3_00_map_check_holo", false);
            }
        }
        else if (current_map == "sp_a3_01") {
            CreateAPHologram(Vector(6016.0f, 4496.0f, -448.0f), QAngle(0, 0, 0), 1.0f, null, "", 0, "sp_a3_01_map_check_holo", true);
        }
        else if (current_map == "sp_a3_portal_intro") {
            CreateAPHologram(Vector(3839.990f, 348.800f, 5674.670f), QAngle(0, 0, 0), 1.0f, null, "", 0, "sp_a3_portal_intro_map_check_holo", true);
        }
        else if (current_map == "sp_a4_laser_platform") {
            CreateAPHologram(Vector(3456.0f, -1024.0f, -2480.0f), QAngle(0, 0, 0), 1.0f, null, "", 0, "sp_a4_laser_platform_map_check_holo", true);
        }
        else if (current_map == "sp_a4_finale1") {
            CreateAPHologram(Vector(-12832.0f, -3040.0f, -112.0f), QAngle(0, 0, 0), 1.0f, null, "", 0, "sp_a4_finale1_map_check_holo", true);
        }
        else if (current_map == "sp_a4_finale2") {
            CreateAPHologram(Vector(-3152.0f, -1928.0f, -280.0f), QAngle(0, 0, 0), 1.0f, null, "", 0, "sp_a4_finale2_map_check_holo", true);
        } 
        else if (current_map == "sp_a4_finale3") {
            CreateAPHologram(Vector(-616.0f, 5376.0f, 580.0f), QAngle(0, 0, 0), 1.0f, null, "", 0, "sp_a4_finale3_map_check_holo", true);
        }    
    }
    
    // --- PARTIE 2 : ASCENSEURS ---
    if (!isNonElevatorMap || current_map == "sp_a2_core" || current_map == "sp_a1_intro1") {
        CBaseEntity@ tEnt = null;
        while ((@tEnt = EntityList().FindByClassname(tEnt, "func_tracktrain")) !is null) {
            string tName = tEnt.GetEntityName();
            
            if (tName.locate("exit_lift_train") != uint(-1) || tName.locate("departure_elevator-elevator") != uint(-1) || tName.locate("exit_elevator_train") != uint(-1)) {
                
                bool animate_elevator = true;
                if (current_map == "sp_a2_core" || current_map == "sp_a1_intro1") {
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
            float offsetX = -85.0f; 
            float offsetY = 25.0f;   
            float offsetZ = 0.0f;   
            
            pos.x += offsetX;
            pos.y += offsetY;
            pos.z += offsetZ;

            // --- RÉGLAGE DE LA TAILLE (SCALE) ---
            float holoScale = 2.0f; 

            // --- ORIENTATION MANUELLE ---
            QAngle fixed_ang(0.0f, -277.0f, 90.0f); 

            // Création de l'hologramme
            CreateAPHologram(pos, fixed_ang, holoScale, null, "", 0, "moon_holo", false);
        }
    }
} 

} // Legacy