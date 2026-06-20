// =============================================================
// ARCHIPELAGO WORKFLOW & SETUP MANAGER (OOP VERSION)
// =============================================================

namespace Archipelago {

class WorkflowManager {
    // --- ELEVATOR TRACKING STATE ---
    private EHandle<CBaseEntity> m_hElevator;
    private float m_flInitialElevatorZ;

    WorkflowManager() {
        m_flInitialElevatorZ = 0.0f;
    }

    void Initialize() {
        m_flInitialElevatorZ = 0.0f;
    }

    // =============================================================
    // GENERAL UTILITY LOGIC
    // =============================================================

    void PrintMapName() {
        ArchipelagoLog("map_name:" + g_Archipelago.GetCurrentMap());
    }

    void WarpToMenu() {
        g_Archipelago.UpdateInternalMapName();
        g_Archipelago.CallVScript("SendToPanorama(\"Archipelago_WarpToMenu\", \"" + g_Archipelago.GetCurrentMap() + "\")");
    }

    void SafeRemoveEntity(CBaseEntity@ ent) {
        if (ent is null) return;
        Variant v;
        ent.FireInput("Kill", v, 0.0f, null, null, 0);
    }

    void SpawnPaintBomb(Vector position) {
        CBaseEntity@ gel = util::CreateEntityByName("prop_paint_bomb");
        if (gel !is null) {
            gel.SetAbsOrigin(position);
            gel.Spawn();
        }
    }

    void WaitExecute(string command, float delay, string timerName = "") {
        CBaseEntity@ cmdEnt = EntityList().FindByName(null, "InitCmd");
        if (cmdEnt !is null) {
            Variant v;
            v.SetString(command);
            cmdEnt.FireInput("Command", v, delay, null, null, 0);
            ArchipelagoLog("Scheduled command in " + delay + "s: " + command);
        }
    }

    void AddEntityOutputScriptAtPos(Vector pos, string cls, string output, string script, float delay = 0.0f, int times = -1) {
        CBaseEntity@ ent = EntityList().FindByClassnameNearest(cls, pos, 150.0f);
        if (ent !is null) {
            g_Archipelago.SafeAddOutput(ent, output, "InitCmd", "Command", script, delay, times);
        }
    }

    // =============================================================
    // MAP SPECIFIC SETUP
    // =============================================================

    void DoMapSpecificSetup() {
        string currentMap = g_Archipelago.GetCurrentMap();

        if (currentMap == "sp_a1_intro1") {
            ConVarRef skipIntroContainerCvar("cv_SkipIntroContainerScene");
            if (skipIntroContainerCvar.IsValid() && skipIntroContainerCvar.GetInt() == 1) {
                SkipContainer();
            }
        } 
        else if (currentMap == "sp_a1_intro3") {
            AddEntityOutputScriptAtPos(Vector(25, 1958, -299), "trigger_once", "OnStartTouch", "PrintItem Portal Gun", 0.0f, 1);
            AddEntityOutputScriptAtPos(Vector(-704, 1856, -32), "trigger_multiple", "OnStartTouch", "PrintItem Portal Gun", 0.0f, 1);
        } 
        else if (currentMap == "sp_a1_intro4") {
            g_Archipelago.GetEntityManager().PreventPickupForModel("water_bottle.mdl");
        } 
        else if (currentMap == "sp_a2_intro") {
            CBaseEntity@ gun_trigger = EntityList().FindByName(null, "player_near_portalgun");
            if (gun_trigger !is null) {
                g_Archipelago.SafeAddOutput(gun_trigger, "OnStartTouch", "InitCmd", "Command", "PrintItem Upgraded Portal Gun", 0.0f, 1);
            }
            AddEntityOutputScriptAtPos(Vector(-360, 440, -10680), "trigger_once", "OnStartTouch", "PrintItem Upgraded Portal Gun", 0.0f, 1);
        } 
        else if (currentMap == "sp_a2_trust_fling") {
            g_Archipelago.GetEntityManager().PreventPickupForModel("food_can_open.mdl");
            g_Archipelago.GetEntityManager().PreventPickupForModel("water_bottle.mdl");
        } 
        else if (currentMap == "sp_a2_bridge_the_gap") {
            ConVarRef skipBirdCvar("cv_SkipBirdScene");
            if (skipBirdCvar.IsValid() && skipBirdCvar.GetInt() == 1) {
                Vector targetPos(-1074, -640, 1224);
                CBaseEntity@ trigger = EntityList().FindByClassnameWithin(null, "trigger_once", targetPos, 16.0f);
                if (trigger !is null) {
                    Variant empty;
                    trigger.FireInput("Kill", empty, 0.0f, null, null, 0);
                }
            }
        } 
        else if (currentMap == "sp_a2_sphere_peek") {
            ConVarRef skipCeilingCvar("cv_SkipCeilingScene");
            if (skipCeilingCvar.IsValid() && skipCeilingCvar.GetInt() == 1) {
                CBaseEntity@ cmd = EntityList().FindByName(null, "InitCmd");
                if (cmd !is null) {
                    Variant v1;
                    v1.SetString("ent_fire @trigger_this_to_fix_ceiling Trigger");
                    cmd.FireInput("Command", v1, 0.5f, null, null, 0);

                    Variant v2;
                    v2.SetString("ent_fire @trigger_this_to_fix_catapult Trigger");
                    cmd.FireInput("Command", v2, 0.6f, null, null, 0);
                } else {
                    CBaseEntity@ ceilingRelay = EntityList().FindByName(null, "@trigger_this_to_fix_ceiling");
                    if (ceilingRelay !is null) {
                        Variant empty;
                        ceilingRelay.FireInput("Trigger", empty, 0.0f, null, null, 0);
                    }
                    CBaseEntity@ catapultRelay = EntityList().FindByName(null, "@trigger_this_to_fix_catapult");
                    if (catapultRelay !is null) {
                        Variant empty;
                        catapultRelay.FireInput("Trigger", empty, 0.0f, null, null, 0);
                    }
                }

                CBaseEntity@ ent = null;
                while ((@ent = EntityList().FindByClassname(ent, "trigger_multiple")) !is null) {
                    if (ent.GetEntityName() == "") {
                        util::Remove(ent);
                    }
                }
            }
        } 
        else if (currentMap == "sp_a3_transition01") {
            CBaseEntity@ potatos_btn = EntityList().FindByName(null, "sphere_entrance_potatos_button");
            if (potatos_btn !is null) {
                g_Archipelago.SafeAddOutput(potatos_btn, "OnPressed", "InitCmd", "Command", "PrintItem PotatOS; RemovePotatosFromGun", 0.0f, -1);
                potatos_btn.FireInput("Unlock", Variant(), 1.0f, null, null, 0);
            }
        } 
        else if (currentMap == "sp_a2_laser_intro") {
            CBaseEntity@ cmd = EntityList().FindByName(null, "InitCmd");
            if (cmd !is null) {
                Variant v1;
                v1.SetString("ent_fire laser_emitter_door_holo SetParent laser_emitter_door:0.8:-1");
                cmd.FireInput("Command", v1, 0.5f, null, null, 0);
                
                Variant v2;
                v2.SetString("ent_fire laser_catcher_door_holo SetParent laser_catcher_door:0.8:-1");
                cmd.FireInput("Command", v2, 0.5f, null, null, 0);
            }
        } 
        else if (currentMap == "sp_a2_laser_vs_turret") {
            g_Archipelago.GetEntityManager().PreventPickupForModel("water_bottle.mdl");
        } 
        else if (currentMap == "sp_a2_bts4") {
            CBaseEntity@ existingTimer = EntityList().FindByName(null, "bts4_conveyor_timer");
            if (existingTimer is null) {
                CBaseEntity@ timer = util::CreateEntityByName("logic_timer");
                if (timer !is null) {
                    timer.KeyValue("targetname", "bts4_conveyor_timer");
                    timer.KeyValue("RefireTime", "0.1");
                    
                    string payload = "InitCmd\x1BCommand\x1BAP_BTS4_ConveyorTick\x1B0\x1B-1";
                    timer.KeyValue("OnTimer", payload);
                    timer.Spawn();
                    
                    Variant empty;
                    timer.FireInput("Enable", empty, 0.0f, null, null, 0);
                }
            }
        } 
        else if (currentMap == "sp_a4_finale2") {
            CBaseEntity@ existingTimer = EntityList().FindByName(null, "finale2_turret_timer");
            if (existingTimer is null) {
                CBaseEntity@ timer = util::CreateEntityByName("logic_timer");
                if (timer !is null) {
                    timer.KeyValue("targetname", "finale2_turret_timer");
                    timer.KeyValue("RefireTime", "0.2");
                    
                    string payload = "InitCmd\x1BCommand\x1BFinale2TurretTick\x1B0\x1B-1";
                    timer.KeyValue("OnTimer", payload);
                    timer.Spawn();
                    
                    Variant empty;
                    timer.FireInput("Enable", empty, 0.0f, null, null, 0);
                }
            }
        }
    }

    // =============================================================
    // SCENE AND TIMEOUT SKIPS
    // =============================================================

    void SkipContainer() {
        array<string> names = {
            "",                                 // Step 0
            "camera_intro",                     // Step 1
            "good_morning_vcd",                 // Step 2
            "@exit_wall_hit_counter",           // Step 3
            "@exit_wall_hit_counter",           // Step 4
            "actor_wall_destruction_01",        // Step 5
            "actor_wall_destruction_02",        // Step 6
            "actor_wall_destruction_03",        // Step 7
            "@rl_container_ride_third_section", // Step 8
            "@debug_teleport_to_vault_relay",   // Step 9
            "info_player_start",                // Step 10
            "camera_intro",                     // Step 11
            ""                                  // Step 12
        };

        array<string> actions = {
            "fadeout",
            "disable",
            "remove",
            "setvalue 1",
            "setvalue 2",
            "remove",
            "remove",
            "remove",
            "trigger",
            "trigger",
            "remove",
            "remove",
            "fadein"
        };

        uint stepCount = names.length();
        Variant emptyVariant;
        CBaseEntity@ player = util::GetEntityByIndex(1);

        for (uint i = 0; i < stepCount; i++) {
            string targetName = names[i];
            string actionInput = actions[i];

            if (actionInput.empty()) continue;

            string lowerAction = actionInput.tolower();
            float scheduledDelay = 1.0f;
            if (i == 0) scheduledDelay = 0.0f;
            if (i == stepCount - 1) scheduledDelay = 1.2f;

            if (lowerAction == "fadeout" || lowerAction == "fadein") {
                CBaseEntity@ fadeEnt = util::CreateEntityByName("env_fade");
                if (fadeEnt !is null) {
                    fadeEnt.KeyValue("rendercolor", "0 0 0"); 
                    if (lowerAction == "fadeout") {
                        fadeEnt.KeyValue("duration", "0.0");
                        fadeEnt.KeyValue("holdtime", "0.0"); 
                        fadeEnt.KeyValue("spawnflags", "8"); 
                    } else {
                        fadeEnt.KeyValue("duration", "3.0");
                        fadeEnt.KeyValue("holdtime", "0.0");
                        fadeEnt.KeyValue("spawnflags", "1"); 
                    }
                    fadeEnt.Spawn();
                    fadeEnt.FireInput("Fade", emptyVariant, scheduledDelay, player, player);
                }
                continue;
            }

            if (targetName == "@debug_teleport_to_vault_relay" && player !is null) {
                player.FireInput("ClearParent", emptyVariant, scheduledDelay, player, player);
            }

            if (targetName.empty()) continue;

            CBaseEntity@ ent = EntityList().FindByName(null, targetName);
            if (ent is null) continue;

            if (lowerAction == "remove") {
                ent.FireInput("Kill", emptyVariant, scheduledDelay, player, player);
            } else if (lowerAction == "trigger") {
                ent.FireInput("Trigger", emptyVariant, scheduledDelay, player, player);
            } else if (lowerAction == "enable") {
                ent.FireInput("Enable", emptyVariant, scheduledDelay, player, player);
            } else if (lowerAction == "disable") {
                ent.FireInput("Disable", emptyVariant, scheduledDelay, player, player);
            } else if (lowerAction.locate("setvalue") == 0) {
                int spaceIdx = actionInput.locate(" ");
                int value = 0;
                if (spaceIdx != -1) {
                    value = int(actionInput.substr(spaceIdx + 1).trim().toInt());
                }
                Variant val;
                val.SetInt(value);
                ent.FireInput("SetValue", val, scheduledDelay, player, player);
            } else {
                ent.FireInput(actionInput, emptyVariant, scheduledDelay, player, player);
            }
        }
    }

    void CheckElevatorRide() {
        CBaseEntity@ train = m_hElevator.Get();
        if (train is null) {
            CBaseEntity@ timer = EntityList().FindByName(null, "ap_elevator_timer");
            if (timer !is null) timer.Remove();
            return;
        }

        Vector currentPos = train.GetAbsOrigin();

        if (!closeTo(currentPos.z, m_flInitialElevatorZ, 0.00f)) {
            CBaseEntity@ cmd = EntityList().FindByName(null, "InitCmd");
            if (cmd !is null) {
                Variant vFade;
                vFade.SetString("fadeout 0.2");
                cmd.FireInput("Command", vFade, 0.0f, null, null, 0);
            }
            g_Archipelago.GetCheckManager().PrintMapComplete();

            CBaseEntity@ timer = EntityList().FindByName(null, "ap_elevator_timer");
            if (timer !is null) {
                timer.Remove();
            }
        }
    }

    void SkipElevatorRide() {
        ConVarRef cv_SkipElavatorRide("cv_SkipElavatorRide");
        if (cv_SkipElavatorRide.IsValid() && cv_SkipElavatorRide.GetInt() == 0) {
            return;
        }

        CBaseEntity@ train = null;
        while ((@train = EntityList().FindByClassname(train, "func_tracktrain")) !is null) {
            string name = train.GetEntityName();
            if (name.locate("departure") < name.length()) {
                m_hElevator.Set(train);
                m_flInitialElevatorZ = train.GetAbsOrigin().z;

                CBaseEntity@ timer = util::CreateEntityByName("logic_timer");
                if (timer !is null) {
                    timer.KeyValue("targetname", "ap_elevator_timer");
                    timer.KeyValue("RefireTime", "0.25"); 
                    
                    string payload = "InitCmd\x1BCommand\x1BCheckElevatorRide\x1B0\x1B-1";
                    timer.KeyValue("OnTimer", payload);
                    timer.Spawn();
                    
                    Variant empty;
                    timer.FireInput("Enable", empty, 0.0f, null, null, 0);
                }
                break; 
            }
        }
    }

    // =============================================================
    // DEATHLINK SINK AND HOOKS
    // =============================================================

    void AttachDeathTrigger() {
        g_Archipelago.SetSentDeathLink(false);

        CBaseEntity@ timer = util::CreateEntityByName("logic_timer");
        if (timer !is null) {
            timer.KeyValue("targetname", "ap_deathlink_timer");
            timer.KeyValue("RefireTime", "0.25");
            
            string payload = "InitCmd\x1BCommand\x1BCheckDeathLinkQueue\x1B0\x1B-1";
            timer.KeyValue("OnTimer", payload);
            timer.Spawn();
            
            Variant empty;
            timer.FireInput("Enable", empty, 0.0f, null, null, 0);
        }
        ArchipelagoLog("DeathLink continuous sync active");
    }

    void BlockWheatleyFight() {
        CBaseEntity@ socket = EntityList().FindByName(null, "breaker_socket_button");
        if (socket !is null) {
            Vector place = socket.GetAbsOrigin();
            CBaseEntity@ target = util::CreateEntityByName("info_target_instructor_hint");
            target.KeyValue("targetname", "hint_target_no_potatos");
            target.SetAbsOrigin(place);
            target.Spawn();
        
            g_Archipelago.GetEntityManager().DeleteEntity("breaker_socket_button", false);
            g_Archipelago.GetEntityManager().DeleteEntity("breaker_hint", false);
        }

        CBaseEntity@ hint = util::CreateEntityByName("env_instructor_hint");
        hint.KeyValue("targetname", "hudhint_no_potatos");
        hint.KeyValue("hint_target", "hint_target_no_potatos");
        hint.KeyValue("hint_static", "0");
        hint.KeyValue("hint_caption", "PotatOS not unlocked");
        hint.KeyValue("hint_icon_onscreen", "icon_alert");
        hint.KeyValue("hint_color", "255 50 50");
        hint.Spawn();

        g_Archipelago.SafeAddOutput(EntityList().FindByName(null, "trigger_portal_cleanser"), "OnStartTouch", "hudhint_no_potatos", "ShowHint", "", 0.0f, -1);
    }

    void HandleMonitorWarp(string monitorID) {
        CBaseEntity@ player = EntityList().FindByClassname(null, "player");
        if (player is null) return;

        Vector vel = player.GetAbsVelocity();
        if (vel.z >= -30.0f) {
            ArchipelagoLog("Player is not falling (vel.z = " + vel.z + "), skipping warp.");
            return;
        }

        Vector targetPos;
        QAngle targetAng;
        bool shouldWarp = false;

        if (monitorID == "sp_a4_tb_trust_drop") {
            targetPos = Vector(317, 1154, 800);
            targetAng = QAngle(0, -90, 0);
            shouldWarp = true;
        } else if (monitorID == "sp_a4_tb_catch 1") {
            targetPos = Vector(10.0, -1260.0, -80.0); 
            targetAng = QAngle(0, 90, 0);
            shouldWarp = true;
        } else if (monitorID == "sp_a4_finale3") {
            targetPos = Vector(7, -235, -173);
            targetAng = QAngle(0, 180, 0);
            shouldWarp = true;
        }

        if (shouldWarp) {
            CBaseEntity@ cam = util::CreateEntityByName("point_viewcontrol");
            if (cam !is null) {
                cam.SetAbsOrigin(targetPos);
                cam.SetAbsAngles(targetAng);
                cam.KeyValue("spawnflags", "140"); 
                cam.Spawn();

                Variant empty;
                cam.FireInput("Enable", empty, 0.0f, player, player);
                cam.FireInput("TeleportToView", empty, 0.02f, player, player);
                cam.FireInput("Disable", empty, 0.1f, player, player);
                cam.FireInput("Kill", empty, 0.2f, null, null);
                
                player.SetAbsVelocity(Vector(0, 0, 0));
            }
        }
    }
}

} // namespace Archipelago
