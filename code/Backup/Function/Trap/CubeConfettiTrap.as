// =============================================================
// ARCHIPELAGO CUBE CONFETTI TRAP
// =============================================================
void TriggerCubeConfettiTrap() {
    CBaseEntity@ player = EntityList().FindByClassname(null, "player");
    if (player is null) return;
    Vector pos = player.GetAbsOrigin();
    for (int i = 0; i < 20; i++) {
        CBaseEntity@ cube = util::CreateEntityByName("prop_weighted_cube");
        if (cube !is null) {
            cube.SetAbsOrigin(pos);
            cube.Spawn();
            int colorIdx = RandomInt(0, trap_colors.length() - 1);
            Variant vColor;
            vColor.SetString(trap_colors[colorIdx]);
            cube.FireInput("Color", vColor, 0.0f, null, null, 0);
            cube.FireInput("Dissolve", Variant(), 3.0f, null, null, 0);
        }
    }
}

