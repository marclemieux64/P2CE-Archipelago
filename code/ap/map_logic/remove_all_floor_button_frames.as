/**
 * RemoveAllFloorButtonFrames - Restores all floor buttons and clears AP assets.
 */
void RemoveAllFloorButtonFrames() {
    array<string> classes = { "prop_floor_button" };
    for (uint c = 0; c < classes.length(); c++) {
        CBaseEntity@ ent = null;
        while ((@ent = EntityList().FindByClassname(ent, classes[c])) !is null) {
            ent.FireInput("Unlock", Variant(), 0.0f, null, null, 0);

            CBaseEntity@ nearby = null;
            while ((@nearby = EntityList().FindInSphere(nearby, ent.GetAbsOrigin(), 100.0f)) !is null) {
                if (nearby is ent) continue;
                string model = nearby.GetModelName();
                if (model == "models/props/archipelago/ap_floorbuttonframe.mdl" || 
                    model == "models/effects/ap/archipelago_hologram.mdl") {
                    nearby.Remove();
                }
            }
        }
    }
}
