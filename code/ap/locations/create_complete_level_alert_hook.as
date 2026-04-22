void CreateCompleteLevelAlertHook(string map) {
    g_has_printed_map_complete = false;
    
    // Initialisation du compteur pour les maps à double trigger
    if (two_trigger_levels.find(map) >= 0) {
        transition_script_count = 1;
    }

    // --- LE SCAN DES TRIGGERS ANONYMES (La clé qui remplace le VScript) ---
    CBaseEntity@ tr = null;
    while ((@tr = EntityList().FindByClassname(tr, "trigger_once")) !is null) {
        if (tr.GetEntityName() == "") { 
            Vector pos = tr.GetAbsOrigin();
            bool is_target = false;

            if (map == "sp_a2_bts3" && pos.DistTo(Vector(5952, 4624, -1736)) < 100) is_target = true;
            else if (map == "sp_a2_bts4" && pos.DistTo(Vector(-4080, -7232, 6328)) < 100) is_target = true;
            else if (map == "sp_a2_core" && pos.DistTo(Vector(0, 304, -10438)) < 100) is_target = true;
            else if (map == "sp_a4_finale1" && pos.DistTo(Vector(-12832, -3040, -112)) < 100) is_target = true;
            else if (map == "sp_a4_finale2" && pos.DistTo(Vector(-3152, -1928, -240)) < 100) is_target = true;

            if (is_target) {
                Variant v;
                v.SetString("OnStartTouch ap_init_cmd:Command:ap_print_complete:0.0:-1");
                tr.FireInput("AddOutput", v, 0.0f, null, null, 0);
            }
        }
    }

    // --- LOGIQUE FINALE ---
    if (map == "sp_a4_finale4") {
        array<CBaseEntity@> relays = FindEntities("ending_relay");
        for (uint i = 0; i < relays.length(); i++) {
            Variant v;
            v.SetString("OnTrigger ap_init_cmd:Command:ap_print_complete_no_exit:0.0:-1");
            relays[i].FireInput("AddOutput", v, 0.0f, null, null, 0);
        }
    } 
    // --- LOGIQUE NON-ELEVATOR (Méthode Simplifiée) ---
    else if (non_elevator_maps.find(map) >= 0) {
        
        // LA MÉTHODE "BTS5" APPLIQUÉE PARTOUT : 
        // On détruit proprement le script de transition natif pour TOUTES ces maps.
        // Cela empêche le jeu de faire un "hot-swap" du niveau sous nos pieds.
        array<CBaseEntity@> logicScripts = FindEntities("@transition_script");
        for (uint i = 0; i < logicScripts.length(); i++) {
            logicScripts[i].Remove();
        }

        // Hooks standards (Safe fallback)
        array<string> targets = { 
            "transition_trigger", 
            "trigger_transition",
            "@transition_from_map", 
            "*transition_without_survey*",
            "*transition_with_survey*",
            "@debug_change_to_next_map",
            "potatos_end_relay",
            "relay_transition",
            "ending_relay"
        };
        
        for (uint s = 0; s < targets.length(); s++) {
            CBaseEntity@ ent = null;
            while ((@ent = EntityList().FindByName(ent, targets[s])) != null) {
                Variant v; v.SetString("OnStartTouch ap_init_cmd:Command:ap_print_complete:0.0:-1");
                ent.FireInput("AddOutput", v, 0.0f, null, null, 0);
                Variant v2; v2.SetString("OnTrigger ap_init_cmd:Command:ap_print_complete:0.0:-1");
                ent.FireInput("AddOutput", v2, 0.0f, null, null, 0);
            }
        }
    } 
    // --- LOGIQUE ELEVATOR ---
    else {
        array<CBaseEntity@> cls = FindEntities("@transition_from_map");
        if (cls.length() > 0) {
            for (uint i = 0; i < cls.length(); i++) {
                Variant v;
                v.SetString("OnTrigger ap_init_cmd:Command:ap_print_complete:0.0:-1");
                cls[i].FireInput("AddOutput", v, 0.0f, null, null, 0);
            }
        }
        DeleteEntity("@exit_teleport", false);
    }
}