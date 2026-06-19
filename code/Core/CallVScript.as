// =============================================================
// CALL VSCRIPT
// =============================================================
// This module is responsible to contact panorama UI from Anglescript.
// This module exist because only vscript has the abitlity to directly talk to panorama UI.

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
