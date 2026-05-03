// =============================================================
// ARCHIPELAGO RUN GAME STATUS TICK COMMAND
// =============================================================

void RunGameStatusTickCommand(const CommandArgs@ args) {
    // 0. Sync ArchipelagoDebug with Panorama
    bool currentDebug = cv_ArchipelagoDebug.GetBool();
    if (currentDebug != g_LastDebugState) {
        g_LastDebugState = currentDebug;
        CallVScript("SendToPanorama(\"ArchipelagoDebug\", \"" + (currentDebug ? "1" : "0") + "\")");
        CallVScript("::ArchipelagoDebug <- " + (currentDebug ? "true" : "false"));
        ArchipelagoLog("[AP] Debug logging " + (currentDebug ? "ENABLED" : "DISABLED"));
    }

    CBaseEntity@ cmd = EntityList().FindByName(null, "InitCmd");
    if (cmd is null) return;

    // 1. Suppression Loop (Only if needed)
    if (g_suppressed_entities.length() > 0) {
        for (uint i = 0; i < g_suppressed_entities.length(); i++) {
            Variant v;
            v.SetString("ent_fire " + g_suppressed_entities[i] + " Stop");
            cmd.FireInput("Command", v, 0.0f, null, null, 0);
        }
    }

    // 2. Persistent Class Suppression (Turrets)
    if (g_suppressed_classes.length() > 0) {
        for (uint i = 0; i < g_suppressed_classes.length(); i++) {
            string cls = g_suppressed_classes[i];
            
            CBaseEntity@ t = null;
            while ((@t = EntityList().FindByClassname(t, cls)) !is null) {
                string tName = t.GetEntityName();
                if (tName == "") {
                    tName = cls + "_" + t.GetEntityIndex();
                    t.KeyValue("targetname", tName);
                }
                
                string hName = tName + "_holo";
                if (EntityList().FindByName(null, hName) !is null) continue;

                // New turret! 
                if (cv_ArchipelagoDebug.GetBool()) ArchipelagoLog("[AP DEBUG] Heartbeat FOUND NEW TURRET " + tName + ". Triggering attachment.");
                
                DisableEntityPickup(cls);
                AttachHologramToEntity(tName, "", 0.66f, 20.0f, 2);
            }
        }
    }
}
