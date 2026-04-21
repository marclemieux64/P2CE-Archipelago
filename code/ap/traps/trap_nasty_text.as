// THE BIO-HAZARD ENGINE
void ResetNastyBlock(int i) {
    g_NastyX[i] = RandomFloat(-0.2f, 1.2f);
    g_NastyY[i] = RandomFloat(-0.2f, 1.2f);
    g_NastyDX[i] = RandomFloat(-0.2f, 0.2f);
    g_NastyDY[i] = RandomFloat(-0.2f, 0.2f);
    g_ColorPhase[i] = RandomInt(0, 1);
}

/**
 * TriggerNastyTextTrap - Triggers maximum sensory overload.
 */
void TriggerNastyTextTrap() {
    g_NastyTextTicks = 0;
    string glitchMsg = "██████████████████████████████\n" +
        "▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒\n" +
            "▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓\n" +
                "░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░\n" +
                    "█ █ █ █ █ █ █ █ █ █ █ █ █ █ █\n" +
                        "SYSTEM_COLLAPSE_INITIATED\n" +
                            "010101010101010101010101010101\n" +
                                "CRITICAL_BIOMETRIC_FAILURE\n" +
                                    "██████████████████████████████";
    for (int i = 0; i < BLOCK_COUNT; i++) {
        ResetNastyBlock(i);
        string name = "ap_nasty_text_" + i;
        CBaseEntity@ ent = EntityList().FindByName(null, name);
        if (ent !is null) ent.Remove();
        @ent = util::CreateEntityByName("game_text");
        if (ent !is null) {
            ent.KeyValue("targetname", name);
            ent.KeyValue("message", glitchMsg);
            ent.KeyValue("fadein", "0.0");
            ent.KeyValue("fadeout", "0.0"); 
            ent.KeyValue("holdtime", "0.03");
            ent.KeyValue("spawnflags", "1"); 
            ent.KeyValue("channel", "" + ((i % 6) + 1));
            ent.Spawn();
        }
    }
    CBaseEntity@ timer = EntityList().FindByName(null, "ap_nasty_text_timer");
    if (timer !is null) timer.Remove();
    @timer = util::CreateEntityByName("logic_timer");
    if (timer !is null) {
        timer.KeyValue("targetname", "ap_nasty_text_timer");
        timer.KeyValue("RefireTime", "0.01");
        timer.Spawn();
        Variant v;
        v.SetString("OnTimer ap_init_cmd:Command:ap_nasty_text_tick:0.0:-1");
        timer.FireInput("AddOutput", v, 0.0f, null, null, 0);
    }
}

/**
 * RunNastyTextTick - Per-tick logic for the strobe trap.
 */
void RunNastyTextTick() {
    g_NastyTextTicks++;
    if (g_NastyTextTicks > 2000) {
        CBaseEntity@ timer = EntityList().FindByName(null, "ap_nasty_text_timer");
        if (timer !is null) timer.Remove();
        for (int i = 0; i < BLOCK_COUNT; i++) {
            CBaseEntity@ ent = EntityList().FindByName(null, "ap_nasty_text_" + i);
            if (ent !is null) ent.Remove();
        }
        return;
    }
    for (int i = 0; i < BLOCK_COUNT; i++) {
        g_NastyX[i] += g_NastyDX[i];
        g_NastyY[i] += g_NastyDY[i];
        if (g_NastyX[i] < -1.5f || g_NastyX[i] > 2.5f || g_NastyY[i] < -1.5f || g_NastyY[i] > 2.5f) ResetNastyBlock(i);
        CBaseEntity@ text = EntityList().FindByName(null, "ap_nasty_text_" + i);
        if (text !is null) {
            string clr = (g_NastyTextTicks % (2 + (i % 3)) == 0) ? "255 0 0" : (g_NastyTextTicks % 3 == 0 ? "0 255 0" : "255 255 255");
            text.KeyValue("color", clr);
            text.KeyValue("x", g_NastyX[i] + RandomFloat(-0.1f, 0.1f));
            text.KeyValue("y", g_NastyY[i] + RandomFloat(-0.1f, 0.1f));
            text.FireInput("Display", Variant(), 0.0f, null, null, 0);
        }
    }
    CBaseEntity@ player = EntityList().FindByClassname(null, "player");
    if (player !is null) {
        CBasePlayer@ p = cast<CBasePlayer>(player);
        p.SetViewPunchAngle(QAngle(RandomFloat(-15, 15), RandomFloat(-15, 15), RandomFloat(-30, 30)));
        if (g_NastyTextTicks % 2 == 0) p.EmitSound("UI/buttonrolly_select.wav");
    }
}
