namespace Archipelago {

    void CreateAPButton(string name, Vector position, QAngle angle, float holo_scale, int skin = 0) {
        string scenarioName = TranslateButtonName(name);

        if (scenarioName.locate("rd") == 0) skin = 0;

        array<CBaseEntity@> entsToRemove;
        CBaseEntity@ entCheck = null;
        
        while ((@entCheck = EntityList().FindInSphere(entCheck, position, 24.0f)) !is null) {
            string cls = entCheck.GetClassname();
            string entName = entCheck.GetEntityName();
            
            if (entName == scenarioName + "_model" || entName.locate("ap_") == 0) return;
            
            if (cls.locate("button") != uint(-1) || cls.locate("switch") != uint(-1) || cls.locate("dynamic") != uint(-1)) {
                entsToRemove.insertLast(entCheck); 
            }
        }

        for (uint i = 0; i < entsToRemove.length(); i++) {
            entsToRemove[i].Remove();
        }

        string uid = "ap_" + RandomInt(1000, 9999);
        
        CBaseEntity@ body = util::CreateEntityByName("prop_dynamic");
        if (body !is null) {
            body.KeyValue("targetname", scenarioName + "_model");
            body.SetModel("models/props/switch001.mdl");
            body.KeyValue("solid", "6");
            body.SetAbsOrigin(position);
            body.SetAbsAngles(angle);
            body.Spawn();
        }

        CBaseEntity@ snd_dn = util::CreateEntityByName("ambient_generic");
        if (snd_dn !is null) {
            snd_dn.KeyValue("targetname", uid + "_dn");
            snd_dn.KeyValue("message", "Portal.button_down");
            snd_dn.KeyValue("spawnflags", "48"); 
            snd_dn.SetAbsOrigin(position);
            snd_dn.Spawn();
            snd_dn.SetParent(body);
        }

        CBaseEntity@ snd_up = util::CreateEntityByName("ambient_generic");
        if (snd_up !is null) {
            snd_up.KeyValue("targetname", uid + "_up");
            snd_up.KeyValue("message", "Portal.button_up");
            snd_up.KeyValue("spawnflags", "48"); 
            snd_up.SetAbsOrigin(position);
            snd_up.Spawn();
            snd_up.SetParent(body);
        }

        CBaseEntity@ brain = util::CreateEntityByName("func_rot_button");
        if (brain !is null) {
            brain.KeyValue("targetname", scenarioName);
            brain.KeyValue("spawnflags", "1025");
            brain.KeyValue("wait", "0.5");
            
            // L'ASTUCE : On lui donne un modèle pour que le moteur "accepte" de calculer ses collisions...
            brain.SetModel("models/props/switch001.mdl");
            // ... Mais on le rend 100% invisible pour qu'on ne voie que votre prop_dynamic !
            brain.KeyValue("rendermode", "10");
        
            SafeAddOutput(brain, "OnPressed", "InitCmd", "Command", "ReportAPButton " + scenarioName, 0.1f, -1);
            SafeAddOutput(brain, "OnPressed", "!parent", "SetAnimation", "down", 0.0f, -1);
            SafeAddOutput(brain, "OnPressed", "!parent", "SetAnimation", "up", 0.5f, -1);
            SafeAddOutput(brain, "OnPressed", uid + "_dn", "PlaySound", "", 0.0f, -1);
            SafeAddOutput(brain, "OnPressed", uid + "_up", "PlaySound", "", 0.5f, -1);
        
            // ON ÉCRASE LA TAILLE DU MODÈLE : On le force à être un cube
            brain.SetSolid(SOLID_BBOX);
            
            // VOTRE CUBE GÉANT : Va de -30 à +30 = Un gros cube de 60x60x60 !
            brain.SetCollisionBounds(Vector(-30.0f, -30.0f, -30.0f), Vector(30.0f, 30.0f, 30.0f));
            
            brain.Spawn();
            brain.SetParent(body);
            
            // On centre ce cube géant exactement au milieu du plastique
            brain.SetLocalOrigin(Vector(0, 0, 0)); 
        }

        Vector localPos = Vector(0, 0, 90.0f);
        QAngle localAng = QAngle(0, 90, 0);
        CreateAPHologram(localPos, localAng, holo_scale, body, "", skin, name);
    }



} // namespace Archipelago
