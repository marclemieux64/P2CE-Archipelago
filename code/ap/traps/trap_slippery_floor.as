void TriggerSlipperyFloorTrap() {
    CBaseEntity@ player = EntityList().FindByClassname(null, "player");
    if (player !is null) {
        player.SetFriction(0.01f);
        player.KeyValue("friction", "0.01");
    }

    CBaseEntity@ cmd = EntityList().FindByName(null, "ap_init_cmd");
    if (cmd !is null) {
        Variant v;
        // Set world friction low for a real slippery feel
        v.SetString("sv_friction 0.0");
        cmd.FireInput("Command", v, 0.0f, null, null, 0);
        
        // Reset world friction after 15 seconds
        v.SetString("sv_friction 4");
        cmd.FireInput("Command", v, 15.00f, null, null, 0);
        
        // Reset player-specific friction
        v.SetString("ent_fire !player AddOutput \"friction 1\"");
        cmd.FireInput("Command", v, 15.01f, null, null, 0);
        
        v.SetString("say [AP] A slippery floor trap has been activated!");
        cmd.FireInput("Command", v, 0.0f, null, null, 0);
    }
}
