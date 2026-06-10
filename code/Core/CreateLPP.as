namespace Archipelago {

void CreateLPP() {
        CBaseEntity@ lpp = EntityList().FindByClassname(null, "logic_playerproxy");
        if (lpp is null) {
            @lpp = util::CreateEntityByName("logic_playerproxy");
            if (lpp !is null) {
                lpp.KeyValue("targetname", "lpp"); 
                lpp.Spawn();
            }
        }
    }

} // namespace Archipelago
