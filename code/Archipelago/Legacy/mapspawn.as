// =============================================================
// ARCHIPELAGO LEGACY MAPSPAWN (Converted from Squirrel)
// =============================================================
#include "legacy_globals.as"

// Helper: Check if item is in array
bool ItemInList(string item, array<string> list) {
    for (uint i = 0; i < list.length(); i++) {
        if (list[i] == item) return true;
    }
    return false;
}

float DegToRad(float degrees) {
    return degrees * (3.14159f / 180.0f);
}

Vector AnglesToDirection(QAngle angles) {
    // Correct Vector from Angles conversion for Source
    Vector forward;
    AngleVectors(angles, forward);
    return forward;
}

Vector AnglesToUp(QAngle angles) {
    // Rotating angles 90 degrees up to find the relative 'up' vector
    QAngle upAngles = angles;
    upAngles.x -= 90;
    Vector up;
    AngleVectors(upAngles, up);
    return up;
}

array<string> scripted_fling_levels = {"sp_a3_03", "sp_a3_bomb_flings", "sp_a3_transition01", "sp_a3_speed_flings", "sp_a3_end", "sp_a4_jump_polarity"};

/**
 * DeleteEntity - Collects targets first to safely iterate and remove.
 */
void DeleteEntity(string entity_name, bool create_holo = true) {
    if (entity_name == "trigger_catapult" && ItemInList(current_map, scripted_fling_levels)) {
        ArchipelagoLog("not removing trigger_catapult");
        return;
    }

    array<CBaseEntity@> targets = FindEntities(entity_name);

    for (uint i = 0; i < targets.length(); i++) {
        CBaseEntity@ ent = targets[i];
        if (ent is null) continue;

        // Faith plate protection logic
        if (entity_name == "trigger_catapult") {
            CBaseEntity@ plate1 = EntityList().FindByClassnameNearest("prop_dynamic", ent.GetAbsOrigin(), 30.0f);
            if (plate1 is null || (plate1.GetModelName().locate("models/props/faith_plate") == uint(-1))) continue;
        }

        if (create_holo) {
            QAngle angles = ent.GetAbsAngles();
            if (entity_name == "prop_tractor_beam") angles = QAngle(0, 0, 0);
            CreateAPHologram(ent.GetAbsOrigin() + (AnglesToDirection(angles) * -50.0f), angles, 0.7f, null, "", 4, "");
        }
        ent.Remove();
    }
}

bool portalgun_2_disabled = false;

void DisablePortalGun(bool blue, bool orange) {
    if (current_map == "sp_a3_01") {
        EntFire("weapon_portalgun", "AddOutput", "CanFirePortal2 0", 13.0f);
    }

    if (current_map == "sp_a2_intro") {
        portalgun_2_disabled = true;
    }

    if (blue) EntFire("weapon_portalgun", "AddOutput", "CanFirePortal1 0");
    if (orange) EntFire("weapon_portalgun", "AddOutput", "CanFirePortal2 0");
}

void DisableEntityPickup(string entity_name) {
    array<CBaseEntity@> targets = FindEntities(entity_name);
    for (uint i = 0; i < targets.length(); i++) {
        targets[i].KeyValue("PickupEnabled", "0");
    }
}

void DisableEntityPhysics(string entity_name) {
    array<CBaseEntity@> targets = FindEntities(entity_name);
    for (uint i = 0; i < targets.length(); i++) {
        targets[i].KeyValue("movetype", "4");
    }
}

void AddFloorButtonFrame(string entity_name) {
    array<CBaseEntity@> targets = FindEntities(entity_name);
    for (uint i = 0; i < targets.length(); i++) {
        CBaseEntity@ ent = targets[i];
        Vector position = ent.GetAbsOrigin();
        QAngle angles = ent.GetAbsAngles();
        CBaseEntity@ box = util::CreateEntityByName("prop_dynamic");
        if (box !is null) {
            box.KeyValue("model", "models/props/archipelago/ap_floorbuttonframe.mdl");
            box.KeyValue("solid", "6");
            box.SetAbsOrigin(position);
            box.SetAbsAngles(angles);
            box.Spawn();
        }
        // Create hologram with unique name per entity index and check for duplicates
        string holoName = entity_name + "_" + ent.GetEntityIndex() + "_holo";
        if (EntityList().FindByName(null, holoName) is null) {
            CreateAPHologram(position + Vector(0, 0, 40.0f), angles, 1.0f, null, "", 4, holoName);
        }
    }
}

void AddButtonFrame(string entity_name) {
    array<CBaseEntity@> targets = FindEntities(entity_name);
    for (uint i = 0; i < targets.length(); i++) {
        CBaseEntity@ ent = targets[i];
        Vector position = ent.GetAbsOrigin();
        QAngle angles = ent.GetAbsAngles();
        
        CBaseEntity@ box = util::CreateEntityByName("prop_dynamic");
        if (box !is null) {
            box.KeyValue("model", "models/props/archipelago/ap_buttonframe.mdl");
            box.KeyValue("solid", "6");
            box.SetAbsOrigin(position);
            box.SetAbsAngles(angles);
            box.Spawn();
        }

        string model = ent.GetModelName();
        CBaseEntity@ btn = util::CreateEntityByName("prop_dynamic");
        if (btn !is null) {
            btn.KeyValue("model", model);
            btn.SetAbsOrigin(position);
            btn.SetAbsAngles(angles);
            btn.Spawn();
        }
        
        // Create hologram with unique name per entity index and check for duplicates
        string holoName = entity_name + "_" + ent.GetEntityIndex() + "_holo";
        if (EntityList().FindByName(null, holoName) is null) {
            CreateAPHologram(position + (AnglesToUp(angles) * 60.0f), angles, 0.66f, null, "", 4, holoName);
        }
    }
    DeleteEntity(entity_name, false);
}

void DeleteCoreOnOutput(string core_name, string target_name, string output) {
    float delay = 5.0f;
    EntFire(target_name, "AddOutput", output + " InitCmd,Command,DeleteEntity " + core_name + " 0, " + delay + ",-1");
}

void BlockWheatleyFight() {
    CBaseEntity@ socket = EntityList().FindByName(null, "breaker_socket_button");
    if (socket !is null) {
        Vector place = socket.GetAbsOrigin();
        CBaseEntity@ target = util::CreateEntityByName("info_target_instructor_hint");
        target.KeyValue("targetname", "hint_target_no_potatos");
        target.SetAbsOrigin(place);
        target.Spawn();
        
        DeleteEntity("breaker_socket_button", false);
        DeleteEntity("breaker_hint", false);
    }

    CBaseEntity@ hint = util::CreateEntityByName("env_instructor_hint");
    hint.KeyValue("targetname", "hudhint_no_potatos");
    hint.KeyValue("hint_target", "hint_target_no_potatos");
    hint.KeyValue("hint_static", "0");
    hint.KeyValue("hint_caption", "PotatOS not unlocked");
    hint.KeyValue("hint_icon_onscreen", "icon_alert");
    hint.KeyValue("hint_color", "255 50 50");
    hint.Spawn();

    EntFire("trigger_portal_cleanser", "AddOutput", "OnStartTouch hudhint_no_potatos,ShowHint,,0.0,-1");
}

void RemovePotatOS() {
    CBaseEntity@ button = EntityList().FindByName(null, "sphere_entrance_potatos_button");
    if (button !is null) {
        Vector place = button.GetAbsOrigin();
        CBaseEntity@ target = util::CreateEntityByName("info_target_instructor_hint");
        target.KeyValue("targetname", "hint_target_no_potatos");
        target.SetAbsOrigin(place);
        target.Spawn();
        
        DeleteEntity("sphere_entrance_lift_relay", false);
    }

    CBaseEntity@ hint = util::CreateEntityByName("env_instructor_hint");
    hint.KeyValue("targetname", "hudhint_no_potatos");
    hint.KeyValue("hint_target", "hint_target_no_potatos");
    hint.KeyValue("hint_static", "0");
    hint.KeyValue("hint_caption", "PotatOS not unlocked");
    hint.KeyValue("hint_icon_onscreen", "icon_alert");
    hint.KeyValue("hint_color", "255 50 50");
    hint.Spawn();

    EntFire("sphere_entrance_potatos_button", "AddOutput", "OnPressed hudhint_no_potatos,ShowHint,,0.0,-1");
}

void RemovePotatosFromGun() {
    EntFire("logic_playerproxy", "RemovePotatosFromPortalgun", "", 0.5f);
}

array<string> wheatley_screen_maps = {"sp_a4_tb_intro", "sp_a4_tb_trust_drop", "sp_a4_tb_wall_button", "sp_a4_tb_polarity", "sp_a4_tb_catch", "sp_a4_stop_the_box", "sp_a4_laser_catapult", "sp_a4_laser_platform", "sp_a4_speed_tb_catch", "sp_a4_jump_polarity", "sp_a4_finale3"};
dictionary screen_names;

void InitScreenNames() {
    screen_names.set("sp_a4_tb_intro:monitor1-relay_break", "sp_a4_tb_intro");
    screen_names.set("sp_a4_tb_trust_drop:monitor1-relay_break", "sp_a4_tb_trust_drop");
    screen_names.set("sp_a4_tb_wall_button:wheatley_monitor-relay_break", "sp_a4_tb_wall_button");
    screen_names.set("sp_a4_tb_polarity:monitor1-relay_break", "sp_a4_tb_polarity");
    screen_names.set("sp_a4_tb_catch:monitor1-relay_break", "sp_a4_tb_catch 1");
    screen_names.set("sp_a4_tb_catch:monitor2-relay_break", "sp_a4_tb_catch 2");
    screen_names.set("sp_a4_stop_the_box:wheatley_monitor-relay_break", "sp_a4_stop_the_box");
    screen_names.set("sp_a4_laser_catapult:wheatley_monitor_1-relay_break", "sp_a4_laser_catapult");
    screen_names.set("sp_a4_laser_platform:wheatley_monitor_1-relay_break", "sp_a4_laser_platform");
    screen_names.set("sp_a4_speed_tb_catch:wheatley_monitor-relay_break", "sp_a4_speed_tb_catch");
    screen_names.set("sp_a4_jump_polarity:wheatley_monitor_1-relay_break", "sp_a4_jump_polarity");
    screen_names.set("sp_a4_finale3:wheatley_screen-relay_break", "sp_a4_finale3");
}

array<string> checked_screens;

void SetCheckedScreens(array<string> screens) {
    checked_screens = screens;
}

void AddWheatleyMonitorBreakCheck() {
    InitScreenNames();
    array<CBaseEntity@> relays;
    CBaseEntity@ findRelay = null;
    while ((@findRelay = EntityList().FindByClassname(findRelay, "logic_relay")) !is null) {
        relays.insertLast(findRelay);
    }

    for (uint i = 0; i < relays.length(); i++) {
        CBaseEntity@ relay = relays[i];
        string name = relay.GetEntityName();
        string key = current_map + ":" + name;
        if (screen_names.exists(key)) {
            string check_name;
            screen_names.get(key, check_name);
            EntFire(name, "AddOutput", "OnTrigger InitCmd,Command,PrintMonitor " + check_name.replace(" ", ".") + ",0.0,-1");
            
            int skin = 0;
            for (uint j = 0; j < checked_screens.length(); j++) {
                if (checked_screens[j] == check_name) { skin = 1; break; }
            }
            CreateAPHologram(relay.GetAbsOrigin(), QAngle(0, 0, 0), 0.9f, null, "", skin, name);
        }
    }
}

dictionary vitrified_door_check_names;
void InitVitrifiedDoors() {
    vitrified_door_check_names.set("sp_a3_03:dummy_chamber_button", "Vitrified Door 1");
    vitrified_door_check_names.set("sp_a3_03:dummy_chamber_button2", "Vitrified Door 2");
    vitrified_door_check_names.set("sp_a3_03:dummy_chamber_button3", "Vitrified Door 3");
    vitrified_door_check_names.set("sp_a3_transition01:dummy_chamber_button", "Vitrified Door 4");
    vitrified_door_check_names.set("sp_a3_transition01:dummy_chamber_button2", "Vitrified Door 5");
    vitrified_door_check_names.set("sp_a3_transition01:dummy_chamber_button3", "Vitrified Door 6");
}

array<string> checked_vitrified_doors;

void AddVitrifiedDoorChecks() {
    InitVitrifiedDoors();
    array<string>@ keys = vitrified_door_check_names.getKeys();
    for (uint i = 0; i < keys.length(); i++) {
        string key = keys[i];
        if (key.locate(current_map + ":") == 0) {
            string name = key.substr(current_map.length() + 1);
            string check_name;
            vitrified_door_check_names.get(key, check_name);
            
            EntFire(name, "AddOutput", "OnPressed InitCmd,Command,PrintMonitor " + check_name.replace(" ", ".") + ",0.0,-1");
            
            int skin = 0;
            CBaseEntity@ btn = EntityList().FindByName(null, name);
            if (btn !is null) {
                CreateAPHologram(btn.GetAbsOrigin() + Vector(0, 0, -25.0f), QAngle(0, 0, 0), 0.6f, null, "", skin, name);
            }
        }
    }
    ArchipelagoLog("Vitrified Door Locations Linked");
}

void CreateAPButton(string name, Vector position, QAngle angle, float holo_scale, int skin = 0) {
    CBaseEntity@ button = util::CreateEntityByName("prop_button");
    if (button !is null) {
        button.SetAbsOrigin(position);
        button.SetAbsAngles(angle);
        button.Spawn();
        EntFire(button.GetEntityName(), "AddOutput", "OnPressed InitCmd,Command,PrintMonitor " + name.replace(" ", ".") + ",0.0,-1");
    }
    CreateAPHologram(position + (Vector(0, 0, 75.0f) * holo_scale), angle + QAngle(0, 90, 0), holo_scale, null, "", skin, name);
}

void CreateAPHologram(Vector position, QAngle angle, float scale, CBaseEntity@ parent = null, string attachment = "", int skin = 0, string name = "") {
    CBaseEntity@ holo = util::CreateEntityByName("prop_dynamic");
    if (holo !is null) {
        holo.KeyValue("model", "models/effects/ap/archipelago_hologram.mdl");
        holo.KeyValue("solid", "0");
        holo.KeyValue("skin", "" + skin);
        holo.KeyValue("modelscale", "" + scale);
        if (name != "") holo.KeyValue("targetname", name);
        holo.SetAbsOrigin(position);
        holo.SetAbsAngles(angle);
        holo.Spawn();
        
        Variant vAnim;
        vAnim.SetString("idle");
        holo.FireInput("SetAnimation", vAnim, 0.0f, null, null, 0);
        
        if (parent !is null) {
            holo.SetParent(parent);
            if (attachment != "") {
                Variant vAttach;
                vAttach.SetString(attachment);
                holo.FireInput("SetParentAttachmentMaintainOffset", vAttach, 0.0f, null, null, 0);
            }
        }
    }
}

/**
 * AttachHologramToEntity - Safely collects targets to avoid infinite search loops.
 */
void AttachHologramToEntity(string entity_name, string attachment_point, float holo_scale, float offset, int skin = 0) {
    array<CBaseEntity@> targets = FindEntities(entity_name);
    for (uint i = 0; i < targets.length(); i++) {
        CBaseEntity@ ent = targets[i];
        Vector position = ent.GetAbsOrigin();
        QAngle angles = ent.GetAbsAngles();
        string name = entity_name + "_" + i;
        ent.KeyValue("targetname", name);
        CreateAPHologram(position + (AnglesToDirection(angles) * offset), angles, holo_scale, ent, attachment_point, skin, "");
    }
}

void RemoveGel(float x, float y, float z, string object_type = "", string object_name = "") {
    Vector pos = Vector(x, y, z);
    CBaseEntity@ ent = EntityList().FindByClassnameNearest(object_type != "" ? object_type : "prop_dynamic", pos, 5.0f);
    if (ent !is null) {
        if (object_name == "" || ent.GetEntityName() == object_name) {
            ArchipelagoLog("Removing gel near " + ent.GetEntityName());
            ent.Remove();
        }
    }

    CBaseEntity@ bomb = util::CreateEntityByName("prop_paint_bomb");
    if (bomb !is null) {
        bomb.SetAbsOrigin(pos);
        bomb.Spawn();
    }
}

void CreateClearGel(Vector position, float offset = -100.0f) {
    CBaseEntity@ gel = util::CreateEntityByName("prop_paint_bomb");
    if (gel !is null) {
        gel.KeyValue("paint_type", "3");
        Vector p = position;
        p.z += offset;
        gel.SetAbsOrigin(p);
        gel.Spawn();
    }
}

void PrintMapName() {
    ArchipelagoLog("map_name:" + current_map);
}

void ListEntities() {
    CBaseEntity@ ent = null;
    while ((@ent = EntityList().Next(ent)) !is null) {
        ArchipelagoLog("" + ent.GetClassname() + " (" + ent.GetEntityName() + ")");
    }
}

void PrintMapCompleteNoExit() {
    ArchipelagoLog("map_complete:" + current_map);
}

void PrintMapComplete() {
    PrintMapCompleteNoExit();
}

void ExitToMenu() {
    CBaseEntity@ cmdEnt = EntityList().FindByName(null, "InitCmd");
    if (cmdEnt !is null) {
        Variant v;
        v.SetString("disconnect;startupmenu force");
        cmdEnt.FireInput("Command", v, 0.0f, null, null, 0);
    }
}

array<string> non_elevator_maps = {"sp_a1_intro1", "sp_a1_intro7", "sp_a1_wakeup", "sp_a2_turret_intro", "sp_a2_bts1", "sp_a2_bts2", "sp_a2_bts3", "sp_a2_bts4", "sp_a2_bts5", "sp_a2_bts6", "sp_a2_core", "sp_a3_00", "sp_a3_01", "sp_a4_laser_platform", "sp_a3_portal_intro", "sp_a4_finale1", "sp_a4_finale2", "sp_a4_finale3", "sp_a4_finale4"};

void CreateCompleteLevelAlertHook() {
    if (ItemInList(current_map, non_elevator_maps)) {
        EntFire("@transition_script", "AddOutput", "OnTrigger InitCmd,Command,FinishedMap,,0.0,-1");
    } else {
        EntFire("@transition_from_map", "AddOutput", "OnTrigger InitCmd,Command,FinishedMap,,0.0,-1");
        DeleteEntity("@exit_teleport", false);
    }
}

void InciniratorDisablePortalGun() {
    EntFire("player_near_portalgun", "AddOutput", "OnStartTouch InitCmd,Command,DisablePortalGun 0 1,0.25,-1");
}

void DoMapSpecificSetup() {
    if (current_map == "sp_a1_intro3") {
        EntFire(Vector(25, 1958, -299), "AddOutput", "OnStartTouch InitCmd,Command,PrintItem Portal.Gun,0.0,-1", 2.0f, "trigger_once");
        EntFire(Vector(-704, 1856, -32), "AddOutput", "OnStartTouch InitCmd,Command,PrintItem Portal.Gun,0.0,-1", 2.0f, "trigger_multiple");
    } else if (current_map == "sp_a2_intro") {
        EntFire("player_near_portalgun", "AddOutput", "OnStartTouch InitCmd,Command,PrintItem Upgraded.Portal.Gun,0.0,-1");
        EntFire(Vector(-360, 440, -10680), "AddOutput", "OnStartTouch InitCmd,Command,PrintItem Upgraded.Portal.Gun,0.0,-1", 2.0f, "trigger_once");
    } else if (current_map == "sp_a3_transition01") {
        EntFire("sphere_entrance_potatos_button", "AddOutput", "OnPressed InitCmd,Command,PrintItem PotatOS,0.0,-1");
    }
}

void CreateMapSpecificHolos() {
    if (current_map == "sp_a1_intro3") CreateAPHologram(Vector(25, 1958, -299), QAngle(0, 0, 0), 0.66f, null, "", 0, "");
    else if (current_map == "sp_a2_intro") {
        CBaseEntity@ gun = EntityList().FindByName(null, "player_near_portalgun");
        if (gun !is null) CreateAPHologram(gun.GetAbsOrigin(), QAngle(0, 0, 0), 0.66f, null, "", 0, "");
    }
    else if (current_map == "sp_a3_transition01") {
        CBaseEntity@ btn = EntityList().FindByName(null, "sphere_entrance_potatos_button");
        if (btn !is null) CreateAPHologram(btn.GetAbsOrigin(), QAngle(0, 0, 0), 0.66f, null, "", 0, "");
    }
}

void AttachDeathTrigger() {}
void AddToTextQueue(string text, string color = "") {}
