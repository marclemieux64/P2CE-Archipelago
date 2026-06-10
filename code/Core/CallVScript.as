namespace Archipelago {

void CallVScript(string code) {
        CBaseEntity@ scriptEnt = util::CreateEntityByName("logic_script");
        if (scriptEnt !is null) {
            scriptEnt.Spawn();
            Variant vPayload;
            vPayload.SetString(code);
            scriptEnt.FireInput("RunScriptCode", vPayload, 0.0f, null, null, 0);
            Variant vKill;
            scriptEnt.FireInput("Kill", vKill, 0.1f, null, null, 0);
        } else {
            ArchipelagoLog("[Archipelago] Error: CallVScript failed to create logic_script");
        }
    }

} // namespace Archipelago
