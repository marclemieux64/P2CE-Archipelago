// =============================================================
// ARCHIPELAGO MOTION BLUR TRAP
// =============================================================
void TriggerMotionBlurTrap(float duration = 20.0f) {
    CallVScript("SendToPanorama(\"ArchipelagoTrapTriggered\", \"MotionBlur|" + duration + "\")");
    // 1. Find or create logic_playerproxy
    CBaseEntity@ lpp = EntityList().FindByClassname(null, "logic_playerproxy");
    if (lpp is null) {
        @lpp = util::CreateEntityByName("logic_playerproxy");
        if (lpp !is null) lpp.Spawn();
    }

    if (lpp !is null) {
        Variant v;
        
        // 2. Activate blur
        v.SetFloat(1.0f);
        lpp.FireInput("SetMotionBlurAmount", v, 0.0f, null, null);

        // 3. Set up timed reset
        v.SetFloat(0.0f);
        lpp.FireInput("SetMotionBlurAmount", v, duration, null, null);
    }
}


