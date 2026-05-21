namespace Archipelago {

void DoMapSpecificSetup() {
    if (current_map == "sp_a1_intro3") {
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
    }
}

} // namespace Archipelago
