// =============================================================
// ARCHIPELAGO HOLOGRAM VISUAL REGISTRY
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

void GetHologramVisualOverrides(CBaseEntity@ ent, Vector&out targetPos, QAngle&out targetAng, int&out targetSkin, float&out targetScale) {
    if (ent is null) return;
    UpdateInternalMapName();

    string classname = ent.GetClassname();
    string model = ent.GetModelName();
    string name = ent.GetEntityName();
    // Default values
    targetPos = ent.GetAbsOrigin();
    targetAng = ent.GetAbsAngles();
    targetSkin = 0; 
    targetScale = 1.0f;

    // 0. SPECIFIC NAMED ENTITIES (Elevators, Trains, Ratman Dens, Portal Gun)
    bool isElevator = (name.locate("exit_lift_train") != uint(-1) || name.locate("departure_elavator") != uint(-1) || name.locate("departure_elevator") != uint(-1));
    bool isRatmanDen = (name.locate("rd") == 0);
    bool isPortalGun = (name.locate("portal") != uint(-1) && name.locate("gun") != uint(-1));

    if (isElevator || isRatmanDen || isPortalGun) {
        targetPos = ent.GetAbsOrigin();
        
        // Add a vertical offset so it floats above the button/den
        if (isRatmanDen) {
            targetPos = targetPos + (ent.Up() * 75.0f);
        } else if (isPortalGun) {
            targetPos = targetPos + (ent.Up() * 32.0f);
        }

        targetAng = ent.GetAbsAngles();
        targetScale = 1.0f;
        
        string symbols = g_map_symbols;
        bool mapDone = (symbols != "" && symbols.locate("ã") == uint(-1));
        bool mapPlayable = (g_map_status >= 1);
        bool rDone = (symbols == "" || symbols.locate("ø") == uint(-1)); 
        bool pDone = (symbols == "" || (symbols.locate("þ") == uint(-1) && symbols.locate("ý") == uint(-1) && symbols.locate("ǫ") == uint(-1)));

        if (isRatmanDen) {
            targetSkin = (rDone || g_ratman_status == 1 || mapDone) ? 4 : 0;
        } else if (isPortalGun) {
            targetSkin = (pDone || mapDone) ? 4 : 0;
        } else if (name.locate("chamber_button") != uint(-1)) {
            int missingCount = 0;
            int startIdx = 0;
            while ((startIdx = symbols.locate("¢", startIdx)) != -1) {
                missingCount++;
                startIdx += 2; // "¢" is 2 bytes in UTF-8
            }
            int doorIdx = 1;
            if (name.locate("button2") != uint(-1)) doorIdx = 2; else if (name.locate("button3") != uint(-1)) doorIdx = 3;
            targetSkin = (mapDone || missingCount <= (3 - doorIdx)) ? 4 : 0;
        } else {
            targetSkin = mapDone ? 4 : 0;
        }
        
        return;
    }

    // 1. MAP-SPECIFIC OVERRIDES
    if (current_map == "sp_a1_intro1") {
        if (name.locate("dropper") != uint(-1) || model.locate("dropper") != uint(-1) || classname == "env_entity_maker") {
            targetPos = ent.GetAbsOrigin() + (ent.Up() * -175.0f);
            targetSkin = 4;
            return;
        }
    }

    if (current_map == "sp_a1_intro2") {
        if (name.locate("box") != uint(-1)) {
            targetPos = ent.GetAbsOrigin() + (ent.Up() * -30.0f);
            targetAng.x = 0.0f;
            targetAng.y = 0.0f;
            targetAng.z = 0.0f;
            targetSkin = 4;
            targetScale = 0.66f;
            return;
        }
    }
    
    if (current_map == "sp_a1_intro4") {
        if (name.locate("box_dropper-cube_dropper_box") != uint(-1) || classname == "env_entity_maker") {
            targetPos = ent.GetAbsOrigin() + (ent.Up() * -330.0f);
            targetSkin = 4;
            return;
        }
        if (name.locate("section_2_box_2") != uint(-1) || classname == "prop_weighted_cube") {
            targetPos = ent.GetAbsOrigin();
            targetSkin = 4;
            targetScale = 0.66f;
            return;
        }
    }

    if (current_map == "sp_a1_intro7") {
        Vector pos = ent.GetAbsOrigin();
        targetAng = QAngle(0.0f, 0.0f, 0.0f);
        
        if ((pos - Vector(-2801.72f, 213.41f, 1522.55f)).Length() < 10.0f) {
            targetPos = Vector(-2801.72f, 213.41f, 1522.55f); 
            targetAng = QAngle(-70.74f, 349.67f, 0.0f);
            targetSkin = 2; 
            targetScale = 0.7f;
            return;
        }
        if ((pos - Vector(-2768.0f, -146.0f, 1512.0f)).Length() < 10.0f) {
            targetPos = Vector(-2768.0f, -146.0f, 1512.0f);
            targetAng = QAngle(-90.0f, 0.0f, 0.0f);
            targetSkin = 2;
            targetScale = 0.7f;
            return;
        }
        if ((pos - Vector(-2860.0f, 304.0f, 1266.0f)).Length() < 10.0f) {
            targetPos = Vector(-2860.0f, 304.0f, 1266.0f);
            targetAng = QAngle(-60.0f, 0.0f, 0.0f);
            targetSkin = 2;
            targetScale = 0.7f;
            return;
        }
        if ((pos - Vector(-2838.0f, -256.0f, 1268.0f)).Length() < 10.0f) {
            targetPos = Vector(-2838.0f, -256.0f, 1268.0f);
            targetAng = QAngle(-64.31f, 182.29f, 31.14f);
            targetSkin = 2;
            targetScale = 0.7f;
            return;
        }
        if ((pos - Vector(-2943.43f, 37.41f, 1426.5f)).Length() < 10.0f) {
            targetPos = Vector(-2943.43f, 37.41f, 1426.5f);
            targetAng = QAngle(-84.78f, 319.40f, 30.71f);
            targetSkin = 5;
            targetScale = 0.7f;
            return;
        }
        if ((pos - Vector(-2802.90f, 101.77f, 1520.28f)).Length() < 10.0f) {
            targetPos = Vector(-2802.90f, 101.77f, 1520.28f);
            targetAng = QAngle(-75.0f, 0.0f, 0.0f);
            targetSkin = 2;
            targetScale = 0.7f;
            return;
        }
        if ((pos - Vector(-2951.71f, -74.22f, 1442.0f)).Length() < 10.0f) {
            targetPos = Vector(-2951.71f, -74.22f, 1442.0f);
            targetAng = QAngle(-60.0f, 0.0f, 0.0f);
            targetSkin = 3;
            targetScale = 0.7f;
            return;
        }
        if ((pos - Vector(-2851.05f, -66.81f, 1264.59f)).Length() < 10.0f) {
            targetPos = Vector(-2851.05f, -66.81f, 1264.59f);
            targetAng = QAngle(-82.38f, 173.60f, 109.29f);
            targetSkin = 2;
            targetScale = 0.7f;
            return;
        }
        if ((pos - Vector(-2857.17f, -112.81f, 1264.47f)).Length() < 10.0f) {
            targetPos = Vector(-2857.17f, -112.81f, 1264.47f);
            targetAng = QAngle(-82.51f, 6.50f, -83.49f);
            targetSkin = 2;
            targetScale = 0.7f;
            return;
        }
        if ((pos - Vector(-2983.71f, 256.0f, 1146.0f)).Length() < 10.0f) {
            targetPos = Vector(-2983.71f, 256.0f, 1146.0f);
            targetAng = QAngle(-60.0f, 0.0f, 0.0f);
            targetSkin = 2;
            targetScale = 0.7f;
            return;
        }
        if ((pos - Vector(-2912.0f, -238.47f, 1141.86f)).Length() < 10.0f) {
            targetPos = Vector(-2940.0f, -238.47f, 1141.86f);
            targetAng = QAngle(-64.31f, 182.29f, 31.14f);
            targetSkin = 2;
            targetScale = 0.7f;
            return;
        }
        if ((pos - Vector(-2824.36f, -395.82f, 1297.38f)).Length() < 10.0f) {
            targetPos = Vector(-2824.36f, -395.82f, 1297.38f);
            targetAng = QAngle(2.08f, 4.29f, 68.86f);
            targetSkin = 2;
            targetScale = 0.7f;
            return;
        }
    }

    if (current_map == "sp_a2_fizzler_intro") {
        if (name.locate("cube_dropper-cube_dropper_box") != uint(-1)) {
            CBaseEntity@ maker = null;
            while ((@maker = EntityList().FindByClassname(maker, "env_entity_maker")) !is null) {
                if (maker.GetEntityName().locate("cube_dropper") != uint(-1)) {
                    targetPos = maker.GetAbsOrigin() + (maker.Up() * -420.0f);
                    break;
                }
            }
            targetSkin = 4;
            return;
        }
    }

    // 2. WHEATLEY MONITORS
    if (model.locate("wheatley_monitor") != uint(-1) || name.locate("monitor") != uint(-1) || name.locate("tv_crack") != uint(-1)) {
        targetPos = ent.GetAbsOrigin() + (ent.Up() * 140.0f) + (ent.Left() * 40.0f);
        targetAng = ent.GetAbsAngles(); 
        targetScale = 0.9f;
        return;
    }

    // 5. FRANKENTURRETS
    if (classname == "prop_monster_box" || model.locate("monster") != uint(-1)) {
        targetSkin = 4;
        targetPos = ent.GetAbsOrigin() + (ent.Up() * 24.0f);
        return;
    }

    // 6. TRACTOR BEAMS / FUNNELS
    if (classname == "prop_tractor_beam" || classname == "prop_excursion_funnel") {
        targetSkin = 4;
        targetPos = ent.GetAbsOrigin() + (ent.Forward() * 95.0f);
        targetAng.x += 90.0f; 
        return;
    }

    // 7. CUBES
    if (classname.locate("cube") != uint(-1) || model.locate("metal_box") != uint(-1)) {
        targetSkin = 4;
        targetPos = ent.GetAbsOrigin() + (ent.Up() * 32.0f);
        return;
    }

    // 9. STANDARD PEDESTAL BUTTONS
    if (classname == "prop_button" || classname == "prop_under_button") {
        targetSkin = 4;
        targetPos = ent.GetAbsOrigin() + (ent.Up() * 70.0f);
        targetScale = 0.66f;
        return;
    }

    // 10. FLOOR BUTTONS
    if (classname == "prop_floor_button" || classname == "prop_floor_cube_button" || classname == "prop_floor_ball_button" || classname == "prop_under_floor_button") {
        targetSkin = 4;
        targetPos = ent.GetAbsOrigin() + (ent.Up() * 40.0f);
        targetScale = 1.0f;
        return;
    }

    // 11. LASER DEVICES
    bool isLaser = (classname.locate("laser") != uint(-1) || name.locate("laser") != uint(-1) || classname.locate("catcher") != uint(-1));
    if (isLaser) {
        targetSkin = 4;
        targetScale = 0.7f;
        targetAng = ent.GetAbsAngles();
        if (classname.locate("relay") != uint(-1) || name.locate("relay") != uint(-1)) {
            targetPos = ent.GetAbsOrigin() + (ent.Up() * 40.0f);
            targetScale = 0.66f;
        } else {
            targetPos = ent.GetAbsOrigin() + (ent.Forward() * 24.0f);
            targetAng.x += 90.0f;
            targetScale = 0.55f;
        }
        return;
    }

    // 13. TURRETS
    if (classname == "npc_portal_turret_floor" || classname == "npc_rocket_turret" || model.locate("turret") != uint(-1)) {
        targetSkin = 2;
        targetPos = ent.GetAbsOrigin() + (ent.Up() * 80.0f);
        targetScale = 0.7f;
        return;
    }
}
