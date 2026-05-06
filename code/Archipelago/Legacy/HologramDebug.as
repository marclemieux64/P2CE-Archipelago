// =============================================================
// ARCHIPELAGO HOLOGRAM DEBUG TOOLS
// =============================================================

namespace Legacy {

[ServerCommand("ListHolograms", "Lists all active Archipelago holograms in the console")]
void ListHologramsCmd(const CommandArgs@ args) {
    ArchipelagoLog("--- ACTIVE ARCHIPELAGO HOLOGRAMS ---");
    
    CBaseEntity@ ent = EntityList().First();
    int count = 0;
    
    // Scan all entities for the hologram model
    while (@ent !is null) {
        if (ent.GetModelName().tolower().locate("archipelago_hologram") != uint(-1)) {
            string name = ent.GetEntityName();
            string cls = ent.GetClassname();
            if (name == "") name = "[UNNAMED]";
            
            Vector pos = ent.GetAbsOrigin();
            
            ArchipelagoLog(" -> [" + ent.GetEntityIndex() + "] Name: " + name + " | Class: " + cls + " | Pos: " + pos.x + " " + pos.y + " " + pos.z);
            count++;
        }
        @ent = EntityList().Next(ent);
    }
    
    ArchipelagoLog("------------------------------------");
    ArchipelagoLog("Total Holograms Found: " + count);
}

[ServerCommand("FindEntity", "Lists all entities matching the search term")]
void FindEntityCmd(const CommandArgs@ args) {
    if (args.ArgC() < 2) {
        ArchipelagoLog("Usage: FindEntity <name_or_class>");
        return;
    }
    string search = args.Arg(1);
    ArchipelagoLog("--- SEARCHING FOR ENTITIES: " + search + " ---");
    
    CBaseEntity@ ent = EntityList().First();
    int count = 0;
    while (@ent !is null) {
            string name = ent.GetEntityName();
            string cls = ent.GetClassname();
            string model = ent.GetModelName();
            
            if (name.tolower().locate(search.tolower()) != uint(-1) || cls.tolower().locate(search.tolower()) != uint(-1)) {
                Vector pos = ent.GetAbsOrigin();
                ArchipelagoLog(" -> [" + ent.GetEntityIndex() + "] Name: " + (name == "" ? "[UNNAMED]" : name) + " | Class: " + cls + " | Model: " + model + " | Pos: " + pos.x + " " + pos.y + " " + pos.z);
                count++;
            }
            @ent = EntityList().Next(ent);
        }
    ArchipelagoLog("------------------------------------------");
    ArchipelagoLog("Total Matches Found: " + count);
}

[ServerCommand("ListEntitiesAtOrigin", "Lists all entities near (0,0,0)")]
void ListEntitiesAtOriginCmd(const CommandArgs@ args) {
    float radius = (args.ArgC() > 1) ? args.Arg(1).toFloat() : 64.0f;
    ArchipelagoLog("--- SCANNING FOR ENTITIES NEAR (0,0,0) [Radius: " + radius + "] ---");
    
    CBaseEntity@ ent = EntityList().First();
    int count = 0;
    while (@ent !is null) {
        Vector pos = ent.GetAbsOrigin();
        if (pos.Length() <= radius) {
            string name = ent.GetEntityName();
            string cls = ent.GetClassname();
            string model = ent.GetModelName();
            
            ArchipelagoLog(" -> [" + ent.GetEntityIndex() + "] Name: " + (name == "" ? "[UNNAMED]" : name) + " | Class: " + cls + " | Model: " + model + " | Pos: " + pos.x + " " + pos.y + " " + pos.z);
            count++;
        }
        @ent = EntityList().Next(ent);
    }
    ArchipelagoLog("---------------------------------------------------------");
    ArchipelagoLog("Total Entities at Origin: " + count);
}

} // namespace Legacy
