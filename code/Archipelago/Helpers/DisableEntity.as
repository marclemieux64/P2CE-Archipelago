// =============================================================
// ARCHIPELAGO DISABLE ENTITY
// =============================================================

/**
 * DisableEntity - Safely shuts down an entity without deleting it.
 * Works on funnels, triggers, beams, and lights.
 */
void DisableEntity(string search_term) {
    array<CBaseEntity@> targets = FindEntities(search_term);
    
    for (uint i = 0; i < targets.length(); i++) {
        CBaseEntity@ target = targets[i];
        
        // 1. Primary Disable
        target.FireInput("Disable", Variant(), 0.0f, null, null, 0);
        target.FireInput("Deactivate", Variant(), 0.0f, null, null, 0);
        target.FireInput("TurnOff", Variant(), 0.0f, null, null, 0);
        
        Vector pos = target.GetAbsOrigin();
        Vector totalMins(-16, -16, -16);
        Vector totalMaxs(16, 16, 16);
        bool foundClip = false;
        
        // 2. Positional Sweep (Funnels)
        // If this is a tractor beam, find and disable the "Funnel Team" (Lights/Clips)
        string cls = target.GetClassname();
        if (cls == "prop_tractor_beam" || cls == "prop_excursion_funnel") {
            CBaseEntity@ nearby = null;
            while ((@nearby = EntityList().FindInSphere(nearby, pos, 64.0f)) !is null) {
                string nCls = nearby.GetClassname();
                if (nCls == "light" || nCls == "trigger_player_clip" || nCls == "env_instructor_hint" || 
                    nCls == "func_clip_vphysics" || nCls == "func_brush" || nCls == "trigger_vphysics_motion") {
                    
                    bool isClip = (nCls == "func_clip_vphysics" || nCls == "trigger_player_clip" || nCls == "func_brush");
                    
                    if (isClip) {
                        // Measure the clip's bounds
                        Vector cMins, cMaxs;
                        nearby.ComputeWorldSpaceSurroundingBox(cMins, cMaxs);
                        
                        // Convert to local space for the target
                        cMins = cMins - pos;
                        cMaxs = cMaxs - pos;
                        
                        // Expand our target's bounds to match (Simple envelope)
                        if (!foundClip) {
                            totalMins = cMins;
                            totalMaxs = cMaxs;
                            foundClip = true;
                        } else {
                            totalMins = totalMins.Min(cMins);
                            totalMaxs = totalMaxs.Max(cMaxs);
                        }
                    }
                    
                    nearby.FireInput("Disable", Variant(), 0.0f, null, null, 0);
                    nearby.FireInput("TurnOff", Variant(), 0.0f, null, null, 0);
                }
            }
        }

        // Force the target projector to adopt the measured solid size of the clips
        target.SetSolid(SOLID_BBOX);
        target.SetCollisionBounds(totalMins, totalMaxs);
        target.SetMoveType(MOVETYPE_PUSH);
        target.SetAbsOrigin(pos);

        // --- PHYSICAL PLUG ---
        CBaseEntity@ frame = util::CreateEntityByName("prop_dynamic");
        if (frame !is null) {
            frame.SetModel("models/props/archipelago/ap_proptractorbeamframe.mdl");
            
            // Model is already 2.0x in the files, so use 1.0x scale here
            float scale = 1.0f;
            
            // Nudge the frame forward slightly to prevent clipping (Increased for safety)
            Vector nudge = target.Forward() * 5.0f;
            frame.SetAbsOrigin(pos + nudge);
            
            // Adjust orientation to be perpendicular to the beam
            QAngle frameAngles = target.GetAbsAngles();
            frameAngles.x += 90.0f;
            frame.SetAbsAngles(frameAngles);
            
            // Apply configuration before spawning
            frame.KeyValue("solid", "6");
            frame.KeyValue("modelscale", "" + scale);
            frame.KeyValue("disableshadows", "1");
            frame.KeyValue("disablereceiveshadows", "1");
            frame.Spawn();
            
            // Use the model's native baked-in VPhysics
            frame.SetSolid(SOLID_VPHYSICS);
            frame.SetMoveType(MOVETYPE_PUSH);
            
            // Final wake-up call for physics
            frame.FireInput("EnableCollision", Variant(), 0.0f, null, null, 0);
        }
    }
    
    ArchipelagoLog("[Archipelago] Disabled entity: " + search_term);
}
