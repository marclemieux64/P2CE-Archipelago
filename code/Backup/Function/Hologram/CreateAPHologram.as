// =============================================================
// ARCHIPELAGO STABLE CREATE AP HOLOGRAM
// =============================================================

/**
 * StableCreateAPHologram - Factory function that ensures a hologram exists for 
 * a specific location without creating duplicates.
 */
CBaseEntity@ StableCreateAPHologram(Vector position, QAngle angles, float scale, string attachment = "", string bone = "", int skin = 0, string name = "", CBaseEntity@ parent = null, string animation = "idle") {
    CBaseEntity@ h = null;

    if (name != "") {
        @h = EntityList().FindByName(null, name);
    }

    // Name collision / Type check
    if (h !is null) {
        if (h.GetModelName().locate("archipelago_hologram") != uint(-1)) {
            // Already exists - RE-SYNC visuals
            h.SetAbsOrigin(position);
            h.SetAbsAngles(angles);
            h.KeyValue("skin", "" + skin);
            h.KeyValue("modelscale", "" + scale);
            return h;
        } else {
            name = name + "_ap_holo";
            @h = null; // Reset h to force creation
        }
    }

    // Proximity check to prevent overlapping identical holograms
    CBaseEntity@ nearby = EntityList().FindByClassnameNearest("prop_dynamic", position, 5.0f);
    if (nearby !is null && nearby.GetModelName().locate("archipelago_hologram") != uint(-1)) {
        if (name == "" || nearby.GetEntityName() == name) {
            nearby.SetAbsOrigin(position);
            nearby.KeyValue("skin", "" + skin);
            return nearby;
        }
    }

    // Create the entity
    @h = util::CreateEntityByName("prop_dynamic");
    if (h !is null) {
        h.KeyValue("model", "models/effects/ap/archipelago_hologram.mdl");
        if (name != "") h.KeyValue("targetname", name);
        h.KeyValue("skin", "" + skin);
        h.KeyValue("modelscale", "" + scale);
        
        // Use KeyValue for animation to avoid unstable FireInput calls during init
        if (animation != "") {
            h.KeyValue("DefaultAnim", animation);
        } else {
            h.KeyValue("DefaultAnim", "idle");
            h.KeyValue("playbackrate", "0.0");
        }
        
        h.SetAbsOrigin(position);
        h.SetAbsAngles(angles);
        h.Spawn();

        // Holograms should be non-solid by default to avoid blocking players
        h.SetSolid(SOLID_NONE);
        h.SetMoveType(MOVETYPE_NONE);

        if (parent !is null) {
            h.SetParent(parent, -1);
            if (attachment != "") {
                Variant v;
                v.SetString(attachment);
                h.FireInput("SetParentAttachment", v, 0.01f, null, null, 0);
            }
        }
    }

    return h;
}

/**
 * CreateAPHologram - Backward compatibility wrapper.
 */
CBaseEntity@ CreateAPHologram(Vector position, QAngle angles, float scale, string attachment = "", string bone = "", int skin = 0, string name = "", CBaseEntity@ parent = null) {
    return StableCreateAPHologram(position, angles, scale, attachment, bone, skin, name, parent);
}
