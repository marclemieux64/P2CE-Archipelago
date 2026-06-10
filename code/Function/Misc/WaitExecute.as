namespace Archipelago {

void WaitExecute(string command, float delay, string timerName = "") {
        CBaseEntity@ cmdEnt = EntityList().FindByName(null, "InitCmd");
        if (cmdEnt !is null) {
            Variant v;
            v.SetString(command);
            cmdEnt.FireInput("Command", v, delay, null, null, 0);
            ArchipelagoLog("Scheduled command in " + delay + "s: " + command);
        }
    }

} // namespace Archipelago
