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

        // 2. Hook pour les maps à ascenseurs (@transition_from_map)
        CBaseEntity@ cl = EntityList().FindByName(null, "@transition_from_map");
        if (cl !is null) {
            Variant v;
            v.SetString("OnTrigger ap_init_cmd:Command:ap_print_complete:0.0:-1");
            cl.FireInput("AddOutput", v, 0.0f, null, null, 0);
            Msgl("[AP] Connected @transition_from_map trigger natively.");
        }

        // 3. Nettoyage préventif
        array<CBaseEntity@> teleports = FindEntities("@exit_teleport");
        for (uint i = 0; i < teleports.length(); i++) {
            teleports[i].Remove();
        }
    }
}
