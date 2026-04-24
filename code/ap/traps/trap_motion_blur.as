void TriggerMotionBlurTrap() {
    CBaseEntity@ player = EntityList().FindByClassname(null, "player");
    if (player is null) return;
    
    // Attempt to force motion blur via VScript as there is no native entity for it in P2CE
    CallVScript("Convars.SetValue(\"mat_motion_blur_enabled\", 1)");
    CallVScript("Convars.SetValue(\"mat_motion_blur_strength\", 5)");
    
    // Reset after 20 seconds
    WaitExecute("script Convars.SetValue(\"mat_motion_blur_enabled\", 0)", 20.0f);
}
