// =============================================================
// ARCHIPELAGO ITEM: AERIAL FAITH PLATE
// =============================================================

/**
 * HandleFaithPlateLock - Manages the physical stabilization and player feedback
 * for a Faith Plate when its associated trigger is locked.
 */
void HandleFaithPlateLock(CBaseEntity@ trigger) {
    if (trigger is null) return;

    // 1. Stabilization Logic: Locate and sanitize the physical plate
    bool foundPlate = false;
    CBaseEntity@ targetPlate = null;
    string targetPlateName = "";
    
    CBaseEntity@ p = null;
    while ((@p = EntityList().FindInSphere(p, trigger.GetAbsOrigin(), 128.0f)) !is null) {
        string pModel = p.GetModelName().tolower();
        if (pModel.locate("faith_plate") != uint(-1)) {
            // Ensure the plate has a unique name for targeting
            targetPlateName = p.GetEntityName();
            if (targetPlateName == "") {
                targetPlateName = "ap_faith_plate_" + RandomInt(1000, 9999);
                p.KeyValue("targetname", targetPlateName);
            }

            // Force physical solidity (Legacy Archi "Win" logic)
            p.KeyValue("solid", "2");
            p.SetSolid(SOLID_BBOX);
            p.SetMoveType(MOVETYPE_PUSH);
            p.FireInput("EnableCollision", Variant(), 0.0f, null, null, 0);

            // 2. Feedback Systems: Spawn Sounds and Hints
            SetupFaithPlateFeedback(p, targetPlateName);

            @targetPlate = p;
            foundPlate = true;
            break;
        }
    }

    if (!foundPlate) {
        ArchipelagoLog("[AP DEBUG] trigger_catapult has no associated Faith Plate model nearby.");
        return;
    }

    // 3. Proxy Detection Trigger (Inherits the catapult's exact brush shape)
    string proxyUid = "ap_prox_" + trigger.GetEntityIndex();
    CBaseEntity@ proxy = EntityList().FindByName(null, proxyUid);
    if (proxy is null) {
        @proxy = util::CreateEntityByName("trigger_multiple");
        if (proxy !is null) {
            proxy.KeyValue("targetname", proxyUid);
            proxy.KeyValue("spawnflags", "1"); // Players only
            proxy.KeyValue("wait", "1.5"); // Re-fire every 1 second
            proxy.SetAbsOrigin(trigger.GetAbsOrigin());
            proxy.SetAbsAngles(trigger.GetAbsAngles());
            
            // Copy the brush model index (e.g., "*123") to match the exact volume
            proxy.SetModel(trigger.GetModelName());
            proxy.Spawn();

            // Link to the feedback systems
            string hintUid = "ap_hint_" + targetPlateName;
            string sndUid = "ap_cat_snd_" + targetPlateName;
            
            // Fire the hint and sound repeatedly
            Variant vHint;
            vHint.SetString("OnTrigger " + hintUid + ":ShowHint::0:-1");
            proxy.FireInput("AddOutput", vHint, 0.0f, null, null, 0);

            Variant vSnd;
            vSnd.SetString("OnTrigger " + sndUid + ":PlaySound::0:-1");
            proxy.FireInput("AddOutput", vSnd, 0.0f, null, null, 0);

            // Flash the skin of the plate (Skin 1 for 0.5s, then back to 0)
            Variant vSkin;
            vSkin.SetString("OnTrigger " + targetPlateName + ":Skin:1:0:-1");
            proxy.FireInput("AddOutput", vSkin, 0.0f, null, null, 0);

            Variant vSkinReset;
            vSkinReset.SetString("OnTrigger " + targetPlateName + ":Skin:0:0.5:-1");
            proxy.FireInput("AddOutput", vSkinReset, 0.0f, null, null, 0);
        }
    }
}

/**
 * SetupFaithPlateFeedback - Spawns the audio and visual cues for the plate.
 */
void SetupFaithPlateFeedback(CBaseEntity@ plate, string pName) {
    // A. Audio Feedback (Negative Interaction Sound)
    string sndUid = "ap_cat_snd_" + pName;
    CBaseEntity@ snd = EntityList().FindByName(null, sndUid);
    if (snd is null) {
        @snd = util::CreateEntityByName("ambient_generic");
        if (snd !is null) {
            snd.KeyValue("targetname", sndUid);
            snd.KeyValue("message", "World.RobotNegInteractPitchedUp");
            snd.KeyValue("spawnflags", "48"); 
            snd.KeyValue("health", "10"); 
            snd.SetAbsOrigin(plate.GetAbsOrigin());
            snd.Spawn();
        }
    }

    // B. Visual Feedback (Instructor Hint)
    string targetUid = "ap_hint_target_" + pName;
    CBaseEntity@ hintTarget = EntityList().FindByName(null, targetUid);
    if (hintTarget is null) {
        @hintTarget = util::CreateEntityByName("info_target_instructor_hint");
        if (hintTarget !is null) {
            hintTarget.KeyValue("targetname", targetUid);
            hintTarget.SetAbsOrigin(plate.GetAbsOrigin());
            hintTarget.Spawn();
        }
    }

    string hintUid = "ap_hint_" + pName;
    CBaseEntity@ hint = EntityList().FindByName(null, hintUid);
    if (hint is null) {
        @hint = util::CreateEntityByName("env_instructor_hint");
        if (hint !is null) {
            hint.KeyValue("targetname", hintUid);
            hint.KeyValue("hint_target", targetUid);
            hint.KeyValue("hint_static", "1");
            hint.KeyValue("hint_caption", "#AP_Item_AerialFaithPlate_Hint");
            hint.KeyValue("hint_icon_onscreen", "icon_alert");
            hint.KeyValue("hint_color", "255 50 50");
            hint.KeyValue("hint_timeout", "0");
            hint.KeyValue("hint_range", "0"); // Reset to infinite (0) so it's always visible
            hint.Spawn();
        }
    }
}
