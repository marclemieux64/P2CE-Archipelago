namespace Archipelago {

    void AddTractorBeamFrame(string entity_name) {
        array<CBaseEntity@> targets = FindEntities(entity_name);
        for (uint i = 0; i < targets.length(); i++) {
            CBaseEntity@ ent = targets[i];
        
        // Save the original properties before we destroy it
            Vector position = ent.GetAbsOrigin();
            QAngle angles = ent.GetAbsAngles();
            string originalModel = ent.GetModelName(); 
        
        // Calcul des vecteurs directionnels basés sur l'angle natif du prop_wall_projector
            Vector forward, right, up;
            AngleVectors(angles, forward, right, up);
    
        // 1. Spawn the custom Archipelago frame
            CBaseEntity@ box = util::CreateEntityByName("prop_dynamic");
            if (box !is null) {
                box.KeyValue("targetname", entity_name + "_frame");
                box.KeyValue("model", "models/props/archipelago/ap_proptractorbeamframe.mdl");
                box.KeyValue("solid", "6");
            
            // FIX ANTI-CLIPPING : On décale la position du cadre de 3 unités vers l'avant (hors du mur)
                float forwardOffset = 3.0f;
                float rightOffset = 0.0f;
                float upOffset = 0.0f;

                if (current_map == "sp_a4_finale2" && ent.GetEntityName() != "crusher_ride_tbeam") {
                // =============================================================
                // TWEAK THIS: Adjust these values to fix the frame placement!
                // =============================================================
                    forwardOffset = -30.0f; // Adjust distance from the wall (along forward vector)
                    rightOffset = 0.0f; // Adjust lateral alignment (along right vector)
                    upOffset = 0.0f; // Adjust vertical alignment (along up vector)
                }

                Vector frameOffsetPos = position + (forward * forwardOffset) + (right * rightOffset) + (up * upOffset);
                box.SetAbsOrigin(frameOffsetPos);
            
                QAngle angleOffset(90.0f, 0.0f, 0.0f);
                QAngle finalFrameAngles = angles + angleOffset;
                box.SetAbsAngles(finalFrameAngles);
            
                box.Spawn();
            }
    
        // 2. Spawn the un-parented Hologram
            string holoName = entity_name + "_" + ent.GetEntityIndex() + "_holo";
            if (EntityList().FindByName(null, holoName) is null) {
                Vector hPos(0, 0, 0);
                QAngle hAng(0, 0, 0);
                int hSkin = 0;
                float hScale = 1.0f;
                bool hParent = false; // Always false so it survives
                bool hAbs = false;
            
            // We still get overrides, but we ignore what it says about hParent
                Archipelago::GetHologramVisualOverrides(ent, hPos, hAng, hSkin, hScale, hParent, hAbs);
            
                if (current_map == "sp_a4_finale2" && ent.GetEntityName() != "crusher_ride_tbeam") {
                // =============================================================
                // TWEAK THIS: Adjust hologram offset here if needed!
                // =============================================================
                // hPos.x = forward offset (def: 80.0f), hPos.y = right offset, hPos.z = up offset
                    hPos = Vector(47.0f, 0.0f, 0.0f);
                }

                Vector finalPos = position + (forward * hPos.x) + (right * hPos.y) + (up * hPos.z);
                QAngle finalAng = hAbs ? hAng : (angles + hAng);

                Archipelago::CreateAPHologram(finalPos, finalAng, hScale, null, "", hSkin, holoName);
            }

        // 3. Spawn the Inert "Dummy" Replacement
            CBaseEntity@ dummy = util::CreateEntityByName("prop_dynamic");
            if (dummy !is null) {
            // We intentionally leave the targetname blank so scripts can't find it
                dummy.KeyValue("model", originalModel);
                dummy.KeyValue("solid", "6"); // Keep VPhysics collisions
                dummy.SetAbsOrigin(position);
                dummy.SetAbsAngles(angles);
                dummy.Spawn();
            }

        // 4. Murder the real, functioning tractor beam
            ent.Remove();
        }
    }

} // namespace Archipelago
