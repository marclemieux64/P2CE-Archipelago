/**
 * WaitExecute - Schedules a console command to run after a delay.
 */
void WaitExecute(string command, float delay, string timerName = "") {
    CBaseEntity@ cmdEnt = EntityList().FindByName(null, "ap_init_cmd");
    if (cmdEnt !is null) {
        Variant v;
        v.SetString(command);
        cmdEnt.FireInput("Command", v, delay, null, null, 0);
        Msgl("[AP] Scheduled command in " + delay + "s: " + command + (timerName != "" ? " (" + timerName + ")" : ""));
    }
}
