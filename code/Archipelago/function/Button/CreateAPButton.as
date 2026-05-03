// =============================================================
// ARCHIPELAGO CREATE A P BUTTON
// =============================================================
void CreateAPButton(string name, Vector position, QAngle angle, float holo_scale) {
    string scenarioName = TranslateButtonName(name);

    // 0. CLEANUP & IDEMPOTENCY - Ensure no duplicate body or map prop exists here
    CBaseEntity@ entCheck = null;
    while ((@entCheck = EntityList().FindInSphere(entCheck, position, 24.0f)) !is null) {
        string cls = entCheck.GetClassname();
        string entName = entCheck.GetEntityName();
        
        // If an AP-named model already exists, we skip spawning entirely to prevent 'two buttons'
        if (entName == scenarioName + "_model" || entName.locate("ap_") == 0) {
            ArchipelagoLog("[Archipelago] Button already exists here. Skipping spawn.");
            return; 
        }

        // Kill any map props (buttons, switches, or dynamics) that shouldn't be here
        if (cls.locate("button") != uint(-1) || cls.locate("switch") != uint(-1) || cls.locate("dynamic") != uint(-1)) {
            entCheck.Remove();
        }
    }
    string uid = "ap_" + RandomInt(1000, 9999);
    CBaseEntity@ body = util::CreateEntityByName("prop_dynamic");
    if (body !is null) {
        body.KeyValue("targetname", scenarioName + "_model");
        body.SetModel("models/props/switch001.mdl");
        body.SetAbsOrigin(position);
        body.SetAbsAngles(angle);
        body.Spawn();
    }
    CBaseEntity@ cmd = util::CreateEntityByName("point_clientcommand");
    if (cmd !is null) {
        cmd.KeyValue("targetname", uid + "_cmd");
        cmd.Spawn();
    }
    CBaseEntity@ snd_dn = util::CreateEntityByName("ambient_generic");
    if (snd_dn !is null) {
        snd_dn.KeyValue("targetname", uid + "_dn");
        snd_dn.KeyValue("message", "Portal.button_down");
        snd_dn.KeyValue("spawnflags", "48"); 
        snd_dn.SetAbsOrigin(position);
        snd_dn.Spawn();
        snd_dn.SetParent(body, -1);
    }
    CBaseEntity@ snd_up = util::CreateEntityByName("ambient_generic");
    if (snd_up !is null) {
        snd_up.KeyValue("targetname", uid + "_up");
        snd_up.KeyValue("message", "Portal.button_up");
        snd_up.KeyValue("spawnflags", "48"); 
        snd_up.SetAbsOrigin(position);
        snd_up.Spawn();
        snd_up.SetParent(body, -1);
    }
    CBaseEntity@ brain = util::CreateEntityByName("func_rot_button");
    if (brain !is null) {
        brain.KeyValue("targetname", scenarioName);
        brain.KeyValue("spawnflags", "1025");
        brain.KeyValue("wait", "0.5");
        brain.PrecacheScriptSound("Portal.button_down");
        brain.PrecacheScriptSound("Portal.button_up");
        string trigger = "ReportAPButton " + scenarioName;
        SafeAddOutput(brain, "OnPressed", uid + "_cmd", "Command", trigger, 0.1f, -1);
        SafeAddOutput(brain, "OnPressed", "!parent", "SetAnimation", "down", 0.0f, -1);
        SafeAddOutput(brain, "OnPressed", "!parent", "SetAnimation", "up", 0.5f, -1);
        SafeAddOutput(brain, "OnPressed", uid + "_dn", "PlaySound", "", 0.0f, -1);
        SafeAddOutput(brain, "OnPressed", uid + "_up", "PlaySound", "", 0.5f, -1);
        brain.Spawn();
        brain.SetParent(body, -1);
        brain.SetLocalOrigin(Vector(0, 0, 40)); 
        CollisionProperty@ coll = brain.CollisionProp();
        if (coll !is null) {
            coll.SetSolid(SOLID_BBOX);
            coll.SetCollisionBounds(Vector(-8, -8, -8), Vector(8, 8, 8));
        }
    }
   // --- NEW LOGIC FOR THE HOLOGRAM ---
    Vector hPos;
    QAngle hAng;
    int hSkin;
    float hScale = holo_scale;

// Use our central visual override system
    GetHologramVisualOverrides(body, hPos, hAng, hSkin, hScale);

// Create the hologram with the new name and proper parent
    StableCreateAPHologram(hPos, hAng, hScale, "", "", hSkin, scenarioName + "_holo", body);

}

