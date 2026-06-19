// =============================================================
// ARCHIPELAGO SV INIT (ENTRY POINT)
// =============================================================

// This file is the starting point of the AngelScript Section of the mod.

// --- DEBUG FIRST  ---
#include "Function/Debug/ArchipelagoLog.as"
#include "Function/Debug/HologramDebug.as"

// --- CORE ---
#include "Core/ArchipelagoCommands.as"
#include "Core/CallVScript.as"
#include "Core/Globals/ArchipelagoGlobals.as"
#include "Core/ResetPersistentSystems.as"
#include "Core/SafeAddOutput.as"
#include "Core/UpdateInternalMapName.as"

// --- CHECK ---
#include "Function/Check/Map/AddMapCheck.as"
#include "Function/Check/Vitrified Door/AddVitrifiedDoorChecks.as"
#include "Function/Check/Wheatley Monitor/AddWheatleyMonitorBreakCheck.as"
#include "Function/Check/Map/CreateCompleteLevelAlertHook.as"
#include "Function/Check/Vitrified Door/InitLocationRegistries.as"
#include "Function/Check/Map/PrintMapComplete.as"
#include "Function/Check/Map/PrintMapCompleteNoExit.as"
#include "Function/Check/Wheatley Monitor/InitMonitorData.as"
#include "Function/Check/Ratman Den/SetCheckedButtons.as"
#include "Function/Check/Map/SetCheckedMaps.as"
#include "Function/Check/Ratman Den/ButtonScenarios.as"
#include "Function/Check/Ratman Den/CreateAPButton.as"
#include "Function/Check/Vitrified Door/SetVitrifiedDoorChecks.as"
#include "Function/Check/Camera/AddCameraCheck.as"
#include "Function/Check/Camera/SetCheckedCamera.as"

// --- ENTITY ---
#include "Function/Entity/AddTractorBeamFrame.as"
#include "Function/Entity/DeleteCoreOnOutput.as"
#include "Function/Entity/DeleteEntity.as"
#include "Function/Entity/DisableEntityPhysics.as"
#include "Function/Entity/DisableEntityPickup.as"
#include "Function/Entity/MakeFaithPlateFaulty.as"
#include "Function/Entity/PreventPickupForModel.as"
// --- ENTITY/BUTTONS ---
#include "Function/Entity/Buttons/AddButtonFrame.as"
#include "Function/Entity/Buttons/AddFloorButtonFrame.as"
// --- ENTITY/GEL ---
#include "Function/Entity/Gel/CreateClearGel.as"
#include "Function/Entity/Gel/RemoveGel.as"
#include "Function/Entity/Gel/LockButtonByName.as"

// --- HOLOGRAM ---
#include "Function/Hologram/CreateAPHologram.as"
#include "Function/Hologram/UpdateHologramsVisibility.as"
#include "Function/Hologram/AttachHologramToEntity.as"
#include "Function/Hologram/BTS4ConveyorLogic.as"
#include "Function/Hologram/Finale2TurretLogic.as"
#include "Function/Hologram/CreateMapSpecificHolos.as"
// --- HOLOGRAM/OVERRIDES ---
#include "Function/Hologram/Overrides/GetHologramVisualOverrides.as"
#include "Function/Hologram/Overrides/OverrideGel.as"
#include "Function/Hologram/Overrides/OverrideCube.as"
#include "Function/Hologram/Overrides/OverrideProjector.as"

// --- MISC ---
#include "Function/Misc/AddEntityOutputScriptAtPos.as"
#include "Function/Misc/AttachDeathTrigger.as"
#include "Function/Misc/BlockWheatleyFight.as"
#include "Function/Misc/DoMapSpecificSetup.as"
#include "Function/Misc/HandleMonitorWarp.as"
#include "Function/Misc/SafeRemoveEntity.as"
#include "Function/Misc/SpawnPaintBomb.as"
#include "Function/Misc/WaitExecute.as"
#include "Function/Misc/WarpToMenu.as"
#include "Function/Misc/PrintMapName.as"
// -- MISC/SKIP ---
#include "Function/Misc/Skip/SkipContainer.as"
#include "Function/Misc/Skip/SkipElevatorRide.as"

// --- PORTAL GUN ---
#include "Function/Portal_Gun/DisablePortalGun.as"
#include "Function/Portal_Gun/IncineratorDisablePortalGun.as"

// --- POTATOS ---
#include "Function/PotatOS/RemovePotatOS.as"
#include "Function/PotatOS/RemovePotatosFromGun.as"

// --- TRAPS  ---
#include "Function/Traps/ButterFingerTrap.as"
#include "Function/Traps/CubeConfettiTrap.as"
#include "Function/Traps/DialogTrap.as"
#include "Function/Traps/FizzlePortalTrap.as"
#include "Function/Traps/MotionBlurTrap.as"
#include "Function/Traps/SlipperyFloorTrap.as"

// --- UTILS ---
#include "Utils/FindEntities.as"
#include "Utils/GetPlayer.as"
#include "Utils/MathUtils.as"

/**
 * InitializeArchipelago.
 That Function is responsible of creating the entity that gonna execute the 
 command send by the python Server via netcon. It also Precacche the asset ussed by the mod. 
 Lastly it's responsible to start the initialization sequence that act has a fail safe for the communication of the mod
 */
bool InitializeArchipelago() {
    Msg("[Archipelago] INITIALIZING CORE...\n");
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
        
        Msg("[Archipelago] SUCCESS: Core Bridge Ready.\n");
    }
    
    return true; 
}

// Global bootstrap trigger
bool Init = InitializeArchipelago();
