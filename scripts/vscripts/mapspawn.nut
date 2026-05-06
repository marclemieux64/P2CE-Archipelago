// =============================================================
// ARCHIPELAGO MAPSPAWN (VScript entry point)
// =============================================================

// Load the notification queue system
IncludeScript("archipelago_notify");

if (!("ap_queued_commands" in getroottable())) ::ap_queued_commands <- [];
if (!("ap_player_connected" in getroottable())) ::ap_player_connected <- false;
if (!("ArchipelagoDebug" in getroottable())) ::ArchipelagoDebug <- false;
if (!("ap_potatos_muted" in getroottable())) ::ap_potatos_muted <- false;

::SafeSendToConsole <- function(cmd) {
    if (::ap_player_connected) {
        EntFire("InitCmd", "Command", cmd);
    } else {
        ::ap_queued_commands.push(cmd);
    }
}

if ("Entities" in getroottable()) {
    ::ArchipelagoCheckConnection <- function() {
        if (::ap_player_connected) return;
        
        if (Entities.FindByClassname(null, "player") != null) {
            ::ap_player_connected = true;
            
            // Sync subtitle mute state to Panorama now that HUD is ready
            if (::ap_potatos_muted) {
                SendToPanorama("ArchipelagoMutePotatos", "1");
            }

            foreach (cmd in ::ap_queued_commands) {
                EntFire("InitCmd", "Command", cmd);
            }
            ::ap_queued_commands.clear();
        }
    }

    ::ArchipelagoStartConnectionCheck <- function() {
        local timer = Entities.FindByName(null, "ArchipelagoConnectionTimer");
        if (!timer) {
            timer = Entities.CreateByClassname("logic_script");
            timer.__KeyValueFromString("targetname", "ArchipelagoConnectionTimer");
        }
        
        ::ArchipelagoCheckConnection();
        if (!::ap_player_connected) {
            // Self-recurse via the timer entity
            EntFire("ArchipelagoConnectionTimer", "RunScriptCode", "::ArchipelagoStartConnectionCheck()", 0.1);
        } else {
            // Player found, cleanup the timer
            timer.Destroy();
        }
    }

    // Initial kick-off
    ::ArchipelagoStartConnectionCheck();
}

// =============================================================
// PATH-SAFE PROXY SYSTEM
// =============================================================
class APPathProxy {
    path = "";
    constructor(p) { path = p; }
    function _div(v) { return APPathProxy(path + "/" + v); }
    function _get(v) { return APPathProxy(path + "." + v); }
    function _tostring() { return path; }
}

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

::ppmod <- {
    function addscript(ent, output, scr = "", delay = 0, max = -1, a=0, b=0, c=0) {
        if (typeof ent == "array") {
            local cmd = "AddScriptAtPos " + ent[0].x + " " + ent[0].y + " " + ent[0].z + " " + ent[2] + " \"" + output + "\" \"" + scr + "\" " + delay + " " + max;
            ::SafeSendToConsole(cmd);
        } else {
            local entName = (typeof ent == "instance") ? ent.GetName() : ent;
            ::SafeSendToConsole("AddScript \"" + entName + "\" \"" + output + "\" \"" + scr + "\" " + delay + " " + max);
        }
    }
    
    function disable_pickup(target) { ::SafeSendToConsole("DisableEntityPickup \"" + target + "\""); }
    function force_disable_pickup(target) { ::SafeSendToConsole("DisableEntityPickup \"" + target + "\""); }
    function keyval(target, key, val, a=0, b=0, c=0) { 
        EntFire(target, "AddOutput", key + " " + val); 
    }

    function get(arg1, arg2 = null, arg3 = null, arg4 = null) {
        return {
            _name = arg1,
            function Destroy() { ::SafeSendToConsole("DeleteEntity \"" + _name + "\" 1"); }
            function Kill() { ::SafeSendToConsole("DeleteEntity \"" + _name + "\" 1"); }
            function Disable() { ::SafeSendToConsole("DisableEntity \"" + _name + "\""); }
        };
    }
}

::CreateAPButton <- function(name, pos, rot, scale, is_checked = 0) {
    local cmd = "CreateAPButton \"" + name + "\" " +
                "Vector(" + pos.x + " " + pos.y + " " + pos.z + ") " +
                "Vector(" + rot.x + " " + rot.y + " " + rot.z + ") " +
                scale;
    ::SafeSendToConsole(cmd);
    if (is_checked) ::SafeSendToConsole("AddCheckedDen " + name);
    return cmd;
}

::DeleteEntity <- function(entity_name = "", create_holo = true, scale = 0.7) { 
    local cmd = "DeleteEntity \"" + entity_name + "\" " + (create_holo ? "1" : "0") + " " + scale;
    ::SafeSendToConsole(cmd);
    return cmd;
}
::ty <- function(entity_name, create_holo = true, scale = 0.7) {::DeleteEntity(entity_name, create_holo, scale);}

::DisableEntityPickup <- function(entity_name = "") {
    local cmd = "DisableEntityPickup \"" + entity_name + "\"";
    ::SafeSendToConsole(cmd);
    return cmd;
}

::DeleteCoreOnOutput <- function(core_name = "", target_name = "", output = "") {
    local cmd = "DeleteCoreOnOutput \"" + core_name + "\" \"" + target_name + "\" \"" + output + "\"";
    ::SafeSendToConsole(cmd);
    return cmd;
}

::DisablePortalGun <- function(blue = true, orange = true) {   
    local cmd = "DisablePortalGun " + (blue ? "1" : "0") + " " + (orange ? "1" : "0");
    ::SafeSendToConsole(cmd);
    return cmd;
}

::InciniratorDisablePortalGun <- function() { 
    local cmd = "InciniratorDisablePortalGun";
    ::SafeSendToConsole(cmd);
    return cmd;
}

::DisableEntityPhysics <- function(entity_name = "") {
    local cmd = "DisableEntityPhysics \"" + entity_name + "\"";
    ::SafeSendToConsole(cmd);
    return cmd;
}

::DisableEntity <- function(entity_name = "") {
    local cmd = "DisableEntity \"" + entity_name + "\"";
    ::SafeSendToConsole(cmd);
    return cmd;
}

::RemoveGel <- function(x, y, z, object_type = null, object_name = null, create_holo = 1) {
    local cmd = "RemoveGel " + x + " " + y + " " + z;
    if (object_type != null) cmd += " \"" + object_type + "\"";
    if (object_name != null) cmd += " \"" + object_name + "\"";
    cmd += " " + create_holo;
    ::SafeSendToConsole(cmd);
}

::CreateClearGel <- function(pos, offset = -100) {
    local cmd = "CreateClearGel " + pos.x + " " + pos.y + " " + pos.z + " " + offset;
    ::SafeSendToConsole(cmd);
}

::FinishedMap <- function() { ::SafeSendToConsole("FinishedMap");}
::ChangeLevel <- function(next_map="") {}

::AddButtonFrame <- function(search_term = "") {
    local cmd = "AddButtonFrame \"" + search_term + "\"";
    ::SafeSendToConsole(cmd);
    return cmd;
}
::AddFloorButtonFrame <- function(search_term = "") {
    local cmd = "AddFloorButtonFrame \"" + search_term + "\"";
    ::SafeSendToConsole(cmd);
    return cmd;
}

::AttachHologramToEntity <- function(entity_name = "", attachment = "", scale = 1.0, offset = 0.0, skin = 0) {
    local cmd = "AttachHologramToEntity \"" + entity_name + "\" \"" + attachment + "\" " + scale + " " + offset + " " + skin;
    ::SafeSendToConsole(cmd);
}

::AddWheatleyMonitorBreakCheck <- function(entity_name = "", check_id = 0) {
    local cmd = "AddWheatleyMonitorBreakCheck \"" + entity_name + "\" " + check_id;
    ::SafeSendToConsole(cmd);
}

::MotionBlurTrap <- function() { ::SafeSendToConsole("MotionBlurTrap"); return "MotionBlurTrap"; }
::FizzlePortalTrap <- function() { ::SafeSendToConsole("FizzlePortalTrap"); return "FizzlePortalTrap"; }
::ButterFingersTrap <- function() { ::SafeSendToConsole("ButterFingersTrap"); return "ButterFingersTrap"; }
::CubeConfettiTrap <- function() { ::SafeSendToConsole("CubeConfettiTrap"); return "CubeConfettiTrap"; }
::SlipperyFloorTrap <- function() { ::SafeSendToConsole("SlipperyFloorTrap"); return "SlipperyFloorTrap"; }
::RemovePotatosFromGun <- function() { ::SafeSendToConsole("RemovePotatosFromGun");}
::BlockWheatleyFight <- function() { ::SafeSendToConsole("BlockWheatleyFight");}
::RemovePotatOS <- function() { ::SafeSendToConsole("RemovePotatOS");}

::MutePotatOSSubtitles <- function(mute) {
    ::ap_potatos_muted = mute;
    ::SafeSendToConsole("ap_potatos_muted " + (mute ? "1" : "0"));
    if (::ap_player_connected) {
        SendToPanorama("ArchipelagoMutePotatos", mute ? "1" : "0");
    }
}

