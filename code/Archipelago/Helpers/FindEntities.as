// =============================================================
// ARCHIPELAGO FIND ENTITIES
// =============================================================

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
    
    // 1.1. MAP-SPECIFIC EXCEPTIONS (Catch targets that the engine's model/name search might miss)
    if (current_map == "sp_a2_triple_laser" && search.locate("reflection_cube") != uint(-1)) {
        CBaseEntity@ box = EntityList().FindByName(null, "new_box1");
        if (box !is null) {
            bool alreadyIn = false;
            for (uint j = 0; j < targets.length(); j++) { if (@targets[j] == @box) alreadyIn = true; }
            if (!alreadyIn) targets.insertLast(box);
        }
    }

    // 2. KEYWORD & MODEL SEARCHES (Pass 2 - For monster boxes, cubes, lasers, sprayers, and turrets)
    bool isReflectionCubeRequest = (search.locate("reflection_cube") != uint(-1));
    bool isSprayerRequest = (search.locate("paint") != uint(-1) || search.locate("sprayer") != uint(-1));
    bool isTurretRequest = (search.locate("turret") != uint(-1));

    if (search == "monster" || search == "cube" || search == "laser" || search == "paint" || search == "sprayer" || 
        isTurretRequest || isReflectionCubeRequest) {
        
        @ent = EntityList().First();
        while (@ent !is null) {
            string cls = ent.GetClassname();
            string model = ent.GetModelName();
            string name = ent.GetEntityName();

            // We look at physical props, NPCs, and critical environmental triggers/emitters
            if (cls.locate("prop") != uint(-1) || cls.locate("npc") != uint(-1) || cls.locate("env_") != uint(-1) || 
                cls == "info_paint_sprayer" || cls == "paint_sphere") {
                
                bool isSprayerCls = (cls == "info_paint_sprayer" || cls == "paint_sphere");
                bool isFakeTurret = (isTurretRequest && model.locate("turret_01.mdl") != uint(-1));
                bool isChainingBox = (current_map == "sp_a2_laser_chaining" && name.locate("box") != uint(-1));

                if (cls.locate(search) != uint(-1) || model.locate(search) != uint(-1) || name.locate(search) != uint(-1) || 
                    isFakeTurret || (isSprayerRequest && isSprayerCls) || (isReflectionCubeRequest && isChainingBox)) {
                    
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

