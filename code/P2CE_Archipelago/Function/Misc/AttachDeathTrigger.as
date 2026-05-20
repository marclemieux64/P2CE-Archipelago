namespace Archipelago {

void AttachDeathTrigger() {
        sent_death_link = false; // Réinitialise à chaque chargement de map

        // Création du timer natif
        CBaseEntity@ timer = util::CreateEntityByName("logic_timer");
        if (timer !is null) {
            timer.KeyValue("targetname", "ap_deathlink_timer");
            timer.KeyValue("RefireTime", "0.5"); // Check 2 fois par seconde (plus réactif)
            
            // Format d'output Source : Target \x1B Input \x1B Parameter \x1B Delay \x1B MaxFires
            // On utilise l'entité "InitCmd" pour lancer notre ServerCommand
            string payload = "InitCmd\x1BCommand\x1BDeathLink\x1B0\x1B-1";
            timer.KeyValue("OnTimer", payload);
            
            timer.Spawn();
            
            // Activation du timer
            Variant empty;
            timer.FireInput("Enable", empty, 0.0f, null, null, 0);
        }

        Msgl("DeathLink active");
    }

} // namespace Archipelago
