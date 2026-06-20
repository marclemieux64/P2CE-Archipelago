// =============================================================
// ARCHIPELAGO BUTTER FINGERS TRAP (OOP VERSION)
// =============================================================

namespace Archipelago {

class ButterFingerTrap : ITrap {
    string GetName() const override { return "ButterFingers"; }

    void Trigger(const CommandArgs@ args) override {
        float duration = (args !is null && args.ArgC() >= 2) ? args.Arg(1).toFloat() : 30.0f;
        CallVScript("SendToPanorama(\"ArchipelagoTrapTriggered\", \"ButterFingers|" + duration + "\")");
        
        // 1. Clean up old instances of this trap
        CBaseEntity@ oldInterval = EntityList().FindByName(null, "butter fingers");
        if (oldInterval !is null) oldInterval.Remove();

        CBaseEntity@ oldDisable = EntityList().FindByName(null, "disable butter fingers");
        if (oldDisable !is null) oldDisable.Remove();

        // 2. Create the Timer entity (logic_timer)
        CBaseEntity@ timer = util::CreateEntityByName("logic_timer");
        if (timer !is null) {
            timer.KeyValue("targetname", "butter fingers");
            timer.KeyValue("RefireTime", "2.5");
            timer.Spawn();

            // Simulate player pressing (+use) and releasing (-use) buttons
            SafeAddOutput(timer, "OnTimer", "InitCmd", "Command", "+use", 0.0f, -1);
            SafeAddOutput(timer, "OnTimer", "InitCmd", "Command", "-use", 0.5f, -1);
        }

        // 3. Create the cleanup relay (logic_relay)
        CBaseEntity@ killer = util::CreateEntityByName("logic_relay");
        if (killer !is null) {
            killer.KeyValue("targetname", "disable butter fingers");
            killer.Spawn();

            SafeAddOutput(killer, "OnTrigger", "butter fingers", "Kill", "", duration, 1);
            SafeAddOutput(killer, "OnTrigger", "InitCmd", "Command", "-use", duration + 0.1f, 1);
            SafeAddOutput(killer, "OnTrigger", "InitCmd", "Command", "say [Archipelago] Butter Fingers Trap Expired.", duration, 1);
            SafeAddOutput(killer, "OnTrigger", "!self", "Kill", "", duration + 0.5f, 1);

            // Execute the relay trigger
            killer.FireInput("Trigger", Variant(), 0.0f, null, null);
        }

        Msg("Butter Fingers Trap Activated for " + duration + " seconds!\n");
    }
}

} // namespace Archipelago
