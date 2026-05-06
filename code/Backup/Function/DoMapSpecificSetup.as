// =============================================================
// ARCHIPELAGO DO MAP SPECIFIC SETUP
// =============================================================
void DoMapSpecificSetup(string current_map) {
    // 1. Spawning items/triggers for early game
    if (current_map == "sp_a1_intro3") {
        CBaseEntity@ pg1 = EntityList().FindByClassnameNearest("trigger_once", Vector(25, 1958, -299), 10.0f);
        if (pg1 !is null) {
            Variant vOut;
            vOut.SetString("OnStartTouch InitCmd:Command:PrintItem Portal Gun:0.0:1");
            pg1.FireInput("AddOutput", vOut, 0.0f, null, null, 0);
        }
        CBaseEntity@ pg2 = EntityList().FindByClassnameNearest("trigger_multiple", Vector(-704, 1856, -32), 10.0f);
        if (pg2 !is null) {
            Variant vOut;
            vOut.SetString("OnStartTouch InitCmd:Command:PrintItem Portal Gun:0.0:1");
            pg2.FireInput("AddOutput", vOut, 0.0f, null, null, 0);
            
            // Force it to disable after one fire to prevent floods
            Variant vDis; vDis.SetString("OnStartTouch !self:Disable::0.1:-1");
            pg2.FireInput("AddOutput", vDis, 0.0f, null, null, 0);
        }
    } else if (current_map == "sp_a2_intro") {
        CBaseEntity@ gun_trigger = EntityList().FindByName(null, "player_near_portalgun");
        if (gun_trigger !is null) {
            Variant vOut;
            vOut.SetString("OnStartTouch InitCmd:Command:PrintItem Upgraded Portal Gun:0.0:1");
            gun_trigger.FireInput("AddOutput", vOut, 0.0f, null, null, 0);
        }
        CBaseEntity@ gun2 = EntityList().FindByClassnameNearest("trigger_once", Vector(-360, 440, -10680), 10.0f);
        if (gun2 !is null) {
            Variant vOut;
            vOut.SetString("OnStartTouch InitCmd:Command:PrintItem Upgraded Portal Gun:0.0:1");
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
            vOut.SetString("OnPressed InitCmd:Command:PrintItem PotatOS:0.0:1");
            potatos.FireInput("AddOutput", vOut, 0.0f, null, null, 0);
        }
    } else if (current_map == "sp_a2_bts2") {
        CBaseEntity@ trigger = EntityList().FindByClassnameNearest("trigger_once", Vector(1514, -3898, 64), 150.0f);
        if (trigger !is null) {
            Variant vOut;
            vOut.SetString("OnStartTouch InitCmd:Command:DisableEntityPhysics npc_portal_turret_floor:3.0:1");
            trigger.FireInput("AddOutput", vOut, 0.0f, null, null, 0);
        }
    } else if (current_map == "sp_a4_finale2") {
        CBaseEntity@ trigger = EntityList().FindByClassnameNearest("trigger_once", Vector(11835, 11776, 8543), 150.0f);
        if (trigger !is null) {
            Variant vOut;
            vOut.SetString("OnStartTouch InitCmd:Command:DisableEntityPhysics npc_portal_turret_floor:2.5:1");
            trigger.FireInput("AddOutput", vOut, 0.0f, null, null, 0);
        }
    } else if (current_map == "sp_a2_pull_the_rug") {
        // Create a persistent timer to check if the bridge is gone (handles delayed deletions)
        CBaseEntity@ timer = util::CreateEntityByName("logic_timer");
        if (timer !is null) {
            timer.KeyValue("targetname", "ap_ratman_door_timer");
            timer.KeyValue("RefireTime", "1.0");
            timer.Spawn();
            
            Variant v;
            v.SetString("OnTimer InitCmd:Command:CheckBridgeLockout:0.0:-1");
            timer.FireInput("AddOutput", v, 0.0f, null, null, 0);
            
            // Initial fire
            timer.FireInput("FireTimer", Variant(), 0.1f, null, null, 0);
        }
    } else if (current_map == "sp_a2_laser_intro") {
        // TIMING & NAME FIX: Reverting to specific names with the working 1.3s delay.
        CBaseEntity@ cmd = EntityList().FindByName(null, "InitCmd");
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

