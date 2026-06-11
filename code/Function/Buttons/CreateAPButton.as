namespace Archipelago {

    // Tableau global de persistence pour stocker les boutons complétés de la session
    void CreateAPButton(string name, Vector position, QAngle angle, float holo_scale, int skin = 0) {
        string scenarioName = TranslateButtonName(name);
        if (scenarioName.locate("rd") == 0) skin = 0;

        // ÉTAPE DE VÉRIFICATION UNIFORME : Est-ce que le bouton est dans notre tableau global ?
        int is_pressed = (checked_buttons.find(scenarioName) != -1) ? 1 : 0;
        int finalSkin = (is_pressed == 1) ? 4 : skin;

        // Nom unique et standardisé de l'hologramme pour cet emplacement (ex: ratman_den_1_holo)
        string holoName = scenarioName + "_holo";

        array<CBaseEntity@> entsToRemove;
        CBaseEntity@ entCheck = null;
        
        while ((@entCheck = EntityList().FindInSphere(entCheck, position, 24.0f)) !is null) {
            string cls = entCheck.GetClassname();
            string entName = entCheck.GetEntityName();
            
            // Si le modèle existe déjà et qu'on rafraîchit l'état en cours de jeu
            if (entName == scenarioName + "_model") {
                if (is_pressed == 1) {
                    CBaseAnimating@ animBody = cast<CBaseAnimating>(entCheck);
                    if (animBody !is null) {
                        animBody.SetSequence(animBody.LookupSequence("down"));
                    }
                    CBaseEntity@ brainEnt = EntityList().FindByName(null, scenarioName);
                    if (brainEnt !is null) {
                        brainEnt.KeyValue("m_bLocked", 1);
                        brainEnt.KeyValue("spawnflags", "3073");
                    }
                    
                    // Recherche et mise à jour immédiate du skin de l'hologramme existant
                    CBaseEntity@ holo = null;
                    while ((@holo = EntityList().FindByClassname(holo, "prop_dynamic")) !is null) {
                        if (holo.GetMoveParent() is entCheck && holo.GetEntityName() == holoName) {
                            CBaseAnimating@ animHolo = cast<CBaseAnimating>(holo);
                            if (animHolo !is null) animHolo.SetSkin(finalSkin);
                            break;
                        }
                    }
                }
                return;
            }
            
            if (cls.locate("button") != uint(-1) || cls.locate("switch") != uint(-1) || cls.locate("dynamic") != uint(-1)) {
                entsToRemove.insertLast(entCheck); 
            }
        }

        for (uint i = 0; i < entsToRemove.length(); i++) {
            util::Remove(entsToRemove[i]);
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
            
            if (is_pressed == 1) {
                CBaseAnimating@ animBody = cast<CBaseAnimating>(body);
                if (animBody !is null) {
                    animBody.SetSequence(animBody.LookupSequence("down"));
                }
            }
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
            
            int spawnFlags = 1025;
            if (is_pressed == 1) {
                spawnFlags += 2048; 
            }
            brain.KeyValue("spawnflags", "" + spawnFlags);
            brain.KeyValue("wait", "0.5");
            
            brain.SetModel("models/props/switch001.mdl");
            brain.KeyValue("rendermode", "10");
        
            SafeAddOutput(brain, "OnPressed", "InitCmd", "Command", "ReportAPButton " + scenarioName, 0.1f, -1);
            SafeAddOutput(brain, "OnPressed", "!parent", "SetAnimation", "down", 0.0f, -1);
            SafeAddOutput(brain, "OnPressed", "!parent", "SetAnimation", "up", 0.5f, -1);
            SafeAddOutput(brain, "OnPressed", uid + "_dn", "PlaySound", "", 0.0f, -1);
            SafeAddOutput(brain, "OnPressed", uid + "_up", "PlaySound", "", 0.5f, -1);
        
            brain.SetSolid(SOLID_BBOX);
            brain.SetCollisionBounds(Vector(-30.0f, -30.0f, -30.0f), Vector(30.0f, 30.0f, 30.0f));
            
            brain.Spawn();
            brain.SetParent(body, -1);
            brain.SetLocalOrigin(Vector(0, 0, 0)); 
            
            if (is_pressed == 1) {
                brain.KeyValue("m_bLocked", 1);
            }
        }

        Vector localPos = Vector(0, 0, 90.0f);
        QAngle localAng = QAngle(0, 90, 0);

        CreateAPHologram(localPos, localAng, holo_scale, body, "", finalSkin, holoName, true);
    }
}// namespace Archipelago

