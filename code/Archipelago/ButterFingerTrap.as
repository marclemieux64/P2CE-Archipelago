namespace Legacy {
void ButterFingersTrap(float duration = 30.0f) {
        // 1. Nettoyage des anciennes entités
        CBaseEntity@ oldInterval = EntityList().FindByName(null, "butter fingers");
        if (oldInterval !is null) oldInterval.Remove();

        CBaseEntity@ oldDisable = EntityList().FindByName(null, "disable butter fingers");
        if (oldDisable !is null) oldDisable.Remove();

        // 2. Création du Timer (logic_timer)
        CBaseEntity@ timer = util::CreateEntityByName("logic_timer");
        if (timer !is null) {
            timer.KeyValue("targetname", "butter fingers");
            timer.KeyValue("RefireTime", "2.5");
            timer.Spawn();

            // Simule l'appui (+use) et le relâchement (-use)
            SafeAddOutput(timer, "OnTimer", "InitCmd", "Command", "+use", 0.0f, -1);
            SafeAddOutput(timer, "OnTimer", "InitCmd", "Command", "-use", 0.5f, -1);
            SafeAddOutput(timer, "OnTimer", "InitCmd", "Command", "snd_playsounds Error", 0.0f, -1);
        }

        // 3. Le minuteur de fin (logic_relay)
        CBaseEntity@ killer = util::CreateEntityByName("logic_relay");
        if (killer !is null) {
            killer.KeyValue("targetname", "disable butter fingers");
            killer.Spawn();

            SafeAddOutput(killer, "OnTrigger", "butter fingers", "Kill", "", duration, 1);
            SafeAddOutput(killer, "OnTrigger", "InitCmd", "Command", "-use", duration + 0.1f, 1);
            SafeAddOutput(killer, "OnTrigger", "InitCmd", "Command", "say [Archipelago] Butter Fingers Trap Expired.", duration, 1);
            SafeAddOutput(killer, "OnTrigger", "!self", "Kill", "", duration + 0.5f, 1);

            // Déclenchement
            killer.FireInput("Trigger", Variant(), 0.0f, null, null);
        }

        // 4. Logging dans la console Source
        // Si 'print' ne fonctionne pas, 'Msg' est la fonction native de P2:CE
        Msg("Butter Fingers Trap Activated for " + duration + " seconds!\n");
    }

} // namespace Legacy