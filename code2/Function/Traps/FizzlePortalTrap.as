// =============================================================
// ARCHIPELAGO FIZZLE PORTAL TRAP (OOP VERSION)
// =============================================================

namespace Archipelago {

class FizzlePortalTrap : ITrap {
    string GetName() const override { return "FizzlePortal"; }

    void Trigger(const CommandArgs@ args) override {
        // Find and fizzle all active player portals
        CBaseEntity@ portal = null;
        while ((@portal = EntityList().FindByClassname(portal, "prop_portal")) !is null) {
            portal.FireInput("Fizzle", Variant(), 0.0f, null, null, 0);
        }
    }
}

} // namespace Archipelago
