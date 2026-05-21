// =============================================================
// ARCHIPELAGO HOLOGRAM OVERRIDES (OPTIMIZED GEL SUB-SYSTEM)
// =============================================================

namespace Archipelago {

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

// Variables globales exclusives aux Gels
array<GelOverrideData@> g_GelDatabase;
array<GelOverrideData@> g_ActiveGelCache;
string g_LastGelCachedMap = "";
bool g_GelDatabaseInitialized = false;

void InitializeGelDatabase() {
    if (g_GelDatabaseInitialized) return;

    // --- sp_a3_jump_intro ---
    g_GelDatabase.insertLast(GelOverrideData("sp_a3_jump_intro", "", Vector(0, 0, 0), QAngle(-90, 0, 0), 1.0f, false, false, 0));

    // --- sp_a3_bomb_flings ---
    g_GelDatabase.insertLast(GelOverrideData("sp_a3_bomb_flings", "paint_bomb_maker_-224_-64_656_holo", Vector(0, 0, -85), QAngle(180, 0, 0), 1.0f, false, false, 0));

    // --- sp_a3_crazy_box ---
    g_GelDatabase.insertLast(GelOverrideData("sp_a3_crazy_box", "paint_bomb_template_2240_-896_656_holo", Vector(0, 0, -350.0f), QAngle(180, 0, 0), 1.0f, false, false, 0));
    g_GelDatabase.insertLast(GelOverrideData("sp_a3_crazy_box", "paint_drip1_1716_-1772_714_holo", Vector(25, 0, 0), QAngle(90, 0, 0), 1.0f, false, false, 0));
    g_GelDatabase.insertLast(GelOverrideData("sp_a3_crazy_box", "paint_sprayer_bounce_1280_-1408_1776_holo", Vector(60, 0, 0), QAngle(90, 0, 0), 1.0f, false, false, 0));

    // --- sp_a3_speed_ramp ---
    g_GelDatabase.insertLast(GelOverrideData("sp_a3_speed_ramp", "paint_sprayer_576_0_704_holo", Vector(0, 0, -5000.0f), QAngle(180, 0, 0), 0.0f, false, false, 0));
    g_GelDatabase.insertLast(GelOverrideData("sp_a3_speed_ramp", "paint_sprayer_576_0_696_holo", Vector(120, 0, 0), QAngle(90, 0, 0), 1.0f, false, false, 0));
    g_GelDatabase.insertLast(GelOverrideData("sp_a3_speed_ramp", "paint_sprayer_2_-1600_-896_960_holo", Vector(65, 0, 0), QAngle(90, 0, 0), 1.0f, false, false, 0));
    g_GelDatabase.insertLast(GelOverrideData("sp_a3_speed_ramp", "paint_sprayer_3_-1600_-384_960_holo", Vector(65, 0, 0), QAngle(90, 0, 0), 1.0f, false, false, 0));

    // --- sp_a3_speed_flings ---
    g_GelDatabase.insertLast(GelOverrideData("sp_a3_speed_flings", "paint_sprayer_bounce_2816_-128_320_holo", Vector(260, 0, 0), QAngle(90, 0, 0), 1.0f, false, false, 0));
    g_GelDatabase.insertLast(GelOverrideData("sp_a3_speed_flings", "paint_sprayer_speed_2560_-128_-152_holo", Vector(10, 0, 0), QAngle(90, 0, 0), 1.0f, false, false, 0));

    // --- sp_a3_portal_intro ---
    g_GelDatabase.insertLast(GelOverrideData("sp_a3_portal_intro", "pump_machine_white_sprayer_1908_1712_-1984_holo", Vector(15, 0, 0), QAngle(-90, 0, 0), 1.0f, false, false, 0));
    g_GelDatabase.insertLast(GelOverrideData("sp_a3_portal_intro", "pump_machine_blue_sprayer_1088_1712_-2068_holo", Vector(10, 0, 0), QAngle(90, 0, 0), 1.0f, false, false, 0));
    g_GelDatabase.insertLast(GelOverrideData("sp_a3_portal_intro", "_-1680_holo", Vector(0, 0, -10), QAngle(0, 270, 0), 1.0f, false, false, 0));
    g_GelDatabase.insertLast(GelOverrideData("sp_a3_portal_intro", "_-1672_holo", Vector(25, 0, 0), QAngle(-90, 0, 0), 1.0f, false, false, 0));
    g_GelDatabase.insertLast(GelOverrideData("sp_a3_portal_intro", "_-1728_holo", Vector(0, 0, 35), QAngle(0, 270, 0), 1.0f, false, false, 0));
    g_GelDatabase.insertLast(GelOverrideData("sp_a3_portal_intro", "_-1704_holo", Vector(0, 0, 10), QAngle(0, 270, 0), 1.0f, false, false, 0));
    g_GelDatabase.insertLast(GelOverrideData("sp_a3_portal_intro", "_-1712_holo", Vector(0, 0, 20), QAngle(0, 270, 0), 1.0f, false, false, 0));
    g_GelDatabase.insertLast(GelOverrideData("sp_a3_portal_intro", "paint_sprayer_1_32_99_144_holo", Vector(0, 0, 0), QAngle(0, 0, 0), 1.0f, false, true, 1)); // Mode spécial 1
    g_GelDatabase.insertLast(GelOverrideData("sp_a3_portal_intro", "paint_sprayer_2_287_192_292_holo", Vector(-80.0f, 0.0f, -80.0f), QAngle(90.0f, 0.0f, 0.0f), 1.0f, false, true, 2)); // Mode spécial 2

    // --- sp_a3_end ---
    g_GelDatabase.insertLast(GelOverrideData("sp_a3_end", "paint_trickle_blue_1", Vector(35, 0, -10), QAngle(90, 0, 0), 1.0f, false, false, 0));
    g_GelDatabase.insertLast(GelOverrideData("sp_a3_end", "paint_trickle_white_2", Vector(50, 0, 0), QAngle(90, 0, 0), 1.0f, false, false, 0));
    g_GelDatabase.insertLast(GelOverrideData("sp_a3_end", "paint_trickle", Vector(35, 0, 0), QAngle(90, 0, 0), 1.0f, false, false, 0));
    g_GelDatabase.insertLast(GelOverrideData("sp_a3_end", "paint_duct", Vector(0, 0, 0), QAngle(90, -90, 0), 1.0f, false, true, 3)); // Mode spécial 3

    // --- sp_a4_speed_tb_catch ---
    g_GelDatabase.insertLast(GelOverrideData("sp_a4_speed_tb_catch", "autoinstance1-paint_sprayer_256_1376_552_holo", Vector(135, 0, 0), QAngle(90, 0, 0), 1.0f, false, false, 0));

    // --- sp_a4_jump_polarity ---
    g_GelDatabase.insertLast(GelOverrideData("sp_a4_jump_polarity", "paint_mesilly_1902_65_188_holo", Vector(0, 0, 0), QAngle(0, 0, 0), 1.0f, false, false, 0));
    g_GelDatabase.insertLast(GelOverrideData("sp_a4_jump_polarity", "paint_mesilly_1742_-62_140_holo", Vector(0, 0, 0), QAngle(0, 0, 0), 1.0f, false, false, 0));
    g_GelDatabase.insertLast(GelOverrideData("sp_a4_jump_polarity", "paint_sprayer_-576_-64_640_holo", Vector(320, 0, 0), QAngle(90, 0, 0), 1.0f, false, false, 0));

    // --- sp_a4_finale1 ---
    g_GelDatabase.insertLast(GelOverrideData("sp_a4_finale1", "paint_sprayer_portal_", Vector(0, 0, 0), QAngle(-90, 0, 0), 1.0f, false, false, 0));
    g_GelDatabase.insertLast(GelOverrideData("sp_a4_finale1", "platform_sprayer", Vector(0, 0, 0), QAngle(0, 0, 0), 1.0f, false, false, 0));

    // --- sp_a4_finale2 ---
    g_GelDatabase.insertLast(GelOverrideData("sp_a4_finale2", "paint_sprayer_jump_-1710_", Vector(0, 0, 0), QAngle(-90, 0, 0), 1.0f, false, false, 0));
    g_GelDatabase.insertLast(GelOverrideData("sp_a4_finale2", "trigger_to_drop", Vector(0, 0, -5000.0f), QAngle(0, 0, 0), 0.0f, false, true, 0));
    g_GelDatabase.insertLast(GelOverrideData("sp_a4_finale2", "template_artillery", Vector(0, 0, -5000.0f), QAngle(0, 0, 0), 0.0f, false, true, 0));
    g_GelDatabase.insertLast(GelOverrideData("sp_a4_finale2", "bomb_", Vector(0, 0, 215.0f), QAngle(180, 0, 0), 1.0f, false, false, 0));

    // --- sp_a4_finale3 ---
    g_GelDatabase.insertLast(GelOverrideData("sp_a4_finale3", "practice_paint_sprayer_", Vector(100, 100, 0), QAngle(90, 0, 90), 1.0f, false, false, 0));
    g_GelDatabase.insertLast(GelOverrideData("sp_a4_finale3", "paint_sprayer_2_-960_113_-70_holo", Vector(135, 0, 145), QAngle(0, 0, 0), 1.0f, false, false, 0));
    g_GelDatabase.insertLast(GelOverrideData("sp_a4_finale3", "", Vector(0, 0, -5000.0f), QAngle(0, 0, 0), 0.0f, false, false, 0)); 

    // --- sp_a4_finale4 ---
    g_GelDatabase.insertLast(GelOverrideData("sp_a4_finale4", "_160_", Vector(0, 0, -500.0f), QAngle(0, 0, 0), 0.0f, false, true, 0));
    g_GelDatabase.insertLast(GelOverrideData("sp_a4_finale4", "paint_blue_sprayer_-544_-16_320_holo", Vector(0, 0, 0), QAngle(0, -90, 0), 1.0f, false, false, 0));
    g_GelDatabase.insertLast(GelOverrideData("sp_a4_finale4", "pipe_bounce_paint_bomb_template1_", Vector(90, 0, 0), QAngle(90, 0, 0), 1.0f, false, false, 0));
    g_GelDatabase.insertLast(GelOverrideData("sp_a4_finale4", "toxin_paint_sprayer_882_256_192_holo", Vector(105, 135, 0), QAngle(0, -90, 0), 1.0f, false, false, 0));
    g_GelDatabase.insertLast(GelOverrideData("sp_a4_finale4", "_728_-368_60_", Vector(0, 0, 0), QAngle(0, 0, -90), 1.0f, false, false, 0));
    g_GelDatabase.insertLast(GelOverrideData("sp_a4_finale4", "_752_-368_184_", Vector(0, 0, 0), QAngle(0, 90, 0), 1.0f, false, false, 0));
    g_GelDatabase.insertLast(GelOverrideData("sp_a4_finale4", "_240_0_64_", Vector(0, 0, -55), QAngle(0, 0, 0), 1.0f, false, false, 0));
    g_GelDatabase.insertLast(GelOverrideData("sp_a4_finale4", "_448_64_64_", Vector(0, 0, -55), QAngle(0, 0, 0), 1.0f, false, false, 0));
    g_GelDatabase.insertLast(GelOverrideData("sp_a4_finale4", "_544_-360_32_", Vector(0, 0, -10), QAngle(0, 0, 0), 1.0f, false, false, 0));
    g_GelDatabase.insertLast(GelOverrideData("sp_a4_finale4", "_240_144_24_", Vector(0, 0, -10), QAngle(0, 0, 0), 1.0f, false, false, 0));
    g_GelDatabase.insertLast(GelOverrideData("sp_a4_finale4", "_0_256_8_", Vector(0, 0, -10), QAngle(0, 0, 0), 1.0f, false, false, 0));
    
    array<string> eventSpheres = {
        "_329_-315_443_", "_0_-403_443_", "_0_-325_578_", "_-290_-247_578_", "_-346_775_578_", "_329_827_443_", "_503_546_578_"
    };
    for (uint s = 0; s < eventSpheres.length(); s++) {
        g_GelDatabase.insertLast(GelOverrideData("sp_a4_finale4", eventSpheres[s], Vector(0, 0, 0), QAngle(0, 0, -90), 1.0f, false, false, 0));
    }

    array<string> whiteSpheres = {
        "paint_white_event_sphere1_", "paint_white_event_sphere2_", "paint_white_event_sphere4_", "paint_white_event_sphere5_", 
        "paint_white_event_sphere7_", "paint_white_event_sphere8_", "paint_white_event_sphere10_"
    };
    for (uint w = 0; w < whiteSpheres.length(); w++) {
        g_GelDatabase.insertLast(GelOverrideData("sp_a4_finale4", whiteSpheres[w], Vector(0, 0, 0), QAngle(0, 0, 0), 1.0f, false, false, 0));
    }

    array<string> blueSpheres = { "paint_blue_event_sphere1_", "paint_blue_event_sphere2_", "paint_blue_event_sphere3_", "paint_blue_event_sphere4_" };
    for (uint b = 0; b < blueSpheres.length(); b++) {
        g_GelDatabase.insertLast(GelOverrideData("sp_a4_finale4", blueSpheres[b], Vector(0, 0, -20), QAngle(0, 0, 0), 1.0f, false, false, 0));
    }

    g_GelDatabaseInitialized = true;
}

void UpdateActiveGelCache() {
    InitializeGelDatabase();
    if (::current_map == g_LastGelCachedMap) return;

    g_ActiveGelCache.resize(0);
    g_LastGelCachedMap = ::current_map;

    for (uint i = 0; i < g_GelDatabase.length(); i++) {
        if (g_GelDatabase[i].map_name == g_LastGelCachedMap) {
            g_ActiveGelCache.insertLast(g_GelDatabase[i]);
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
    uint cacheSize = g_ActiveGelCache.length();
    if (cacheSize == 0) return;

    string lowerName = name.tolower();

    for (uint i = 0; i < cacheSize; i++) {
        if (g_ActiveGelCache[i].entity_substring != "" && lowerName.locate(g_ActiveGelCache[i].entity_substring) != uint(-1)) {
            
            // Traitement rigoureux des calculs dynamiques d'origine
            if (g_ActiveGelCache[i].special_mode == 1) {
                targetPos = ent.GetAbsOrigin();
                targetAng = QAngle(0, 0, 0);
            } 
            else if (g_ActiveGelCache[i].special_mode == 2) {
                targetPos = ent.GetAbsOrigin() + g_ActiveGelCache[i].target_pos;
                QAngle nativeAng = ent.GetAbsAngles();
                targetAng = QAngle(nativeAng.x + 90.0f, nativeAng.y, nativeAng.z);
            } 
            else if (g_ActiveGelCache[i].special_mode == 3) {
                targetPos = ent.GetAbsOrigin();
                targetAng = g_ActiveGelCache[i].target_ang;
            }
            else {
                targetPos = g_ActiveGelCache[i].target_pos;
                targetAng = g_ActiveGelCache[i].target_ang;
            }

            targetScale = g_ActiveGelCache[i].target_scale;
            shouldParent = g_ActiveGelCache[i].should_parent;
            absoluteAngles = g_ActiveGelCache[i].absolute_angles;
            return; 
        }
    }

    for (uint i = 0; i < cacheSize; i++) {
        if (g_ActiveGelCache[i].entity_substring == "") {
            targetPos = g_ActiveGelCache[i].target_pos;
            targetAng = g_ActiveGelCache[i].target_ang;
            targetScale = g_ActiveGelCache[i].target_scale;
            shouldParent = g_ActiveGelCache[i].should_parent;
            absoluteAngles = g_ActiveGelCache[i].absolute_angles;
            return;
        }
    }
}

} // namespace Archipelago