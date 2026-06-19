namespace Archipelago {

void CreateCompleteLevelAlertHook(string map) {
    g_has_printed_map_complete = false;
    
    // Initialisation du compteur pour les maps à double trigger
    if (two_trigger_levels.find(map) >= 0) {
        transition_script_count = 1;
    }

    // --- RESTAURATION : Le scan des triggers anonymes (Fixes spécifiques par map) ---
    // On crée un tableau avec les deux types de triggers à chercher
    array<string> triggerClasses = {"trigger_once", "trigger_multiple"};
    
    for (uint i = 0; i < triggerClasses.length(); i++) {
        CBaseEntity@ tr = null;
        while ((@tr = EntityList().FindByClassname(tr, triggerClasses[i])) !is null) {
            if (tr.GetEntityName() == "") { 
                Vector pos = tr.GetAbsOrigin();
                bool is_target = false;

                // CORRECTION : La chaîne des 'else if' est maintenant parfaite
                if (map == "sp_a2_bts3" && pos.DistTo(Vector(5952, 4624, -1736)) < 2.0f) is_target = true;
                else if (map == "sp_a2_bts4" && pos.DistTo(Vector(-4080, -7232, 6328)) < 2.0f) is_target = true;
                else if (map == "sp_a2_core" && pos.DistTo(Vector(0, 304, -10438)) < 2.0f) is_target = true;
                else if (map == "sp_a4_finale1" && pos.DistTo(Vector(-12832, -3040, -112)) < 2.0f) is_target = true;
                else if (map == "sp_a4_finale2" && pos.DistTo(Vector(-3152, -1928, -240)) < 2.0f) is_target = true;

                if (is_target) {
                    SafeAddOutput(tr, "OnStartTouch", "InitCmd", "Command", "PrintMapComplete", 0.0f, -1);
                }
            }
        }
    }

    // --- RESTAURATION : Logique finale spéciale pour sp_a4_finale4 ---
    if (map == "sp_a4_finale4") {
        array<CBaseEntity@> relays = FindEntities("ending_relay");
        for (uint i = 0; i < relays.length(); i++) {
            SafeAddOutput(relays[i], "OnTrigger", "InitCmd", "Command", "PrintCompleteNoExit", 0.0f, -1);
        }
    } 
    // --- LOGIQUE NON-ELEVATOR (Méthode Moderne) ---
    else if (non_elevator_maps.find(map) >= 0) {
        // Empêche le jeu de faire un "hot-swap"
        array<CBaseEntity@> logicScripts = FindEntities("@transition_script");
        for (uint i = 0; i < logicScripts.length(); i++) {
            logicScripts[i].Remove();
        }

        // CORRECTION : Les doublons ont été retirés !
        array<string> targets = { "transition_trigger", "relay_transition", "ending_relay", "potatos_end_relay" };
        for (uint s = 0; s < targets.length(); s++) {
            array<CBaseEntity@> ents = FindEntities(targets[s]);
            for (uint i = 0; i < ents.length(); i++) {
                SafeAddOutput(ents[i], "OnStartTouch", "InitCmd", "Command", "PrintMapComplete", 0.0f, -1);
                SafeAddOutput(ents[i], "OnTrigger", "InitCmd", "Command", "PrintMapComplete", 0.0f, -1);
            }
        }
    } 
    // --- LOGIQUE ELEVATOR (Avec Restauration du hook) ---
    else {
        array<CBaseEntity@> cls = FindEntities("@transition_from_map");
        for (uint i = 0; i < cls.length(); i++) {
            SafeAddOutput(cls[i], "OnTrigger", "InitCmd", "Command", "PrintMapComplete", 0.0f, -1);
        }
        
        DeleteEntity("@exit_teleport", false);
    }
}

} // namespace Archipelago
