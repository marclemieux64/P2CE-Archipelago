/**
 * FindEntities - Robust search helper that handles Name, Class, Model, Target, and 
 * Keyword-based fallback for complex items like Frankenturrets.
 */
array<CBaseEntity@> FindEntities(string search) {
    array<CBaseEntity@> targets;
    CBaseEntity@ ent = null;
    
    // 1. PRIMARY SEARCH PASSES (Standard engine methods)
    while ((@ent = EntityList().FindByName(ent, search)) !is null) targets.insertLast(ent);
    @ent = null;
    while ((@ent = EntityList().FindByClassname(ent, search)) !is null) targets.insertLast(ent);
    @ent = null;
    while ((@ent = EntityList().FindByTarget(ent, search)) !is null) targets.insertLast(ent);
    @ent = null;
    while ((@ent = EntityList().FindByModel(ent, search)) !is null) targets.insertLast(ent);

    // 2. KEYWORD & MODEL SEARCHES (Pass 2 - For monster boxes, cubes, lasers, sprayers, and turrets)
    if (search == "monster" || search == "cube" || search == "laser" || search == "paint" || search == "sprayer" || search.locate("turret") != uint(-1)) {
        @ent = EntityList().First();
        while (@ent !is null) {
            string cls = ent.GetClassname();
            string model = ent.GetModelName();
            string name = ent.GetEntityName();

            // We look at physical props, NPCs, and critical environmental triggers/emitters
            if (cls.locate("prop") != uint(-1) || cls.locate("npc") != uint(-1) || cls.locate("env_") != uint(-1) || 
                cls == "info_paint_sprayer" || cls == "paint_sphere") {
                
                // Special broad match for paint/sprayers: If search term is related, match all sprayers
                bool isSprayerRequest = (search.locate("paint") != uint(-1) || search.locate("sprayer") != uint(-1));
                bool isSprayerCls = (cls == "info_paint_sprayer" || cls == "paint_sphere");

                bool isFakeTurret = (search.locate("turret") != uint(-1) && model.locate("turret_01.mdl") != uint(-1));

                // Match if Name, Class, or Model contains the search term, OR if it's a sprayer being requested
                if (cls.locate(search) != uint(-1) || model.locate(search) != uint(-1) || name.locate(search) != uint(-1) || isFakeTurret || (isSprayerRequest && isSprayerCls)) {
                    bool alreadyIn = false;
                    for (uint j = 0; j < targets.length(); j++) { if (@targets[j] == @ent) alreadyIn = true; }
                    if (!alreadyIn) targets.insertLast(ent);
                }
            }
            @ent = EntityList().Next(ent);
        }
    }
    
    // 3. INSTANCE SUFFIX FALLBACK (Pass 3)
    if (targets.length() == 0) {
        @ent = EntityList().First();
        while (@ent !is null) {
            string name = ent.GetEntityName();
            int nLen = int(name.length());
            int sLen = int(search.length());
            if (nLen > sLen && sLen > 0) {
                uint8 d1 = name[nLen - sLen - 1]; // Delimiter check (- or :)
                if ((d1 == 45 || d1 == 58) && name.substr(nLen - sLen) == search) {
                    targets.insertLast(ent);
                }
            }
            @ent = EntityList().Next(ent);
        }
    }
    
    return targets;
}

/**
 * ppmod_get - AngelScript equivalent of legacy VScript ppmod.get
 */
CBaseEntity@ ppmod_get(string arg1) {
    CBaseEntity@ ent = null;
    @ent = EntityList().FindByName(null, arg1);
    if (ent !is null) return ent;
    @ent = EntityList().FindByClassname(null, arg1);
    if (ent !is null) return ent;
    @ent = EntityList().FindByModel(null, arg1);
    return ent;
}

CBaseEntity@ ppmod_get(Vector pos, float radius = 32.0f, string filter = "") {
    CBaseEntity@ ent = null;
    float radiusSqr = radius * radius;
    
    @ent = EntityList().First();
    while (@ent !is null) {
        Vector ePos = ent.GetAbsOrigin();
        float dist = (ePos - pos).LengthSqr();
        if (dist <= radiusSqr) {
            if (filter == "" || ent.GetEntityName() == filter || ent.GetClassname() == filter || ent.GetModelName() == filter) {
                return ent;
            }
        }
        @ent = EntityList().Next(ent);
    }
    return null;
}

CBaseEntity@ ppmod_get(int arg1) {
    CBaseEntity@ ent = EntityList().First();
    while (@ent !is null) {
        if (ent.GetEntityIndex() == arg1) return ent;
        @ent = EntityList().Next(ent);
    }
    return null;
}

