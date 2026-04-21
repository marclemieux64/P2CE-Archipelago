void CreateCompleteLevelAlertHook(string map) {
    // CAS SPÉCIAL : Finale de Portal 2 (sp_a4_finale4)
    if (map == "sp_a4_finale4") {
        array<CBaseEntity@> relays = FindEntities("ending_relay");
        for (uint i = 0; i < relays.length(); i++) {
            Variant v;
            v.SetString("OnTrigger ap_init_cmd:Command:ap_print_complete_no_exit:0.0:-1");
            relays[i].FireInput("AddOutput", v, 0.0f, null, null, 0);
        }
    } else {
        // 1. Hook pour les maps sans ascenseurs (transition_trigger)
        array<CBaseEntity@> tlist = FindEntities("transition_trigger");
        for (uint i = 0; i < tlist.length(); i++) {
            Variant v;
            v.SetString("OnStartTouch ap_init_cmd:Command:ap_print_complete:0.0:-1");
            tlist[i].FireInput("AddOutput", v, 0.0f, null, null, 0);
        }

        // 2. Hook pour les relais de transition (Standard et PotatOS)
        // On évite les relais "start" car ils sont souvent utilisés au spawn.
        array<string> relayNames = { 
            "@transition_from_map", 
            "potatos_end_relay", 
            "elevator_1_departure_relay", 
            "departure_relay",
            "level_end_relay",
            "elevator_departure_relay",
            "@debug_change_to_next_map"
        };
        
        for (uint i = 0; i < relayNames.length(); i++) {
            array<CBaseEntity@> relays = FindEntities(relayNames[i]);
            for (uint j = 0; j < relays.length(); j++) {
                Variant v;
                v.SetString("OnTrigger ap_init_cmd:Command:ap_print_complete:0.0:-1");
                relays[j].FireInput("AddOutput", v, 0.0f, null, null, 0);
                Msgl("[AP] Hooked transition relay: " + relayNames[i]);
            }
        }

        // 3. Désamorçage et remplacement des trigger_changelevel (Zone de crash connue)
        array<CBaseEntity@> cllist = FindEntities("trigger_changelevel");
        for (uint i = 0; i < cllist.length(); i++) {
            Variant v;
            v.SetString("OnStartTouch ap_init_cmd:Command:ap_print_complete:0.0:-1");
            cllist[i].FireInput("AddOutput", v, 0.0f, null, null, 0);
            
            Variant vEmpty;
            vEmpty.SetString(""); 
            cllist[i].FireInput("SetMap", vEmpty, 0.0f, null, null, 0);
            
            Msgl("[AP] Disarmed crash-prone trigger_changelevel.");
        }

        // 4. Nettoyage préventif des téléportations de sortie
        array<CBaseEntity@> teleports = FindEntities("@exit_teleport");
        for (uint i = 0; i < teleports.length(); i++) {
            teleports[i].Remove();
        }
    }
}
