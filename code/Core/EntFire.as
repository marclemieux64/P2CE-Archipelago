namespace Archipelago {

void EntFire(Vector pos, string input, string value = "", float delay = 0.0f, string cls = "") {
        CBaseEntity@ target = null;
        if (cls != "" && cls != "*") {
            @target = EntityList().FindByClassnameNearest(cls, pos, 100.0f);
        } else {
        // Fallback: Manual proximity search for any entity type
            float minDist = 100.0f;
            CBaseEntity@ ent = EntityList().First();
            while (@ent !is null) {
                float d = (ent.GetAbsOrigin() - pos).Length();
                if (d < minDist) {
                    @target = ent;
                    minDist = d;
                }
                @ent = EntityList().Next(ent);
            }
        }
    
        if (target !is null) {
            Variant v;
            v.SetString(value);
            target.FireInput(input, v, delay, null, null, 0);
        }
    }

} // namespace Archipelago
