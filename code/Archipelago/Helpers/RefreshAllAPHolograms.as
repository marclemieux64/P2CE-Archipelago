// =============================================================
// ARCHIPELAGO REFRESH ALL AP HOLOGRAMS
// =============================================================

void RefreshAllAPHolograms() {
    UpdateInternalMapName();
    
    CBaseEntity@ holo = null;
    while ((@holo = EntityList().FindByClassname(holo, "prop_dynamic")) !is null) {
        string modelName = holo.GetModelName();
        string holoName = holo.GetEntityName();
        
        if (modelName.locate("archipelago_hologram") != uint(-1)) {
            int finalSkin = -1;

            string symbols = g_map_symbols;
            bool rDone = (symbols == "" || symbols.locate("ø") == uint(-1)); 
            bool pDone = (symbols == "" || (symbols.locate("þ") == uint(-1) && symbols.locate("ý") == uint(-1) && symbols.locate("ǫ") == uint(-1)));
            bool uDone = (symbols == "" || symbols.locate("ù") == uint(-1));
            bool wDone = (symbols == "" || symbols.locate("ÿ") == uint(-1));

            bool mapDone = (symbols != "" && symbols.locate("ã") == uint(-1));
            bool mapPlayable = (g_map_status >= 1);
            bool isRD = (holoName.locate("rd") == 0 || holoName.locate("Ratman Den") != uint(-1));
            bool isPG = (holoName.locate("portal") != uint(-1) && holoName.locate("gun") != uint(-1));
            bool isPotatos = (holoName.locate("potatos") != uint(-1) || holoName.locate("gla") != uint(-1));
            bool isWheatley = (holoName.locate("wheatley") != uint(-1) || holoName.locate("monitor") != uint(-1));

            if (isRD) {
                finalSkin = (rDone || g_ratman_status == 1 || mapDone) ? 4 : 0;
            } else if (isPG) {
                finalSkin = (pDone || mapDone) ? 4 : 0;
            } else if (isPotatos) {
                finalSkin = (uDone || mapDone) ? 4 : 0;
            } else if (isWheatley) {
                finalSkin = (wDone || g_wheatley_status == 1 || mapDone) ? 4 : 0;
            } else if (holoName.locate("chamber_button") != uint(-1)) {
                // Count how many '¢' are in the string (missing items)
                int missingCount = 0;
                int startIdx = 0;
                while ((startIdx = symbols.locate("¢", startIdx)) != -1) {
                    missingCount++;
                    startIdx++;
                }
                
                // Door 1 is done if missing count < 3
                // Door 2 is done if missing count < 2
                // Door 3 is done if missing count < 1
                int doorIdx = 1;
                if (holoName.locate("button2") != uint(-1)) doorIdx = 2; else if (holoName.locate("button3") != uint(-1)) doorIdx = 3;
                
                finalSkin = (mapDone || (missingCount <= (3 - doorIdx))) ? 4 : 0;
            } else {
                CBaseEntity@ parent = holo.GetMoveParent();
                if (parent !is null) {
                    Vector tPos;
                    QAngle tAng;
                    int tSkin;
                    float tScale;
                    GetHologramVisualOverrides(parent, tPos, tAng, tSkin, tScale);
                    
                    // If the override returned 0 (default), apply our map-wide logic
                    if (tSkin == 0) {
                        tSkin = mapDone ? 4 : 0;
                    }
                    finalSkin = tSkin;
                }
            }

            if (finalSkin != -1) {
                if (cv_ArchipelagoDebug.GetBool()) {
                    ArchipelagoLog("[AP DEBUG] Setting skin " + finalSkin + " on " + holoName);
                }
                holo.KeyValue("skin", "" + finalSkin);
            }
        }
    }
}