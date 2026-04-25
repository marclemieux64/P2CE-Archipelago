void SpawnAPButtonLogic(string name, Vector position, QAngle angle, float holo_scale) {
    string scenarioName = TranslateButtonName(name);
    string uid = "ap_" + RandomInt(1000, 9999);
    Msgl("[AP-DEBUG] Spawning Button Assembly: " + name + " -> " + scenarioName);

    // 1. Spawn Button Body
    CBaseEntity@ body = util::CreateEntityByName("prop_dynamic");
    if (body !is null) {
        body.KeyValue("targetname", scenarioName + "_model");
        body.SetModel("models/props/switch001.mdl");
        body.SetAbsOrigin(position);
        body.SetAbsAngles(angle);
        body.Spawn();
        Msgl("[AP-DEBUG] Body Created.");
    }

    // 2. Spawn Command Interface
    CBaseEntity@ cmd = util::CreateEntityByName("point_clientcommand");
    if (cmd !is null) {
        cmd.KeyValue("targetname", uid + "_cmd");
        cmd.Spawn();
    }

    // 3. Audio Setup
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

    // 4. Logic Hub (The actual button brain)
    CBaseEntity@ brain = util::CreateEntityByName("func_rot_button");
    if (brain !is null) {
        brain.KeyValue("targetname", scenarioName);
        brain.KeyValue("spawnflags", "1025");
        brain.KeyValue("wait", "0.5");
        
        // Ensure it has some form of model/bounds so the engine doesn't kill it
        brain.KeyValue("model", "models/props/switch001.mdl");
        brain.KeyValue("rendermode", "10"); // Invisible
        
        string trigger = "ReportAPButton " + scenarioName;
        Variant vOut;
        vOut.SetString("OnPressed " + uid + "_cmd:Command:" + trigger + ":0.1:-1");
        brain.FireInput("AddOutput", vOut, 0.0f, null, null, 0);
        vOut.SetString("OnPressed !parent:SetAnimation:down:0.0:-1");
        brain.FireInput("AddOutput", vOut, 0.0f, null, null, 0);
        vOut.SetString("OnPressed !parent:SetAnimation:up:0.5:-1");
        brain.FireInput("AddOutput", vOut, 0.0f, null, null, 0);
        vOut.SetString("OnPressed " + uid + "_dn:PlaySound::0.0:-1");
        brain.FireInput("AddOutput", vOut, 0.0f, null, null, 0);
        vOut.SetString("OnPressed " + uid + "_up:PlaySound::0.5:-1");
        brain.FireInput("AddOutput", vOut, 0.0f, null, null, 0);
        
        brain.Spawn();
        brain.SetParent(body, -1);
        brain.SetLocalOrigin(Vector(0, 0, 40)); 
        
        CollisionProperty@ coll = brain.CollisionProp();
        if (coll !is null) {
            coll.SetSolid(SOLID_BBOX);
            coll.SetCollisionBounds(Vector(-8, -8, -8), Vector(8, 8, 8));
        }
        Msgl("[AP-DEBUG] Brain Spawned.");
    }

    // 5. Unified Archipelago Hologram (Registry Driven)
    Vector hPos;
    QAngle hAng;
    int hSkin;
    float hScale;
    
    // Check registry for final positioning
    GetHologramVisualOverrides(body, hPos, hAng, hSkin, hScale);
    float finalScale = (hScale != 1.0f) ? hScale : holo_scale;

    CreateAPHologram(hPos, hAng, finalScale, scenarioName + "_model", "", hSkin, scenarioName + "_holo");
}
