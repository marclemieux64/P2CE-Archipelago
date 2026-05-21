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

    CBaseEntity@ CreateAPHologram(Vector position, QAngle angles, float scale, CBaseEntity@ parent = null, string attachment = "", int skin = 0, string name = "", bool animate = true) {
    CBaseEntity@ h = null;

    if (name != "") {
        @h = EntityList().FindByName(null, name);
    }

    // BLOC DE MISE À JOUR CORRECTIF POUR LE RELOAD
    if (h !is null) {
        if (h.GetModelName().locate("archipelago_hologram") != uint(-1)) {
            if (Archipelago::cv_ArchipelagoDebug.GetBool()) {
                Archipelago::ArchipelagoLog("[AP DEBUG] Updating Hologram '" + name + "' to " + angles.x + " " + angles.y + " " + angles.z + " | Skin: " + skin);
            }
            
            // 1. Re-parentage et gestion d'origine stricte à chaque snapshot pour contrer le reload
            if (parent !is null) {
                h.SetParent(parent);
                h.SetLocalOrigin(position);
                h.SetLocalAngles(angles);
                
                if (attachment != "") {
                    Variant v;
                    v.SetString(attachment);
                    h.FireInput("SetParentAttachment", v, 0.01f, null, null, 0);
                }
            } else {
                if (h.GetMoveParent() !is null) {
                    h.SetParent(null); 
                }
                h.SetAbsOrigin(position);
                h.SetAbsAngles(angles);
            }
            
            // 2. Refresh instantané du matériau via CBaseAnimating
            CBaseAnimating@ animH = cast<CBaseAnimating>(h);
            if (animH !is null) {
                animH.SetSkin(skin);
            } else {
                h.KeyValue("skin", "" + skin); 
            }
            
            h.KeyValue("modelscale", "" + scale);

            // Apply visibility settings
            int hideOption = Archipelago::cv_ArchipelagoHideHolograms.GetInt();
            bool shouldHide = (hideOption == 2) || (hideOption == 1 && skin == 4);
            Variant emptyVal;
            h.KeyValue("rendermode", "0");
            if (shouldHide) {
                h.FireInput("Disable", emptyVal, 0.0f, null, null, 0);
            } else {
                h.FireInput("Enable", emptyVal, 0.0f, null, null, 0);
            }

            return h;
        }
    }

    // BLOC DE CRÉATION INITIALE 
    @h = util::CreateEntityByName("prop_dynamic");
    if (h !is null) {
        h.KeyValue("model", "models/effects/ap/archipelago_hologram.mdl");
        if (name != "") h.KeyValue("targetname", name);
        h.KeyValue("skin", "" + skin);
        h.KeyValue("modelscale", "" + scale);
        h.KeyValue("DefaultAnim", animate ? "idle" : "");

        if (parent !is null) {
            h.SetAbsOrigin(parent.GetAbsOrigin()); 
            h.SetAbsAngles(parent.GetAbsAngles());
        } else {
            h.SetAbsOrigin(position); 
            h.SetAbsAngles(angles);
        }
        
        h.Spawn(); 

        h.SetSolid(SOLID_NONE);
        h.SetMoveType(MOVETYPE_NONE);

        if (parent !is null) {
            h.SetParent(parent);
            h.SetLocalOrigin(position); 
            h.SetLocalAngles(angles);
            
            if (attachment != "") {
                Variant v;
                v.SetString(attachment);
                h.FireInput("SetParentAttachment", v, 0.01f, null, null, 0);
            }
        }

        // Apply visibility settings
        int hideOption = Archipelago::cv_ArchipelagoHideHolograms.GetInt();
        bool shouldHide = (hideOption == 2) || (hideOption == 1 && skin == 4);
        Variant emptyVal;
        h.KeyValue("rendermode", "0");
        if (shouldHide) {
            h.FireInput("Disable", emptyVal, 0.0f, null, null, 0);
        } else {
            h.FireInput("Enable", emptyVal, 0.0f, null, null, 0);
        }
    }
    return h;
}

void UpdateHologramsVisibility() {
    CBaseEntity@ ent = null;
    int hideOption = cv_ArchipelagoHideHolograms.GetInt();
    
    while ((@ent = EntityList().FindByClassname(ent, "prop_dynamic")) !is null) {
        if (ent.GetModelName().locate("archipelago_hologram") != uint(-1)) {
            int skin = 0;
            CBaseAnimating@ anim = cast<CBaseAnimating>(ent);
            if (anim !is null) {
                skin = anim.GetSkin();
            }
            
            bool shouldHide = (hideOption == 2) || (hideOption == 1 && skin == 4);
            Variant emptyVal;
            ent.KeyValue("rendermode", "0");
            if (shouldHide) {
                ent.FireInput("Disable", emptyVal, 0.0f, null, null, 0);
            } else {
                ent.FireInput("Enable", emptyVal, 0.0f, null, null, 0);
            }
        }
    }
}

} // namespace Archipelago