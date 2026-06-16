namespace Archipelago {

void Finale2TurretTick() {
    if (current_map != "sp_a4_finale2") return;

    CBaseEntity@ ent = null;
    while ((@ent = EntityList().FindByClassname(ent, "prop_dynamic")) !is null) {
        string model = ent.GetModelName().tolower();
        if (model.locate("archipelago_hologram") != uint(-1)) {
            string name = ent.GetEntityName().tolower();
            if (name.locate("turret") != uint(-1) && name.locate("_holo") != uint(-1)) {
                CBaseAnimating@ anim = cast<CBaseAnimating>(ent);
                if (anim !is null && anim.GetSkin() == 1) {
                    anim.SetSkin(2);
                }
            }
        }
    }
}

} // namespace Archipelago
