// =============================================================
// ARCHIPELAGO SV INIT (ENTRY POINT)
// =============================================================

// 1. Core & Debug

#include "Archipelago/Core/Globals.as"
#include "Archipelago/Core/ResetPersistantSystems.as"
#include "Archipelago/Core/StartGameStatusTimer.as"
#include "Archipelago/Core/UpdatesInternalMapName.as"
#include "Archipelago/Core/RunGameStatusTickCommand.as"
#include "Archipelago/Debug/ArchipelagoLog.as"

// 2. Tools
#include "Archipelago/Tools/ParseMath.as"
#include "Archipelago/Tools/ExtractFloats.as"
#include "Archipelago/Tools/SplitString.as"

// 3. Helpers & Shared
#include "Archipelago/Helpers/CallVScript.as"
#include "Archipelago/Helpers/DisableEntity.as"
#include "Archipelago/Helpers/DisarmLegacyLogic.as"
#include "Archipelago/Helpers/FindEntities.as"
#include "Archipelago/Helpers/GetHologramVisualOverrides.as"
#include "Archipelago/Helpers/HandleMonitorWarp.as"
#include "Archipelago/Helpers/PrintAllEntities.as"
#include "Archipelago/Helpers/RefreshAllAPHolograms.as"
#include "Archipelago/Helpers/RunDeathLinkTick.as"
#include "Archipelago/function/Check/WarpToMenu.as"

// 4. Restore
#include "Archipelago/Restore/RemoveAllButtonFrames.as"
#include "Archipelago/Restore/RemoveAllFloorButtonFrames.as"
#include "Archipelago/Restore/RestoreCatapults.as"

// 5. Functions
#include "Archipelago/function/AddEntityOutputScript.as"
#include "Archipelago/function/AddEntityOutputScriptAtPos.as"
#include "Archipelago/function/AttachDeathTrigger.as"
#include "Archipelago/function/BlockWheatleyFight.as"
#include "Archipelago/function/DeleteCoreOnOutput.as"
#include "Archipelago/function/DeleteEntity.as"
#include "Archipelago/function/DisableEntityPhysics.as"
#include "Archipelago/function/DisableEntityPickup.as"
#include "Archipelago/function/DoMapSpecificSetup.as"

// 6. Function Categories
#include "Archipelago/function/Button/AddButtonFrame.as"
#include "Archipelago/function/Button/AddCustomFrame.as"
#include "Archipelago/function/Button/AddFloorButtonFrame.as"
#include "Archipelago/function/Button/CreateAPButton.as"

#include "Archipelago/function/Check/AddVitrifiedDoorCheck.as"
#include "Archipelago/function/Check/AddWheatleyMonitorBreakCheck.as"
#include "Archipelago/function/Check/CreateCompleteLevelAlertHook.as"
#include "Archipelago/function/Check/HandleMapCompletion.as"

#include "Archipelago/function/Gel/CreateClearGel.as"
#include "Archipelago/function/Gel/RemoveGel.as"

#include "Archipelago/function/Hologram/AttachHologramToEntity.as"
#include "Archipelago/function/Hologram/CreateAPHologram.as"
#include "Archipelago/function/Hologram/CreateMapSpecificHolos.as"

#include "Archipelago/function/PortalGun/DisablePortalGun.as"
#include "Archipelago/function/PortalGun/IncineratorDisablePortalGun.as"

#include "Archipelago/function/PotatOS/RemovePotatOS.as"
#include "Archipelago/function/PotatOS/RemovePotatosFromGun.as"
#include "Archipelago/Restore/RestorePotatosToGun.as"

#include "Archipelago/function/Trap/ButterFingerTrap.as"
#include "Archipelago/function/Trap/CubeConfettiTrap.as"
#include "Archipelago/function/Trap/DialogTrap.as"
#include "Archipelago/function/Trap/FizzlePortalTrap.as"
#include "Archipelago/function/Trap/MotionBlurTrap.as"
#include "Archipelago/function/Trap/SlipperyFloorTrap.as"

// 7. Interfaces & Startup
#include "Archipelago/Core/RunDelayedInitialization.as"
#include "Archipelago/Core/ServerCommand.as"


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
        
        // --- NUCLEAR CLEANUP ---
        // Force-delete legacy VScript functions that might be overriding us from VPKs
        Variant vNuke;
        vNuke.SetString("::CreateAPHologram <- null; ::AttachHologramToEntity <- null;");
        cmd.FireInput("Command", vNuke, 0.0f, null, null, 0);

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
