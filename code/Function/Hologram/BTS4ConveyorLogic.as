namespace Archipelago {

void CleanOrphanRedHolograms() {
    CBaseEntity@ ent = EntityList().First();
    while (@ent !is null) {
        if (ent.GetModelName().tolower().locate("archipelago_hologram") != uint(-1)) {
            string name = ent.GetEntityName();
            // Clean up any dynamic conveyor/turret holograms that became orphans,
            // but explicitly preserve the static check hologram.
            if (name != "sp_a2_bts4_map_check_holo" && name.locate("_holo") != uint(-1)) {
                if (ent.GetMoveParent() is null) {
                    ArchipelagoLog("[AP DEBUG] Cleaning up orphaned conveyor hologram: " + name);
                    ent.Remove();
                }
            }
        }
        @ent = EntityList().Next(ent);
    }
}

bool DoesHologramExistFor(string substring) {
    CBaseEntity@ ent = EntityList().First();
    while (@ent !is null) {
        if (ent.GetModelName().tolower().locate("archipelago_hologram") != uint(-1)) {
            string name = ent.GetEntityName();
            if (name.locate(substring) != uint(-1) && name.locate("_holo") != uint(-1)) {
                return true;
            }
        }
        @ent = EntityList().Next(ent);
    }
    return false;
}

void AP_BTS4_ConveyorTick() {
    UpdateInternalMapName();
    if (current_map != "sp_a2_bts4") return;

    // Detect if hologram checks are still incomplete based on ConVars or existing holograms
    bool initialActive = cv_BTS4_InitialTemplateHoloActive.GetBool() || DoesHologramExistFor("initial_template_turret");
    bool conveyor1Active = cv_BTS4_Conveyor1TemplateHoloActive.GetBool() || DoesHologramExistFor("turret_conveyor_1");

    g_bInitialTemplateHoloActive = initialActive;
    g_bConveyor1TemplateHoloActive = conveyor1Active;

    // Occasional tick log to prove the timer is running
    g_bts4ConveyorTickCounter++;
    if (g_bts4ConveyorTickCounter % 50 == 0) {
        ArchipelagoLog("[AP DEBUG] Conveyor Tick # " + g_bts4ConveyorTickCounter + " | InitialActive: " + g_bInitialTemplateHoloActive + " | Conveyor1Active: " + g_bConveyor1TemplateHoloActive);
    }

    if (g_bInitialTemplateHoloActive || g_bConveyor1TemplateHoloActive) {
        // Clean up orphaned conveyor holograms first
        CleanOrphanRedHolograms();
    } else {
        // Reset the ConVars to 0 since the checks are complete
        cv_BTS4_InitialTemplateHoloActive.SetValue(0);
        cv_BTS4_Conveyor1TemplateHoloActive.SetValue(0);

        
        // Remove all conveyor holograms and re-enable pickup
        CBaseEntity@ ent = EntityList().First();
        while (@ent !is null) {
            if (Archipelago::IsConveyorTurret(ent)) {
                ent.KeyValue("PickupEnabled", "1");
            }
            
            if (ent.GetModelName().tolower().locate("archipelago_hologram") != uint(-1)) {
                string name = ent.GetEntityName();
                if (name != "sp_a2_bts4_map_check_holo" && name.locate("_holo") != uint(-1)) {
                    ent.Remove();
                }
            }
            @ent = EntityList().Next(ent);
        }
        return;
    }

    CBaseEntity@ ent = EntityList().First();
    while (@ent !is null) {
        if (Archipelago::IsConveyorTurret(ent)) {
            string name = ent.GetEntityName();
            bool isConveyor1 = false;
            float dist = ent.GetAbsOrigin().DistTo(Vector(1824, -7024, 6655.830f));
            if (name.locate("turret_conveyor_1") != uint(-1) || dist < 300.0f) {
                isConveyor1 = true;
            }

            bool shouldHaveHolo = isConveyor1 ? g_bConveyor1TemplateHoloActive : g_bInitialTemplateHoloActive;

            if (g_bts4ConveyorTickCounter % 50 == 0) {
                ArchipelagoLog("[AP DEBUG] Conveyor Turret: " + name + " | Dist to conveyor1 template: " + dist + " | isConveyor1: " + isConveyor1 + " | shouldHaveHolo: " + shouldHaveHolo);
            }

            if (shouldHaveHolo) {
                // 1. Ensure pickup is disabled
                ent.KeyValue("PickupEnabled", "0");

                // 2. Attach hologram if it doesn't exist
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
                    ArchipelagoLog("[AP DEBUG] Spawning hologram for: " + name + " -> " + holoName + " parented to ent index " + ent.GetEntityIndex());
                    // Offset: turret visual override default targetPos is (0, 0, 60), we add offset of 20 = 80
                    Vector finalOffset(0, 0, 80.0f);
                    QAngle hAng(0, 0, 0);
                    Archipelago::CreateAPHologram(finalOffset, hAng, 0.66f, ent, "", 2, holoName);
                }
            }
        }
        @ent = EntityList().Next(ent);
    }
}

} // namespace Archipelago
