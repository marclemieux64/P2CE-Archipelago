// =============================================================
// ARCHIPELAGO INITIALIZATION BOOTSTRAP
// =============================================================
#include "ap/globals.as"
#include "ap/utils.as"
#include "ap/holograms.as"
#include "ap/buttons.as"
#include "ap/map_logic.as"
#include "ap/traps.as"
#include "ap/server_command.as"

// =============================================================
// INITIALIZATION
// =============================================================
bool InitializeArchipelago() {
    Msgl("----------------------------------------------");
    Msgl(">>> ARCHIPELAGO: Systems Starting...");
    Msgl("----------------------------------------------");
    
    CBaseEntity@ cmd = util::CreateEntityByName("point_servercommand");
    if (cmd !is null) {
        cmd.KeyValue("targetname", "ap_init_cmd");
        cmd.Spawn();
        
        // Precache Archipelago resources via this entity
        cmd.PrecacheModel("models/props/archipelago/ap_buttonframe.mdl");
        cmd.PrecacheModel("models/props/archipelago/ap_floorbuttonframe.mdl");
        cmd.PrecacheModel("models/props/switch001.mdl");
        cmd.PrecacheModel("models/props_underground/underground_testchamber_button.mdl");
        cmd.PrecacheModel("models/props/portal_button.mdl");
        cmd.PrecacheModel("models/effects/ap/archipelago_hologram.mdl");
        
        // --- ARCHIPELAGO SANITIZATION ---
        // Force all persistent trap states back to default on map load
        ResetPersistentSystems();
    }

    CBaseEntity@ relay = util::CreateEntityByName("logic_relay");
    if (relay !is null) {
        relay.KeyValue("targetname", "ap_init_relay");
        relay.Spawn();
        
        // The explicit VScript MapName grab using the console 'script' command was removed
        // here because P2CE blocks entities from executing console scripts.
        // We now safely rely entirely on the native 'host_map' ConVar fallback in utils.as.
        
        // 2. Spawn holos and setup completion hooks (which calls CreateCompleteLevelAlertHook)
        Variant vOut;
        vOut.SetString("OnTrigger ap_init_cmd:Command:ap_spawn_holos:1.0:-1");
        relay.FireInput("AddOutput", vOut, 0.0f, null, null, 0);
        
        relay.FireInput("Trigger", Variant(), 0.0f, null, null, 0);
    }
    
    return true; 
}

// This global bool is the ONLY thing that triggers automatically on script load
bool g_InitHandler = InitializeArchipelago();
