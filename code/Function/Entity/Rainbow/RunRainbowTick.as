namespace Archipelago  {
void RunRainbowTick() {
    if (!g_rainbow_active) return;
    
    int step = 15; 
    if (g_rainbow_r > 0 && g_rainbow_b == 0)      { g_rainbow_r -= step; g_rainbow_g += step; }
    else if (g_rainbow_g > 0 && g_rainbow_r == 0) { g_rainbow_g -= step; g_rainbow_b += step; }
    else if (g_rainbow_b > 0 && g_rainbow_g == 0) { g_rainbow_r += step; g_rainbow_b -= step; }
    
    if (g_rainbow_r < 0) g_rainbow_r = 0; if (g_rainbow_r > 255) g_rainbow_r = 255;
    if (g_rainbow_g < 0) g_rainbow_g = 0; if (g_rainbow_g > 255) g_rainbow_g = 255;
    if (g_rainbow_b < 0) g_rainbow_b = 0; if (g_rainbow_b > 255) g_rainbow_b = 255;

    Variant vColor, vLaserColor;
    vColor.SetString(g_rainbow_r + " " + g_rainbow_g + " " + g_rainbow_b);
    vLaserColor.SetString(g_rainbow_r + " " + g_rainbow_g + " " + g_rainbow_b + " 255");
    
    CBaseEntity@ ent = EntityList().First();
    while (@ent !is null) {
        string cls = ent.GetClassname();
        if (cls == "prop_weighted_cube" && cv_RainbowCubes.GetBool()) {
            ent.FireInput("Color", vColor, 0.0f, null, null);
        } else if (cls == "env_portal_laser" && cv_RainbowLasers.GetBool()) {
            ent.FireInput("SetBeamColor", vLaserColor, 0.0f, null, null);
        }
        @ent = EntityList().Next(ent);
    }
}
}