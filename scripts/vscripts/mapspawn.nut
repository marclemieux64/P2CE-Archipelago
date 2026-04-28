// =============================================================
// ARCHIPELAGO MAPSPAWN (VScript entry point)
// =============================================================
// This file is auto-executed by the game on every map load
// because it is named "mapspawn.nut".
// =============================================================

// Load the notification queue system
IncludeScript("archipelago_notify");

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
::ppmod <- {
    // We use a large number of arguments to "catch" whatever the client sends
    function addscript(ent, output, scr = "", delay = 0, max = -1, a=0, b=0, c=0) {
        if (typeof ent == "array") {
            // Handle coordinate-based triggers: [Vector, radius, class]
            local cmd = "ap_add_script_at_pos " + ent[0].x + " " + ent[0].y + " " + ent[0].z + " " + ent[2] + " \"" + output + "\" \"" + scr + "\" " + delay + " " + max;
            SendToConsole(cmd);
        } else {
            local entName = (typeof ent == "instance") ? ent.GetName() : ent;
            SendToConsole("ap_add_script \"" + entName + "\" \"" + output + "\" \"" + scr + "\" " + delay + " " + max);
        }
    }
    
    function disable_pickup(target) { SendToConsole("DisableEntityPickup \"" + target + "\""); }
    function force_disable_pickup(target) { SendToConsole("DisableEntityPickup \"" + target + "\""); }
    function keyval(target, key, val) { EntFire(target, "AddOutput", key + " " + val); }
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
    SendToConsole(cmd);
}

// =============================================================
// ARCHIPELAGO DELETE ENTITY BRIDGE
// =============================================================
::scripted_fling_levels <- ["sp_a3_03", "sp_a3_bomb_flings", "sp_a3_transition01", "sp_a3_speed_flings", "sp_a3_end", "sp_a4_jump_polarity"];

function DeleteEntity(entity_name, create_holo = true, scale = 0.7) { SendToConsole("DeleteEntity \"" + entity_name + "\" " + (create_holo ? "1" : "0") + " " + scale);}
function ty(entity_name, create_holo = true, scale = 0.7) {DeleteEntity(entity_name, create_holo, scale);}

// =============================================================
// ARCHIPELAGO PICKUP DISABLE BRIDGE
// =============================================================

function DisableEntityPickup(entity_name) {SendToConsole("DisableEntityPickup \"" + entity_name + "\"");}

function DeleteCoreOnOutput(core_name, target_name, output) {SendToConsole("DeleteCoreOnOutput \"" + core_name + "\" \"" + target_name + "\" \"" + output + "\"");}

function DisablePortalGun(blue, orange) {   
    local cmd = "DisablePortalGun " + (blue ? "1" : "0") + " " + (orange ? "1" : "0");
    SendToConsole(cmd);
}

function InciniratorDisablePortalGun() { SendToConsole("InciniratorDisablePortalGun");}


function DisableEntityPhysics(entity_name) {SendToConsole("DisableEntityPhysics \"" + entity_name + "\"");}

function DisableEntity(entity_name) {SendToConsole("DisableEntity \"" + entity_name + "\"");}


// =============================================================
// ARCHIPELAGO MAP COMPLETION INTERCEPT
// =============================================================

/**
 * FinishedMap - Override for standard P2 transition function.
 * Called automatically by non-elevator maps via 'transition.nut'.
 */
function FinishedMap() {  SendToConsole("FinishMap");}

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


function AddButtonFrame(search_term) {SendToConsole("AddButtonFrame \"" + search_term + "\"");}
function AddFloorButtonFrame(search_term) {SendToConsole("AddFloorButtonFrame \"" + search_term + "\"");}

// =============================================================
// ARCHIPELAGO HOLOGRAM ATTACHMENT BRIDGE
// =============================================================

/**
 * AttachHologramToEntity - Bridge to AngelScript AttachHologramToEntity command.
 */
function AttachHologramToEntity(entity_name, attachment, scale, offset, skin = 0) {
    local cmd = "AttachHologramToEntity \"" + entity_name + "\" \"" + attachment + "\" " + scale + " " + offset + " " + skin;
    SendToConsole(cmd);
}

// =============================================================
// ARCHIPELAGO TRAP BRIDGES
// =============================================================

function MotionBlurTrap() { SendToConsole("MotionBlurTrap"); }
function FizzlePortalTrap() { SendToConsole("FizzlePortalTrap"); }
function ButterFingersTrap() { SendToConsole("ButterFingersTrap"); }
function CubeConfettiTrap() { SendToConsole("CubeConfettiTrap"); }
function SlipperyFloorTrap() { SendToConsole("SlipperyFloorTrap"); }
function DialogTrap() { SendToConsole("DialogTrap"); }


function RemovePotatosFromGun() { SendToConsole("RemovePotatosFromGun");}
function RestorePotatosToGun() { SendToConsole("RestorePotatosToGun");}
function BlockWheatleyFight() { SendToConsole("BlockWheatleyFight");}
function RemovePotatOS() { SendToConsole("RemovePotatOS");}


function MutePotatOSSubtitles(mute) {
    if (mute) {
        SendToPanorama("AP_MutePotatos", "1");
    } else {
        SendToPanorama("AP_MutePotatos", "0");
    }
}




