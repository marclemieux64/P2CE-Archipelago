// =============================================================
// ARCHIPELAGO LEGACY GLOBALS
// =============================================================

// --- GLOBALS (TRUE GLOBAL SCOPE) ---
string current_map = "unknown";
int transition_script_count = 0;
bool g_has_printed_map_complete = false;
bool sent_death_link = false;


namespace Archipelago {

// --- CONVARS & REFS ---
    ConVar cv_ArchipelagoDebug("ArchipelagoDebug", "0");
    ConVar cv_ArchipelagoHideHolograms("ap_hide_holograms", "0", FCVAR_ARCHIVE);
    ConVarRef host_map("host_map");
    ConVar cv_BTS4_InitialTemplateHoloActive("ap_bts4_initial_holo_active", "0");
    ConVar cv_BTS4_Conveyor1TemplateHoloActive("ap_bts4_conveyor1_holo_active", "0");


// --- BOOLEANS ---
bool portalgun_2_disabled = false;
bool g_bInitialTemplateHoloActive = false;
bool g_bConveyor1TemplateHoloActive = false;
int g_bts4ConveyorTickCounter = 0;

// --- INTEGERS ---
    dictionary g_vitrified_door_names;
    ConVar cv_ArchipelagoVitrifiedStatus("ArchipelagoVitrifiedStatus", "000000", FCVAR_ARCHIVE);
    int g_ButterFingersTicks = 0;

// --- STRINGS ---
    // Moved to global scope

// --- ARRAYS ---
    array<string> two_trigger_levels = { "sp_a1_intro1", "sp_a4_finale3" };
    array<string> non_elevator_maps = { 
        "sp_a1_intro1", "sp_a1_intro7", "sp_a1_wakeup", "sp_a2_turret_intro", "sp_a2_bts1", 
        "sp_a2_bts2", "sp_a2_bts3", "sp_a2_bts4", "sp_a2_bts5", "sp_a2_bts6", "sp_a2_core", 
        "sp_a3_00", "sp_a3_01", "sp_a4_laser_platform", "sp_a3_portal_intro", "sp_a4_finale1", 
        "sp_a4_finale2", "sp_a4_finale3", "sp_a4_finale4" 
    };
    array<string> g_suppressed_entities;
    array<string> g_suppressed_classes;
    array<string> g_reported_monitors;
    array<int> g_processed_turret_indices;
    array<int> g_processed_entity_indices;
    array<string> trap_colors = { "255 0 0", "0 255 0", "0 0 255", "255 255 0", "255 0 255", "0 255 255" };

    array<string> scripted_fling_levels = {"sp_a3_03", "sp_a3_bomb_flings", "sp_a3_transition01", "sp_a3_speed_flings", "sp_a3_end", "sp_a4_jump_polarity" };

    bool IsConveyorTurret(CBaseEntity@ ent) {
        if (ent is null) return false;
        
        string cls = ent.GetClassname();
        if (cls != "npc_portal_turret_floor") return false;
        
        string model = ent.GetModelName().tolower();
        bool hasTurretModel = (model.locate("npcs/turret/turret.mdl") != uint(-1) || model.locate("npcs/turret/turret_skeleton.mdl") != uint(-1));
        if (!hasTurretModel) return false;

        // Ignore hologram entities themselves
        string name = ent.GetEntityName().tolower();
        if (name.locate("_holo") != uint(-1)) return false;

        // Conveyor turrets are in the upper volume of sp_a2_bts4
        Vector pos = ent.GetAbsOrigin();
        bool inConveyorZone = (pos.z > 6000.0f && pos.y < -3500.0f);
        
        // They are either parented/attached to moving carriages/tracktrains,
        // or they have names explicitly containing conveyor/initial template substrings,
        // or they are very close to the spawn points.
        bool hasConveyorName = (name.locate("turret_conveyor_1") != uint(-1) || name.locate("initial_template_turret") != uint(-1));
        bool hasParent = (ent.GetMoveParent() !is null);
        bool nearSpawn = (pos.DistTo(Vector(1824, -7024, 6655.830f)) < 300.0f || pos.DistTo(Vector(1444, -7084, 6737.0f)) < 300.0f);

        return (inConveyorZone && (hasParent || nearSpawn || hasConveyorName)) || hasConveyorName;
    }

} // namespace Archipelago
