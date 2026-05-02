// =============================================================
// ARCHIPELAGO INITIALIZATION BOOTSTRAP
// =============================================================

// 1. Foundation (Global Memory)
#include "ap/shared/tracking_globals.as"

// 2. Entities (Visual Foundation)
#include "ap/entities/create_ap_hologram.as"
#include "ap/entities/attach_hologram_to_entity.as"
#include "ap/entities/remove_all_button_frames.as"
#include "ap/entities/remove_all_floor_button_frames.as"
#include "ap/entities/frame_logic_pedestal.as"
#include "ap/entities/frame_logic_floor.as"
#include "ap/entities/map_holos.as"

// 3. Locations (Randomizer Checks & Progression)
#include "ap/locations/add_wheatley_monitor_break_check.as"
#include "ap/locations/HandleMonitorWarp.as"
#include "ap/locations/spawn_ap_button_logic.as"
#include "ap/locations/create_complete_level_alert_hook.as"
#include "ap/locations/handle_map_completion.as"

// 4. Client (Player Systems)
#include "ap/client/deathlink.as"
#include "ap/client/potatos.as"

// 5. Overrides (Map Fixes)
#include "ap/overrides/do_map_specific_setup.as"
#include "ap/overrides/disarm_legacy_logic.as"
#include "ap/overrides/block_wheatley_fight.as"

// 6. Shared Library
#include "ap/shared/update_internal_map_name.as"
#include "ap/shared/ap_hologram_visuals.as"
#include "ap/shared/add_entity_output_script.as"
#include "ap/shared/add_entity_output_script_at_pos.as"
#include "ap/shared/call_vscript.as"
#include "ap/shared/delete_core_on_output.as"
#include "ap/shared/delete_entity.as"
//#include "ap/shared/get_entities.as"
#include "ap/shared/disable_entity.as"
#include "ap/shared/disable_entity_physics.as"

#include "ap/shared/disable_entity_pickup.as"
#include "ap/shared/disable_portal_gun.as"
#include "ap/shared/find_entities.as"
#include "ap/shared/warp_to_menu.as"

// 7. Interfaces & Startup
#include "ap/traps/traps_hub.as"
#include "ap/server_command.as"
#include "ap/bootstrap/delayed_init.as"
#include "ap/bootstrap/reset_persistent_systems.as"
#include "ap/heartbeat.as"

/**
 * InitializeArchipelago - Atomic setup of core bridge entities.
 */
bool InitializeArchipelago() {
    ArchipelagoLog("[Archipelago] INITIALIZING CORE...");
    CBaseEntity@ cmd = util::CreateEntityByName("point_servercommand");
    if (cmd !is null) {
        cmd.KeyValue("targetname", "InitCmd");
        cmd.Spawn();
        
        // --- PRECACHE ARCHIPELAGO ASSETS ---
        // Using the cmd entity to handle the precaching
        cmd.PrecacheModel("models/props/archipelago/ap_buttonframe.mdl");
        cmd.PrecacheModel("models/props/archipelago/ap_floorbuttonframe.mdl");
        cmd.PrecacheModel("models/props/archipelago/ap_proptractorbeamframe.mdl");
        cmd.PrecacheModel("models/effects/ap/archipelago_hologram.mdl");
        cmd.PrecacheModel("models/props/switch001.mdl");
        
        // Precache standard entities used in traps
        cmd.PrecacheModel("models/props/weighted_cube.mdl");
        cmd.PrecacheModel("models/props/metal_box.mdl");
        cmd.PrecacheModel("models/props_underground/underground_weighted_cube.mdl");
        
        // Start background systems immediately.
        AttachDeathTrigger();
        StartGameStatusTimer();

        // Schedule the one-time map setup to run exactly 1.0 second from now
        Variant vInit;
        vInit.SetString("RunDelayedInit");
        cmd.FireInput("Command", vInit, 1.0f, null, null, 0);

        ArchipelagoLog("[Archipelago] SUCCESS: Core Ready & Assets Precached.");
    }
    
    return true; 
}

// Global bootstrap trigger
bool Init = InitializeArchipelago();
