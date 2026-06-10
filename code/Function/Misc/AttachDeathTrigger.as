// =============================================================
// ARCHIPELAGO DEATHLINK TRIGGER ATTACHMENT
// =============================================================

namespace Archipelago {

    void AttachDeathTrigger() {
        sent_death_link = false; // Réinitialise à chaque chargement de map

        // Création du timer natif pour la synchronisation bidirectionnelle
        CBaseEntity@ timer = util::CreateEntityByName("logic_timer");
        if (timer !is null) {
            timer.KeyValue("targetname", "ap_deathlink_timer");
            timer.KeyValue("RefireTime", "0.25"); // Évaluation 4 fois par seconde
            
            // On redirige la sortie du timer vers notre nouvelle fonction centrale
            string payload = "InitCmd\x1BCommand\x1BCheckDeathLinkQueue\x1B0\x1B-1";
            timer.KeyValue("OnTimer", payload);
            
            timer.Spawn();
            
            // Activation immédiate du timer
            Variant empty;
            timer.FireInput("Enable", empty, 0.0f, null, null, 0);
        }

        Msgl("DeathLink continuous sync active");
    }

} // namespace Archipelago