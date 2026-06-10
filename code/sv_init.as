// =============================================================
// ARCHIPELAGO SV INIT (ENTRY POINT)
// =============================================================

// --- DEBUG FIRST (Pour s'assurer que ArchipelagoLog est défini avant les commandes) ---
#include "Function/Debug/ArchipelagoLog.as"
#include "Function/Debug/HologramDebug.as"

// --- CORE ---
#include "Core/ArchipelagoCommands.as"
#include "Core/CallVScript.as"
#include "Core/CreateLPP.as"
#include "Core/EntFire.as"
#include "Core/Globals/ArchipelagoGlobals.as"
#include "Core/PrintAllEntities.as"
#include "Core/ResetPersistentSystems.as"
#include "Core/SafeAddOutput.as"
#include "Core/SendToConsole.as"
#include "Core/TextQueue.as"
#include "Core/UpdateInternalMapName.as"

// --- BUTTONS ---
#include "Function/Buttons/AddButtonFrame.as"
#include "Function/Buttons/AddFloorButtonFrame.as"
#include "Function/Buttons/ButtonScenarios.as"
#include "Function/Buttons/CreateAPButton.as"

// --- CHECK ---
#include "Function/Check/AddMapCheck.as"
#include "Function/Check/AddVitrifiedDoorChecks.as"
#include "Function/Check/AddWheatleyMonitorBreakCheck.as"
#include "Function/Check/CreateCompleteLevelAlertHook.as"
#include "Function/Check/InitLocationRegistries.as"
#include "Function/Check/PrintMapComplete.as"
#include "Function/Check/PrintMapCompleteNoExit.as"
#include "Function/Check/PrintMapName.as"

// --- ENTITY ---
 #include "Function/Entity/AddTractorBeamFrame.as"
#include "Function/Entity/CreateClearGel.as"
#include "Function/Entity/DeleteCoreOnOutput.as"
#include "Function/Entity/DeleteEntity.as"
#include "Function/Entity/DisableEntityPhysics.as"
#include "Function/Entity/DisableEntityPickup.as"
#include "Function/Entity/MakeFaithPlateFaulty.as"
#include "Function/Entity/PreventPickupForModel.as"
#include "Function/Entity/RemoveGel.as"

// --- HOLOGRAM ---
#include "Function/Hologram/CreateAPHologram.as"
#include "Function/Hologram/UpdateHologramsVisibility.as"
#include "Function/Hologram/AttachHologramToEntity.as"
#include "Function/Hologram/BTS4ConveyorLogic.as"
#include "Function/Hologram/CreateMapSpecificHolos.as"
#include "Function/Hologram/Overrides/GetHologramVisualOverrides.as"
#include "Function/Hologram/Overrides/OverrideGel.as"
#include "Function/Hologram/Overrides/OverrideCube.as"


// --- MISC ---
#include "Function/Misc/AddEntityOutputScriptAtPos.as"
#include "Function/Misc/AttachDeathTrigger.as"
#include "Function/Misc/BlockWheatleyFight.as"
#include "Function/Misc/DoMapSpecificSetup.as"
#include "Function/Misc/HandleMonitorWarp.as"
#include "Function/Misc/InitMonitorData.as"
#include "Function/Misc/SafeRemoveEntity.as"
#include "Function/Misc/SpawnPaintBomb.as"
#include "Function/Misc/WaitExecute.as"
#include "Function/Misc/WarpToMenu.as"

// --- PORTAL GUN ---
#include "Function/Portal_Gun/DisablePortalGun.as"
#include "Function/Portal_Gun/IncineratorDisablePortalGun.as"

// --- POTATOS ---
#include "Function/PotatOS/RemovePotatOS.as"
#include "Function/PotatOS/RemovePotatosFromGun.as"

// --- TRAPS (CORRIGÉ) ---
#include "Function/Traps/ButterFingerTrap.as"
#include "Function/Traps/CubeConfettiTrap.as"
#include "Function/Traps/DialogTrap.as"
#include "Function/Traps/FizzlePortalTrap.as"
#include "Function/Traps/MotionBlurTrap.as"
#include "Function/Traps/SlipperyFloorTrap.as"

// --- UTILS ---
#include "Utils/FindEntities.as"
#include "Utils/GetPlayer.as"
#include "Utils/ItemInList.as"
#include "Utils/MathUtils.as"

/**
 * InitializeArchipelago - Atomic setup of core bridge entities.
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
