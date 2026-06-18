namespace Archipelago {

void DoMapSpecificSetup() {
    if (current_map == "sp_a1_intro1") {
        ConVarRef skipIntroContainerCvar("cv_SkipIntroContainerScene");
        if (skipIntroContainerCvar.IsValid() && skipIntroContainerCvar.GetInt() == 1) {
            SkipContainer();
        }
    } else if (current_map == "sp_a1_intro3") {
        // Portal Gun pickup trigger (Primary - by Vector)
        AddEntityOutputScriptAtPos(Vector(25, 1958, -299), "trigger_once", "OnStartTouch", "PrintItem Portal Gun", 0.0f, 1);
        // Portal Gun pickup trigger (Backup for speedrun pickup)
        AddEntityOutputScriptAtPos(Vector(-704, 1856, -32), "trigger_multiple", "OnStartTouch", "PrintItem Portal Gun", 0.0f, 1);
        
    } else if (current_map == "sp_a1_intro4") {
        // Remplacement magique de la bouteille
        PreventPickupForModel("water_bottle.mdl");

    } else if (current_map == "sp_a2_intro") {
        // Upgraded Portal Gun (By Name)
        CBaseEntity@ gun_trigger = EntityList().FindByName(null, "player_near_portalgun");
        if (gun_trigger !is null) {
            SafeAddOutput(gun_trigger, "OnStartTouch", "InitCmd", "Command", "PrintItem Upgraded Portal Gun", 0.0f, 1);
        }
        
        // Upgraded Portal Gun (Backup - by Vector)
        AddEntityOutputScriptAtPos(Vector(-360, 440, -10680), "trigger_once", "OnStartTouch", "PrintItem Upgraded Portal Gun", 0.0f, 1);
        
    } else if (current_map == "sp_a2_trust_fling") {
        // Remplacement magique de la boîte et de la bouteille
        PreventPickupForModel("food_can_open.mdl");
        PreventPickupForModel("water_bottle.mdl");

    } else if (current_map == "sp_a2_bridge_the_gap") {
        // Instancier une référence au convar via ConVarRef pour sauter la scène de l'oiseau
        ConVarRef skipBirdCvar("cv_SkipBirdScene");
        
        // Si la convar existe et qu'elle est active (égale à 1)
        if (skipBirdCvar.IsValid() && skipBirdCvar.GetInt() == 1) {
            Vector targetPos(-1074, -640, 1224);
            CBaseEntity@ trigger = EntityList().FindByClassnameWithin(null, "trigger_once", targetPos, 16.0f);
            
            if (trigger !is null) {
                // Destruction du trigger spécifié via l'input Kill
                Variant empty;
                trigger.FireInput("Kill", empty, 0.0f, null, null, 0);
            }
        }

    } else if (current_map == "sp_a2_sphere_peek") {
        ConVarRef skipCeilingCvar("cv_SkipCeilingScene");

        if (skipCeilingCvar.IsValid() && skipCeilingCvar.GetInt() == 1) {
            // 1. Trouver notre entité de commande de la map pour lancer les relais
            CBaseEntity@ cmd = EntityList().FindByName(null, "InitCmd");
            
            if (cmd !is null) {
                // Déclencher le correctif du plafond (ceiling)
                Variant v1;
                v1.SetString("ent_fire @trigger_this_to_fix_ceiling Trigger");
                cmd.FireInput("Command", v1, 0.5f, null, null, 0);

                // Déclencher le correctif de la catapulte (catapult)
                Variant v2;
                v2.SetString("ent_fire @trigger_this_to_fix_catapult Trigger");
                cmd.FireInput("Command", v2, 0.6f, null, null, 0);
            } else {
                // Fallback direct en cas d'absence de l'entité InitCmd
                CBaseEntity@ ceilingRelay = EntityList().FindByName(null, "@trigger_this_to_fix_ceiling");
                if (ceilingRelay !is null) {
                    Variant empty;
                    ceilingRelay.FireInput("Trigger", empty, 0.0f, null, null, 0);
                }
                
                CBaseEntity@ catapultRelay = EntityList().FindByName(null, "@trigger_this_to_fix_catapult");
                if (catapultRelay !is null) {
                    Variant empty;
                    catapultRelay.FireInput("Trigger", empty, 0.0f, null, null, 0);
                }
            }

            // 2. Parcourir et supprimer de force l'ensemble des trigger_multiple anonymes du monde
            CBaseEntity@ ent = null;
            while ((@ent = EntityList().FindByClassname(ent, "trigger_multiple")) !is null) {
                if (ent.GetEntityName() == "") {
                    // Suppression brute via la fonction utilitaire du moteur
                    util::Remove(ent);
                }
            }
        }

    } else if (current_map == "sp_a3_transition01") {
        CBaseEntity@ potatos_btn = EntityList().FindByName(null, "sphere_entrance_potatos_button");
        if (potatos_btn !is null) {
            // On envoie les DEUX commandes à la console en même temps
            SafeAddOutput(potatos_btn, "OnPressed", "InitCmd", "Command", "PrintItem PotatOS; RemovePotatosFromGun", 0.0f, -1);
            
            potatos_btn.FireInput("Unlock", Variant(), 1.0f, null, null, 0);
        }
    } else if (current_map == "sp_a2_laser_intro") {
        CBaseEntity@ cmd = EntityList().FindByName(null, "InitCmd");
        if (cmd !is null) {
            Variant v1;
            v1.SetString("ent_fire laser_emitter_door_holo SetParent laser_emitter_door:0.8:-1");
            cmd.FireInput("Command", v1, 0.5f, null, null, 0);
            
            Variant v2;
            v2.SetString("ent_fire laser_catcher_door_holo SetParent laser_catcher_door:0.8:-1");
            cmd.FireInput("Command", v2, 0.5f, null, null, 0);
        }
    } else if (current_map == "sp_a2_laser_vs_turret") {
        // Remplacement magique de la bouteille
        PreventPickupForModel("water_bottle.mdl");
    } else if (current_map == "sp_a2_bts4") {
        CBaseEntity@ existingTimer = EntityList().FindByName(null, "bts4_conveyor_timer");
        if (existingTimer is null) {
            // Create a logic_timer to tick the conveyor hologram check
            CBaseEntity@ timer = util::CreateEntityByName("logic_timer");
            if (timer !is null) {
                timer.KeyValue("targetname", "bts4_conveyor_timer");
                timer.KeyValue("RefireTime", "0.1");
                
                // Format d'output Source: Target \x1B Input \x1B Parameter \x1B Delay \x1B MaxFires
                string payload = "InitCmd\x1BCommand\x1BAP_BTS4_ConveyorTick\x1B0\x1B-1";
                timer.KeyValue("OnTimer", payload);
                
                timer.Spawn();
                
                // Enable the timer
                Variant empty;
                timer.FireInput("Enable", empty, 0.0f, null, null, 0);
            }
        }
    } else if (current_map == "sp_a4_finale2") {
        CBaseEntity@ existingTimer = EntityList().FindByName(null, "finale2_turret_timer");
        if (existingTimer is null) {
            // Create a logic_timer to tick the finale 2 turret skin check
            CBaseEntity@ timer = util::CreateEntityByName("logic_timer");
            if (timer !is null) {
                timer.KeyValue("targetname", "finale2_turret_timer");
                timer.KeyValue("RefireTime", "0.2");
                
                string payload = "InitCmd\x1BCommand\x1BFinale2TurretTick\x1B0\x1B-1";
                timer.KeyValue("OnTimer", payload);
                
                timer.Spawn();
                
                // Enable the timer
                Variant empty;
                timer.FireInput("Enable", empty, 0.0f, null, null, 0);
            }
        }
    }
}

} // namespace Archipelago