namespace Archipelago {

// Global persistent reference handle to prevent allocation churn
EHandle<CBaseEntity> g_hVScriptBridge;

/**
 * Executes a VScript snippet inside the game engine.
 * Reuses a single persistent logic_script entity to save engine edicts.
 */
void CallVScript(string code) {
    CBaseEntity@ scriptEnt = g_hVScriptBridge.Get();
    
    // If our cached handle is invalid, try to find or create the persistent bridge
    if (scriptEnt is null) {
        @scriptEnt = EntityList().FindByName(null, "ap_vscript_bridge");
        
        if (scriptEnt is null) {
            @scriptEnt = util::CreateEntityByName("logic_script");
            if (scriptEnt !is null) {
                scriptEnt.KeyValue("targetname", "ap_vscript_bridge");
                scriptEnt.Spawn();
                ArchipelagoLog("Persistent VScript bridge successfully allocated.");
            }
        }
        g_hVScriptBridge.Set(scriptEnt);
    }

    if (scriptEnt !is null) {
        Variant vPayload;
        vPayload.SetString(code);
        scriptEnt.FireInput("RunScriptCode", vPayload, 0.0f, null, null, 0);
    } else {
        ArchipelagoLog("Error: CallVScript failed to allocate persistent logic_script bridge.");
    }
}

} 