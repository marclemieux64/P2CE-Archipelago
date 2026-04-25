ConVar ap_hologram_freeze("ap_hologram_freeze", "0", FCVAR_CHEAT);

void CreateAPHologram(Vector position, QAngle angles, float scale, string new_parent = "", string attachment = "", int skin = 0, string name = "") {
    Msgl("[AP] CreateAPHologram executing: Pos(" + position.x + "," + position.y + "," + position.z + ") Name: " + name);

    // 0. IDEMPOTENCY CHECK - Avoid double spawning at the same spot
    CBaseEntity@ check = null;
    while ((@check = EntityList().FindByClassnameWithin(check, "prop_dynamic", position, 128.0f)) !is null) {
        if (check.GetModelName().locate("archipelago_hologram") != uint(-1)) {
            // New Name-Aware Check: Only snap if it's the SAME named hologram OR both are unnamed
            string checkName = check.GetEntityName();
            if (name != "" && checkName != name) continue; 
            
            // A hologram already exists near here! 
            // We update its skin, scale, and POSITION to the new correct one.
            check.SetAbsOrigin(position);
            check.SetAbsAngles(angles);
            check.KeyValue("skin", skin);
            check.KeyValue("modelscale", "" + scale);

            if (ap_hologram_freeze.GetBool()) {
                CBaseAnimating@ anim = cast<CBaseAnimating>(check);
                if (anim !is null) anim.SetPlaybackRate(0.0f);
            } else {
                CBaseAnimating@ anim = cast<CBaseAnimating>(check);
                if (anim !is null) anim.SetPlaybackRate(1.0f);
            }
            return;
        }
    }

    // 1. Setup the entity (AngelScript P2CE API)
    CBaseEntity@ holo = util::CreateEntityByName("prop_dynamic");
    if (holo is null) return;

    holo.KeyValue("model", "models/effects/ap/archipelago_hologram.mdl");
    holo.KeyValue("solid", "0");
    holo.KeyValue("skin", skin);
    holo.KeyValue("modelscale", "" + scale);
    holo.KeyValue("DefaultAnim", "idle");

    if (name != "") {
        holo.KeyValue("targetname", name);
    }
    
    holo.SetAbsOrigin(position);
    holo.SetAbsAngles(angles);

    // 2. Spawn
    holo.Spawn();

    if (ap_hologram_freeze.GetBool()) {
        CBaseAnimating@ anim = cast<CBaseAnimating>(holo);
        if (anim !is null) anim.SetPlaybackRate(0.0f);
    }

    if (new_parent != "") {
        holo.KeyValue("parentname", new_parent);
        if (attachment != "") {
            holo.SetParentAttachment(attachment);
        }
    }

    // 3. Final snap
    holo.SetAbsOrigin(position);
    holo.SetAbsAngles(angles);
}
