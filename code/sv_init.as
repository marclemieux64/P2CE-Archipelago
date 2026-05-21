// =============================================================
// ARCHIPELAGO SV INIT (ENTRY POINT)
// =============================================================

// --- DEBUG FIRST (Pour s'assurer que ArchipelagoLog est défini avant les commandes) ---
#include "P2CE_Archipelago/Function/Debug/ArchipelagoLog.as"
#include "P2CE_Archipelago/Function/Debug/HologramDebug.as"

// --- CORE ---
#include "P2CE_Archipelago/Core/ArchipelagoCommands.as"
#include "P2CE_Archipelago/Core/CallVScript.as"
#include "P2CE_Archipelago/Core/CreateLPP.as"
#include "P2CE_Archipelago/Core/EntFire.as"
#include "P2CE_Archipelago/Core/Globals/ArchipelagoGlobals.as"
#include "P2CE_Archipelago/Core/PrintAllEntities.as"
#include "P2CE_Archipelago/Core/ResetPersistentSystems.as"
#include "P2CE_Archipelago/Core/SafeAddOutput.as"
#include "P2CE_Archipelago/Core/SendToConsole.as"
#include "P2CE_Archipelago/Core/TextQueue.as"
#include "P2CE_Archipelago/Core/UpdateInternalMapName.as"

// --- BUTTONS ---
#include "P2CE_Archipelago/Function/Buttons/AddButtonFrame.as"
#include "P2CE_Archipelago/Function/Buttons/AddFloorButtonFrame.as"
#include "P2CE_Archipelago/Function/Buttons/ButtonScenarios.as"
#include "P2CE_Archipelago/Function/Buttons/CreateAPButton.as"

// --- CHECK ---
#include "P2CE_Archipelago/Function/Check/AddMapCheck.as"
#include "P2CE_Archipelago/Function/Check/AddVitrifiedDoorChecks.as"
#include "P2CE_Archipelago/Function/Check/AddWheatleyMonitorBreakCheck.as"
#include "P2CE_Archipelago/Function/Check/CreateCompleteLevelAlertHook.as"
#include "P2CE_Archipelago/Function/Check/InitLocationRegistries.as"
#include "P2CE_Archipelago/Function/Check/PrintMapComplete.as"
#include "P2CE_Archipelago/Function/Check/PrintMapCompleteNoExit.as"
#include "P2CE_Archipelago/Function/Check/PrintMapName.as"

// --- ENTITY ---
 #include "P2CE_Archipelago/Function/Entity/AddTractorBeamFrame.as"
#include "P2CE_Archipelago/Function/Entity/CreateClearGel.as"
#include "P2CE_Archipelago/Function/Entity/DeleteCoreOnOutput.as"
#include "P2CE_Archipelago/Function/Entity/DeleteEntity.as"
#include "P2CE_Archipelago/Function/Entity/DisableEntityPhysics.as"
#include "P2CE_Archipelago/Function/Entity/DisableEntityPickup.as"
#include "P2CE_Archipelago/Function/Entity/MakeFaithPlateFaulty.as"
#include "P2CE_Archipelago/Function/Entity/PreventPickupForModel.as"
#include "P2CE_Archipelago/Function/Entity/RemoveGel.as"

// --- HOLOGRAM ---
#include "P2CE_Archipelago/Function/Hologram/AttachHologramToEntity.as"
#include "P2CE_Archipelago/Function/Hologram/CreateMapSpecificHolos.as"
#include "P2CE_Archipelago/Function/Hologram/Overrides/GetHologramVisualOverrides.as"
#include "P2CE_Archipelago/Function/Hologram/Overrides/OverrideGel.as"
#include "P2CE_Archipelago/Function/Hologram/Overrides/OverrideCube.as"

// --- MISC ---
#include "P2CE_Archipelago/Function/Misc/AddEntityOutputScriptAtPos.as"
#include "P2CE_Archipelago/Function/Misc/AttachDeathTrigger.as"
#include "P2CE_Archipelago/Function/Misc/BlockWheatleyFight.as"
#include "P2CE_Archipelago/Function/Misc/DoMapSpecificSetup.as"
#include "P2CE_Archipelago/Function/Misc/HandleMonitorWarp.as"
#include "P2CE_Archipelago/Function/Misc/InitMonitorData.as"
#include "P2CE_Archipelago/Function/Misc/SafeRemoveEntity.as"
#include "P2CE_Archipelago/Function/Misc/SpawnPaintBomb.as"
#include "P2CE_Archipelago/Function/Misc/WaitExecute.as"
#include "P2CE_Archipelago/Function/Misc/WarpToMenu.as"

// --- PORTAL GUN ---
#include "P2CE_Archipelago/Function/Portal_Gun/DisablePortalGun.as"
#include "P2CE_Archipelago/Function/Portal_Gun/IncineratorDisablePortalGun.as"

// --- POTATOS ---
#include "P2CE_Archipelago/Function/PotatOS/RemovePotatOS.as"
#include "P2CE_Archipelago/Function/PotatOS/RemovePotatosFromGun.as"

// --- TRAPS (CORRIGÉ) ---
#include "P2CE_Archipelago/Function/Traps/ButterFingerTrap.as"
#include "P2CE_Archipelago/Function/Traps/CubeConfettiTrap.as"
#include "P2CE_Archipelago/Function/Traps/DialogTrap.as"
#include "P2CE_Archipelago/Function/Traps/FizzlePortalTrap.as"
#include "P2CE_Archipelago/Function/Traps/MotionBlurTrap.as"
#include "P2CE_Archipelago/Function/Traps/SlipperyFloorTrap.as"

// --- UTILS ---
#include "P2CE_Archipelago/Utils/FindEntities.as"
#include "P2CE_Archipelago/Utils/GetPlayer.as"
#include "P2CE_Archipelago/Utils/ItemInList.as"
#include "P2CE_Archipelago/Utils/MathUtils.as"

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
