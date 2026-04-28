void DoMapSpecificSetup(string current_map) {
    // 1. Spawning items/triggers for early game
    if (current_map == "sp_a1_intro3") {
        CBaseEntity@ pg1 = EntityList().FindByClassnameNearest("trigger_once", Vector(25, 1958, -299), 10.0f);
        if (pg1 !is null) {
            Variant vOut;
            vOut.SetString("OnStartTouch ap_init_cmd:Command:ap_print_item Portal Gun:0.0:1");
            pg1.FireInput("AddOutput", vOut, 0.0f, null, null, 0);
        }
        CBaseEntity@ pg2 = EntityList().FindByClassnameNearest("trigger_multiple", Vector(-704, 1856, -32), 10.0f);
        if (pg2 !is null) {
            Variant vOut;
            vOut.SetString("OnStartTouch ap_init_cmd:Command:ap_print_item Portal Gun:0.0:1");
            pg2.FireInput("AddOutput", vOut, 0.0f, null, null, 0);
            
            // Force it to disable after one fire to prevent floods
            Variant vDis; vDis.SetString("OnStartTouch !self:Disable::0.1:-1");
            pg2.FireInput("AddOutput", vDis, 0.0f, null, null, 0);
        }
    } else if (current_map == "sp_a2_intro") {
        CBaseEntity@ gun_trigger = EntityList().FindByName(null, "player_near_portalgun");
        if (gun_trigger !is null) {
            Variant vOut;
            vOut.SetString("OnStartTouch ap_init_cmd:Command:ap_print_item Upgraded Portal Gun:0.0:1");
            gun_trigger.FireInput("AddOutput", vOut, 0.0f, null, null, 0);
        }
        CBaseEntity@ gun2 = EntityList().FindByClassnameNearest("trigger_once", Vector(-360, 440, -10680), 10.0f);
        if (gun2 !is null) {
            Variant vOut;
            vOut.SetString("OnStartTouch ap_init_cmd:Command:ap_print_item Upgraded Portal Gun:0.0:1");
            gun2.FireInput("AddOutput", vOut, 0.0f, null, null, 0);
        }
    } else if (current_map == "sp_a3_transition01") {
        CBaseEntity@ potatos = EntityList().FindByName(null, "sphere_entrance_potatos_button");
        if (potatos !is null) {
            // Quality of Life: Always unlock the button immediately
            // We use multiple delays to ensure we beat the map's own locking logic.
            Variant vEmpty;
            potatos.FireInput("Unlock", vEmpty, 0.1f, null, null, 0);
            potatos.FireInput("Unlock", vEmpty, 1.0f, null, null, 0);
            potatos.FireInput("Unlock", vEmpty, 2.0f, null, null, 0);

            Variant vOut;
            vOut.SetString("OnPressed ap_init_cmd:Command:ap_print_item PotatOS:0.0:1");
            potatos.FireInput("AddOutput", vOut, 0.0f, null, null, 0);
        }
    } else if (current_map == "sp_a2_bts2") {
        CBaseEntity@ trigger = EntityList().FindByClassnameNearest("trigger_once", Vector(1514, -3898, 64), 150.0f);
        if (trigger !is null) {
            Variant vOut;
            vOut.SetString("OnStartTouch ap_init_cmd:Command:DisableEntityPhysics npc_portal_turret_floor:3.0:1");
            trigger.FireInput("AddOutput", vOut, 0.0f, null, null, 0);
        }
    } else if (current_map == "sp_a4_finale2") {
        CBaseEntity@ trigger = EntityList().FindByClassnameNearest("trigger_once", Vector(11835, 11776, 8543), 150.0f);
        if (trigger !is null) {
            Variant vOut;
            vOut.SetString("OnStartTouch ap_init_cmd:Command:DisableEntityPhysics npc_portal_turret_floor:2.5:1");
            trigger.FireInput("AddOutput", vOut, 0.0f, null, null, 0);
        }
    } else if (current_map == "sp_a2_pull_the_rug") {
        CBaseEntity@ door = EntityList().FindByName(null, "ratman_lockoff_door");
        if (door !is null) {
            Variant v;
            door.FireInput("Open", v, 0.5f, null, null, 0);
        }
    } else if (current_map == "sp_a2_laser_intro") {
        // TIMING & NAME FIX: Reverting to specific names with the working 1.3s delay.
        CBaseEntity@ cmd = EntityList().FindByName(null, "ap_init_cmd");
        if (cmd !is null) {
            Variant v;
            // Parent the Emitter (Trying all likely names)
            v.SetString("ent_fire laser_emitter_door_holo SetParent laser_emitter_door:0.8:-1");
            cmd.FireInput("Command", v, 0.5f, null, null, 0);
            v.SetString("ent_fire laser_emitter_holo SetParent laser_emitter_door:0.8:-1");
            cmd.FireInput("Command", v, 0.5f, null, null, 0);
            v.SetString("ent_fire emitter_1_holo SetParent laser_emitter_door:0.8:-1");
            cmd.FireInput("Command", v, 0.5f, null, null, 0);

            // Parent the Catcher (Working)
            v.SetString("ent_fire laser_catcher_door_holo SetParent laser_catcher_door:0.8:-1");
            cmd.FireInput("Command", v, 0.5f, null, null, 0);
            v.SetString("ent_fire catcher_1_holo SetParent laser_catcher_door:0.8:-1");
            cmd.FireInput("Command", v, 0.5f, null, null, 0);
        }
    }
}

/**
 * IncineratorDisablePortalGun - Replicates the VScript incinerator logic.
 * Disables the portal gun (if required) when the player enters the incinerator.
 */
void IncineratorDisablePortalGun() {
    CBaseEntity@ trigger = EntityList().FindByName(null, "player_near_portalgun");
    if (trigger !is null) {
        Variant v;
        // Arguments: blue=0 (off), orange=(portalgun_2_disabled ? 1 : 0), isDelayed=0
        string orangeVal = portalgun_2_disabled ? "1" : "0";
        v.SetString("OnStartTouch ap_init_cmd:Command:DisablePortalGun 0 " + orangeVal + " 0:0.25:-1");
        trigger.FireInput("AddOutput", v, 0.0f, null, null, 0);
    }
}
