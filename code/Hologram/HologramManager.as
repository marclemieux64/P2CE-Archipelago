// =============================================================
// ARCHIPELAGO HOLOGRAM MANAGER (OOP VERSION)
// =============================================================

namespace Archipelago {

// Helper class for Cube Visual Overrides
class CubeOverrideData {
    string map_name;
    string entity_substring;
    Vector target_pos;
    QAngle target_ang;
    float target_scale;

    CubeOverrideData(string map, string sub, Vector pos, QAngle ang, float scale) {
        map_name = map;
        entity_substring = sub;
        target_pos = pos;
        target_ang = ang;
        target_scale = scale;
    }
}

// Helper class for Gel Visual Overrides
class GelOverrideData {
    string map_name;
    string entity_substring;
    Vector target_pos;
    QAngle target_ang;
    float target_scale;
    bool should_parent;
    bool absolute_angles;
    int special_mode; 

    GelOverrideData(string map, string sub, Vector pos, QAngle ang, float scale, bool parent, bool abs_ang, int mode) {
        map_name = map;
        entity_substring = sub;
        target_pos = pos;
        target_ang = ang;
        target_scale = scale;
        should_parent = parent;
        absolute_angles = abs_ang;
        special_mode = mode;
    }
}

class HologramManager {
    // --- STATE VARIABLES ---
    private bool m_bInitialTemplateHoloActive;
    private bool m_bConveyor1TemplateHoloActive;
    private bool m_rainbowActive;
    private int m_rainbowR;
    private int m_rainbowG;
    private int m_rainbowB;
    private int m_bts4ConveyorTickCounter;

    // --- OVERRIDES DATABASES ---
    private array<CubeOverrideData@> m_cubeDatabase;
    private array<CubeOverrideData@> m_activeCubeCache;
    private string m_lastCubeCachedMap;
    private bool m_cubeDatabaseInitialized;

    private array<GelOverrideData@> m_gelDatabase;
    private array<GelOverrideData@> m_activeGelCache;
    private string m_lastGelCachedMap;
    private bool m_gelDatabaseInitialized;

    HologramManager() {
        // Initialization performed in Initialize()
    }

    void Initialize() {
        m_bInitialTemplateHoloActive = false;
        m_bConveyor1TemplateHoloActive = false;
        m_rainbowActive = false;
        m_rainbowR = 255;
        m_rainbowG = 0;
        m_rainbowB = 0;
        m_bts4ConveyorTickCounter = 0;

        m_lastCubeCachedMap = "";
        m_cubeDatabaseInitialized = false;

        m_lastGelCachedMap = "";
        m_gelDatabaseInitialized = false;

        InitializeCubeDatabase();
        InitializeGelDatabase();
    }

    // --- GETTERS & SETTERS ---
    bool IsInitialTemplateHoloActive() const { return m_bInitialTemplateHoloActive; }
    void SetInitialTemplateHoloActive(bool active) { m_bInitialTemplateHoloActive = active; }

    bool IsConveyor1TemplateHoloActive() const { return m_bConveyor1TemplateHoloActive; }
    void SetConveyor1TemplateHoloActive(bool active) { m_bConveyor1TemplateHoloActive = active; }

    // =============================================================
    // CORE HOLOGRAM HANDLING
    // =============================================================

    CBaseEntity@ CreateAPHologram(Vector position, QAngle angles, float scale, CBaseEntity@ parent = null, string attachment = "", int skin = 0, string name = "", bool animate = true, float playbackRate = 1.0f) {
        CBaseEntity@ h = null;

        if (name != "") {
            @h = EntityList().FindByName(null, name);
        }

        // Snapshot update for handling game reload state persistence
        if (h !is null) {
            if (h.GetModelName().tolower().locate("archipelago_hologram") != uint(-1)) {
                if (cv_ArchipelagoDebug.GetBool()) {
                    ArchipelagoLog("Updating Hologram '" + name + "' to angles " + angles.x + " " + angles.y + " " + angles.z + " | Skin: " + skin + " | PlaybackRate: " + playbackRate);
                }
            
                // Setup parent attachments
                if (parent !is null) {
                    h.SetParent(parent);
                    h.SetLocalOrigin(position);
                    h.SetLocalAngles(angles);
                
                    if (attachment != "") {
                        Variant v;
                        v.SetString(attachment);
                        h.FireInput("SetParentAttachment", v, 0.01f, null, null, 0);
                    }
                } else {
                    if (h.GetMoveParent() !is null) {
                        h.SetParent(null); 
                    }
                    h.SetAbsOrigin(position);
                    h.SetAbsAngles(angles);
                }
            
                CBaseAnimating@ animH = cast<CBaseAnimating>(h);
                if (animH !is null) {
                    animH.SetSkin(skin);
                    animH.SetPlaybackRate(playbackRate);
                } else {
                    h.KeyValue("skin", "" + skin); 
                }
                h.KeyValue("modelscale", "" + scale);

                // Visibility update based on client ConVars
                int hideOption = cv_ArchipelagoHideHolograms.GetInt();
                bool shouldHide = (hideOption == 2) || (hideOption == 1 && (skin == 4 || skin == 2));
                Variant emptyVal;
                h.KeyValue("rendermode", "0");
                if (shouldHide) {
                    h.FireInput("Disable", emptyVal, 0.0f, null, null, 0);
                } else {
                    h.FireInput("Enable", emptyVal, 0.0f, null, null, 0);
                }

                return h;
            }
        }

        // Initial creation
        @h = util::CreateEntityByName("prop_dynamic");
        if (h !is null) {
            h.KeyValue("model", "models/effects/ap/archipelago_hologram.mdl");
            if (name != "") h.KeyValue("targetname", name);
            h.KeyValue("skin", "" + skin);
            h.KeyValue("modelscale", "" + scale);
            h.KeyValue("DefaultAnim", animate ? "idle" : "");

            if (parent !is null) {
                h.SetAbsOrigin(parent.GetAbsOrigin()); 
                h.SetAbsAngles(parent.GetAbsAngles());
            } else {
                h.SetAbsOrigin(position); 
                h.SetAbsAngles(angles);
            }
        
            h.Spawn(); 

            h.SetSolid(SOLID_NONE);
            h.SetMoveType(MOVETYPE_NONE);

            if (parent !is null) {
                h.SetParent(parent);
                h.SetLocalOrigin(position); 
                h.SetLocalAngles(angles);
            
                if (attachment != "") {
                    Variant v;
                    v.SetString(attachment);
                    h.FireInput("SetParentAttachment", v, 0.01f, null, null, 0);
                }
            }

            CBaseAnimating@ animH = cast<CBaseAnimating>(h);
            if (animH !is null) {
                animH.SetPlaybackRate(playbackRate);
            }

            int hideOption = cv_ArchipelagoHideHolograms.GetInt();
            bool shouldHide = (hideOption == 2) || (hideOption == 1 && (skin == 4 || skin == 2));
            Variant emptyVal;
            h.KeyValue("rendermode", "0");
            if (shouldHide) {
                h.FireInput("Disable", emptyVal, 0.0f, null, null, 0);
            } else {
                h.FireInput("Enable", emptyVal, 0.0f, null, null, 0);
            }
        }
        return h;
    }

    void UpdateHologramsVisibility() {
        CBaseEntity@ ent = null;
        int hideOption = cv_ArchipelagoHideHolograms.GetInt();
    
        while ((@ent = EntityList().FindByClassname(ent, "prop_dynamic")) !is null) {
            if (ent.GetModelName().tolower().locate("archipelago_hologram") != uint(-1)) {
                int skin = 0;
                CBaseAnimating@ anim = cast<CBaseAnimating>(ent);
                if (anim !is null) {
                    skin = anim.GetSkin();
                }
            
                bool shouldHide = (hideOption == 2) || (hideOption == 1 && (skin == 4 || skin == 2));
                Variant emptyVal;
                ent.KeyValue("rendermode", "0");
                if (shouldHide) {
                    ent.FireInput("Disable", emptyVal, 0.0f, null, null, 0);
                } else {
                    ent.FireInput("Enable", emptyVal, 0.0f, null, null, 0);
                }
            }
        }
    }

    void AttachHologramToEntity(string entity_name, string attachment_point, float holo_scale, float offset, int skin = 0) {
        string currentMap = g_Archipelago.GetCurrentMap();
        if (currentMap == "sp_a2_bts4") {
            if (entity_name == "npc_portal_turret_floor" || entity_name == "initial_template_turret") {
                m_bInitialTemplateHoloActive = true;
                cv_BTS4_InitialTemplateHoloActive.SetValue(1);
            }
            if (entity_name == "npc_portal_turret_floor" || entity_name == "turret_conveyor_1_template") {
                m_bConveyor1TemplateHoloActive = true;
                cv_BTS4_Conveyor1TemplateHoloActive.SetValue(1);
            }
        }

        array<CBaseEntity@> targets = FindEntities(entity_name);
        
        for (uint i = 0; i < targets.length(); i++) {
            CBaseEntity@ ent = targets[i]; 
            if (ent is null) continue;

            Vector hPos(0, 0, 0);
            QAngle hAng(0, 0, 0);
            int hSkin = 0;
            float hScale = 1.0f;
            bool hParent = true;
            bool hAbsolute = false;
            
            GetHologramVisualOverrides(ent, hPos, hAng, hSkin, hScale, hParent, hAbsolute);
            
            if (hSkin == 0) hSkin = skin;
            if (hScale == 1.0f) hScale = holo_scale;
            
            Vector verticalOffset(0, 0, offset);
            Vector finalOffset = hPos + verticalOffset;

            // Remove any unique trigger suffix from name
            string cleanName = ent.GetEntityName();
            if (cleanName.locate("&") != uint(-1)) {
                cleanName = cleanName.substr(0, cleanName.locate("&"));
            }
            if (cleanName == "") {
                cleanName = entity_name;
            }
            string holoName = cleanName + "_" + ent.GetEntityIndex() + "_holo";

            if (hAbsolute) {
                Vector worldPos = ent.GetAbsOrigin() + (AnglesToForward(ent.GetAbsAngles()) * finalOffset.x) + (AnglesToRight(ent.GetAbsAngles()) * -finalOffset.y) + (AnglesToUp(ent.GetAbsAngles()) * finalOffset.z);
                CreateAPHologram(worldPos, hAng, hScale, null, "", hSkin, holoName);
            } else {
                if (hParent) {
                    CreateAPHologram(finalOffset, hAng, hScale, ent, attachment_point, hSkin, holoName);
                } else {
                    // Calcul de la position absolue dans le monde avec les offsets locaux pour éviter le parenting direct
                    Vector worldPos = ent.GetAbsOrigin() + (AnglesToForward(ent.GetAbsAngles()) * finalOffset.x) + (AnglesToRight(ent.GetAbsAngles()) * -finalOffset.y) + (AnglesToUp(ent.GetAbsAngles()) * finalOffset.z);
                    QAngle worldAng = ent.GetAbsAngles() + hAng;
                    CreateAPHologram(worldPos, worldAng, hScale, null, "", hSkin, holoName);
                }
            }
        }
    }

    void CreateMapSpecificHolos() {
        string currentMap = g_Archipelago.GetCurrentMap();
        if (currentMap == "sp_a1_intro3") {
            CreateAPHologram(Vector(25, 1958, -250), QAngle(0, 0, 0), 0.66f, null, "", 0, "intro3_portalgun_holo");
        } 
        else if (currentMap == "sp_a2_intro") {
            CBaseEntity@ gun = EntityList().FindByName(null, "player_near_portalgun");
            if (gun !is null) {
                CreateAPHologram(Vector(-1027.680, 449.250, -11010.100), QAngle(0, 0, 0), 0.66f, null, "", 0, "a2_intro_gun_holo");
            }
        } 
        else if (currentMap == "sp_a3_transition01") {
            CBaseEntity@ btn = EntityList().FindByName(null, "sphere_entrance_potatos_button");
            if (btn !is null) {
                CreateAPHologram(Vector(-2920, 414.010, -4500.410), QAngle(0, 0, 0), 0.66f, null, "", 0, "a3_potatos_button_holo");
            }
        }
    
        g_Archipelago.GetCheckManager().AddMapCheck();
        g_Archipelago.GetCheckManager().AddVitrifiedDoorChecks(currentMap);
    }

    // =============================================================
    // DYNAMIC TICK LOGIC FOR CAMPAIGNS
    // =============================================================

    void CleanOrphanRedHolograms() {
        CBaseEntity@ ent = null;
        while ((@ent = EntityList().FindByModel(ent, "models/effects/ap/archipelago_hologram.mdl")) !is null) {
            string name = ent.GetEntityName();
            if (name != "sp_a2_bts4_map_check_holo" && name.locate("_holo") != uint(-1)) {
                if (ent.GetMoveParent() is null) {
                    ArchipelagoLog("Cleaning up orphaned conveyor hologram: " + name);
                    ent.Remove();
                }
            }
        }
    }

    bool DoesHologramExistFor(string substring) {
        CBaseEntity@ ent = null;
        while ((@ent = EntityList().FindByModel(ent, "models/effects/ap/archipelago_hologram.mdl")) !is null) {
            string name = ent.GetEntityName();
            if (name.locate(substring) != uint(-1) && name.locate("_holo") != uint(-1)) {
                return true;
            }
        }
        return false;
    }

    void AP_BTS4_ConveyorTick() {
        g_Archipelago.UpdateInternalMapName();
        if (g_Archipelago.GetCurrentMap() != "sp_a2_bts4") return;

        bool initialActive = cv_BTS4_InitialTemplateHoloActive.GetBool() || DoesHologramExistFor("initial_template_turret");
        bool conveyor1Active = cv_BTS4_Conveyor1TemplateHoloActive.GetBool() || DoesHologramExistFor("turret_conveyor_1");

        m_bInitialTemplateHoloActive = initialActive;
        m_bConveyor1TemplateHoloActive = conveyor1Active;

        m_bts4ConveyorTickCounter++;
        if (m_bts4ConveyorTickCounter % 50 == 0) {
            ArchipelagoLog("Conveyor Tick # " + m_bts4ConveyorTickCounter + " | InitialActive: " + m_bInitialTemplateHoloActive + " | Conveyor1Active: " + m_bConveyor1TemplateHoloActive);
        }

        if (m_bInitialTemplateHoloActive || m_bConveyor1TemplateHoloActive) {
            CleanOrphanRedHolograms();
        } else {
            cv_BTS4_InitialTemplateHoloActive.SetValue(0);
            cv_BTS4_Conveyor1TemplateHoloActive.SetValue(0);

            CBaseEntity@ ent = null;
            while ((@ent = EntityList().FindByClassname(ent, "npc_portal_turret_floor")) !is null) {
                if (IsConveyorTurret(ent)) {
                    ent.KeyValue("PickupEnabled", "1");
                }
            }
            @ent = null;
            while ((@ent = EntityList().FindByModel(ent, "models/effects/ap/archipelago_hologram.mdl")) !is null) {
                string name = ent.GetEntityName();
                if (name != "sp_a2_bts4_map_check_holo" && name.locate("_holo") != uint(-1)) {
                    ent.Remove();
                }
            }
            return;
        }

        CBaseEntity@ ent = null;
        while ((@ent = EntityList().FindByClassname(ent, "npc_portal_turret_floor")) !is null) {
            if (IsConveyorTurret(ent)) {
                string name = ent.GetEntityName();
                bool isConveyor1 = false;
                float dist = ent.GetAbsOrigin().DistTo(Vector(1824, -7024, 6655.830f));
                if (name.locate("turret_conveyor_1") != uint(-1) || dist < 300.0f) {
                    isConveyor1 = true;
                }

                bool shouldHaveHolo = isConveyor1 ? m_bConveyor1TemplateHoloActive : m_bInitialTemplateHoloActive;

                if (m_bts4ConveyorTickCounter % 50 == 0) {
                    ArchipelagoLog("Conveyor Turret: " + name + " | Dist: " + dist + " | isConveyor1: " + isConveyor1 + " | shouldHaveHolo: " + shouldHaveHolo);
                }

                if (shouldHaveHolo) {
                    ent.KeyValue("PickupEnabled", "0");

                    string cleanName = name;
                    if (cleanName.locate("&") != uint(-1)) {
                        cleanName = cleanName.substr(0, cleanName.locate("&"));
                    }
                    if (cleanName == "" || cleanName.tolower().locate("npc_portal_turret") != uint(-1) || cleanName.tolower().locate("prop_dynamic") != uint(-1)) {
                        cleanName = isConveyor1 ? "turret_conveyor_1_template" : "initial_template_turret";
                    }
                    string holoName = cleanName + "_" + ent.GetEntityIndex() + "_holo";

                    CBaseEntity@ existingHolo = EntityList().FindByName(null, holoName);
                    if (existingHolo is null) {
                        ArchipelagoLog("Spawning hologram for: " + name + " -> " + holoName + " parented to ent index " + ent.GetEntityIndex());
                        Vector finalOffset(0, 0, 80.0f);
                        QAngle hAng(0, 0, 0);
                        CreateAPHologram(finalOffset, hAng, 0.66f, ent, "", 2, holoName);
                    }
                }
            }
        }
    }

    void Finale2TurretTick() {
        if (g_Archipelago.GetCurrentMap() != "sp_a4_finale2") return;

        CBaseEntity@ ent = null;
        while ((@ent = EntityList().FindByClassname(ent, "prop_dynamic")) !is null) {
            string model = ent.GetModelName().tolower();
            if (model.locate("archipelago_hologram") != uint(-1)) {
                string name = ent.GetEntityName().tolower();
                if (name.locate("turret") != uint(-1) && name.locate("_holo") != uint(-1)) {
                    CBaseAnimating@ anim = cast<CBaseAnimating>(ent);
                    if (anim !is null && anim.GetSkin() == 1) {
                        anim.SetSkin(2);
                    }
                }
            }
        }
    }

    // =============================================================
    // HOLOGRAM VISUAL OVERRIDES
    // =============================================================

    void GetHologramVisualOverrides(CBaseEntity@ ent, Vector&out targetPos, QAngle&out targetAng, int&out targetSkin, float&out targetScale, bool&out shouldParent, bool&out absoluteAngles) {
        targetPos = Vector(0, 0, 0);
        targetAng = QAngle(0, 0, 0);
        targetSkin = 4; // Default Archipelago rusty skin
        targetScale = 1.0f;
        shouldParent = false;
        absoluteAngles = false;

        if (ent is null) return;
        
        string classname = ent.GetClassname();
        string model = ent.GetModelName().tolower();
        
        string name = ent.GetEntityName();
        if (name == "") {
            string shortModelName = ent.GetModelName().tolower();
            int lastSlash = -1;
            int len = shortModelName.length();
            for (int c = len - 1; c >= 0; c--) {
                if (shortModelName[c] == 47) { lastSlash = c; break; }
            }
            if (lastSlash != -1) name = shortModelName.substr(lastSlash + 1); else name = shortModelName;
        }
        string name_lower = name.tolower();

        string mapName = g_Archipelago.GetCurrentMap();

        // Règle explicite pour les caméras de sécurité afin d'empêcher tout rattachement physique accidentel
        if (classname == "npc_security_camera") {
            targetPos = Vector(0.0f, 0.0f, 0.0f);
            targetAng = QAngle(0.0f, 0.0f, 0.0f);
            targetSkin = 0;
            targetScale = 0.6f;
            shouldParent = false;
            absoluteAngles = false; // Sera géré proprement sans liaison dynamique par le correctif de l'émetteur
            return;
        }

        if (mapName == "sp_a3_crazy_box") {
            if (name_lower == "erase_blocker_button" || model.locate("underground_testchamber_button") != uint(-1)) {
                targetPos = Vector(45.0f, 0.0f, 25.0f);
                targetAng = QAngle(90.0f, 0.0f, 0.0f); 
                targetSkin = 4;
                targetScale = 0.66f;
                shouldParent = false;
                absoluteAngles = false;
                return;
            }
        }

        if (mapName == "sp_a2_bts1") {
            if ((name_lower.locate("button") != uint(-1) || model.locate("button") != uint(-1) || classname.locate("button") != uint(-1)) && 
                classname.locate("floor") == uint(-1) && model.locate("floor") == uint(-1) && name_lower.locate("floor") == uint(-1)) {
                
                targetPos = Vector(45.0f, 0.0f, 25.0f);
                targetAng = ent.GetAbsAngles();
                targetAng.x += 90.0f;
                targetSkin = 4;
                targetScale = 0.66f;
                shouldParent = false;
                absoluteAngles = true;
                return;
            }
        }

        if (classname == "npc_portal_turret_floor") {
            targetPos = Vector(0.0f, 0.0f, 60.0f);
            targetSkin = 2; 
            shouldParent = true;
            return;
        }

        // Cubes handling
        if (classname == "prop_weighted_cube" || model.locate("metal_box") != uint(-1) || model.locate("box") != uint(-1) || model.locate("cube") != uint(-1) || model.locate("reflection") != uint(-1) || model.locate("mp_ball") != uint(-1) || model.locate("underground_weighted_cube") != uint(-1) || name_lower.locate("metal_box") != uint(-1) || name_lower.locate("entity_box_maker_rm1") != uint(-1) || name_lower.locate("cube_dropper_box_spawner") != uint(-1) || name_lower.locate("laser_cube_spawner") != uint(-1) || name_lower.locate("reflection_cube") != uint(-1)) {
            OverrideCube(name, ent, targetPos, targetAng, targetSkin, targetScale, shouldParent, absoluteAngles);
            return; 
        }

        // Gels handling
        if (classname == "info_paint_sprayer" || classname == "prop_paint_bomb" || classname == "paint_sphere" || name_lower.locate("trigger_to_drop") != uint(-1) || name_lower.locate("template_artillery") != uint(-1) || (name_lower.locate("paint") != uint(-1) && name_lower.locate("panel") == uint(-1))) {
            OverrideGel(name, ent, targetPos, targetAng, targetSkin, targetScale, shouldParent, absoluteAngles);
            return;
        }

        // Dummy buttons handling
        if (name_lower.locate("dummy_chamber_button") != uint(-1)) {
            targetSkin = 0;
            targetScale = 1.0f;
            shouldParent = true;
            absoluteAngles = true; 

            uint idx = name_lower.locate("dummy_chamber_button");
            uint idx2 = name_lower.locate("dummy_chamber_button2");
            uint idx3 = name_lower.locate("dummy_chamber_button3");

            bool is_btn1 = (idx != uint(-1) && (idx + 20 == name_lower.length()));
            bool is_btn2 = (idx2 != uint(-1) && (idx2 + 21 == name_lower.length()));
            bool is_btn3 = (idx3 != uint(-1) && (idx3 + 21 == name_lower.length()));

            if (is_btn1) {
                if (mapName == "sp_a3_03") { targetPos = Vector(-6.0f, -44.0f, -34.5f); targetAng = QAngle(0, 90, 0); } else if (mapName == "sp_a3_transition01") { targetPos = Vector(44.0f, -6.0f, -34.5f); targetAng = QAngle(0, 180, 0); }
            } else if (is_btn2) {
                if (mapName == "sp_a3_03") { targetPos = Vector(-6.0f, -44.0f, -34.5f); targetAng = QAngle(0, 90, 0); } else if (mapName == "sp_a3_transition01") { targetPos = Vector(-44.0f, -6.0f, -34.5f); targetAng = QAngle(0, 180, 0); }
            } else if (is_btn3) {
                if (mapName == "sp_a3_03") { targetPos = Vector(-44.0f, 5.5f, -34.5f); targetAng = QAngle(0, 0, 0); } else if (mapName == "sp_a3_transition01") { targetPos = Vector(-4.05f, -45.0f, -34.5f); targetAng = QAngle(0, -90, 0); }
            }
            return;
        }

        if (model.locate("glados_screenborder_curve.mdl") != uint(-1)) {
            targetPos = Vector(30.0f, 0.0f, 100.0f);
            targetAng = QAngle(0.0f, 0.0f, 0.0f); 
            targetSkin = 0;
            targetScale = 1.0f;
            shouldParent = true;  
            absoluteAngles = false; 
            return;
        }

        if (classname.locate("core") != uint(-1) || name_lower.locate("core") != uint(-1) || model.locate("personality_sphere") != uint(-1)) {
            if (name.locate("1") != uint(-1)) targetSkin = 6; else if (name.locate("2") != uint(-1)) targetSkin = 5; else if (name.locate("3") != uint(-1)) targetSkin = 3; else targetSkin = 4;
            targetPos = Vector(0, 0, 0.0f);
            targetAng = QAngle(0, 0, 0);
            absoluteAngles = true;
            shouldParent = false;
            targetScale = 1.0f;
            return;
        }

        if (model.locate("faith_plate") != uint(-1)) {
            targetScale = 1.0f;
            targetPos = Vector(0, 0, 30.0f);
            return;
        }
        
        if (classname == "prop_wall_projector") {
            OverrideProjector(mapName, ent, targetPos, targetAng, targetSkin, targetScale, shouldParent, absoluteAngles);
            return;
        }

        if (classname == "prop_monster_box") {
            targetPos = Vector(0, 0, 32.0f);
            targetScale = 0.66f;
            shouldParent = true;
            absoluteAngles = true;
            return;
        } 

        if (classname.locate("env_portal_laser") != uint(-1) || classname.locate("prop_laser_relay") != uint(-1) || classname.locate("prop_laser_catcher") != uint(-1)) {
            shouldParent = false;
            absoluteAngles = true;
            targetScale = 0.66f;
            targetSkin = 4;

            Vector forward, right, up;
            AngleVectors(ent.GetAbsAngles(), forward, right, up);

            Vector worldPos;
            if (classname.locate("prop_laser_relay") != uint(-1)) {
                worldPos = ent.GetAbsOrigin() + (up * 32.0f);
            } else {
                worldPos = ent.GetAbsOrigin() + (forward * 32.0f);
            }

            targetPos = worldPos - ent.GetAbsOrigin();

            if (classname.locate("prop_laser_relay") != uint(-1)) {
                targetAng = ent.GetAbsAngles();
            } else {
                VectorAngles(up, forward, targetAng);
            }
            return;
        } 

        if (classname.locate("button") != uint(-1)) {
            shouldParent = true;
            if (classname.locate("floor") != uint(-1) || model.locate("floor_button") != uint(-1)) {
                targetPos = Vector(0, 0, 50.0f);
            } else {
                targetPos = Vector(0, 0, 70.0f);
                targetScale = 0.66f;
            }
            return;
        } 

        if (classname == "prop_tractor_beam" || classname == "prop_excursion_funnel") {
            targetSkin = 4;
            targetPos = Vector(80.0f, 0, 0); 
            targetAng = QAngle(90.0f, 0, 0); 
            return;
        }
    }

    void OverrideCube(const string&in name, CBaseEntity@ ent, Vector&out targetPos, QAngle&out targetAng, int&out targetSkin, float&out targetScale, bool&out shouldParent, bool&out absoluteAngles) {
        targetPos = Vector(0, 0, 0);
        targetAng = QAngle(0, 0, 0);
        targetSkin = 4;
        targetScale = 0.8f;   
        shouldParent = false;
        absoluteAngles = true;

        UpdateActiveCubeCache();
        uint cacheSize = m_activeCubeCache.length();
        if (cacheSize == 0) return;

        string lowerName = name.tolower();
        for (uint i = 0; i < cacheSize; i++) {
            if (lowerName.locate(m_activeCubeCache[i].entity_substring) != uint(-1)) {
                targetPos = m_activeCubeCache[i].target_pos;
                targetAng = m_activeCubeCache[i].target_ang;
                targetScale = m_activeCubeCache[i].target_scale;
                return; 
            }
        }
    }

    void OverrideGel(const string&in name, CBaseEntity@ ent, Vector&out targetPos, QAngle&out targetAng, int&out targetSkin, float&out targetScale, bool&out shouldParent, bool&out absoluteAngles) {
        targetPos = Vector(0, 0, 0);
        targetAng = QAngle(180, 0, 0);
        targetSkin = 4;
        targetScale = 1.0f;
        shouldParent = false;
        absoluteAngles = false;

        UpdateActiveGelCache();
        uint cacheSize = m_activeGelCache.length();
        if (cacheSize == 0) return;

        string lowerName = name.tolower();

        for (uint i = 0; i < cacheSize; i++) {
            if (m_activeGelCache[i].entity_substring != "" && lowerName.locate(m_activeGelCache[i].entity_substring) != uint(-1)) {
                if (m_activeGelCache[i].special_mode == 1) {
                    targetPos = ent.GetAbsOrigin();
                    targetAng = QAngle(0, 0, 0);
                } 
                else if (m_activeGelCache[i].special_mode == 2) {
                    targetPos = ent.GetAbsOrigin() + m_activeGelCache[i].target_pos;
                    QAngle nativeAng = ent.GetAbsAngles();
                    targetAng = QAngle(nativeAng.x + 90.0f, nativeAng.y, nativeAng.z);
                } 
                else if (m_activeGelCache[i].special_mode == 3) {
                    targetPos = ent.GetAbsOrigin();
                    targetAng = m_activeGelCache[i].target_ang;
                }
                else {
                    targetPos = m_activeGelCache[i].target_pos;
                    targetAng = m_activeGelCache[i].target_ang;
                }

                targetScale = m_activeGelCache[i].target_scale;
                shouldParent = m_activeGelCache[i].should_parent;
                absoluteAngles = m_activeGelCache[i].absolute_angles;
                return; 
            }
        }

        for (uint i = 0; i < cacheSize; i++) {
            if (m_activeGelCache[i].entity_substring == "") {
                targetPos = m_activeGelCache[i].target_pos;
                targetAng = m_activeGelCache[i].target_ang;
                targetScale = m_activeGelCache[i].target_scale;
                shouldParent = m_activeGelCache[i].should_parent;
                absoluteAngles = m_activeGelCache[i].absolute_angles;
                return;
            }
        }
    }

    void OverrideProjector(string mapName, CBaseEntity@ ent, Vector&out targetPos, QAngle&out targetAng, int&out targetSkin, float&out targetScale, bool&out shouldParent, bool&out absoluteAngles) {
        shouldParent = false;   
        absoluteAngles = true;  
        targetScale = 0.66f;
        targetSkin = 4;

        targetAng = ent.GetAbsAngles();
        targetPos = Vector(0.0f, 0.0f, 16.0f);

        if (mapName == "sp_a2_bridge_intro") {
            targetAng = QAngle(90.0f, 0.0f, 0.0f); 
            targetPos = Vector(16.0f, 0.0f, 8.0f);
        } 
        else if (mapName == "sp_a2_bridge_the_gap") {
            targetAng = QAngle(90.0f, 0.0f, 0.0f); 
            targetPos = Vector(16.0f, 0.0f, 0.0f);
        } 
        else if (mapName == "sp_a2_turret_blocker") {
            targetAng = QAngle(0.0f, 90.0f, 0.0f); 
            targetPos = Vector(16.0f, 0.0f, 0.0f);
        } 
        else if (mapName == "sp_a2_pull_the_rug") {
            targetAng = QAngle(90.0f, 0.0f, 0.0f); 
            targetPos = Vector(16.0f, 0.0f, 0.0f);
        } 
        else if (mapName == "sp_a2_column_blocker") {
            targetAng = QAngle(90.0f, 0.0f, 0.0f); 
            targetPos = Vector(16.0f, 0.0f, 0.0f);
        } 
        else if (mapName == "sp_a2_bts1") {
            targetAng = QAngle(90.0f, 0.0f, 0.0f); 
            targetPos = Vector(16.0f, 0.0f, 0.0f);
        } 
        else if (mapName == "sp_a4_stop_the_box") {
            targetAng = QAngle(0.0f, 90.0f, 0.0f); 
            targetPos = Vector(16.0f, 0.0f, 0.0f);
        }
    }

    private void InitializeCubeDatabase() {
        if (m_cubeDatabaseInitialized) return;

        m_cubeDatabase.insertLast(CubeOverrideData("sp_a1_intro1", "entity_box_maker_rm1", Vector(0, 0, -195), QAngle(180, 0, 0), 1.0f));
        m_cubeDatabase.insertLast(CubeOverrideData("sp_a1_intro1", "cube_dropper_2-cube_dropper_box", Vector(0, 0, -195), QAngle(180, 0, 0), 1.0f));
        m_cubeDatabase.insertLast(CubeOverrideData("sp_a1_intro4", "box_dropper-cube_dropper_box", Vector(0, 0, -500), QAngle(180, 0, 0), 1.0f));
        m_cubeDatabase.insertLast(CubeOverrideData("sp_a1_intro4", "metal_box.mdl_1307_-909_-39", Vector(0, 0, -800), QAngle(0, 0, 0), 0.8f));
        m_cubeDatabase.insertLast(CubeOverrideData("sp_a1_intro5", "cube_dropper_1-cube_dropper_box", Vector(0, 0, -500), QAngle(180, 0, 0), 1.0f));
        m_cubeDatabase.insertLast(CubeOverrideData("sp_a1_intro5", "cube_dropper_2-cube_dropper_box", Vector(0, 0, -500), QAngle(180, 0, 0), 1.0f));
        m_cubeDatabase.insertLast(CubeOverrideData("sp_a1_intro6", "cube_dropper-cube_dropper_box", Vector(0, 0, -500), QAngle(180, 0, 0), 1.0f));
        m_cubeDatabase.insertLast(CubeOverrideData("sp_a1_intro7", "metal_box.mdl", Vector(0, 0, 25), QAngle(0, 0, 90), 0.8f));
        m_cubeDatabase.insertLast(CubeOverrideData("sp_a1_intro7", "reflection_cube.mdl", Vector(0, 0, 25), QAngle(0, 0, 90), 0.8f));
        m_cubeDatabase.insertLast(CubeOverrideData("sp_a2_laser_stairs", "cube_dropper_01-cube_dropper_box", Vector(0, 0, -500), QAngle(180, 0, 0), 1.0f));
        m_cubeDatabase.insertLast(CubeOverrideData("sp_a2_laser_over_goo", "cube_dropper_box", Vector(0, 0, -530), QAngle(180, 0, 0), 1.0f));
        m_cubeDatabase.insertLast(CubeOverrideData("sp_a2_catapult_intro", "cube_dropper-cube_dropper_box", Vector(0, 0, -500), QAngle(180, 0, 0), 1.0f));
        m_cubeDatabase.insertLast(CubeOverrideData("sp_a2_trust_fling", "cube_dropper_box", Vector(0, 0, -530), QAngle(180, 0, 0), 1.0f));
        m_cubeDatabase.insertLast(CubeOverrideData("sp_a2_pit_flings", "cube_dropper-cube_dropper_box", Vector(0, 0, -500), QAngle(180, 0, 0), 1.0f));
        m_cubeDatabase.insertLast(CubeOverrideData("sp_a2_fizzler_intro", "cube_dropper-cube_dropper_box", Vector(0, 0, -500), QAngle(180, 0, 0), 1.0f));
        m_cubeDatabase.insertLast(CubeOverrideData("sp_a2_sphere_peek", "reflectocube_dropper_box", Vector(0, 0, -530), QAngle(180, 0, 0), 1.0f));
        m_cubeDatabase.insertLast(CubeOverrideData("sp_a2_ricochet", "reflecto_cube_dropper-cube_dropper_box", Vector(0, 0, -500), QAngle(180, 0, 0), 1.0f));
        m_cubeDatabase.insertLast(CubeOverrideData("sp_a2_ricochet", "juggled_cube", Vector(0, 0, 35), QAngle(0, 0, 0), 0.8f));
        m_cubeDatabase.insertLast(CubeOverrideData("sp_a2_bridge_intro", "box_dropper_01-cube_dropper_box", Vector(0, 0, -500), QAngle(180, 0, 0), 1.0f));
        m_cubeDatabase.insertLast(CubeOverrideData("sp_a2_bridge_the_gap", "cube_dropper-cube_dropper_box", Vector(0, 0, -500), QAngle(180, 0, 0), 1.0f));
        m_cubeDatabase.insertLast(CubeOverrideData("sp_a2_laser_relays", "laser_cube_spawner", Vector(0, 0, -30), QAngle(0, 0, 0), 0.8f));
        m_cubeDatabase.insertLast(CubeOverrideData("sp_a2_column_blocker", "cube_dropper_1-cube_dropper_box", Vector(0, 0, -500), QAngle(180, 0, 0), 1.0f));
        m_cubeDatabase.insertLast(CubeOverrideData("sp_a2_column_blocker", "cube_dropper_2-cube_dropper_box", Vector(0, 0, -500), QAngle(180, 0, 0), 1.0f));
        m_cubeDatabase.insertLast(CubeOverrideData("sp_a2_bts1", "cube_dropper-cube_dropper_box", Vector(0, 0, -530), QAngle(180, 0, 0), 1.0f));
        m_cubeDatabase.insertLast(CubeOverrideData("sp_a2_bts1", "pre_solved_chamber-box_dropper_01-cube_dropper_box", Vector(0, 0, -500), QAngle(180, 0, 0), 1.0f));
        m_cubeDatabase.insertLast(CubeOverrideData("sp_a3_jump_intro", "cube_dropper_box", Vector(0, 25, -65), QAngle(180, 0, 0), 1.0f));
        m_cubeDatabase.insertLast(CubeOverrideData("sp_a3_speed_flings", "cube_dropper_box", Vector(0, 25, -65), QAngle(180, 0, 0), 1.0f));
        m_cubeDatabase.insertLast(CubeOverrideData("sp_a4_laser_platform", "cube_dropper_box", Vector(0, 0, -500), QAngle(180, 0, 0), 1.0f));
        m_cubeDatabase.insertLast(CubeOverrideData("sp_a4_intro", "cube_dropper_box", Vector(0, 0, -530), QAngle(180, 0, 0), 1.0f));
        m_cubeDatabase.insertLast(CubeOverrideData("sp_a4_tb_intro", "cube_dropper_box", Vector(0, 0, -540), QAngle(180, 0, 0), 1.0f));
        m_cubeDatabase.insertLast(CubeOverrideData("sp_a4_tb_trust_drop", "cube_dropper_box", Vector(0, 0, -540), QAngle(180, 0, 0), 1.0f));
        m_cubeDatabase.insertLast(CubeOverrideData("sp_a4_tb_wall_button", "cube_dropper_box_spawner", Vector(-1540, 0, -500), QAngle(180, 0, 0), 1.0f));
        m_cubeDatabase.insertLast(CubeOverrideData("sp_a4_tb_wall_button", "dropper", Vector(-1540, 0, -500), QAngle(180, 0, 0), 1.0f));
        m_cubeDatabase.insertLast(CubeOverrideData("sp_a4_tb_polarity", "cube_dropper_box", Vector(0, 0, -525), QAngle(180, 0, 0), 1.0f));
        m_cubeDatabase.insertLast(CubeOverrideData("sp_a4_tb_catch", "cube_dropper_box", Vector(0, 0, -525), QAngle(180, 0, 0), 1.0f));
        m_cubeDatabase.insertLast(CubeOverrideData("sp_a4_stop_the_box", "cube_dropper_box", Vector(0, 0, -525), QAngle(180, 0, 0), 1.0f));
        m_cubeDatabase.insertLast(CubeOverrideData("sp_a4_speed_tb_catch", "cube_dropper_box", Vector(0, 0, -525), QAngle(180, 0, 0), 1.0f));
        m_cubeDatabase.insertLast(CubeOverrideData("sp_a4_finale1", "cube_dropper_box", Vector(0, 0, -540), QAngle(180, 0, 0), 1.0f));
        
        m_cubeDatabaseInitialized = true;
    }

    private void UpdateActiveCubeCache() {
        InitializeCubeDatabase();
        string currentMap = g_Archipelago.GetCurrentMap();
        if (currentMap == m_lastCubeCachedMap) return;

        m_activeCubeCache.resize(0);
        m_lastCubeCachedMap = currentMap;
        for (uint i = 0; i < m_cubeDatabase.length(); i++) {
            if (m_cubeDatabase[i].map_name == m_lastCubeCachedMap) {
                m_activeCubeCache.insertLast(m_cubeDatabase[i]);
            }
        }
    }

    private void InitializeGelDatabase() {
        if (m_gelDatabaseInitialized) return;

        m_gelDatabase.insertLast(GelOverrideData("sp_a3_jump_intro", "", Vector(0, 0, 0), QAngle(-90, 0, 0), 1.0f, false, false, 0));
        m_gelDatabase.insertLast(GelOverrideData("sp_a3_bomb_flings", "paint_bomb_maker_-224_-64_656_holo", Vector(0, 0, -85), QAngle(180, 0, 0), 1.0f, false, false, 0));
        m_gelDatabase.insertLast(GelOverrideData("sp_a3_crazy_box", "paint_bomb_template_2240_-896_656_holo", Vector(0, 0, -350.0f), QAngle(180, 0, 0), 1.0f, false, false, 0));
        m_gelDatabase.insertLast(GelOverrideData("sp_a3_crazy_box", "paint_drip1_1716_-1772_714_holo", Vector(25, 0, 0), QAngle(90, 0, 0), 1.0f, false, false, 0));
        m_gelDatabase.insertLast(GelOverrideData("sp_a3_crazy_box", "paint_sprayer_bounce_1280_-1408_1776_holo", Vector(60, 0, 0), QAngle(90, 0, 0), 1.0f, false, false, 0));
        m_gelDatabase.insertLast(GelOverrideData("sp_a3_speed_ramp", "paint_sprayer_576_0_704_holo", Vector(0, 0, -5000.0f), QAngle(180, 0, 0), 0.0f, false, false, 0));
        m_gelDatabase.insertLast(GelOverrideData("sp_a3_speed_ramp", "paint_sprayer_576_0_696_holo", Vector(120, 0, 0), QAngle(90, 0, 0), 1.0f, false, false, 0));
        m_gelDatabase.insertLast(GelOverrideData("sp_a3_speed_ramp", "paint_sprayer_2_-1600_-896_960_holo", Vector(65, 0, 0), QAngle(90, 0, 0), 1.0f, false, false, 0));
        m_gelDatabase.insertLast(GelOverrideData("sp_a3_speed_ramp", "paint_sprayer_3_-1600_-384_960_holo", Vector(65, 0, 0), QAngle(90, 0, 0), 1.0f, false, false, 0));
        m_gelDatabase.insertLast(GelOverrideData("sp_a3_speed_flings", "paint_sprayer_bounce_2816_-128_320_holo", Vector(260, 0, 0), QAngle(90, 0, 0), 1.0f, false, false, 0));
        m_gelDatabase.insertLast(GelOverrideData("sp_a3_speed_flings", "paint_sprayer_speed_2560_-128_-152_holo", Vector(10, 0, 0), QAngle(90, 0, 0), 1.0f, false, false, 0));
        m_gelDatabase.insertLast(GelOverrideData("sp_a3_portal_intro", "pump_machine_white_sprayer_1908_1712_-1984_holo", Vector(15, 0, 0), QAngle(-90, 0, 0), 1.0f, false, false, 0));
        m_gelDatabase.insertLast(GelOverrideData("sp_a3_portal_intro", "pump_machine_blue_sprayer_1088_1712_-2068_holo", Vector(10, 0, 0), QAngle(90, 0, 0), 1.0f, false, false, 0));
        m_gelDatabase.insertLast(GelOverrideData("sp_a3_portal_intro", "_-1680_holo", Vector(0, 0, -10), QAngle(0, 270, 0), 1.0f, false, false, 0));
        m_gelDatabase.insertLast(GelOverrideData("sp_a3_portal_intro", "_-1672_holo", Vector(25, 0, 0), QAngle(-90, 0, 0), 1.0f, false, false, 0));
        m_gelDatabase.insertLast(GelOverrideData("sp_a3_portal_intro", "_-1728_holo", Vector(0, 0, 35), QAngle(0, 270, 0), 1.0f, false, false, 0));
        m_gelDatabase.insertLast(GelOverrideData("sp_a3_portal_intro", "_-1704_holo", Vector(0, 0, 10), QAngle(0, 270, 0), 1.0f, false, false, 0));
        m_gelDatabase.insertLast(GelOverrideData("sp_a3_portal_intro", "_-1712_holo", Vector(0, 0, 20), QAngle(0, 270, 0), 1.0f, false, false, 0));
        m_gelDatabase.insertLast(GelOverrideData("sp_a3_portal_intro", "paint_sprayer_1_32_99_144_holo", Vector(0, 0, 0), QAngle(0, 0, 0), 1.0f, false, true, 1)); 
        m_gelDatabase.insertLast(GelOverrideData("sp_a3_portal_intro", "paint_sprayer_2_287_192_292_holo", Vector(-80.0f, 0.0f, -80.0f), QAngle(90.0f, 0.0f, 0.0f), 1.0f, false, true, 2)); 
        m_gelDatabase.insertLast(GelOverrideData("sp_a3_end", "paint_trickle_blue_1", Vector(35, 0, -10), QAngle(90, 0, 0), 1.0f, false, false, 0));
        m_gelDatabase.insertLast(GelOverrideData("sp_a3_end", "paint_trickle_white_2", Vector(50, 0, 0), QAngle(90, 0, 0), 1.0f, false, false, 0));
        m_gelDatabase.insertLast(GelOverrideData("sp_a3_end", "paint_trickle", Vector(35, 0, 0), QAngle(90, 0, 0), 1.0f, false, false, 0));
        m_gelDatabase.insertLast(GelOverrideData("sp_a3_end", "paint_duct", Vector(0, 0, 0), QAngle(90, -90, 0), 1.0f, false, true, 3)); 
        m_gelDatabase.insertLast(GelOverrideData("sp_a4_speed_tb_catch", "autoinstance1-paint_sprayer_256_1376_552_holo", Vector(135, 0, 0), QAngle(90, 0, 0), 1.0f, false, false, 0));
        m_gelDatabase.insertLast(GelOverrideData("sp_a4_jump_polarity", "paint_mesilly_1902_65_188_holo", Vector(0, 0, 0), QAngle(0, 0, 0), 1.0f, false, false, 0));
        m_gelDatabase.insertLast(GelOverrideData("sp_a4_jump_polarity", "paint_mesilly_1742_-62_140_holo", Vector(0, 0, 0), QAngle(0, 0, 0), 1.0f, false, false, 0));
        m_gelDatabase.insertLast(GelOverrideData("sp_a4_jump_polarity", "paint_sprayer_-576_-64_640_holo", Vector(320, 0, 0), QAngle(90, 0, 0), 1.0f, false, false, 0));
        m_gelDatabase.insertLast(GelOverrideData("sp_a4_finale1", "paint_sprayer_portal_", Vector(0, 0, 0), QAngle(-90, 0, 0), 1.0f, false, false, 0));
        m_gelDatabase.insertLast(GelOverrideData("sp_a4_finale1", "platform_sprayer", Vector(0, 0, 0), QAngle(0, 0, 0), 1.0f, false, false, 0));
        m_gelDatabase.insertLast(GelOverrideData("sp_a4_finale2", "paint_sprayer_jump_-1710_", Vector(0, 0, 0), QAngle(-90, 0, 0), 1.0f, false, false, 0));
        m_gelDatabase.insertLast(GelOverrideData("sp_a4_finale2", "trigger_to_drop", Vector(0, 0, -5000.0f), QAngle(0, 0, 0), 0.0f, false, true, 0));
        m_gelDatabase.insertLast(GelOverrideData("sp_a4_finale2", "template_artillery", Vector(0, 0, -5000.0f), QAngle(0, 0, 0), 0.0f, false, true, 0));
        m_gelDatabase.insertLast(GelOverrideData("sp_a4_finale2", "bomb_", Vector(0, 0, 215.0f), QAngle(180, 0, 0), 1.0f, false, false, 0));
        m_gelDatabase.insertLast(GelOverrideData("sp_a4_finale3", "practice_paint_sprayer_", Vector(100, 100, 0), QAngle(90, 0, 90), 1.0f, false, false, 0));
        m_gelDatabase.insertLast(GelOverrideData("sp_a4_finale3", "paint_sprayer_2_-960_113_-70_holo", Vector(135, 0, 145), QAngle(0, 0, 0), 1.0f, false, false, 0));
        m_gelDatabase.insertLast(GelOverrideData("sp_a4_finale3", "", Vector(0, 0, -5000.0f), QAngle(0, 0, 0), 0.0f, false, false, 0)); 
        m_gelDatabase.insertLast(GelOverrideData("sp_a4_finale4", "_160_", Vector(0, 0, -500.0f), QAngle(0, 0, 0), 0.0f, false, true, 0));
        m_gelDatabase.insertLast(GelOverrideData("sp_a4_finale4", "paint_blue_sprayer_-544_-16_320_holo", Vector(0, 0, 0), QAngle(0, -90, 0), 1.0f, false, false, 0));
        m_gelDatabase.insertLast(GelOverrideData("sp_a4_finale4", "pipe_bounce_paint_bomb_template1_", Vector(90, 0, 0), QAngle(90, 0, 0), 1.0f, false, false, 0));
        m_gelDatabase.insertLast(GelOverrideData("sp_a4_finale4", "toxin_paint_sprayer_882_256_192_holo", Vector(105, 135, 0), QAngle(0, -90, 0), 1.0f, false, false, 0));
        m_gelDatabase.insertLast(GelOverrideData("sp_a4_finale4", "_728_-368_60_", Vector(0, 0, 0), QAngle(0, 0, -90), 1.0f, false, false, 0));
        m_gelDatabase.insertLast(GelOverrideData("sp_a4_finale4", "_752_-368_184_", Vector(0, 0, 0), QAngle(0, 90, 0), 1.0f, false, false, 0));
        m_gelDatabase.insertLast(GelOverrideData("sp_a4_finale4", "_240_0_64_", Vector(0, 0, -55), QAngle(0, 0, 0), 1.0f, false, false, 0));
        m_gelDatabase.insertLast(GelOverrideData("sp_a4_finale4", "_448_64_64_", Vector(0, 0, -55), QAngle(0, 0, 0), 1.0f, false, false, 0));
        m_gelDatabase.insertLast(GelOverrideData("sp_a4_finale4", "_544_-360_32_", Vector(0, 0, -10), QAngle(0, 0, 0), 1.0f, false, false, 0));
        m_gelDatabase.insertLast(GelOverrideData("sp_a4_finale4", "_240_144_24_", Vector(0, 0, -10), QAngle(0, 0, 0), 1.0f, false, false, 0));
        m_gelDatabase.insertLast(GelOverrideData("sp_a4_finale4", "_0_256_8_", Vector(0, 0, -10), QAngle(0, 0, 0), 1.0f, false, false, 0));

        array<string> eventSpheres = {
            "_329_-315_443_", "_0_-403_443_", "_0_-325_578_", "_-290_-247_578_", "_-346_775_578_", "_329_827_443_", "_503_546_578_"
        };
        for (uint s = 0; s < eventSpheres.length(); s++) {
            m_gelDatabase.insertLast(GelOverrideData("sp_a4_finale4", eventSpheres[s], Vector(0, 0, 0), QAngle(0, 0, -90), 1.0f, false, false, 0));
        }

        array<string> whiteSpheres = {
            "paint_white_event_sphere1_", "paint_white_event_sphere2_", "paint_white_event_sphere4_", "paint_white_event_sphere5_", 
            "paint_white_event_sphere7_", "paint_white_event_sphere8_", "paint_white_event_sphere10_"
        };
        for (uint w = 0; w < whiteSpheres.length(); w++) {
            m_gelDatabase.insertLast(GelOverrideData("sp_a4_finale4", whiteSpheres[w], Vector(0, 0, 0), QAngle(0, 0, 0), 1.0f, false, false, 0));
        }

        array<string> blueSpheres = { "paint_blue_event_sphere1_", "paint_blue_event_sphere2_", "paint_blue_event_sphere3_", "paint_blue_event_sphere4_" };
        for (uint b = 0; b < blueSpheres.length(); b++) {
            m_gelDatabase.insertLast(GelOverrideData("sp_a4_finale4", blueSpheres[b], Vector(0, 0, -20), QAngle(0, 0, 0), 1.0f, false, false, 0));
        }

        m_gelDatabaseInitialized = true;
    }

    private void UpdateActiveGelCache() {
        InitializeGelDatabase();
        string currentMap = g_Archipelago.GetCurrentMap();
        if (currentMap == m_lastGelCachedMap) return;

        m_activeGelCache.resize(0);
        m_lastGelCachedMap = currentMap;
        for (uint i = 0; i < m_gelDatabase.length(); i++) {
            if (m_gelDatabase[i].map_name == m_lastGelCachedMap) {
                m_activeGelCache.insertLast(m_gelDatabase[i]);
            }
        }
    }
}

// Global Wrapper Function for compatibility with external references if needed
CBaseEntity@ CreateAPHologram(Vector position, QAngle angles, float scale, CBaseEntity@ parent = null, string attachment = "", int skin = 0, string name = "", bool animate = true, float playbackRate = 1.0f) {
    return g_Archipelago.GetHologramManager().CreateAPHologram(position, angles, scale, parent, attachment, skin, name, animate, playbackRate);
}

} // namespace Archipelago