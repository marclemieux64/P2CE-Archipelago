/**
 * PrintAllEntities - Scans the map and prints every entity to console.
 * Used by the client to identify items to delete or modify.
 */
void PrintAllEntities() {
    //ArchipelagoLog("--- BEGIN ENTITY LIST ---");
    CBaseEntity@ ent = EntityList().First();
    uint count = 0;
    
    while (ent !is null) {
        string cls = ent.GetClassname();
        string name = ent.GetEntityName();
        string model = ent.GetModelName();
        
        // Format: [CLASS] NAME | MODEL
        //ArchipelagoLog("ENT: [" + cls + "] " + (name == "" ? "(unnamed)" : name) + " | " + (model == "" ? "(no model)" : model));
        
        count++;
        @ent = EntityList().Next(ent);
    }
    
    //ArchipelagoLog("--- END ENTITY LIST (Total: " + count + ") ---");
}
