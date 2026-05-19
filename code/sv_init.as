// =============================================================
// ARCHIPELAGO SV INIT (LEGACY ENTRY POINT)
// =============================================================

// 1. Independent Legacy Globals
#include "Archipelago/Legacy/legacy_globals.as"

// 2. Legacy Logic
#include "Archipelago/Legacy/textqueue.as"
#include "Archipelago/Legacy/HologramOverrides.as"
#include "Archipelago/Legacy/mapspawn.as"
#include "Archipelago/Legacy/mapspawn_commands.as"
#include "Archipelago/Legacy/AddMapCheck.as"
#include "Archipelago/Legacy/HologramDebug.as"
#include "Archipelago/ButterFingerTrap.as"
#include "Archipelago/CubeConfettiTrap.as"
#include "Archipelago/DialogTrap.as"
#include "Archipelago/MotionBlurTrap.as"
#include "Archipelago/SlipperyFloorTrap.as"
#include "Archipelago/FizzlePortalTrap.as"


/**
 * InitializeArchipelago - Atomic setup of core bridge entities.
 */
bool InitializeArchipelago() {
    Legacy::ArchipelagoLog("[Archipelago] INITIALIZING LEGACY CORE...");
    CBaseEntity@ cmd = util::CreateEntityByName("point_servercommand");
    if (cmd !is null) {
        cmd.KeyValue("targetname", "InitCmd");
        cmd.Spawn();
        
        // --- PRECACHE ARCHIPELAGO ASSETS ---
        cmd.PrecacheModel("models/props/archipelago/ap_buttonframe.mdl");
        cmd.PrecacheModel("models/props/archipelago/ap_floorbuttonframe.mdl");
        cmd.PrecacheModel("models/props/archipelago/ap_proptractorbeamframe.mdl");
        cmd.PrecacheModel("models/effects/ap/archipelago_hologram.mdl");
        
        // --- INITIALIZE LEGACY SYSTEMS ---
        // Delayed to prevent null pointer exceptions during early bootstrap
        Variant vInit;
        vInit.SetString("RunDelayedInit");
        cmd.FireInput("Command", vInit, 0.5f, null, null, 0);
        
        Legacy::ArchipelagoLog("[Archipelago] SUCCESS: Legacy Core Bridge Ready.");
    }
    
    return true; 
}

// Global bootstrap trigger
bool Init = InitializeArchipelago();
