// =============================================================
// ARCHIPELAGO HOLOGRAM OVERRIDES (OPTIMIZED CUBE SUB-SYSTEM)
// =============================================================

namespace Archipelago {

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

// Variables globales exclusives aux Cubes
array<CubeOverrideData@> g_CubeDatabase;
array<CubeOverrideData@> g_ActiveCubeCache;
string g_LastCubeCachedMap = "";
bool g_CubeDatabaseInitialized = false;

void InitializeCubeDatabase() {
    if (g_CubeDatabaseInitialized) return;

    // --- Matrice de Base de Données des Cubes Rigoureuse ---
    g_CubeDatabase.insertLast(CubeOverrideData("sp_a1_intro1", "entity_box_maker_rm1", Vector(0, 0, -195), QAngle(180, 0, 0), 1.0f));
    g_CubeDatabase.insertLast(CubeOverrideData("sp_a1_intro1", "cube_dropper_2-cube_dropper_box", Vector(0, 0, -195), QAngle(180, 0, 0), 1.0f));
    
    g_CubeDatabase.insertLast(CubeOverrideData("sp_a1_intro4", "box_dropper-cube_dropper_box", Vector(0, 0, -500), QAngle(180, 0, 0), 1.0f));
    g_CubeDatabase.insertLast(CubeOverrideData("sp_a1_intro4", "metal_box.mdl_1307_-909_-39", Vector(0, 0, -800), QAngle(0, 0, 0), 0.8f));
    
    g_CubeDatabase.insertLast(CubeOverrideData("sp_a1_intro5", "cube_dropper_1-cube_dropper_box", Vector(0, 0, -500), QAngle(180, 0, 0), 1.0f));
    g_CubeDatabase.insertLast(CubeOverrideData("sp_a1_intro5", "cube_dropper_2-cube_dropper_box", Vector(0, 0, -500), QAngle(180, 0, 0), 1.0f));
    
    g_CubeDatabase.insertLast(CubeOverrideData("sp_a1_intro6", "cube_dropper-cube_dropper_box", Vector(0, 0, -500), QAngle(180, 0, 0), 1.0f));
    g_CubeDatabase.insertLast(CubeOverrideData("sp_a1_intro7", "metal_box.mdl", Vector(0, 0, 25), QAngle(0, 0, 90), 0.8f));
    g_CubeDatabase.insertLast(CubeOverrideData("sp_a1_intro7", "reflection_cube.mdl", Vector(0, 0, 25), QAngle(0, 0, 90), 0.8f));
    g_CubeDatabase.insertLast(CubeOverrideData("sp_a2_laser_stairs", "cube_dropper_01-cube_dropper_box", Vector(0, 0, -500), QAngle(180, 0, 0), 1.0f));
    g_CubeDatabase.insertLast(CubeOverrideData("sp_a2_laser_over_goo", "cube_dropper_box", Vector(0, 0, -530), QAngle(180, 0, 0), 1.0f));
    g_CubeDatabase.insertLast(CubeOverrideData("sp_a2_catapult_intro", "cube_dropper-cube_dropper_box", Vector(0, 0, -500), QAngle(180, 0, 0), 1.0f));
    g_CubeDatabase.insertLast(CubeOverrideData("sp_a2_trust_fling", "cube_dropper_box", Vector(0, 0, -530), QAngle(180, 0, 0), 1.0f));
    g_CubeDatabase.insertLast(CubeOverrideData("sp_a2_pit_flings", "cube_dropper-cube_dropper_box", Vector(0, 0, -500), QAngle(180, 0, 0), 1.0f));
    g_CubeDatabase.insertLast(CubeOverrideData("sp_a2_fizzler_intro", "cube_dropper-cube_dropper_box", Vector(0, 0, -500), QAngle(180, 0, 0), 1.0f));
    g_CubeDatabase.insertLast(CubeOverrideData("sp_a2_sphere_peek", "reflectocube_dropper_box", Vector(0, 0, -530), QAngle(180, 0, 0), 1.0f));
    
    g_CubeDatabase.insertLast(CubeOverrideData("sp_a2_ricochet", "reflecto_cube_dropper-cube_dropper_box", Vector(0, 0, -500), QAngle(180, 0, 0), 1.0f));
    g_CubeDatabase.insertLast(CubeOverrideData("sp_a2_ricochet", "juggled_cube", Vector(0, 0, 35), QAngle(0, 0, 0), 0.8f));
    
    g_CubeDatabase.insertLast(CubeOverrideData("sp_a2_bridge_intro", "box_dropper_01-cube_dropper_box", Vector(0, 0, -500), QAngle(180, 0, 0), 1.0f));
    g_CubeDatabase.insertLast(CubeOverrideData("sp_a2_bridge_the_gap", "cube_dropper-cube_dropper_box", Vector(0, 0, -500), QAngle(180, 0, 0), 1.0f));
    g_CubeDatabase.insertLast(CubeOverrideData("sp_a2_laser_relays", "laser_cube_spawner", Vector(0, 0, -30), QAngle(0, 0, 0), 0.8f));
    
    g_CubeDatabase.insertLast(CubeOverrideData("sp_a2_column_blocker", "cube_dropper_1-cube_dropper_box", Vector(0, 0, -500), QAngle(180, 0, 0), 1.0f));
    g_CubeDatabase.insertLast(CubeOverrideData("sp_a2_column_blocker", "cube_dropper_2-cube_dropper_box", Vector(0, 0, -500), QAngle(180, 0, 0), 1.0f));
    
    g_CubeDatabase.insertLast(CubeOverrideData("sp_a2_bts1", "cube_dropper-cube_dropper_box", Vector(0, 0, -530), QAngle(180, 0, 0), 1.0f));
    g_CubeDatabase.insertLast(CubeOverrideData("sp_a2_bts1", "pre_solved_chamber-box_dropper_01-cube_dropper_box", Vector(0, 0, -500), QAngle(180, 0, 0), 1.0f));
    g_CubeDatabase.insertLast(CubeOverrideData("sp_a3_jump_intro", "cube_dropper_box", Vector(0, 25, -65), QAngle(180, 0, 0), 1.0f));
    g_CubeDatabase.insertLast(CubeOverrideData("sp_a3_speed_flings", "cube_dropper_box", Vector(0, 25, -65), QAngle(180, 0, 0), 1.0f));
    g_CubeDatabase.insertLast(CubeOverrideData("sp_a4_laser_platform", "cube_dropper_box", Vector(0, 0, -500), QAngle(180, 0, 0), 1.0f));
    g_CubeDatabase.insertLast(CubeOverrideData("sp_a4_intro", "cube_dropper_box", Vector(0, 0, -530), QAngle(180, 0, 0), 1.0f));
    g_CubeDatabase.insertLast(CubeOverrideData("sp_a4_tb_intro", "cube_dropper_box", Vector(0, 0, -540), QAngle(180, 0, 0), 1.0f));
    g_CubeDatabase.insertLast(CubeOverrideData("sp_a4_tb_trust_drop", "cube_dropper_box", Vector(0, 0, -540), QAngle(180, 0, 0), 1.0f));
    
    // --- SCÉNARIO SP_A4_TB_WALL_BUTTON DOUBLE SÉCURITÉ ---
    // Match par nom d'entité strict
    g_CubeDatabase.insertLast(CubeOverrideData("sp_a4_tb_wall_button", "cube_dropper_box_spawner", Vector(-1540, 0, -500), QAngle(180, 0, 0), 1.0f));
    // Filet de sécurité : Match par sous-chaîne de modèle si l'entité résiduelle est anonyme
    g_CubeDatabase.insertLast(CubeOverrideData("sp_a4_tb_wall_button", "dropper", Vector(-1540, 0, -500), QAngle(180, 0, 0), 1.0f));

    g_CubeDatabase.insertLast(CubeOverrideData("sp_a4_tb_polarity", "cube_dropper_box", Vector(0, 0, -525), QAngle(180, 0, 0), 1.0f));
    g_CubeDatabase.insertLast(CubeOverrideData("sp_a4_tb_catch", "cube_dropper_box", Vector(0, 0, -525), QAngle(180, 0, 0), 1.0f));
    g_CubeDatabase.insertLast(CubeOverrideData("sp_a4_stop_the_box", "cube_dropper_box", Vector(0, 0, -525), QAngle(180, 0, 0), 1.0f));
    g_CubeDatabase.insertLast(CubeOverrideData("sp_a4_speed_tb_catch", "cube_dropper_box", Vector(0, 0, -525), QAngle(180, 0, 0), 1.0f));
    g_CubeDatabase.insertLast(CubeOverrideData("sp_a4_finale1", "cube_dropper_box", Vector(0, 0, -540), QAngle(180, 0, 0), 1.0f));
    g_CubeDatabaseInitialized = true;
}

void UpdateActiveCubeCache() {
    InitializeCubeDatabase();
    if (::current_map == g_LastCubeCachedMap) return;

    g_ActiveCubeCache.resize(0);
    g_LastCubeCachedMap = ::current_map;
    for (uint i = 0; i < g_CubeDatabase.length(); i++) {
        if (g_CubeDatabase[i].map_name == g_LastCubeCachedMap) {
            g_ActiveCubeCache.insertLast(g_CubeDatabase[i]);
        }
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
    uint cacheSize = g_ActiveCubeCache.length();
    if (cacheSize == 0) return;

    string lowerName = name.tolower();
    for (uint i = 0; i < cacheSize; i++) {
        if (lowerName.locate(g_ActiveCubeCache[i].entity_substring) != uint(-1)) {
            targetPos = g_ActiveCubeCache[i].target_pos;
            targetAng = g_ActiveCubeCache[i].target_ang;
            targetScale = g_ActiveCubeCache[i].target_scale;
            return; 
        }
    }
}

} // namespace Archipelago
