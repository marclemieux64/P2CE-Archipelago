// =============================================================
// ARCHIPELAGO REMOVE ALL BUTTON FRAMES
// =============================================================

/**
 * RemoveAllButtonFrames - Restores all pedestal buttons and clears AP assets.
 */
void RemoveAllButtonFrames() {
    array<string> classes = { "prop_button", "prop_under_button" };
    for (uint c = 0; c < classes.length(); c++) {
        CBaseEntity@ ent = null;
        while ((@ent = EntityList().FindByClassname(ent, classes[c])) !is null) {
            CBaseAnimating@ anim = cast<CBaseAnimating>(ent);
            if (anim !is null) anim.SetSkin(0);
            
            Variant vUp;
            vUp.SetString("up");
            ent.FireInput("SetAnimation", vUp, 0.0f, null, null, 0);
            ent.FireInput("Unlock", Variant(), 0.0f, null, null, 0);
            ent.FireInput("Enable", Variant(), 0.0f, null, null, 0);

            CBaseEntity@ nearby = null;
            while ((@nearby = EntityList().FindInSphere(nearby, ent.GetAbsOrigin(), 100.0f)) !is null) {
                if (nearby is ent) continue;
                string model = nearby.GetModelName();
                if (model == "models/props/archipelago/ap_buttonframe.mdl" || 
                    model == "models/effects/ap/archipelago_hologram.mdl") {
                    nearby.Remove();
                }
            }
        }
    }
}
