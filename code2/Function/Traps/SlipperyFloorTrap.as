// =============================================================
// ARCHIPELAGO SLIPPERY FLOOR TRAP (OOP VERSION)
// =============================================================

namespace Archipelago {

class SlipperyFloorTrap : ITrap {
    string GetName() const override { return "SlipperyFloor"; }

    void Trigger(const CommandArgs@ args) override {
        // Retrieve duration parameter from command arguments
        float duration = (args !is null && args.ArgC() >= 2) ? args.Arg(1).toFloat() : 30.0f;
        
        CallVScript("SendToPanorama(\"ArchipelagoTrapTriggered\", \"SlipperyFloor|" + duration + "\")");
        
        CBaseEntity@ player = EntityList().FindByClassname(null, "player");
        if (player !is null) {
            player.SetFriction(0.01f);
            player.KeyValue("friction", "0.01");
        }

        CBaseEntity@ cmd = EntityList().FindByName(null, "InitCmd");
        if (cmd !is null) {
            Variant v;
            // Set world friction low for a real slippery feel
            v.SetString("sv_friction 0.0");
            cmd.FireInput("Command", v, 0.0f, null, null, 0);
            
            // Reset world friction after duration
            v.SetString("sv_friction 4");
            cmd.FireInput("Command", v, duration, null, null, 0);
            
            // Reset player-specific friction using a relay for the delay
            CBaseEntity@ relay = util::CreateEntityByName("logic_relay");
            if (relay !is null) {
                relay.Spawn();
                SafeAddOutput(relay, "OnTrigger", "!player", "AddOutput", "friction 1", duration + 0.01f, 1);
                relay.FireInput("Trigger", Variant(), 0.0f, null, null, 0);
                SafeAddOutput(relay, "OnTrigger", "!self", "Kill", "", duration + 1.0f, 1);
            }
            
            v.SetString("say [Archipelago] A slippery floor trap has been activated!");
            cmd.FireInput("Command", v, 0.0f, null, null, 0);
        }
    }
}

} // namespace Archipelago
