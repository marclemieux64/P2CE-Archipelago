// =============================================================
// ARCHIPELAGO MOTION BLUR TRAP (OOP VERSION)
// =============================================================

namespace Archipelago {

class MotionBlurTrap : ITrap {
    string GetName() const override { return "MotionBlur"; }

    void Trigger(const CommandArgs@ args) override {
        // Retrieve duration parameter from command arguments
        float duration = (args !is null && args.ArgC() >= 2) ? args.Arg(1).toFloat() : 20.0f;
        
        CallVScript("SendToPanorama(\"ArchipelagoTrapTriggered\", \"MotionBlur|" + duration + "\")");
        
        // 1. Check if motion blur is enabled in player settings
        ConVarRef cv_motionblur("mat_motion_blur_enabled");
        bool wasEnabled = cv_motionblur.GetBool();
        
        CBaseEntity@ cmd = EntityList().FindByName(null, "InitCmd");
        if (!wasEnabled && cmd !is null) {
            Variant v;
            v.SetString("mat_motion_blur_enabled 1");
            cmd.FireInput("Command", v, 0.0f, null, null, 0);
        }

        // 2. Find or create logic_playerproxy
        CBaseEntity@ lpp = EntityList().FindByClassname(null, "logic_playerproxy");
        if (lpp is null) {
            @lpp = util::CreateEntityByName("logic_playerproxy");
            if (lpp !is null) lpp.Spawn();
        }

        if (lpp !is null) {
            Variant v;
            
            // 3. Activate motion blur
            v.SetFloat(1.0f);
            lpp.FireInput("SetMotionBlurAmount", v, 0.0f, null, null);

            // 4. Set up timed reset back to 0
            v.SetFloat(0.0f);
            lpp.FireInput("SetMotionBlurAmount", v, duration, null, null);
        }

        // 5. Restore original motion blur setting after trap finishes
        if (!wasEnabled && cmd !is null) {
            Variant vRestore;
            vRestore.SetString("mat_motion_blur_enabled 0");
            cmd.FireInput("Command", vRestore, duration, null, null, 0);
        }
    }
}

} // namespace Archipelago
