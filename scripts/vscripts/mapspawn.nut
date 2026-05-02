// =============================================================
// ARCHIPELAGO MAPSPAWN (VScript entry point)
// =============================================================
// This file is auto-executed by the game on every map load
// because it is named "mapspawn.nut".
// =============================================================

// Load the notification queue system
IncludeScript("archipelago_notify");

::ap_queued_commands <- [];
::ap_player_connected <- false;

function SafeSendToConsole(cmd) {
    if (::ap_player_connected) {
        // Player is here, fire immediately
        EntFire("InitCmd", "Command", cmd);
    } else {
        // No player yet, buffer the command
        ::ap_queued_commands.push(cmd);
    }
}

if ("Entities" in getroottable()) {
    // Server logic: Polling for player connection before flushing commands
    function ArchipelagoCheckConnection() {
        if (::ap_player_connected) return;
        
        if (Entities.FindByClassname(null, "player") != null) {
            ::ap_player_connected = true;
            printl("[AP-VScript] Player detected! Flushing " + ::ap_queued_commands.len() + " buffered commands.");
            foreach (cmd in ::ap_queued_commands) {
                EntFire("InitCmd", "Command", cmd);
            }
            ::ap_queued_commands.clear();
        }
    }

    // Start a frequent check for the player
    function ArchipelagoStartConnectionCheck() {
        // Create a dedicated timer entity if it doesn't exist
        local timer = Entities.FindByName(null, "ArchipelagoConnectionTimer");
        if (!timer) {
            timer = Entities.CreateByClassname("info_target");
            timer.__KeyValueFromString("targetname", "ArchipelagoConnectionTimer");
        }
        
        ArchipelagoCheckConnection();
        if (!::ap_player_connected) {
            EntFire("ArchipelagoConnectionTimer", "RunScriptCode", "ArchipelagoStartConnectionCheck()", 0.1);
        } else {
            // Player found, cleanup the timer
            timer.Destroy();
        }
    }

    // Initial kick-off
    ArchipelagoStartConnectionCheck();
}

// =============================================================
// PATH-SAFE PROXY SYSTEM
// =============================================================
// Catches unquoted paths (models/props/...) from Python calls
// and converts them to strings automatically.
// =============================================================
class APPathProxy {
    path = "";
    constructor(p) { path = p; }
    function _div(v) { return APPathProxy(path + "/" + v); }
    function _get(v) { return APPathProxy(path + "." + v); }
    function _tostring() { return path; }
}

// Global aliases to catch the start of paths
::models <- APPathProxy("models");
::props <- APPathProxy("props");
::archipelago <- APPathProxy("archipelago");
::reflection_cube <- APPathProxy("reflection_cube");
::weighted_cube <- APPathProxy("weighted_cube");
::metal_box <- APPathProxy("metal_box");
::underground_weighted_cube <- APPathProxy("underground_weighted_cube");
::ap_buttonframe <- APPathProxy("ap_buttonframe");
::ap_floorbuttonframe <- APPathProxy("ap_floorbuttonframe");
::ap_proptractorbeamframe <- APPathProxy("ap_proptractorbeamframe");
::archipelago_hologram <- APPathProxy("archipelago_hologram");
::switch001 <- APPathProxy("switch001");
::mdl <- APPathProxy("mdl");

// Entity Class Aliases (These are fine as strings since they are usually leaf nodes)
::env_portal_laser <- "env_portal_laser";
::prop_under_floor_button <- "prop_under_floor_button";
::prop_monster_box <- "prop_monster_box";
::prop_wall_projector <- "prop_wall_projector";
::prop_under_button <- "prop_under_button";
::prop_laser_relay <- "prop_laser_relay";
::info_paint_sprayer <- "info_paint_sprayer";
::prop_tractor_beam <- "prop_tractor_beam";
::trigger_catapult <- "trigger_catapult";
::prop_laser_catcher <- "prop_laser_catcher";
::npc_portal_turret_floor <- "npc_portal_turret_floor";
::prop_floor_button <- "prop_floor_button";
::prop_button <- "prop_button";

// =============================================================
// SYMBOL ALIASES (For unquoted Python calls)
// =============================================================
::npc_portal_turret_floor <- "npc_portal_turret_floor";
::prop_weighted_cube     <- "prop_weighted_cube";
::prop_monster_box      <- "prop_monster_box";
::prop_test_chamber_door <- "prop_test_chamber_door";

// =============================================================
// PPMOD NATIVE BRIDGE
// =============================================================
// This minimal bridge allows legacy calls from the Python client
// to be handled by the native AngelScript system.
// =============================================================
printl("[AP-VScript] " + Time() + " ARCHIPELAGO MAPSPAWN (VScript entry point)");
::ppmod <- {
    // We use a large number of arguments to "catch" whatever the client sends
    function addscript(ent, output, scr = "", delay = 0, max = -1, a=0, b=0, c=0) {
        if (typeof ent == "array") {
            // Handle coordinate-based triggers: [Vector, radius, class]
            local cmd = "AddScriptAtPos " + ent[0].x + " " + ent[0].y + " " + ent[0].z + " " + ent[2] + " \"" + output + "\" \"" + scr + "\" " + delay + " " + max;
            SafeSendToConsole(cmd);
        } else {
            local entName = (typeof ent == "instance") ? ent.GetName() : ent;
            SafeSendToConsole("AddScript \"" + entName + "\" \"" + output + "\" \"" + scr + "\" " + delay + " " + max);
        }
    }
    
    function disable_pickup(target) { SafeSendToConsole("DisableEntityPickup \"" + target + "\""); }
    function force_disable_pickup(target) { SafeSendToConsole("DisableEntityPickup \"" + target + "\""); }
    function keyval(target, key, val) { EntFire(target, "AddOutput", key + " " + val); }

    function get(arg1, arg2 = null, arg3 = null, arg4 = null) {
        return {
            _name = arg1
            function Destroy() { SafeSendToConsole("DeleteEntity \"" + _name + "\" 1"); }
            function Kill() { SafeSendToConsole("DeleteEntity \"" + _name + "\" 1"); }
            function Disable() { SafeSendToConsole("DisableEntity \"" + _name + "\""); }
        };
    }
}


// =============================================================
// CreateAPButton — bridge from Python to AngelScript command.
//
// Python calls:
//   script CreateAPButton("Name", Vector(x,y,z), Vector(r,p,y), scale)
// This reconstructs the exact string that sv_init.as expects.
// =============================================================
function CreateAPButton(name, pos, rot, scale) {
    local cmd = "CreateAPButton \"" + name + "\" " +
                "Vector(" + pos.x + " " + pos.y + " " + pos.z + ") " +
                "Vector(" + rot.x + " " + rot.y + " " + rot.z + ") " +
                scale;
    SafeSendToConsole(cmd);
    return cmd;
}

// =============================================================
// ARCHIPELAGO DELETE ENTITY BRIDGE
// =============================================================
::scripted_fling_levels <- ["sp_a3_03", "sp_a3_bomb_flings", "sp_a3_transition01", "sp_a3_speed_flings", "sp_a3_end", "sp_a4_jump_polarity"];

function DeleteEntity(entity_name, create_holo = true, scale = 0.7) { 
    local cmd = "DeleteEntity \"" + entity_name + "\" " + (create_holo ? "1" : "0") + " " + scale;
    SafeSendToConsole(cmd);
    return cmd; // Return string for nesting
}
function ty(entity_name, create_holo = true, scale = 0.7) {DeleteEntity(entity_name, create_holo, scale);}

// =============================================================
// ARCHIPELAGO PICKUP DISABLE BRIDGE
// =============================================================

function DisableEntityPickup(entity_name) {
    local cmd = "DisableEntityPickup \"" + entity_name + "\"";
    SafeSendToConsole(cmd);
    return cmd;
}

function DeleteCoreOnOutput(core_name, target_name, output) {
    local cmd = "DeleteCoreOnOutput \"" + core_name + "\" \"" + target_name + "\" \"" + output + "\"";
    SafeSendToConsole(cmd);
    return cmd;
}

function DisablePortalGun(blue, orange) {   
    local cmd = "DisablePortalGun " + (blue ? "1" : "0") + " " + (orange ? "1" : "0");
    SafeSendToConsole(cmd);
    return cmd;
}

function InciniratorDisablePortalGun() { 
    local cmd = "InciniratorDisablePortalGun";
    SafeSendToConsole(cmd);
    return cmd;
}


function DisableEntityPhysics(entity_name) {
    local cmd = "DisableEntityPhysics \"" + entity_name + "\"";
    SafeSendToConsole(cmd);
    return cmd;
}

function DisableEntity(entity_name) {
    local cmd = "DisableEntity \"" + entity_name + "\"";
    SafeSendToConsole(cmd);
    return cmd;
}


// =============================================================
// ARCHIPELAGO MAP COMPLETION INTERCEPT
// =============================================================

/**
 * FinishedMap - Override for standard P2 transition function.
 * Called automatically by non-elevator maps via 'transition.nut'.
 */
function FinishedMap() {  SafeSendToConsole("FinishedMap");}

/**
 * ChangeLevel - Override for standard P2 transition function.
 * By absorbing this call, we permanently block the map from loading the next BSP,
 * freezing the transition perfectly so we can handle returning to the menu independently.
 */
function ChangeLevel(next_map="") {
    // We intentionally do nothing here. The map is now suspended indefinitely.
}

// =============================================================
// ARCHIPELAGO BUTTON FRAME BRIDGES
// =============================================================


function AddButtonFrame(search_term) {
    local cmd = "AddButtonFrame \"" + search_term + "\"";
    SafeSendToConsole(cmd);
    return cmd;
}
function AddFloorButtonFrame(search_term) {
    local cmd = "AddFloorButtonFrame \"" + search_term + "\"";
    SafeSendToConsole(cmd);
    return cmd;
}

// =============================================================
// ARCHIPELAGO HOLOGRAM ATTACHMENT BRIDGE
// =============================================================

/**
 * AttachHologramToEntity - Bridge to AngelScript AttachHologramToEntity command.
 */
function AttachHologramToEntity(entity_name, attachment, scale, offset, skin = 0) {
    local cmd = "AttachHologramToEntity \"" + entity_name + "\" \"" + attachment + "\" " + scale + " " + offset + " " + skin;
    SafeSendToConsole(cmd);
}

// =============================================================
// ARCHIPELAGO TRAP BRIDGES
// =============================================================

function MotionBlurTrap() { SafeSendToConsole("MotionBlurTrap"); return "MotionBlurTrap"; }
function FizzlePortalTrap() { SafeSendToConsole("FizzlePortalTrap"); return "FizzlePortalTrap"; }
function ButterFingersTrap() { SafeSendToConsole("ButterFingersTrap"); return "ButterFingersTrap"; }
function CubeConfettiTrap() { SafeSendToConsole("CubeConfettiTrap"); return "CubeConfettiTrap"; }
function SlipperyFloorTrap() { SafeSendToConsole("SlipperyFloorTrap"); return "SlipperyFloorTrap"; }
function RemovePotatosFromGun() { SafeSendToConsole("RemovePotatosFromGun");}
function BlockWheatleyFight() { SafeSendToConsole("BlockWheatleyFight");}
function RemovePotatOS() { SafeSendToConsole("RemovePotatOS");}


function MutePotatOSSubtitles(mute) {
    if (mute) {
        SendToPanorama("ArchipelagoMutePotatos", "1");
    } else {
        SendToPanorama("ArchipelagoMutePotatos", "0");
    }
}




