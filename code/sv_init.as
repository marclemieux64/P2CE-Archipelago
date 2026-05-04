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
#include "Archipelago/Function/Check/WarpToMenu.as"

// 4. Restore
#include "Archipelago/Restore/RemoveAllButtonFrames.as"
#include "Archipelago/Restore/RemoveAllFloorButtonFrames.as"
#include "Archipelago/Restore/RestoreCatapults.as"

// 5. Functions
#include "Archipelago/Function/AddEntityOutputScript.as"
#include "Archipelago/Function/AddEntityOutputScriptAtPos.as"
#include "Archipelago/Function/AttachDeathTrigger.as"
#include "Archipelago/Function/BlockWheatleyFight.as"
#include "Archipelago/Function/DeleteCoreOnOutput.as"
#include "Archipelago/Function/DeleteEntity.as"
#include "Archipelago/Function/DisableEntityPhysics.as"
#include "Archipelago/Function/DisableEntityPickup.as"
#include "Archipelago/Function/DoMapSpecificSetup.as"

// 6. Items
#include "Archipelago/Items/AerialFaithPlate.as"

// 7. Function Categories
#include "Archipelago/Function/Button/AddButtonFrame.as"
#include "Archipelago/Function/Button/AddCustomFrame.as"
#include "Archipelago/Function/Button/AddFloorButtonFrame.as"
#include "Archipelago/Function/Button/CreateAPButton.as"

#include "Archipelago/Function/Check/AddVitrifiedDoorCheck.as"
#include "Archipelago/Function/Check/AddWheatleyMonitorBreakCheck.as"
#include "Archipelago/Function/Check/CreateCompleteLevelAlertHook.as"
#include "Archipelago/Function/Check/HandleMapCompletion.as"

#include "Archipelago/Function/Gel/CreateClearGel.as"
#include "Archipelago/Function/Gel/RemoveGel.as"

#include "Archipelago/Function/Hologram/AttachHologramToEntity.as"
#include "Archipelago/Function/Hologram/CreateAPHologram.as"
#include "Archipelago/Function/Hologram/CreateMapSpecificHolos.as"

#include "Archipelago/Function/PortalGun/DisablePortalGun.as"
#include "Archipelago/Function/PortalGun/IncineratorDisablePortalGun.as"

#include "Archipelago/Function/PotatOS/RemovePotatOS.as"
#include "Archipelago/Function/PotatOS/RemovePotatosFromGun.as"
#include "Archipelago/Restore/RestorePotatosToGun.as"

#include "Archipelago/Function/Trap/ButterFingerTrap.as"
#include "Archipelago/Function/Trap/CubeConfettiTrap.as"
#include "Archipelago/Function/Trap/DialogTrap.as"
#include "Archipelago/Function/Trap/FizzlePortalTrap.as"
#include "Archipelago/Function/Trap/MotionBlurTrap.as"
#include "Archipelago/Function/Trap/SlipperyFloorTrap.as"

// 8. Interfaces & Startup
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
