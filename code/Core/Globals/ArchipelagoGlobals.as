// =============================================================
// ARCHIPELAGO GLOBALS & CONVARS (OOP VERSION)
// =============================================================

namespace Archipelago {

// --- CONVARS & ENGINE REFERENCES ---
// These must remain as global objects so they correctly register with the engine's CVAR system.
ConVar cv_Debug("cv_Debug", "0");
ConVarRef host_map("host_map");
ConVar cv_BTS4InitialHoloActive("cv_BTS4InitialHoloActive", "0");
ConVar cv_BTS4Conveyor1HoloActive("cv_BTS4Conveyor1HoloActive", "0");
ConVar cv_HideHolograms("cv_HideHolograms", "0");
ConVar cv_ShowMapStatusHUD("cv_ShowMapStatusHUD", "0");
ConVar cv_SkipBirdScene("cv_SkipBirdScene", "0");
ConVar cv_SkipCeilingScene("cv_SkipCeilingScene", "0");
ConVar cv_SkipIntroContainerScene("cv_SkipIntroContainerScene", "0");
ConVar cv_SkipElevatorRide("cv_SkipElevatorRide", "0");
ConVar cv_VitrifiedStatus("cv_VitrifiedStatus", "000000");

// --- STATIC READ-ONLY CONFIGURATION ARRAYS ---
const array<string> two_trigger_levels = { "sp_a1_intro1", "sp_a4_finale3" };

const array<string> non_elevator_maps = {
    "sp_a1_intro1", "sp_a1_intro7", "sp_a1_wakeup", "sp_a2_turret_intro", "sp_a2_bts1",
    "sp_a2_bts2", "sp_a2_bts3", "sp_a2_bts4", "sp_a2_bts5", "sp_a2_bts6", "sp_a2_core",
    "sp_a3_00", "sp_a3_01", "sp_a4_laser_platform", "sp_a3_portal_intro", "sp_a4_finale1",
    "sp_a4_finale2", "sp_a4_finale3", "sp_a4_finale4"
};

const array<string> trap_colors = { 
    "255 0 0", "0 255 0", "0 0 255", "255 255 0", "255 0 255", "0 255 255" 
};

const array<string> scripted_fling_levels = { 
    "sp_a3_03", "sp_a3_bomb_flings", "sp_a3_transition01", "sp_a3_speed_flings", "sp_a3_end", "sp_a4_jump_polarity" 
};

// --- GLOBAL HELPER FUNCTIONS ---

/**
 * Checks if the given entity is a turret located on the conveyor belt in sp_a2_bts4.
 */
bool IsConveyorTurret(CBaseEntity@ ent) {
    if (ent is null) return false;
    
    string cls = ent.GetClassname();
    if (cls != "npc_portal_turret_floor") return false;
    
    string model = ent.GetModelName().tolower();
    bool hasTurretModel = (model.locate("npcs/turret/turret.mdl") != uint(-1) || model.locate("npcs/turret/turret_skeleton.mdl") != uint(-1));
    if (!hasTurretModel) return false;

    // Ignore hologram entities
    string name = ent.GetEntityName().tolower();
    if (name.locate("_holo") != uint(-1)) return false;

    // Conveyor turrets are in the upper volume of sp_a2_bts4
    Vector pos = ent.GetAbsOrigin();
    bool inConveyorZone = (pos.z > 6000.0f && pos.y < -3500.0f);
    
    // They are either parented/attached to moving carriages,
    // named conveyor/template, or are very close to spawn points.
    bool hasConveyorName = (name.locate("turret_conveyor_1") != uint(-1) || name.locate("initial_template_turret") != uint(-1));
    bool hasParent = (ent.GetMoveParent() !is null);
    bool nearSpawn = (pos.DistTo(Vector(1824, -7024, 6655.830f)) < 300.0f || pos.DistTo(Vector(1444, -7084, 6737.0f)) < 300.0f);

    return (inConveyorZone && (hasParent || nearSpawn || hasConveyorName)) || hasConveyorName;
}

} // namespace Archipelago
