// =============================================================
// ARCHIPELAGO SV INIT (ENTRY POINT - OOP VERSION)
// =============================================================

// This file is the starting point of the OOP AngelScript Section of the mod.

// --- DEBUG FIRST ---
#include "Debug/ArchipelagoLog.as"
#include "Debug/HologramDebug.as"

// --- UTILS ---
#include "Utils/MathUtils.as"
#include "Utils/GetPlayer.as"
#include "Utils/FindEntities.as"

// --- CORE ---
#include "Core/CallVScript.as"
#include "Core/SafeAddOutput.as"
#include "Core/Globals/ArchipelagoGlobals.as"

// --- TRAPS ---
#include "Traps/TrapManager.as"

// --- MANAGERS & SUBSYSTEMS ---
#include "Hologram/HologramManager.as"
#include "Entity/EntityManager.as"
#include "Misc/WorkflowManager.as"
#include "Check/APLocation.as"
#include "Check/CheckManager.as"

// --- COORDINATOR ---
#include "Core/ArchipelagoManager.as"

// --- COMMANDS ---
#include "Core/ArchipelagoCommands.as"

/**
 * InitializeArchipelago.
 * This function is responsible for creating the servercommand entity,
 * precaching all required custom models, and bootstrapping the OOP manager.
 */
bool InitializeArchipelago() {
    Msg("[Archipelago] INITIALIZING OOP CORE...\n");
    
    // Construct and Initialize the Coordinator
    @Archipelago::g_Archipelago = Archipelago::ArchipelagoManager();
    Archipelago::g_Archipelago.Initialize();

    CBaseEntity@ cmd = util::CreateEntityByName("point_servercommand");
    if (cmd !is null) {
        cmd.KeyValue("targetname", "InitCmd");
        cmd.Spawn();
        
        // --- PRECACHE ARCHIPELAGO ASSETS ---
        cmd.PrecacheModel("models/props/archipelago/ap_buttonframe.mdl");
        cmd.PrecacheModel("models/props/archipelago/ap_floorbuttonframe.mdl");
        cmd.PrecacheModel("models/props/archipelago/ap_proptractorbeamframe.mdl");
        cmd.PrecacheModel("models/effects/ap/archipelago_hologram.mdl");
        
        // --- INITIALIZE SYSTEMS ---
        Variant vInit;
        vInit.SetString("RunDelayedInit");
        cmd.FireInput("Command", vInit, 0.5f, null, null, 0);
        
        Msg("[Archipelago] SUCCESS: OOP Core Bridge Ready.\n");
    }
    
    return true; 
}

// Global bootstrap trigger
bool Init = InitializeArchipelago();
