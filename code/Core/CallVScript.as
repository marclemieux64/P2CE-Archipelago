namespace Archipelago {

/**
 * Executes a VScript snippet inside the game engine.
 * Finds or creates the logic_script entity for the current map session.
 */
void CallVScript(const string &in code) {
    CBaseEntity@ scriptEnt = EntityList().FindByName(null, "ap_vscript_bridge");
    
    if (scriptEnt is null) {
        @scriptEnt = util::CreateEntityByName("logic_script");
        if (scriptEnt !is null) {
            scriptEnt.KeyValue("targetname", "ap_vscript_bridge");
            scriptEnt.Spawn();
            ArchipelagoLog("Persistent VScript bridge successfully allocated.");
        }
    }

    if (scriptEnt !is null) {
        Variant vPayload;
        vPayload.SetString(code);
        scriptEnt.FireInput("RunScriptCode", vPayload, 0.0f, null, null, 0);
    } else {
        ArchipelagoLog("Error: CallVScript failed to allocate logic_script bridge.");
    }
}

}
