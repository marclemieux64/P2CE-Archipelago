namespace Archipelago {

    void InitVitrifiedDoorRegistry() {
        g_vitrified_door_names.deleteAll();
        g_vitrified_door_names["sp_a3_03:dummy_chamber_button"] = "Vitrified Door 1";
        g_vitrified_door_names["sp_a3_03:dummy_chamber_button2"] = "Vitrified Door 2";
        g_vitrified_door_names["sp_a3_03:dummy_chamber_button3"] = "Vitrified Door 3";
        g_vitrified_door_names["sp_a3_transition01:dummy_chamber_button"] = "Vitrified Door 4";
        g_vitrified_door_names["sp_a3_transition01:dummy_chamber_button2"] = "Vitrified Door 5";
        g_vitrified_door_names["sp_a3_transition01:dummy_chamber_button3"] = "Vitrified Door 6";
    }



    void InitLocationRegistries() {
        InitVitrifiedDoorRegistry();
    }

} // namespace Archipelago
