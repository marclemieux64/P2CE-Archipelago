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

    // 2. KEYWORD & MODEL SEARCHES (Pass 2 - For monster boxes and cubes)
    if (search.locate("monster") != uint(-1) || search.locate("cube") != uint(-1)) {
        @ent = null;
        while ((@ent = EntityList().FindByClassname(ent, "*")) !is null) {
            string cls = ent.GetClassname();
            string model = ent.GetModelName();
            string name = ent.GetEntityName();

            // We only look if the item is something physical
            if (cls.locate("prop") == uint(-1) && cls.locate("npc") == uint(-1)) continue;
            if (cls == "phys_bone_follower" || cls == "phys_hinge_follower") continue;

            // Match if Name, Class, or Model contains the search term (e.g. 'monster')
            if (cls.locate(search) != uint(-1) || model.locate(search) != uint(-1) || name.locate(search) != uint(-1)) {
                bool alreadyIn = false;
                for (uint j = 0; j < targets.length(); j++) { if (@targets[j] == @ent) alreadyIn = true; }
                if (!alreadyIn) targets.insertLast(ent);
            }
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
