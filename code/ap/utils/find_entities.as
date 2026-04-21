/**
 * FindEntities - Search helper that handles Name, Class, Model, Target, and Instance suffixes.
 */
array<CBaseEntity@> FindEntities(string search) {
    array<CBaseEntity@> targets;
    CBaseEntity@ ent = null;
    
    // 1. Primary search passes
    while ((@ent = EntityList().FindByName(ent, search)) !is null) targets.insertLast(ent);
    @ent = null;
    while ((@ent = EntityList().FindByClassname(ent, search)) !is null) targets.insertLast(ent);
    @ent = null;
    while ((@ent = EntityList().FindByTarget(ent, search)) !is null) targets.insertLast(ent);
    @ent = null;
    while ((@ent = EntityList().FindByModel(ent, search)) !is null) targets.insertLast(ent);

    // 2. Fallback: Search for instance suffixes (e.g. "instance_name-target")
    if (targets.length() == 0) {
        @ent = EntityList().First();
        while (@ent !is null) {
            string name = ent.GetEntityName();
            int nLen = int(name.length());
            int sLen = int(search.length());
            if (nLen >= sLen && sLen > 0) {
                if (name == search) {
                    targets.insertLast(ent);
                } else if (nLen > sLen) {
                    // Check for instance delimiters: - or :
                    uint8 d1 = name[nLen - sLen - 1];
                    if ((d1 == 45 || d1 == 58) && name.substr(nLen - sLen) == search) {
                        targets.insertLast(ent);
                    }
                }
            }
            @ent = EntityList().Next(ent);
        }
    }
    
    return targets;
}
