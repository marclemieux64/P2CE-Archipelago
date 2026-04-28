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

    // 2. KEYWORD & MODEL SEARCHES (Pass 2 - For monster boxes, cubes, lasers, and sprayers)
    if (search.locate("monster") != uint(-1) || search.locate("cube") != uint(-1) || 
        search.locate("laser") != uint(-1) || search.locate("paint") != uint(-1) || 
            search.locate("sprayer") != uint(-1)) {
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

                // Match if Name, Class, or Model contains the search term, OR if it's a sprayer being requested
                if (cls.locate(search) != uint(-1) || model.locate(search) != uint(-1) || name.locate(search) != uint(-1) || (isSprayerRequest && isSprayerCls)) {
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
