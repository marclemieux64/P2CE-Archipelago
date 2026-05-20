namespace Archipelago {

void PreventPickupForModel(string model_keyword) {
    // 1. Recherche dans les objets physiques normaux
    CBaseEntity@ prop = null;
    while ((@prop = EntityList().FindByClassname(prop, "prop_physics")) !is null) {
        if (prop.GetModelName().tolower().locate(model_keyword) != uint(-1)) {
            // Retire la physique dynamique, ce qui désactive instantanément la surbrillance et le ramassage
            prop.SetMoveType(MOVETYPE_NONE);
        }
    }

    // 2. Recherche dans les objets physiques forcés (override)
    CBaseEntity@ override_prop = null;
    while ((@override_prop = EntityList().FindByClassname(override_prop, "prop_physics_override")) !is null) {
        if (override_prop.GetModelName().tolower().locate(model_keyword) != uint(-1)) {
            // Retire la physique dynamique
            override_prop.SetMoveType(MOVETYPE_NONE);
        }
    }
}

} // namespace Archipelago
