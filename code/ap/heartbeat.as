// =============================================================
// ARCHIPELAGO DEATHLINK HEARTBEAT
// =============================================================

[ServerCommand("DeathlinkTick", "Internal mod deathlink heartbeat")]
void DeathLinkTickCmd(const CommandArgs@ args) {
    RunDeathLinkTick();
}

// =============================================================
// ARCHIPELAGO GAME STATUS HEARTBEAT
// =============================================================

// Tracking list to ensure we only process an entity ONCE per map session
array<int> g_processed_turret_indices;

void StartGameStatusTimer() {
    CBaseEntity@ old = EntityList().FindByName(null, "GameStatusTimer");
    if (old !is null) old.Remove();

    CBaseEntity@ timer = util::CreateEntityByName("logic_timer");
    if (timer !is null) {
        timer.KeyValue("targetname", "GameStatusTimer");
        timer.KeyValue("RefireTime", "0.5"); // Slower refire for stability
        timer.KeyValue("StartDisabled", "1");
        timer.Spawn();
        
        SafeAddOutput(timer, "OnTimer", "InitCmd", "Command", "GameStatusTick", 0.0f, -1);

        Variant vEnable;
        timer.FireInput("Enable", vEnable, 1.0f, null, null, 0);
    }
    ArchipelagoLog("Archipelago-Mod: Game Status monitoring active.");
}

[ServerCommand("GameStatusTick", "Internal mod game status heartbeat")]
void GameStatusTickCmd(const CommandArgs@ args) {
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
                int index = t.GetEntityIndex();
                
                // Have we already handled this specific turret?
                bool alreadySeen = false;
                for (uint j = 0; j < g_processed_turret_indices.length(); j++) {
                    if (g_processed_turret_indices[j] == index) {
                        alreadySeen = true;
                        break;
                    }
                }
                
                if (alreadySeen) {
                    // ArchipelagoLog("[AP DEBUG] Heartbeat skipping turret " + index + " (Already seen)");
                    continue;
                }

                // New turret! 
                ArchipelagoLog("[AP DEBUG] Heartbeat FOUND NEW TURRET " + index + ". Triggering attachment.");
                g_processed_turret_indices.insertLast(index);
                
                string tName = t.GetEntityName();
                if (tName == "") tName = cls + "_" + index;
                
                DisableEntityPickup(cls);
                AttachHologramToEntity(tName, "", 0.66f, 20.0f, 2);
            }
        }
    }
}
