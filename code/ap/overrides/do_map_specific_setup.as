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
    } else if (current_map == "sp_a4_intro") {
        // --- RESTORED SP_A4_INTRO HOOK ---
        CBaseEntity@ trigger = EntityList().FindByClassnameNearest("trigger_once", Vector(-816, 64, 320), 10.0f);
        if (trigger !is null) {
            Msgl("[AP] Hooking dynamic Frankenturret spawner for session...");
            Variant vOut;
            // Scan for monsters (robustly) 1s after trigger touch
            vOut.SetString("OnStartTouch ap_init_cmd:Command:DeleteEntity prop_monster_box 1 0.7:1.0:-1");
            trigger.FireInput("AddOutput", vOut, 0.0f, null, null, 0);
        }
    }
}
