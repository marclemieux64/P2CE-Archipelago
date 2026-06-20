// =============================================================
// CALL VSCRIPT HELPER
// =============================================================

namespace Archipelago {

/**
 * Executes a VScript snippet inside the game engine.
 * This is used to bridge communications with the Panorama UI.
 */
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
        ArchipelagoLog("Error: CallVScript failed to create logic_script");
    }
}

} // namespace Archipelago
