/**
 * CallVScript - Generic bridge to call VScript from AngelScript.
 * Rewritten to bypass the "Map entities cannot use admin command script" restriction.
 */
void CallVScript(string code) {
    // Create a temporary logic_script to bypass the console command blocklist entirely
    CBaseEntity@ scriptEnt = util::CreateEntityByName("logic_script");
    if (scriptEnt !is null) {
        scriptEnt.Spawn();
        
        Variant vPayload;
        vPayload.SetString(code);
        
        // Fire the code directly into the VScript VM (not the console)
        scriptEnt.FireInput("RunScriptCode", vPayload, 0.0f, null, null, 0);
        
        // Clean up the temporary entity immediately after execution
        Variant vKill;
        scriptEnt.FireInput("Kill", vKill, 0.1f, null, null, 0);
    } else {
        Msgl("[AP] Error: CallVScript failed to create logic_script");
    }
}
