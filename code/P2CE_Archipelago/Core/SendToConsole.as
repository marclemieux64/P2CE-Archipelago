namespace Archipelago {

void SendToConsole(string command) {
        CBaseEntity@ cmd = EntityList().FindByName(null, "InitCmd");
        if (cmd !is null) {
            Variant v;
            v.SetString(command);
            cmd.FireInput("Command", v, 0.0f, null, null, 0);
        }
    }

} // namespace Archipelago
