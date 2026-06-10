namespace Archipelago {

void DisableEntityPickup(string target) {
    if (current_map == "sp_a2_bts4") {
        if (target == "npc_portal_turret_floor" || target == "initial_template_turret") {
            g_bInitialTemplateHoloActive = true;
            cv_BTS4_InitialTemplateHoloActive.SetValue(1);
        }
        if (target == "npc_portal_turret_floor" || target == "turret_conveyor_1_template") {
            g_bConveyor1TemplateHoloActive = true;
            cv_BTS4_Conveyor1TemplateHoloActive.SetValue(1);
        }
    }


    array<CBaseEntity@> targets = FindEntities(target);

    for (uint i = 0; i < targets.length(); i++) {
        CBaseEntity@ t = targets[i];
        if (t is null) continue;
        t.KeyValue("PickupEnabled", "0");
    }
}

} // namespace Archipelago
