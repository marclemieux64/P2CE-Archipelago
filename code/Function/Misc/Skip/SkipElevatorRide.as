namespace Archipelago {

// Variables globales pour maintenir l'état du tracking
EHandle<CBaseEntity> g_hElevator;
float g_flInitialElevatorZ = 0.0f;

// Cette fonction sera appelée périodiquement par le logic_timer
// (ATTENTION : Pense à enregistrer "CheckElevatorRide" comme commande console dans ton mod, tout comme "CheckDeathLinkQueue")
void CheckElevatorRide() {
    CBaseEntity@ train = g_hElevator.Get();
    
    // Sécurité : si l'ascenseur n'existe plus, on nettoie le timer et on s'arrête
    if (train is null) {
        CBaseEntity@ timer = EntityList().FindByName(null, "ap_elevator_timer");
        if (timer !is null) timer.Remove();
        return;
    }

    Vector currentPos = train.GetAbsOrigin();

    // Si la position Z a changé par rapport à la position initiale
    if (!closeTo(currentPos.z, g_flInitialElevatorZ, 0.00f)) {
           CBaseEntity@ cmd = EntityList().FindByName(null, "InitCmd");
        if (cmd !is null) {
            Variant vFade;
            
            vFade.SetString("fadeout 0.2");
            cmd.FireInput("Command", vFade, 0.0f, null, null, 0);
            
            
        }
        PrintMapComplete();

        // Mission accomplie : on détruit le timer pour stopper les vérifications
        CBaseEntity@ timer = EntityList().FindByName(null, "ap_elevator_timer");
        if (timer !is null) {
            timer.Remove();
        }
    }
}

// Fonction d'initialisation à appeler au chargement de la map
void SkipElevatorRide() {
    CBaseEntity@ train = null;
    
    // Recherche de l'ascenseur de départ
    while ((@train = EntityList().FindByClassname(train, "func_tracktrain")) !is null) {
        string name = train.GetEntityName();
        
        if (name.locate("departure") < name.length()) {
            g_hElevator.Set(train);
            g_flInitialElevatorZ = train.GetAbsOrigin().z;

            // Création du timer périodique dédié à l'ascenseur
            CBaseEntity@ timer = util::CreateEntityByName("logic_timer");
            if (timer !is null) {
                timer.KeyValue("targetname", "ap_elevator_timer");
                timer.KeyValue("RefireTime", "0.25"); // Évaluation 4 fois par seconde
                
                // Payload calqué sur ton modèle de DeathLink
                string payload = "InitCmd\x1BCommand\x1BCheckElevatorRide\x1B0\x1B-1";
                timer.KeyValue("OnTimer", payload);
                
                timer.Spawn();
                
                // Activation immédiate
                Variant empty;
                timer.FireInput("Enable", empty, 0.0f, null, null, 0);
            }
            
            break; // Cible trouvée, on sort de la boucle
        }
    }
}

} // namespace Archipelago