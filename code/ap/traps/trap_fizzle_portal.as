void TriggerFizzlePortalTrap() {
    CBaseEntity@ portal = null;
    while ((@portal = EntityList().FindByClassname(portal, "prop_portal")) !is null) {
        portal.FireInput("Fizzle", Variant(), 0.0f, null, null, 0);
    }
}
