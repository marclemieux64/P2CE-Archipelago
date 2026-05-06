// =============================================================
// ARCHIPELAGO RESTORE CATAPULTS
// =============================================================

/**
 * RestoreCatapults - Re-enables all Aerial Faith Plates and cleans up AP assets.
 */
void RestoreCatapults() {
    CBaseEntity@ catapult = null;
    while ((@catapult = EntityList().FindByClassname(catapult, "trigger_catapult")) !is null) {
        string catName = catapult.GetEntityName();
        
        // Exception for sp_a2_sphere_peek
        if (current_map == "sp_a2_sphere_peek" && catName == "catapult2_up") {
            // Keep disabled, but proceed to delete the hologram
        } else {
            catapult.FireInput("Enable", Variant(), 0.0f, null, null, 0);
        }

        string holoName = catName + "_holo";
        if (catName == "") holoName = "trigger_catapult_holo";
        
        CBaseEntity@ holo = null;
        while ((@holo = EntityList().FindByName(holo, holoName)) !is null) {
            holo.FireInput("Kill", Variant(), 0.0f, null, null, 0);
        }
    }

    CBaseEntity@ plate = null;
    while ((@plate = EntityList().FindByClassname(plate, "prop_dynamic")) !is null) {
        if (plate.GetModelName().locate("faith_plate") != uint(-1)) {
            Variant vSkin;
            vSkin.SetString("0");
            plate.FireInput("Skin", vSkin, 0.0f, null, null, 0);
        }
    }

    int disabledCount = 0;
    CBaseEntity@ catCheck = null;
    while ((@catCheck = EntityList().FindByClassname(catCheck, "trigger_catapult")) !is null) {
        string cName = catCheck.GetEntityName();
        string hName = cName + "_holo";
        if (cName == "") hName = "trigger_catapult_holo";
        
        CBaseEntity@ holoCheck = EntityList().FindByName(null, hName);
        if (holoCheck !is null || (current_map == "sp_a2_sphere_peek" && cName == "catapult2_up")) {
            disabledCount++;
        }
    }

    CBaseEntity@ ent = null;
    while ((@ent = EntityList().Next(ent)) !is null) {
        string n = ent.GetEntityName();
        if (n.locate("ap_cat_snd_") == 0 || n.locate("ap_hint_") == 0 || n.locate("ap_hint_target_") == 0) {
            ent.FireInput("Kill", Variant(), 0.0f, null, null, 0);
        }
        
        if (n.locate("ap_cat_timer") == 0 && disabledCount == 0) {
            ent.FireInput("Kill", Variant(), 0.0f, null, null, 0);
        }
    }
}
