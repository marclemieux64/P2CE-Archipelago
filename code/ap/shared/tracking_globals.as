// =============================================================
// ARCHIPELAGO GLOBALS
// =============================================================
string current_map = "unknown";
string last_initialized_map = "";
ConVarRef host_map("host_map");


// Traps Globals
array<string> trap_colors = { "255 0 0", "0 255 0", "0 0 255", "255 255 0", "255 0 255", "0 255 255" };

// Fling Levels
array<string> scripted_fling_levels = { "sp_a3_03", "sp_a3_bomb_flings", "sp_a3_transition01", "sp_a3_speed_flings", "sp_a3_end", "sp_a4_jump_polarity" };




// Butter Fingers Globals
int g_ButterFingersTicks = 0;

// DeathLink Globals
bool g_bSentDeathLink = false;

// Completion Globals
bool portalgun_2_disabled = false;


int transition_script_count = 0;
array<string> g_suppressed_entities; 
array<string> two_trigger_levels = { "sp_a1_intro1", "sp_a4_finale1", "sp_a4_finale3" };
array<string> non_elevator_maps = { 
    "sp_a1_intro1", "sp_a1_intro7", "sp_a1_wakeup", "sp_a2_turret_intro", "sp_a2_bts1", 
    "sp_a2_bts2", "sp_a2_bts3", "sp_a2_bts4", "sp_a2_bts5", "sp_a2_bts6", "sp_a2_core", 
    "sp_a3_00", "sp_a3_01", "sp_a4_laser_platform", "sp_a3_portal_intro", "sp_a4_finale1", 
    "sp_a4_finale2", "sp_a4_finale3", "sp_a4_finale4" 
};

// =============================================================
// REGISTRY & TRANSLATION
// =============================================================

dictionary g_monitor_break_names;

void InitWheatleyMonitorRegistry() {
    g_monitor_break_names.deleteAll();
    g_monitor_break_names["sp_a4_tb_intro:monitor1-relay_monitor_broken"] = "sp_a4_tb_intro";
    g_monitor_break_names["sp_a4_tb_trust_drop:monitor1-relay_monitor_broken"] = "sp_a4_tb_trust_drop";
    g_monitor_break_names["sp_a4_tb_wall_button:wheatley_monitor-relay_monitor_broken"] = "sp_a4_tb_wall_button";
    g_monitor_break_names["sp_a4_tb_polarity:monitor1-relay_monitor_broken"] = "sp_a4_tb_polarity";
    g_monitor_break_names["sp_a4_tb_catch:monitor1-relay_monitor_broken"] = "sp_a4_tb_catch 1";
    g_monitor_break_names["sp_a4_tb_catch:monitor2-relay_monitor_broken"] = "sp_a4_tb_catch 2";
    g_monitor_break_names["sp_a4_stop_the_box:wheatley_monitor-relay_monitor_broken"] = "sp_a4_stop_the_box";
    g_monitor_break_names["sp_a4_laser_catapult:wheatley_monitor_1-relay_monitor_broken"] = "sp_a4_laser_catapult";
    g_monitor_break_names["sp_a4_laser_platform:wheatley_monitor_1-relay_monitor_broken"] = "sp_a4_laser_platform";
    g_monitor_break_names["sp_a4_speed_tb_catch:wheatley_monitor-relay_monitor_broken"] = "sp_a4_speed_tb_catch";
    g_monitor_break_names["sp_a4_jump_polarity:wheatley_monitor_1-relay_monitor_broken"] = "sp_a4_jump_polarity";
    g_monitor_break_names["sp_a4_finale3:wheatley_screen-relay_monitor_broken"] = "sp_a4_finale3";
}

/**
 * TranslateButtonName - Maps user-friendly names to internal IDs.
 */
string TranslateButtonName(string originalName) {
    string clean = originalName.trim();
    if (clean == "Ratman Den 1") return "rd1";
    if (clean == "Ratman Den 2") return "rd2";
    if (clean == "Ratman Den 3") return "rd3";
    if (clean == "Ratman Den 4") return "rd4";
    if (clean == "Ratman Den 5") return "rd5";
    if (clean == "Ratman Den 6") return "rd6";
    if (clean == "Ratman Den 7") return "rd7";
    return (clean.length() > 0) ? clean : "ap_btn"; 
}

/**
 * RunButtonScenarioCheck - Formats and prints button verification status.
 */
void RunButtonScenarioCheck(string buttonName) {
    buttonName = buttonName.trim();
    if (buttonName == "rd1") Msgl("button_check:Ratman Den 1"); else if (buttonName == "rd2") Msgl("button_check:Ratman Den 2"); else if (buttonName == "rd3") Msgl("button_check:Ratman Den 3"); else if (buttonName == "rd4") Msgl("button_check:Ratman Den 4"); else if (buttonName == "rd5") Msgl("button_check:Ratman Den 5"); else if (buttonName == "rd6") Msgl("button_check:Ratman Den 6"); else if (buttonName == "rd7") Msgl("button_check:Ratman Den 7"); else Msgl("button_check:unknown_" + buttonName);
}
