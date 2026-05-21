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

// --- BOOLEANS ---
bool portalgun_2_disabled = false;

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

} // namespace Archipelago
