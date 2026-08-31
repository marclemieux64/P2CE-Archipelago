// =============================================================
// ARCHIPELAGO CHECK MANAGER (OOP OPTIMIZED VERSION)
// =============================================================

namespace Archipelago {

// Helper class for Map Checks
class HologramConfig {
    Vector pos;
    QAngle ang;
    bool animate;
    HologramConfig(Vector p, QAngle a, bool anim) { pos = p; ang = a; animate = anim; }
}

// Helper structure for high-efficiency camera tracking
class TrackedCamera {
    CBaseEntity@ entity;
    string identifier;

    TrackedCamera(CBaseEntity@ ent, string id) {
        @entity = ent;
        identifier = id;
    }
}

class CheckManager {
    // --- STATE VARIABLES ---
    private array<string> m_checkedMaps;
    private array<string> m_checkedButtons;
    private array<string> m_checkedCameras;
    private array<string> m_checkedScreens;
    private array<string> m_checkedVitrifiedDoors;

    // --- OOP STATE: POLYMORPHIC LOCATIONS ---
    private array<APLocation@> m_activeLocations;

    // --- DICTIONARIES (REGISTRIES) ---
    private dictionary m_vitrifiedDoorNames;
    private dictionary m_screenNames;

    // --- OPTIMIZED CAMERA TRACKING CACHE ---
    private array<TrackedCamera@> m_trackedCameras;
    private array<string> m_locallyKnockedCameras; // Anti-doublon local temporaire
    private string m_lastCameraMap;

    CheckManager() {
        // Constructor
    }

    void Initialize() {
        ResetSession();
        InitVitrifiedDoorRegistry();
        InitMonitorData();
    }

    void ResetSession() {
        m_checkedMaps.resize(0);
        m_checkedButtons.resize(0);
        m_checkedCameras.resize(0);
        m_checkedScreens.resize(0);
        m_checkedVitrifiedDoors.resize(0);
        m_activeLocations.resize(0);
        m_trackedCameras.resize(0);
        m_locallyKnockedCameras.resize(0);
        m_lastCameraMap = "";
    }

    // --- Private Map Guard to prevent stale memory leaks across level transitions ---
    private void VerifyMapChange() {
        string currentMap = g_Archipelago.GetCurrentMap();
        if (currentMap != m_lastCameraMap) {
            m_lastCameraMap = currentMap;
            m_trackedCameras.resize(0); 
            m_locallyKnockedCameras.resize(0); 
            m_activeLocations.resize(0); // Clear all stale polymorphic locations across map transitions
        }
    }

    // --- GETTERS & STATE CHECKS ---
    array<string>& GetCheckedMaps() { return m_checkedMaps; }
    array<string>& GetCheckedButtons() { return m_checkedButtons; }
    array<string>& GetCheckedCameras() { return m_checkedCameras; }
    array<string>& GetCheckedScreens() { return m_checkedScreens; }
    array<string>& GetCheckedVitrifiedDoors() { return m_checkedVitrifiedDoors; }
    dictionary& GetVitrifiedDoorNames() { return m_vitrifiedDoorNames; }
    dictionary& GetScreenNames() { return m_screenNames; }
    array<APLocation@>& GetActiveLocations() { return m_activeLocations; }

    // =============================================================
    // MAP COMPLETION CHECKS
    // =============================================================

    void AddMapCheck() {
        VerifyMapChange();

        for (int i = int(m_activeLocations.length()) - 1; i >= 0; i--) {
            MapLocation@ mapLoc = cast<MapLocation>(m_activeLocations[i]);
            if (mapLoc !is null) {
                m_activeLocations.removeAt(i);
            }
        }

        string currentMap = g_Archipelago.GetCurrentMap();
        if (currentMap == "unknown" || currentMap == "") return;

        MapLocation@ mapLoc = MapLocation(currentMap);
        bool isChecked = (m_checkedMaps.find(currentMap.tolower()) != -1);
        mapLoc.SetChecked(isChecked);
        m_activeLocations.insertLast(@mapLoc);

        bool isNonElevatorMap = (non_elevator_maps.find(currentMap) != -1);

        if (isNonElevatorMap) {
            dictionary staticHolograms = { { "sp_a1_intro1", HologramConfig(Vector(-9728, -2976, -550), QAngle(0, 0, 0), true) }, { "sp_a1_intro2", HologramConfig(Vector(-8448, -4448, -550), QAngle(0, 0, 0), true) }, { "sp_a1_intro4", HologramConfig(Vector(-5504, -4064, -220), QAngle(0, 0, 0), true) }, { "sp_a1_intro5", HologramConfig(Vector(-3904, -3456, -350), QAngle(0, 0, 0), true) }, { "sp_a1_intro6", HologramConfig(Vector(-1024, -3456, -350), QAngle(0, 0, 0), true) }, { "sp_a2_intro", HologramConfig(Vector(192, 128, -90), QAngle(0, 0, 0), true) }, { "sp_a1_intro7", HologramConfig(Vector(-2208, 376, 1280), QAngle(0, 0, 0), true) }, { "sp_a1_wakeup", HologramConfig(Vector(6165, 3456, 904), QAngle(0, -90, 90), false) }, { "sp_a2_turret_intro", HologramConfig(Vector(-352.380, 392, -206), QAngle(0, 0, 0), true) }, { "sp_a2_bts1", HologramConfig(Vector(1264, -1344, -390), QAngle(0, 0, 0), true) }, { "sp_a2_bts2", HologramConfig(Vector(2208, 1896, 688), QAngle(0, 0, 0), true) }, { "sp_a2_bts3", HologramConfig(Vector(5952, 4624, -1736), QAngle(0, 0, 0), true) }, { "sp_a2_bts4", HologramConfig(Vector(-4080, -7232, 6328), QAngle(0, 0, 0), true) }, { "sp_a2_bts5", HologramConfig(Vector(1592.840, 512.986, 4492), QAngle(0, 90, 0), false) }, { "sp_a2_bts6", HologramConfig(Vector(-2656, -5120, 5228), QAngle(0, 90, 0), false) }, { "sp_a3_01", HologramConfig(Vector(6016, 4496, -448), QAngle(0, 0, 0), true) }, { "sp_a3_portal_intro", HologramConfig(Vector(3839.990, 348.800, 5674), QAngle(0, 0, 0), true) }, { "sp_a4_laser_platform", HologramConfig(Vector(3456, -1024, -2480), QAngle(0, 0, 0), true) }, { "sp_a4_finale1", HologramConfig(Vector(-12832, -3040, -112), QAngle(0, 0, 0), true) }, { "sp_a4_finale2", HologramConfig(Vector(-3152, -1928, -280), QAngle(0, 0, 0), true) }, { "sp_a4_finale3", HologramConfig(Vector(-616, 5376, 580), QAngle(0, 0, 0), true) } };

            int skin = mapLoc.IsChecked() ? 4 : 0;

            if (staticHolograms.exists(currentMap)) {
                HologramConfig@ cfg = cast<HologramConfig>(staticHolograms[currentMap]);
                CreateAPHologram(cfg.pos, cfg.ang, 1.0f, null, "", skin, currentMap + "_map_check_holo", cfg.animate);
            } else if (currentMap == "sp_a3_00") {
                CBaseEntity@ shaft = EntityList().FindByName(null, "shaft_section_10");
                if (shaft !is null) {
                    CreateAPHologram(Vector(0, 0, 350), QAngle(0, 0, 90), 1.5f, shaft, "", skin, "sp_a3_00_map_check_holo", false);
                }
            }

            string[] transTargets = { "transition_logic_relay", "relay_exit_opened", "elevator_entry_relay", "end_relay" };
            for (uint s = 0; s < transTargets.length(); s++) {
                CBaseEntity@ t = null;
                while ((@t = EntityList().FindByName(t, transTargets[s])) !is null) {
                    CreateAPHologram(t.WorldSpaceCenter(), QAngle(0, 0, 0), 1.0f, null, "", skin, t.GetEntityName() + "map_check_trigger_holo", true);
                }
            }
        }

        if (!isNonElevatorMap || currentMap == "sp_a2_core" || currentMap == "sp_a1_intro1") {
            int skin = mapLoc.IsChecked() ? 4 : 0;
            CBaseEntity@ tEnt = null;
            while ((@tEnt = EntityList().FindByClassname(tEnt, "func_tracktrain")) !is null) {
                string tName = tEnt.GetEntityName();
                if (tName.locate("exit_lift_train") != uint(-1) || tName.locate("departure_elevator-elevator") != uint(-1) || tName.locate("exit_elevator_train") != uint(-1)) {
                    CreateAPHologram(Vector(0, 0, 0), QAngle(0, 0, 0), 1.0f, tEnt, "", skin, "map_check_trigger_elevator_holo", true);
                }
            }
        }

        if (currentMap == "sp_a4_finale4") {
            int skin = mapLoc.IsChecked() ? 4 : 0;
            CBaseEntity@ moon = EntityList().FindByName(null, "sprite_moon_portal"); 
            if (moon !is null) {
                Vector pos = moon.GetAbsOrigin() + Vector(-85.0f, 25.0f, 0.0f); 
                CreateAPHologram(pos, QAngle(0.0f, -277.0f, 90.0f), 2.0f, null, "", skin, "moon_holo", false);
            }
        }
    }

    void CreateCompleteLevelAlertHook(string map) {
        g_Archipelago.SetHasPrintedMapComplete(false);

        array<string> triggerClasses = { "trigger_once", "trigger_multiple" };
        for (uint i = 0; i < triggerClasses.length(); i++) {
            CBaseEntity@ tr = null;
            while ((@tr = EntityList().FindByClassname(tr, triggerClasses[i])) !is null) {
                if (tr.GetEntityName() == "") { 
                    Vector pos = tr.GetAbsOrigin();
                    bool is_target = false;

                    if (map == "sp_a2_bts3" && pos.DistTo(Vector(5952, 4624, -1736)) < 2.0f) is_target = true; else if (map == "sp_a2_bts4" && pos.DistTo(Vector(-4080, -7232, 6328)) < 2.0f) is_target = true; else if (map == "sp_a2_core" && pos.DistTo(Vector(0, 304, -10438)) < 2.0f) is_target = true; else if (map == "sp_a4_finale1" && pos.DistTo(Vector(-12832, -3040, -112)) < 2.0f) is_target = true; else if (map == "sp_a4_finale2" && pos.DistTo(Vector(-3152, -1928, -240)) < 2.0f) is_target = true;

                    if (is_target) {
                        g_Archipelago.SafeAddOutput(tr, "OnStartTouch", "InitCmd", "Command", "PrintMapComplete", 0.0f, -1);
                    }
                }
            }
        }

        if (map == "sp_a4_finale4") {
            array<CBaseEntity@> relays = FindEntities("ending_relay");
            for (uint i = 0; i < relays.length(); i++) {
                g_Archipelago.SafeAddOutput(relays[i], "OnTrigger", "InitCmd", "Command", "PrintCompleteNoExit", 0.0f, -1);
            }
        } else if (non_elevator_maps.find(map) >= 0) {
            array<CBaseEntity@> logicScripts = FindEntities("@transition_script");
            for (uint i = 0; i < logicScripts.length(); i++) {
                Variant killValue;
                logicScripts[i].FireInput("Kill", killValue, 0.0f, null, null, 0);
            }
            array<string> targets = { "transition_trigger", "relay_transition", "ending_relay", "potatos_end_relay" };
            for (uint s = 0; s < targets.length(); s++) {
                array<CBaseEntity@> ents = FindEntities(targets[s]);
                for (uint i = 0; i < ents.length(); i++) {
                    g_Archipelago.SafeAddOutput(ents[i], "OnStartTouch", "InitCmd", "Command", "PrintMapComplete", 0.0f, -1);
                    g_Archipelago.SafeAddOutput(ents[i], "OnTrigger", "InitCmd", "Command", "PrintMapComplete", 0.0f, -1);
                }
            }
        } else {
            array<CBaseEntity@> cls = FindEntities("@transition_from_map");
            for (uint i = 0; i < cls.length(); i++) {
                g_Archipelago.SafeAddOutput(cls[i], "OnTrigger", "InitCmd", "Command", "PrintMapComplete", 0.0f, -1);
            }
            g_Archipelago.GetEntityManager().DeleteEntity("@exit_teleport", false);
        }
    }

    void PrintMapComplete() {
        if (g_Archipelago.HasPrintedMapComplete()) return;

        int transitionCount = g_Archipelago.GetTransitionScriptCount();
        if (transitionCount > 0) {
            g_Archipelago.SetTransitionScriptCount(transitionCount - 1);
            return;
        }
        PrintMapCompleteNoExit();
        g_Archipelago.GetWorkflowManager().WaitExecute("WarpToMenu", 2.0f, "return_to_menu");
    }

    void PrintMapCompleteNoExit() {
        if (g_Archipelago.HasPrintedMapComplete()) return;
        g_Archipelago.SetHasPrintedMapComplete(true);

        g_Archipelago.UpdateInternalMapName();
        ArchipelagoLog("map_complete:" + g_Archipelago.GetCurrentMap());

        if (g_Archipelago.GetCurrentMap() == "sp_a4_finale4") return;

        CBasePlayer@ player = GetPlayer();
        if (player !is null) {
            Variant v;
            player.FireInput("Disable", v, 0.0f, null, null, 0);
        }

        CBaseEntity@ cmd = EntityList().FindByName(null, "InitCmd");
        if (cmd !is null) {
            Variant vFade;
            vFade.SetString("fadeout 0.2");
            cmd.FireInput("Command", vFade, 0.0f, null, null, 0);
        }
    }

    void SetCheckedMaps(array<string> checkedMaps) {
        m_checkedMaps = checkedMaps;

        for (uint i = 0; i < m_activeLocations.length(); i++) {
            MapLocation@ mapLoc = cast<MapLocation>(m_activeLocations[i]);
            if (mapLoc !is null) {
                bool isChecked = (m_checkedMaps.find(mapLoc.GetName()) != -1);
                mapLoc.SetChecked(isChecked);
            }
        }
    }

    void SetCheckedPickup(const CommandArgs@ args) {
        if (args.ArgC() < 2) return;

        string itemPayload = args.Arg(1).tolower();
        string currentMap = g_Archipelago.GetCurrentMap().tolower();

        if (currentMap == "sp_a1_intro3" && itemPayload.locate("portal_gun_1") != uint(-1)) {
            CBaseEntity@ holo = EntityList().FindByName(null, "intro3_portalgun_holo");
            if (holo !is null) {
                CBaseAnimating@ animHolo = cast<CBaseAnimating>(holo);
                if (animHolo !is null) animHolo.SetSkin(4);
            }
            return;
        }

        if (currentMap == "sp_a2_intro" && itemPayload.locate("portal_gun_2") != uint(-1)) {
            CBaseEntity@ holo = EntityList().FindByName(null, "a2_intro_gun_holo");
            if (holo !is null) {
                CBaseAnimating@ animHolo = cast<CBaseAnimating>(holo);
                if (animHolo !is null) animHolo.SetSkin(4);
            }
            return;
        }

        if (currentMap == "sp_a3_transition01" && itemPayload.locate("potatos") != uint(-1)) {
            CBaseEntity@ holo = EntityList().FindByName(null, "a3_potatos_button_holo");
            if (holo !is null) {
                CBaseAnimating@ animHolo = cast<CBaseAnimating>(holo);
                if (animHolo !is null) animHolo.SetSkin(4);
            }
            return;
        }
    }

    // =============================================================
    // SECURITY CAMERA CHECKS (HIGH OPTIMIZATION SINK)
    // =============================================================

    private bool MatchPos2D(Vector pos, float targetX, float targetY) {
        float dx = pos.x - targetX;
        float dy = pos.y - targetY;
        return (dx * dx + dy * dy) < 10000.0f;
    }

    string GetCameraUniqueID(string map, Vector pos) {
        if (map == "sp_a1_intro3") {
            if (MatchPos2D(pos, -1472.0f, 2528.0f)) return "1";
        } else if (map == "sp_a1_intro4") {
            if (MatchPos2D(pos, -596.0f, 256.0f)) return "1";
            if (MatchPos2D(pos, 160.0f, 0.0f)) return "2"; 
            if (MatchPos2D(pos, 40.0f, -656.0f)) return "3"; 
        } else if (map == "sp_a1_intro6") {
            if (MatchPos2D(pos, 464.0f, -256.0f)) return "1";
            if (MatchPos2D(pos, 320.0f, -288.0f)) return "2";
            if (MatchPos2D(pos, 1436.0f, -384.0f)) return "3";
        } else if (map == "sp_a2_intro") {
            if (MatchPos2D(pos, -32.0f, 576.0f)) return "1";
        } else if (map == "sp_a2_laser_stairs") {
            if (MatchPos2D(pos, 232.0f, -480.0f)) return "1";
        } else if (map == "sp_a2_dual_lasers") {
            if (MatchPos2D(pos, 122.0f, 352.0f)) return "1";
        } else if (map == "sp_a2_catapult_intro") {
            if (MatchPos2D(pos, -224.0f, 864.0f)) return "1";
            if (MatchPos2D(pos, 96.0f, -1440.0f)) return "2";
        } else if (map == "sp_a2_fizzler_intro") {
            if (MatchPos2D(pos, 368.0f, 96.0f)) return "1";
        } else if (map == "sp_a2_bridge_intro") {
            if (MatchPos2D(pos, 280.0f, -896.0f)) return "1";
        } else if (map == "sp_a2_bridge_the_gap") {
            if (MatchPos2D(pos, -448.0f, -32.0f)) return "1";
        } else if (map == "sp_a2_turret_intro") {
            if (MatchPos2D(pos, 576.0f, -1415.0f)) return "1";
            if (MatchPos2D(pos, 1152.0f, -296.0f)) return "2";
        } else if (map == "sp_a2_laser_relays") {
            if (MatchPos2D(pos, -704.0f, -1014.0f)) return "1";
        } else if (map == "sp_a2_turret_blocker") {
            if (MatchPos2D(pos, -302.0f, 384.0f)) return "1";
            if (MatchPos2D(pos, 336.0f, 640.0f)) return "2";
        } else if (map == "sp_a2_laser_vs_turret") {
            if (MatchPos2D(pos, 384.0f, -288.0f)) return "1";
        } else if (map == "sp_a2_pull_the_rug") {
            if (MatchPos2D(pos, 320.0f, -160.0f)) return "1";
        } else if (map == "sp_a2_laser_chaining") {
            if (MatchPos2D(pos, -384.0f, -480.0f)) return "1";
        } else if (map == "sp_a2_triple_laser") {
            if (MatchPos2D(pos, 7456.0f, -5998.0f)) return "1";
        }
        return "unk";
    }

    void AddCameraCheck() {
        VerifyMapChange();

        CBaseEntity@ camera = null;
        string currentMap = g_Archipelago.GetCurrentMap();
        while ((@camera = EntityList().FindByClassname(camera, "npc_security_camera")) !is null) {
            Vector camPos = camera.GetAbsOrigin();
            string camID = GetCameraUniqueID(currentMap, camPos);
            if (camID == "unk") continue;

            string camIdentifier = currentMap + "_" + camID;
            string holoName = "camera_check_holo_" + camIdentifier.tolower();

            // If the hologram already exists this camera was already initialized during
            // this session. The CameraLocation is still in m_activeLocations and
            // SetCheckedCameras can update it directly — no need to redo the setup.
            if (EntityList().FindByName(null, holoName) !is null) continue;

            bool isChecked = (m_checkedCameras.find(camIdentifier.tolower()) != -1);

            float holoScale = 0.6f;
            QAngle baseAng = camera.GetAbsAngles();
            Vector finalPos = camPos + (AnglesToForward(baseAng) * 35.0f) + (AnglesToUp(baseAng) * -15.0f);
            QAngle finalAng(baseAng.x + 90.0f, baseAng.y, baseAng.z);

            CameraLocation@ camLoc = CameraLocation(camIdentifier, finalPos, finalAng, holoScale);
            camLoc.SetChecked(isChecked);
            m_activeLocations.insertLast(@camLoc);

            if (!isChecked && m_locallyKnockedCameras.find(camIdentifier.tolower()) == -1) {
                bool alreadyTracked = false;
                for (uint j = 0; j < m_trackedCameras.length(); j++) {
                    if (m_trackedCameras[j].identifier == camIdentifier) {
                        alreadyTracked = true;
                        break;
                    }
                }
                if (!alreadyTracked) {
                    m_trackedCameras.insertLast(TrackedCamera(camera, camIdentifier));
                }
            }
        }

        if (m_trackedCameras.length() == 0) return; // No camera to check, avoid spinning up timer

        CBaseEntity@ existingTimer = EntityList().FindByName(null, "archipelago_camera_timer");
        if (existingTimer is null) {
            CBaseEntity@ timer = util::CreateEntityByName("logic_timer");
            if (timer !is null) {
                timer.KeyValue("targetname", "archipelago_camera_timer");
                timer.KeyValue("RefireTime", "0.1"); // Reduced frequency overhead (10Hz)
                timer.KeyValue("OnTimer", "InitCmd\x1BCommand\x1BCheckCameraPhysicsTick\x1B0\x1B-1");
                timer.Spawn();

                Variant empty;
                timer.FireInput("Enable", empty, 0.0f, null, null, 0);
            }
        }
    }

    void CheckCameraPhysicsTick() {
        VerifyMapChange(); // Flush stale handles if the map changed since the timer was armed.

        uint trackingCount = m_trackedCameras.length();
        if (trackingCount == 0) {
            // No more cameras to monitor on this level. Tear down tracking timer gracefully via Kill input.
            CBaseEntity@ existingTimer = EntityList().FindByName(null, "archipelago_camera_timer");
            if (existingTimer !is null) {
                Variant killValue;
                existingTimer.FireInput("Kill", killValue, 0.0f, null, null, 0);
            }
            return;
        }

        for (int i = int(trackingCount) - 1; i >= 0; i--) {
            CBaseEntity@ camera = m_trackedCameras[i].entity;

            if (camera is null) {
                m_trackedCameras.removeAt(i);
                continue;
            }

            string identifier = m_trackedCameras[i].identifier;

            // Checked externally on Archipelago server? Pop tracker handle.
            if (m_checkedCameras.find(identifier.tolower()) != -1) {
                m_trackedCameras.removeAt(i);
                continue;
            }

            bool isPhysicsMove = (camera.GetMoveType() == MOVETYPE_VPHYSICS);
            Vector vel = camera.GetAbsVelocity();

            // Only query the Havok physics body when the entity is actually under vphysics
            // simulation. Calling GetPhysicsObject() on a non-vphysics entity can return a
            // stale IPhysicsObject* whose internal hkpRigidBody motion state is null;
            // GetVelocity() then dereferences null+0x50 → SIGSEGV in vphysics.so.
            if (isPhysicsMove) {
                IPhysicsObject@ physObj = camera.GetPhysicsObject();
                if (physObj !is null) {
                    // EXTREMELY IMPORTANT: We do not call Wake(). If the camera sleeps, its velocity is zero.
                    Vector physVel, physAngVel;
                    physObj.GetVelocity(physVel, physAngVel);
                    if (physVel.LengthSqr() > vel.LengthSqr()) {
                        vel = physVel;
                    }
                }
            }

            // Evaluation threshold parameters
            if ((isPhysicsMove && vel.z < -5.0f) || vel.z < -20.0f) {
                Msgl("camera_knocked:" + identifier);
                m_locallyKnockedCameras.insertLast(identifier.tolower());
                m_trackedCameras.removeAt(i);
            }
        }
    }

    void SetCheckedCameras(array<string> parsedCameras) {
        m_checkedCameras.resize(0);
        for (uint i = 0; i < parsedCameras.length(); i++) {
            m_checkedCameras.insertLast(parsedCameras[i]);
        }

        for (uint i = 0; i < m_activeLocations.length(); i++) {
            CameraLocation@ camLoc = cast<CameraLocation>(m_activeLocations[i]);
            if (camLoc !is null) {
                bool isChecked = (m_checkedCameras.find(camLoc.GetName()) != -1);
                camLoc.SetChecked(isChecked);
            }
        }
    }

    // =============================================================
    // RATMAN DEN BUTTON CHECKS
    // =============================================================

    void SetCheckedButtons(array<string> parsedButtons) {
        VerifyMapChange();

        m_checkedButtons.resize(0);
        for (uint i = 0; i < parsedButtons.length(); i++) {
            m_checkedButtons.insertLast(TranslateButtonName(parsedButtons[i]));
        }

        for (uint i = 0; i < m_activeLocations.length(); i++) {
            ButtonLocation@ btnLoc = cast<ButtonLocation>(m_activeLocations[i]);
            if (btnLoc !is null) {
                string scenarioName = btnLoc.GetName();
                bool isChecked = (m_checkedButtons.find(scenarioName) != -1);
                btnLoc.SetChecked(isChecked);
            }
        }
    }

    string TranslateButtonName(string originalName) {
        string clean = originalName.trim().tolower();
        if (clean == "ratman den 1") return "rd1";
        if (clean == "ratman den 2") return "rd2";
        if (clean == "ratman den 3") return "rd3";
        if (clean == "ratman den 4") return "rd4";
        if (clean == "ratman den 5") return "rd5";
        if (clean == "ratman den 6") return "rd6";
        if (clean == "ratman den 7") return "rd7";
        return (clean.length() > 0) ? clean : "ap_btn"; 
    }

    void RunButtonScenarioCheck(string buttonName) {
        buttonName = buttonName.trim();
        if (buttonName == "rd1") ArchipelagoLog("button_check:Ratman Den 1"); else if (buttonName == "rd2") ArchipelagoLog("button_check:Ratman Den 2"); else if (buttonName == "rd3") ArchipelagoLog("button_check:Ratman Den 3"); else if (buttonName == "rd4") ArchipelagoLog("button_check:Ratman Den 4"); else if (buttonName == "rd5") ArchipelagoLog("button_check:Ratman Den 5"); else if (buttonName == "rd6") ArchipelagoLog("button_check:Ratman Den 6"); else if (buttonName == "rd7") ArchipelagoLog("button_check:Ratman Den 7"); else ArchipelagoLog("button_check:unknown_" + buttonName);

        CBaseEntity@ holo = EntityList().FindByName(null, buttonName + "_holo");
        if (holo !is null) {
            CBaseAnimating@ anim = cast<CBaseAnimating>(holo);
            if (anim !is null) anim.SetSkin(4);
        }
    }

    void CreateAPButton(string name, Vector position, QAngle angle, float holo_scale, int skin = 0) {
        string scenarioName = TranslateButtonName(name);
        if (scenarioName.locate("rd") == 0) skin = 0;

        // Uniform verification step
        int is_pressed = (m_checkedButtons.find(scenarioName) != -1) ? 1 : 0;
        int finalSkin = (is_pressed == 1) ? 4 : skin;

        // Unique and standardized hologram name for this location
        string holoName = scenarioName + "_holo";

        array<CBaseEntity@> entsToRemove;
        CBaseEntity@ entCheck = null;
        
        while ((@entCheck = EntityList().FindInSphere(entCheck, position, 24.0f)) !is null) {
            string cls = entCheck.GetClassname();
            string entName = entCheck.GetEntityName();
            
            // If the model already exists, update the existing hologram skin and skip re-creation
            if (entName == scenarioName + "_model") {
                CBaseEntity@ holo = null;
                while ((@holo = EntityList().FindByClassname(holo, "prop_dynamic")) !is null) {
                    if (holo.GetMoveParent() is entCheck && holo.GetEntityName() == holoName) {
                        CBaseAnimating@ animHolo = cast<CBaseAnimating>(holo);
                        if (animHolo !is null) animHolo.SetSkin(finalSkin);
                        break;
                    }
                }
                return;
            }
            
            if (cls.locate("button") != uint(-1) || cls.locate("switch") != uint(-1) || cls.locate("dynamic") != uint(-1)) {
                entsToRemove.insertLast(entCheck); 
            }
        }

        // Clean up conflicting overlapping entities
        for (uint i = 0; i < entsToRemove.length(); i++) {
            util::Remove(entsToRemove[i]);
        }

        string uid = "ap_" + RandomInt(1000, 9999);
        
        // Create base button model decoration
        CBaseEntity@ body = util::CreateEntityByName("prop_dynamic");
        if (body !is null) {
            body.KeyValue("targetname", scenarioName + "_model");
            body.SetModel("models/props/switch001.mdl");
            body.KeyValue("solid", "6");
            body.SetAbsOrigin(position);
            body.SetAbsAngles(angle);
            body.Spawn();
            
            if (is_pressed == 1) {
                CBaseAnimating@ animBody = cast<CBaseAnimating>(body);
                if (animBody !is null) {
                    animBody.SetSequence(animBody.LookupSequence("down"));
                }
            }
        }

        // Down Audio Sound Link
        CBaseEntity@ snd_dn = util::CreateEntityByName("ambient_generic");
        if (snd_dn !is null) {
            snd_dn.KeyValue("targetname", uid + "_dn");
            snd_dn.KeyValue("message", "Portal.button_down");
            snd_dn.KeyValue("spawnflags", "48"); 
            snd_dn.SetAbsOrigin(position);
            snd_dn.Spawn();
            snd_dn.SetParent(body, -1);
        }

        // Up Audio Sound Link
        CBaseEntity@ snd_up = util::CreateEntityByName("ambient_generic");
        if (snd_up !is null) {
            snd_up.KeyValue("targetname", uid + "_up");
            snd_up.KeyValue("message", "Portal.button_up");
            snd_up.KeyValue("spawnflags", "48"); 
            snd_up.SetAbsOrigin(position);
            snd_up.Spawn();
            snd_up.SetParent(body, -1);
        }

        // Core Trigger Button Object (Logical Entity)
        CBaseEntity@ brain = util::CreateEntityByName("func_rot_button");
        if (brain !is null) {
            brain.KeyValue("targetname", scenarioName);
            
            int spawnFlags = 1025;
            if (is_pressed == 1) {
                spawnFlags += 2048; 
            }
            brain.KeyValue("spawnflags", "" + spawnFlags);
            brain.KeyValue("wait", "0.5");
            brain.SetModel("models/props/switch001.mdl");
            brain.KeyValue("rendermode", "10");
        
            SafeAddOutput(brain, "OnPressed", "InitCmd", "Command", "ReportAPButton " + scenarioName, 0.1f, -1);
            SafeAddOutput(brain, "OnPressed", holoName, "Skin", "4", 0.0f, -1);
            SafeAddOutput(brain, "OnPressed", "!parent", "SetAnimation", "down", 0.0f, -1);
            SafeAddOutput(brain, "OnPressed", "!parent", "SetAnimation", "up", 0.5f, -1);
            SafeAddOutput(brain, "OnPressed", uid + "_dn", "PlaySound", "", 0.0f, -1);
            SafeAddOutput(brain, "OnPressed", uid + "_up", "PlaySound", "", 0.5f, -1);
        
            brain.SetSolid(SOLID_BBOX);
            brain.SetCollisionBounds(Vector(-30.0f, -30.0f, -30.0f), Vector(30.0f, 30.0f, 30.0f));
            
            brain.Spawn();
            brain.SetParent(body, -1);
            brain.SetLocalOrigin(Vector(0, 0, 0)); 
            
            if (is_pressed == 1) {
                brain.KeyValue("m_bLocked", 1);
            }
        }

        Vector localPos = Vector(0, 0, 90.0f);
        QAngle localAng = QAngle(0, 90, 0);

        CreateAPHologram(localPos, localAng, holo_scale, body, "", finalSkin, holoName, true);
    }


    // =============================================================
    // VITRIFIED DOOR CHECKS
    // =============================================================

    void InitVitrifiedDoorRegistry() {
        m_vitrifiedDoorNames.deleteAll();
        m_vitrifiedDoorNames["sp_a3_03:dummy_chamber_button"] = "Vitrified Door 1";
        m_vitrifiedDoorNames["sp_a3_03:dummy_chamber_button2"] = "Vitrified Door 2";
        m_vitrifiedDoorNames["sp_a3_03:dummy_chamber_button3"] = "Vitrified Door 3";
        m_vitrifiedDoorNames["sp_a3_transition01:dummy_chamber_button"] = "Vitrified Door 4";
        m_vitrifiedDoorNames["sp_a3_transition01:dummy_chamber_button2"] = "Vitrified Door 5";
        m_vitrifiedDoorNames["sp_a3_transition01:dummy_chamber_button3"] = "Vitrified Door 6";
    }

    void AddVitrifiedDoorChecks(string mapName) {
        VerifyMapChange();

        for (int i = int(m_activeLocations.length()) - 1; i >= 0; i--) {
            VitrifiedDoorLocation@ doorLoc = cast<VitrifiedDoorLocation>(m_activeLocations[i]);
            if (doorLoc !is null) {
                m_activeLocations.removeAt(i);
            }
        }

        InitVitrifiedDoorRegistry();
        
        array<string>@ keys = m_vitrifiedDoorNames.getKeys();
        for (uint i = 0; i < keys.length(); i++) {
            string key = keys[i];
            if (key.locate(mapName + ":") == 0) {
                string entName = key.substr(mapName.length() + 1);
                string checkName;
                m_vitrifiedDoorNames.get(key, checkName);
            
                CBaseEntity@ ent = null;
                CBaseEntity@ searchEnt = null;
                string lowerEntName = entName.tolower();
                const array<string> searchClasses = {"func_button", "func_rot_button", "prop_button", "prop_dynamic"};
                for (uint c = 0; c < searchClasses.length(); c++) {
                    @searchEnt = null;
                    while ((@searchEnt = EntityList().FindByClassname(searchEnt, searchClasses[c])) !is null) {
                        string nameLower = searchEnt.GetEntityName().tolower();
                        uint idx = nameLower.locate(lowerEntName);
                        if (idx != uint(-1) && (idx + lowerEntName.length() == nameLower.length())) {
                            @ent = searchEnt;
                            break;
                        }
                    }
                    if (ent !is null) break;
                }
                if (ent !is null) {
                    int doorIndex = 0;
                    if (checkName.locate("Vitrified Door 1") != uint(-1)) doorIndex = 1; else if (checkName.locate("Vitrified Door 2") != uint(-1)) doorIndex = 2; else if (checkName.locate("Vitrified Door 3") != uint(-1)) doorIndex = 3; else if (checkName.locate("Vitrified Door 4") != uint(-1)) doorIndex = 4; else if (checkName.locate("Vitrified Door 5") != uint(-1)) doorIndex = 5; else if (checkName.locate("Vitrified Door 6") != uint(-1)) doorIndex = 6;

                    g_Archipelago.SafeAddOutput(ent, "OnPressed", "InitCmd", "Command", "PrintItem " + checkName, 0.0f, 1);
                
                    if (doorIndex > 0) {
                        g_Archipelago.SafeAddOutput(ent, "OnPressed", "InitCmd", "Command", "ArchipelagoVitrifiedFound " + doorIndex, 0.0f, 1);
                    }
                    g_Archipelago.SafeAddOutput(ent, "OnPressed", entName + "_holo", "Skin", "4", 0.0f, 1);
                
                    Vector hPos(0, 0, 0);
                    QAngle hAng(0, 0, 0);
                    int hSkin = 0;
                    float hScale = 1.0f;
                    bool hParent = false;
                    bool hAbs = false;
                    g_Archipelago.GetHologramManager().GetHologramVisualOverrides(ent, hPos, hAng, hSkin, hScale, hParent, hAbs);

                    if (doorIndex > 0 && m_checkedVitrifiedDoors.find(checkName) != -1) {
                        hSkin = 4;
                    }

                    Vector finalPos = ent.GetAbsOrigin() + (AnglesToForward(ent.GetAbsAngles()) * hPos.x) + (AnglesToRight(ent.GetAbsAngles()) * -hPos.y) + (AnglesToUp(ent.GetAbsAngles()) * hPos.z);
                    QAngle finalAng = hAbs ? hAng : (ent.GetAbsAngles() + hAng);

                    CreateAPHologram(finalPos, finalAng, hScale, null, "", hSkin, entName + "_holo", false);

                    VitrifiedDoorLocation@ doorLoc = VitrifiedDoorLocation(checkName, entName);
                    bool isChecked = (m_checkedVitrifiedDoors.find(checkName) != -1);
                    doorLoc.SetChecked(isChecked);
                    m_activeLocations.insertLast(@doorLoc);
                }
            }
        }
    }

    void SetVitrifiedStatus(array<string> checkedDoors) {
        m_checkedVitrifiedDoors.resize(0);
        for (uint i = 0; i < checkedDoors.length(); i++) {
            m_checkedVitrifiedDoors.insertLast("Vitrified Door " + checkedDoors[i]);
        }
        
        for (uint i = 0; i < m_activeLocations.length(); i++) {
            VitrifiedDoorLocation@ doorLoc = cast<VitrifiedDoorLocation>(m_activeLocations[i]);
            if (doorLoc !is null) {
                bool isChecked = (m_checkedVitrifiedDoors.find(doorLoc.GetName()) != -1);
                doorLoc.SetChecked(isChecked);
            }
        }
    }

    // =============================================================
    // WHEATLEY MONITOR CHECKS
    // =============================================================

    void InitMonitorData() {
        if (m_screenNames.getKeys().length() > 0) return;

        dictionary sp_a4_tb_intro;
        sp_a4_tb_intro.set("monitor1-relay_break", "sp_a4_tb_intro");
        m_screenNames.set("sp_a4_tb_intro", sp_a4_tb_intro);

        dictionary sp_a4_tb_trust_drop;
        sp_a4_tb_trust_drop.set("monitor1-relay_break", "sp_a4_tb_trust_drop");
        m_screenNames.set("sp_a4_tb_trust_drop", sp_a4_tb_trust_drop);

        dictionary sp_a4_tb_wall_button;
        sp_a4_tb_wall_button.set("wheatley_monitor-relay_break", "sp_a4_tb_wall_button");
        m_screenNames.set("sp_a4_tb_wall_button", sp_a4_tb_wall_button);

        dictionary sp_a4_tb_polarity;
        sp_a4_tb_polarity.set("monitor1-relay_break", "sp_a4_tb_polarity");
        m_screenNames.set("sp_a4_tb_polarity", sp_a4_tb_polarity);

        dictionary sp_a4_tb_catch; 
        sp_a4_tb_catch.set("monitor1-relay_break", "sp_a4_tb_catch 1");
        sp_a4_tb_catch.set("monitor2-relay_break", "sp_a4_tb_catch 2");
        m_screenNames.set("sp_a4_tb_catch", sp_a4_tb_catch);

        dictionary sp_a4_stop_the_box;
        sp_a4_stop_the_box.set("wheatley_monitor-relay_break", "sp_a4_stop_the_box");
        m_screenNames.set("sp_a4_stop_the_box", sp_a4_stop_the_box);

        dictionary sp_a4_laser_catapult;
        sp_a4_laser_catapult.set("wheatley_monitor_1-relay_break", "sp_a4_laser_catapult");
        m_screenNames.set("sp_a4_laser_catapult", sp_a4_laser_catapult);

        dictionary sp_a4_laser_platform;
        sp_a4_laser_platform.set("wheatley_monitor_1-relay_break", "sp_a4_laser_platform");
        m_screenNames.set("sp_a4_laser_platform", sp_a4_laser_platform);

        dictionary sp_a4_speed_tb_catch;
        sp_a4_speed_tb_catch.set("wheatley_monitor-relay_break", "sp_a4_speed_tb_catch");
        m_screenNames.set("sp_a4_speed_tb_catch", sp_a4_speed_tb_catch);

        dictionary sp_a4_jump_polarity;
        sp_a4_jump_polarity.set("wheatley_monitor_1-relay_break", "sp_a4_jump_polarity");
        m_screenNames.set("sp_a4_jump_polarity", sp_a4_jump_polarity);

        dictionary sp_a4_finale3;
        sp_a4_finale3.set("wheatley_screen-relay_break", "sp_a4_finale3");
        m_screenNames.set("sp_a4_finale3", sp_a4_finale3);
    }

    void AddWheatleyMonitorBreakCheck() {
        VerifyMapChange();

        for (int i = int(m_activeLocations.length()) - 1; i >= 0; i--) {
            MonitorLocation@ monLoc = cast<MonitorLocation>(m_activeLocations[i]);
            if (monLoc !is null) {
                m_activeLocations.removeAt(i);
            }
        }

        InitMonitorData(); 

        string mapName = g_Archipelago.GetCurrentMap();
        ArchipelagoLog("Running Wheatley monitor break check for map: '" + mapName + "'");

        if (!m_screenNames.exists(mapName)) {
            ArchipelagoLog("Map '" + mapName + "' NOT found in Wheatley monitor dictionary.");
            return;
        }

        dictionary@ mapScreens;
        m_screenNames.get(mapName, @mapScreens);
        if (mapScreens is null) return;

        array<string>@ relayNames = mapScreens.getKeys();
        for (uint r = 0; r < relayNames.length(); r++) {
            string relayName = relayNames[r];
            CBaseEntity@ relay = null;
            while ((@relay = EntityList().FindByName(relay, relayName)) !is null) {
                string checkName;
                mapScreens.get(relayName, checkName);

                g_Archipelago.SafeAddOutput(relay, "OnTrigger", "InitCmd", "Command", "WarpMonitor " + checkName, 0.0f, -1);
                g_Archipelago.SafeAddOutput(relay, "OnTrigger", relayName + "_holo", "Skin", "4", 0.1f, -1);

                int skin = (m_checkedScreens.find(checkName) != -1) ? 4 : 0;

                QAngle angles = relay.GetAbsAngles();
                Vector finalPos = relay.GetAbsOrigin() + (AnglesToRight(angles) * -20.0f) + (AnglesToUp(angles) * 50.0f);
                CreateAPHologram(finalPos, angles, 1.0f, null, "", skin, relayName + "_holo");

                MonitorLocation@ monLoc = MonitorLocation(checkName, relayName);
                bool isChecked = (m_checkedScreens.find(checkName) != -1);
                monLoc.SetChecked(isChecked);
                m_activeLocations.insertLast(@monLoc);
            
                ArchipelagoLog("Attached monitor check '" + checkName + "' to relay '" + relayName + "'");
            }
        }
    }

    void SetCheckedScreens(array<string> parsedScreens) {
        m_checkedScreens.resize(0);
        for (uint i = 0; i < parsedScreens.length(); i++) {
            m_checkedScreens.insertLast(parsedScreens[i]);
        }

        for (uint i = 0; i < m_activeLocations.length(); i++) {
            MonitorLocation@ monLoc = cast<MonitorLocation>(m_activeLocations[i]);
            if (monLoc !is null) {
                bool isChecked = (m_checkedScreens.find(monLoc.GetName()) != -1);
                monLoc.SetChecked(isChecked);
            }
        }
    }
}

} // namespace Archipelago