ConVar hologram_freeze("ap_hologram_freeze", "0", FCVAR_CHEAT);

// THE GHOST TRAP: Any script calling this is using legacy/broken logic
void CreateAPHologram(Vector position, QAngle angles, float scale, string new_parent = "", string attachment = "", int skin = 0, string name = "", CBaseEntity@ parentEnt = null) {
    ArchipelagoLog("[AP WARNING] !!! LEGACY CreateAPHologram CALL DETECTED !!! Name: " + name);
    // Forward it to the stable version so the game doesn't break, but we know it happened.
    StableCreateAPHologram(position, angles, scale, new_parent, attachment, skin, name, parentEnt);
}

void StableCreateAPHologram(Vector position, QAngle angles, float scale, string new_parent = "", string attachment = "", int skin = 0, string name = "", CBaseEntity@ parentEnt = null) {
    // 0. IDEMPOTENCY CHECK (VITAL)
    CBaseEntity@ h = null;

    // Check by name first
    if (name != "" && name.locate("(null") == uint(-1)) {
        @h = EntityList().FindByName(null, name);
    }

    // Check by parent relationship (BEST WAY for moving turrets)
    if (h is null && parentEnt !is null) {
        CBaseEntity@ child = null;
        while ((@child = EntityList().FindByClassname(child, "prop_dynamic")) !is null) {
            if (child.GetMoveParent() !is null && child.GetMoveParent() is parentEnt) {
                if (child.GetModelName().locate("archipelago_hologram") != uint(-1)) {
                    @h = child;
                    break;
                }
            }
        }
    }

    // Proximity fallback (for unparented holos)
    if (h is null) {
        CBaseEntity@ check = null;
        while ((@check = EntityList().FindByClassnameWithin(check, "prop_dynamic", position, 32.0f)) !is null) {
            if (check.GetModelName().locate("archipelago_hologram") != uint(-1)) {
                @h = check;
                break;
            }
        }
    }

    if (h !is null) {
        // Already exists, update and BAIL
        h.KeyValue("skin", "" + skin);
        if (name != "" && name.locate("(null") == uint(-1) && h.GetEntityName() == "") {
            h.KeyValue("targetname", name);
        }
        return;
    }

    // 1. Setup the entity
    CBaseEntity@ holo = util::CreateEntityByName("prop_dynamic");
    if (holo is null) return;

    holo.KeyValue("model", "models/effects/ap/archipelago_hologram.mdl");
    holo.KeyValue("solid", "0");
    holo.KeyValue("skin", "" + skin);
    holo.KeyValue("modelscale", "" + scale);
    holo.KeyValue("DefaultAnim", "idle");

    if (name != "" && name.locate("(null") == uint(-1)) holo.KeyValue("targetname", name);
    
    holo.SetAbsOrigin(position);
    holo.SetAbsAngles(angles);

    // 2. Spawn
    holo.Spawn();
    holo.KeyValue("movetype", "0"); // Force MOVETYPE_NONE

    // 3. Parenting
    string finalAttachment = attachment;
    if (finalAttachment.locate("(null") != uint(-1)) finalAttachment = "";

    if (parentEnt !is null) {
        holo.SetParent(parentEnt, -1);
        if (finalAttachment.length() > 1 && finalAttachment != "null" && finalAttachment != "none") {
            holo.SetParentAttachment(finalAttachment);
        }
    } else if (new_parent != "" && new_parent.locate("(null") == uint(-1)) {
        CBaseEntity@ pEnt = EntityList().FindByName(null, new_parent);
        if (pEnt !is null) {
            holo.SetParent(pEnt, -1);
            if (finalAttachment.length() > 1 && finalAttachment != "null" && finalAttachment != "none") {
                holo.SetParentAttachment(finalAttachment);
            }
        } else {
            holo.KeyValue("parentname", new_parent);
        }
    }
}
