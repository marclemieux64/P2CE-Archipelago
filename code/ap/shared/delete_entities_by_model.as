void DeleteEntitiesByModel(string modelPath) {
    CBaseEntity@ ent = null;
    int count = 0;
    // Iterate through all entities using FindByName with a wildcard
    // (NextEntity is not supported in the P2CE AngelScript API)
    while ((@ent = EntityList().FindByName(ent, "*")) !is null) {
        if (ent.GetModelName() == modelPath) {
            ent.Remove();
            count++;
        }
    }
    if (count > 0) {
        Msgl("[AP] Removed " + count + " entities matching model: " + modelPath);
    }
}
