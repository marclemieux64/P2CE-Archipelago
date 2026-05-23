namespace Archipelago {

void RemovePotatOS() {
     ArchipelagoLog("[AP DEBUG] RemovePotatOS: Disabling elevator,removing potatOs Prop.");
        CBaseEntity@ button = EntityList().FindByName(null, "sphere_entrance_potatos_button");
        if (button !is null) {
            Vector place = button.GetAbsOrigin();
            CBaseEntity@ target = util::CreateEntityByName("info_target_instructor_hint");
            target.KeyValue("targetname", "hint_target_no_potatos");
            target.SetAbsOrigin(place);
            target.Spawn();
        
            DeleteEntity("sphere_entrance_lift_relay", false);
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
        
        }

        CBaseEntity@ hint = util::CreateEntityByName("env_instructor_hint");
        hint.KeyValue("targetname", "hudhint_no_potatos");
        hint.KeyValue("hint_target", "hint_target_no_potatos");
        hint.KeyValue("hint_static", "0");
        hint.KeyValue("hint_caption", "PotatOS not unlocked");
        hint.KeyValue("hint_icon_onscreen", "icon_alert");
        hint.KeyValue("hint_color", "255 50 50");
        hint.Spawn();

        SafeAddOutput(EntityList().FindByName(null, "sphere_entrance_potatos_button"), "OnPressed", "hudhint_no_potatos", "ShowHint", "", 0.0f, -1);
        
        // --- NEW: Silence GLaDOSVO exclusively here ---
        CBaseEntity@ cmd = EntityList().FindByName(null, "InitCmd");
        if (cmd !is null) {
            Variant vMixG;
            vMixG.SetString("snd_setmixer GLaDOSVO vol 0.0");
            cmd.FireInput("Command", vMixG, 0.0f, null, null, 0);
        }

        RemovePotatosFromGun();
    }

} // namespace Archipelago
