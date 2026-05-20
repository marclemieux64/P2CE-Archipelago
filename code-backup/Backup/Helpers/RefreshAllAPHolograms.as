// =============================================================
// ARCHIPELAGO REFRESH ALL AP HOLOGRAMS
// =============================================================
void RefreshAllAPHolograms() {
    UpdateInternalMapName();
    
    bool pDone = (g_portal_gun_status == 1);
    bool mapDone = (g_map_symbols.locate("ý") != uint(-1) || g_map_symbols.locate("ǫ") != uint(-1));
    bool rDone = (g_ratman_status == 1);

    array<CBaseEntity@> holos = FindEntities("archipelago_hologram");
    for (uint i = 0; i < holos.length(); i++) {
        CBaseEntity@ holo = holos[i];
        if (holo is null) continue;

        string hName = holo.GetEntityName();
        CBaseEntity@ ent = holo.GetMoveParent();
        
        // Skip refreshing personality cores
        if (hName.locate("core") != uint(-1)) continue;

        // CRITICAL CLEANUP: factory_target holograms are forbidden. Purge them if they exist.
        if (hName.tolower().locate("factory_target") != uint(-1)) {
            holo.Remove();
            continue;
        }

        // 1. Determine Correct Skin (Color)
        int skin = 1; // Default: Green (Skin 1)
        
        bool isPortalGun = (hName.locate("portal_gun") != uint(-1));
        bool isElevator = (hName.locate("elevator") != uint(-1) || hName.locate("lift") != uint(-1) || hName.locate("transition_trigger") != uint(-1));
        bool isRatmanDen = (hName.locate("rd") == 0);
        bool isVitrified = (hName.locate("vitrified") != uint(-1) || hName.locate("dummy_chamber") != uint(-1));
        bool isTurret = false;
        
        if (ent !is null) {
            string modelName = ent.GetModelName().tolower();
            // DOUBLE CHECK: Model path OR Classname
            isTurret = (modelName.locate("models/npcs/turret/turret.mdl") != uint(-1) || ent.GetClassname() == "npc_portal_turret_floor");
            if (!isVitrified) {
                isVitrified = (modelName.locate("underground") != uint(-1) || modelName.locate("antique") != uint(-1));
            }
        }

        if (isPortalGun) {
            skin = (pDone || mapDone) ? 4 : 0;
        } else if (isElevator) {
            skin = mapDone ? 4 : 0;
        } else if (isRatmanDen) {
            skin = (rDone || mapDone) ? 4 : 0;
        } else if (isTurret) {
            skin = 2; // Turrets stay Skin 2
        } else if (isVitrified) {
            // 1. Determine Door Index
            int doorIndex = 0;
            if (hName.locate("button2") != uint(-1) || hName.locate("Vitrified Door 2") != uint(-1)) doorIndex = 2;
            else if (hName.locate("button3") != uint(-1) || hName.locate("Vitrified Door 3") != uint(-1)) doorIndex = 3;
            else if (hName.locate("button") != uint(-1) || hName.locate("Vitrified Door 1") != uint(-1)) doorIndex = 1;
            else if (hName.locate("Vitrified Door 4") != uint(-1)) doorIndex = 4;
            else if (hName.locate("Vitrified Door 5") != uint(-1)) doorIndex = 5;
            else if (hName.locate("Vitrified Door 6") != uint(-1)) doorIndex = 6;

            // 2. Check local bitmask
            ConVarRef cv_bitmask("ArchipelagoVitrifiedStatus");
            string bitmask = cv_bitmask.GetString();
            bool isLocallyFound = (doorIndex > 0 && bitmask.length() >= uint(doorIndex) && bitmask.substr(doorIndex-1, 1) == "1");

            // 3. Check server symbols
            bool vDone = (g_map_symbols == "" || g_map_symbols.locate("¢") == uint(-1));
            
            skin = (isLocallyFound || vDone || mapDone) ? 4 : 0;
        } else {
            // Standard checks: Default to Green (Skin 1)
            skin = 1;
        }

        // 2. Apply to engine
        Variant v;
        v.SetInt(skin);
        holo.FireInput("Skin", v, 0.0f, null, null, 0);

        if (isVitrified) {
            Variant vRate;
            vRate.SetFloat(0.0f);
            holo.FireInput("SetPlaybackRate", vRate, 0.0f, null, null, 0);
        }
    }
}
