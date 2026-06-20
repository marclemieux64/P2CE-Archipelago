// =============================================================
// ARCHIPELAGO CUBE CONFETTI TRAP (OOP VERSION)
// =============================================================

namespace Archipelago {

class CubeConfettiTrap : ITrap {
    string GetName() const override { return "CubeConfetti"; }

    void Trigger(const CommandArgs@ args) override {
        CBaseEntity@ player = EntityList().FindByClassname(null, "player");
        if (player is null) return;
        
        Vector pos = player.GetAbsOrigin();
        
        // Spawn multiple colored cubes at player origin and dissolve them
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
}

} // namespace Archipelago
