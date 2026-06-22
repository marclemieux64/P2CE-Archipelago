// =============================================================
// ARCHIPELAGO TRAPS
// =============================================================

namespace Archipelago {

// --- INTERFACE ---

interface ITrap {
    string GetName() const;
    void Trigger(const CommandArgs@ args);
}

// --- TRAP IMPLEMENTATIONS ---

class ButterFingerTrap : ITrap {
    string GetName() const override { return "ButterFingers"; }

    void Trigger(const CommandArgs@ args) override {
        float duration = (args !is null && args.ArgC() >= 2) ? args.Arg(1).toFloat() : 30.0f;
        CallVScript("SendToPanorama(\"ArchipelagoTrapTriggered\", \"ButterFingers|" + duration + "\")");

        CBaseEntity@ oldInterval = EntityList().FindByName(null, "butter fingers");
        if (oldInterval !is null) oldInterval.Remove();

        CBaseEntity@ oldDisable = EntityList().FindByName(null, "disable butter fingers");
        if (oldDisable !is null) oldDisable.Remove();

        CBaseEntity@ timer = util::CreateEntityByName("logic_timer");
        if (timer !is null) {
            timer.KeyValue("targetname", "butter fingers");
            timer.KeyValue("RefireTime", "2.5");
            timer.Spawn();
            SafeAddOutput(timer, "OnTimer", "InitCmd", "Command", "+use", 0.0f, -1);
            SafeAddOutput(timer, "OnTimer", "InitCmd", "Command", "-use", 0.5f, -1);
        }

        CBaseEntity@ killer = util::CreateEntityByName("logic_relay");
        if (killer !is null) {
            killer.KeyValue("targetname", "disable butter fingers");
            killer.Spawn();
            SafeAddOutput(killer, "OnTrigger", "butter fingers", "Kill", "", duration, 1);
            SafeAddOutput(killer, "OnTrigger", "InitCmd", "Command", "-use", duration + 0.1f, 1);
            SafeAddOutput(killer, "OnTrigger", "InitCmd", "Command", "say [Archipelago] Butter Fingers Trap Expired.", duration, 1);
            SafeAddOutput(killer, "OnTrigger", "!self", "Kill", "", duration + 0.5f, 1);
            killer.FireInput("Trigger", Variant(), 0.0f, null, null);
        }

        Msg("Butter Fingers Trap Activated for " + duration + " seconds!\n");
    }
}

class CubeConfettiTrap : ITrap {
    string GetName() const override { return "CubeConfetti"; }

    void Trigger(const CommandArgs@ args) override {
        CBaseEntity@ player = EntityList().FindByClassname(null, "player");
        if (player is null) return;

        Vector pos = player.GetAbsOrigin();
        for (int i = 0; i < 20; i++) {
            CBaseEntity@ cube = util::CreateEntityByName("prop_weighted_cube");
            if (cube !is null) {
                cube.SetAbsOrigin(pos);
                cube.Spawn();
                Variant vColor;
                vColor.SetString(trap_colors[RandomInt(0, trap_colors.length() - 1)]);
                cube.FireInput("Color", vColor, 0.0f, null, null, 0);
                cube.FireInput("Dissolve", Variant(), 3.0f, null, null, 0);
            }
        }
    }
}

class DialogTrap : ITrap {
    string GetName() const override { return "Dialog"; }

    void Trigger(const CommandArgs@ args) override {
        float duration = (args !is null && args.ArgC() >= 3) ? args.Arg(2).toFloat() : 15.0f;
        CallVScript("SendToPanorama(\"ArchipelagoTrapTriggered\", \"Dialog|" + duration + "\")");

        CBaseEntity@ text = EntityList().FindByName(null, "ap_dialog_trap");
        if (text is null) {
            @text = util::CreateEntityByName("game_text");
            if (text !is null) {
                text.KeyValue("targetname", "ap_dialog_trap");
                text.KeyValue("message", "THE CAKE IS A LIE!THE CAKE IS A LIE!THE CAKE IS A LIE!\nTHE CAKE IS A LIE!THE CAKE IS A LIE!THE CAKE IS A LIE!\nTHE CAKE IS A LIE!THE CAKE IS A LIE!THE CAKE IS A LIE!\nTHE CAKE IS A LIE!THE CAKE IS A LIE!THE CAKE IS A LIE!\nTHE CAKE IS A LIE!THE CAKE IS A LIE!THE CAKE IS A LIE!\nTHE CAKE IS A LIE!THE CAKE IS A LIE!THE CAKE IS A LIE!\nTHE CAKE IS A LIE!THE CAKE IS A LIE!THE CAKE IS A LIE!\nTHE CAKE IS A LIE!THE CAKE IS A LIE!THE CAKE IS A LIE!");
                text.KeyValue("color", "250 0 0");
                text.KeyValue("fadein", "0.1");
                text.KeyValue("fadeout", "0.1");
                text.KeyValue("holdtime", "" + duration);
                text.KeyValue("spawnflags", "1");
                text.KeyValue("channel", "1");
                text.KeyValue("y", "-1");
                text.KeyValue("x", "-1");
                text.Spawn();
            }
        }
        if (text !is null)
            text.FireInput("Display", Variant(), 0.0f, null, null, 0);
    }
}

class FizzlePortalTrap : ITrap {
    string GetName() const override { return "FizzlePortal"; }

    void Trigger(const CommandArgs@ args) override {
        CBaseEntity@ portal = null;
        while ((@portal = EntityList().FindByClassname(portal, "prop_portal")) !is null)
            portal.FireInput("Fizzle", Variant(), 0.0f, null, null, 0);
    }
}

class MotionBlurTrap : ITrap {
    string GetName() const override { return "MotionBlur"; }

    void Trigger(const CommandArgs@ args) override {
        float duration = (args !is null && args.ArgC() >= 2) ? args.Arg(1).toFloat() : 20.0f;
        CallVScript("SendToPanorama(\"ArchipelagoTrapTriggered\", \"MotionBlur|" + duration + "\")");

        ConVarRef cv_motionblur("mat_motion_blur_enabled");
        bool wasEnabled = cv_motionblur.GetBool();

        CBaseEntity@ cmd = EntityList().FindByName(null, "InitCmd");
        if (!wasEnabled && cmd !is null) {
            Variant v;
            v.SetString("mat_motion_blur_enabled 1");
            cmd.FireInput("Command", v, 0.0f, null, null, 0);
        }

        CBaseEntity@ lpp = EntityList().FindByClassname(null, "logic_playerproxy");
        if (lpp is null) {
            @lpp = util::CreateEntityByName("logic_playerproxy");
            if (lpp !is null) lpp.Spawn();
        }

        if (lpp !is null) {
            Variant v;
            v.SetFloat(1.0f);
            lpp.FireInput("SetMotionBlurAmount", v, 0.0f, null, null);
            v.SetFloat(0.0f);
            lpp.FireInput("SetMotionBlurAmount", v, duration, null, null);
        }

        if (!wasEnabled && cmd !is null) {
            Variant v;
            v.SetString("mat_motion_blur_enabled 0");
            cmd.FireInput("Command", v, duration, null, null, 0);
        }
    }
}

class SlipperyFloorTrap : ITrap {
    string GetName() const override { return "SlipperyFloor"; }

    void Trigger(const CommandArgs@ args) override {
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
            v.SetString("sv_friction 0.0");
            cmd.FireInput("Command", v, 0.0f, null, null, 0);
            v.SetString("sv_friction 4");
            cmd.FireInput("Command", v, duration, null, null, 0);

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

// --- MANAGER ---

class TrapManager {
    private array<ITrap@> m_traps;

    void Initialize() {
        m_traps.insertLast(ButterFingerTrap());
        m_traps.insertLast(CubeConfettiTrap());
        m_traps.insertLast(DialogTrap());
        m_traps.insertLast(FizzlePortalTrap());
        m_traps.insertLast(MotionBlurTrap());
        m_traps.insertLast(SlipperyFloorTrap());
    }

    void TriggerTrap(const string& in trapName, const CommandArgs@ args) {
        for (uint i = 0; i < m_traps.length(); i++) {
            if (m_traps[i].GetName() == trapName) {
                m_traps[i].Trigger(args);
                return;
            }
        }
        ArchipelagoLog("Warning: Trap '" + trapName + "' is not registered.");
    }
}

} // namespace Archipelago
