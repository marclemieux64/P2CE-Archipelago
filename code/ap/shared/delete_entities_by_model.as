void DeleteEntitiesByModel(string modelPath, bool holo = true, float scale = 0.7f) {
    CBaseEntity@ ent = null;
    int count = 0;
    while ((@ent = EntityList().FindByModel(ent, modelPath)) !is null) {
        // Use the main DeleteEntity logic to ensure holograms and delays are handled!
        string tName = ent.GetEntityName();
        if (tName == "") tName = ent.GetClassname();
        DeleteEntity(tName, holo, scale);
        count++;
    }
    if (count > 0) {
        Msgl("[AP] Processed " + count + " entities matching model: " + modelPath);
    }
}
