// =============================================================
// ARCHIPELAGO DIALOG TRAP
// =============================================================
void TriggerDialogTrap(string scene = "", float duration = 15.0f) {
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
    if (text !is null) text.FireInput("Display", Variant(), 0.0f, null, null, 0);
}

