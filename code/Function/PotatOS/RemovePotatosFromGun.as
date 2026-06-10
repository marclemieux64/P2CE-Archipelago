namespace Archipelago {

    void RemovePotatosFromGun() {
        ArchipelagoLog("[AP DEBUG] RemovePotatosFromGun: Executing viewmodel and world cleanup.");
        
        // 1. VIEWMODEL: Force removal via the player proxy
        CBaseEntity@ lpp = EntityList().FindByClassname(null, "logic_playerproxy");
        if (lpp is null) {
            @lpp = util::CreateEntityByName("logic_playerproxy");
            if (lpp !is null) { lpp.KeyValue("targetname", "ap_lpp"); lpp.Spawn(); }
        }
        
        if (lpp !is null) {
            lpp.FireInput("RemovePotatosFromPortalgun", Variant(), 0.0f, null, null, 0);
        }

        // 2. WORLD SPACE: Make them invisible and attach holograms instead of deleting them!
        string[] potatosEntities = { "potatos_prop", "potatos", "models/props/potatos.mdl" };
        for (uint i = 0; i < potatosEntities.length(); i++) {
            string nameOrModel = potatosEntities[i];
            
            array<CBaseEntity@> targets;
            CBaseEntity@ ent = null;
            if (nameOrModel.locate(".mdl") != uint(-1)) {
                while ((@ent = EntityList().FindByModel(ent, nameOrModel)) !is null) {
                    targets.insertLast(ent);
                }
            } else {
                while ((@ent = EntityList().FindByName(ent, nameOrModel)) !is null) {
                    targets.insertLast(ent);
                }
            }
            
            for (uint j = 0; j < targets.length(); j++) {
                CBaseEntity@ target = targets[j];
                if (target !is null) {
                    target.KeyValue("rendermode", "10");
                    
                    string holoName = target.GetEntityName();
                    if (holoName == "") holoName = "potatos_holo_" + i + "_" + j; else holoName = holoName + "_holo";
                    
                    CreateAPHologram(Vector(0, 0, 0), QAngle(0, 0, 0), 0.3f, target, "", 4, holoName, false);
                }
            }
        }
        
        // 3. VOICE & UI: Silence audio group and subtitles via mixer
        CBaseEntity@ cmd = EntityList().FindByName(null, "InitCmd");
        if (cmd !is null) {
            Variant vMix;
            vMix.SetString("snd_setmixer potatosVO vol 0.0");
            cmd.FireInput("Command", vMix, 0.0f, null, null, 0);
            CallVScript("MutePotatOSSubtitles(true)");

        }
        ArchipelagoLog("[AP DEBUG] RemovePotatosFromGun: Done (Visuals, Mixer & Subtitles silenced).");
    }

} // namespace Archipelago
