// =============================================================
// ARCHIPELAGO MASTER HEARTBEAT
// =============================================================

/**
 * APDeathLinkTickCmd - The 1-second pulse that drives the mod.
 * We register this last so it can see both the Bootstrap and the Client.
 */
[ServerCommand("ap_deathlink_tick", "Internal mod heartbeat")]
void APDeathLinkTickCmd(const CommandArgs@ args) {
    // 1. Ensure map is initialized (Self-Healing)
    RunDelayedInitialization();
    
    // 2. Perform periodic health checks
    RunDeathLinkTick();

    // 3. DEBUG: Heartbeat Pulse (Check console with ~)
    // Msgl("[AP] Heartbeat Pulse..."); 

    // 4. Constant Suppression Loop (Force Stop marked entities)
    CBaseEntity@ cmd = EntityList().FindByName(null, "ap_init_cmd");
    if (cmd !is null && g_suppressed_entities.length() > 0) {
        for (uint i = 0; i < g_suppressed_entities.length(); i++) {
            Variant v;
            v.SetString("ent_fire " + g_suppressed_entities[i] + " Stop");
            cmd.FireInput("Command", v, 0.0f, null, null, 0);
        }
    }

    // 5. Persistent Class Suppression (Handles dynamically spawned entities like factory turrets)
    if (g_suppressed_classes.length() > 0) {
        for (uint i = 0; i < g_suppressed_classes.length(); i++) {
            string cls = g_suppressed_classes[i];
            
            CBaseEntity@ t = null;
            while ((@t = EntityList().FindByClassname(t, cls)) !is null) {
                // Check if this specific turret already has a hologram
                string hName = cls + "_" + t.GetEntityIndex() + "_attached_holo";
                if (EntityList().FindByName(null, hName) !is null) continue;

                // New or un-processed turret detected
                DisableEntityPickup(cls);
                AttachHologramToEntity(cls, "", 0.66f, 20.0f, 2);
                break; // AttachHologramToEntity will handle all of them anyway, but we just need to trigger it once
            }

            // BTS4 Stale Hologram Cleanup
            if (current_map == "sp_a2_bts4") {
                CBaseEntity@ h = null;
                while ((@h = EntityList().FindByClassname(h, "prop_dynamic")) !is null) {
                    if (h.GetModelName().locate("archipelago_hologram") != uint(-1)) {
                        string hName = h.GetEntityName();
                        if (hName.locate("turret_conveyor_1_turret_") != uint(-1) || hName.locate("dummyshoot_conveyor_1_turret") == 0) {
                            // Check if this hologram is 'stale' (not near any live turret)
                            CBaseEntity@ nearbyTurret = EntityList().FindByClassnameWithin(null, "npc_portal_turret_floor", h.GetAbsOrigin(), 60.0f);
                            if (nearbyTurret is null) {
                                h.Remove();
                            }
                        }
                    }
                }
            }
        }
    }
}
