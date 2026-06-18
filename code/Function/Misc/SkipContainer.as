// ============================================================================
// THE UNIFIED INTRO BYPASS SYSTEM (TIMED SELECTION)
// ============================================================================
namespace Archipelago {

void SkipContainer()
{
    // ------------------------------------------------------------------------
    // 1. DEFINE PIPELINE STEP DATA
    // ------------------------------------------------------------------------
    array<string> names = {
        "",                                 // Step 0: Start the screen fade transformation sequence
        "camera_intro",                     // Step 1: Securely queue the intro camera setup for disable
        "good_morning_vcd",                 // Step 2: Securely queue the dialogue scene track for deletion
        "@exit_wall_hit_counter",           // Step 3: Set the wall destruction counter value to allow progression
        "@exit_wall_hit_counter",           // Step 4: Set the wall destruction counter value to allow progression
        "actor_wall_destruction_01",        // Step 5: Clean up wall destruction actor 01
        "actor_wall_destruction_02",        // Step 6: Clean up wall destruction actor 02
        "actor_wall_destruction_03",        // Step 7: Clean up wall destruction actor 03
        "@rl_container_ride_third_section", // Step 8: Trigger container ride third section relay
        "@debug_teleport_to_vault_relay",   // Step 9: Trigger the destination teleportation logic relay cleanly
        "info_player_start",                // Step 10: Securely queue the player start point for deletion
        "camera_intro",                     // Step 11: Securely queue the intro camera setup for deletion
        ""                                  // Step 12: Complete the loop sequence and restore clear vision
    };

    array<string> actions = {
        "fadeout",
        "disable",
        "remove",
        "setvalue 1",
        "setvalue 2",
        "remove",
        "remove",
        "remove",
        "trigger",
        "trigger",
        "remove",
        "remove",
        "fadein"
    };

    uint stepCount = names.length();

    // ------------------------------------------------------------------------
    // 2. RUN TIMED CONTAINER LOOP
    // ------------------------------------------------------------------------
    Variant emptyVariant;
    
    // Fetch the local player entity reference (Index 1 is the host player)
    CBaseEntity@ player = util::GetEntityByIndex(1);

    for (uint i = 0; i < stepCount; i++)
    {
        string targetName = names[i];
        string actionInput = actions[i];

        if (actionInput.empty()) continue;

        string lowerAction = actionInput.tolower();

        // TIMING CORRECTION: 
        // Step 0 happens instantly to blindfold the player.
        // Steps 1 to (stepCount - 2) wait 1.0 seconds for the map's native initialization to finish.
        // The last step waits 1.2 seconds before revealing the world context.
        float scheduledDelay = 1.0f;
        if (i == 0) scheduledDelay = 0.0f;
        if (i == stepCount - 1) scheduledDelay = 1.2f;

        // Macro Check: Procedural Screen Fade Injection Context
        if (lowerAction == "fadeout" || lowerAction == "fadein")
        {
            CBaseEntity@ fadeEnt = util::CreateEntityByName("env_fade");
            if (fadeEnt !is null)
            {
                fadeEnt.KeyValue("rendercolor", "0 0 0"); 
                
                if (lowerAction == "fadeout")
                {
                    fadeEnt.KeyValue("duration", "0.0");
                    fadeEnt.KeyValue("holdtime", "0.0"); 
                    fadeEnt.KeyValue("spawnflags", "8"); // Fade To Black, Stay Out (Indefinitely black)
                }
                else // fadein
                {
                    fadeEnt.KeyValue("duration", "3.0");
                    fadeEnt.KeyValue("holdtime", "0.0");
                    fadeEnt.KeyValue("spawnflags", "1"); // Fade From Black back to clear
                }
                
                fadeEnt.Spawn();
                fadeEnt.FireInput("Fade", emptyVariant, scheduledDelay, player, player);
                Msg("[Sequence] Step " + i + ": Scheduled fade effect (" + actionInput + ") at " + scheduledDelay + "s\n");
            }
            continue;
        }

        // CRITICAL TELEPORT FIX: Right before firing the teleport relay, 
        // tell the engine to strip the player of its parent pod attachments at that exact same timestamp.
        if (targetName == "@debug_teleport_to_vault_relay" && player !is null)
        {
            player.FireInput("ClearParent", emptyVariant, scheduledDelay, player, player);
        }

        if (targetName.empty()) continue;

        CBaseEntity@ ent = EntityList().FindByName(null, targetName);
        if (ent is null)
        {
            Warning("[Sequence] Warning: Step " + i + " skipped. Entity '" + targetName + "' not found inside map data.\n");
            continue;
        }

        // Deletion Check: Scheduled Kill command
        if (lowerAction == "remove")
        {
            Msg("[Sequence] Step " + i + ": Queued 'Kill' input -> " + targetName + " at " + scheduledDelay + "s\n");
            ent.FireInput("Kill", emptyVariant, scheduledDelay, player, player);
        }
        else if (lowerAction == "trigger")
        {
            Msg("[Sequence] Step " + i + ": FireInput 'Trigger' -> " + targetName + " (Delay: " + scheduledDelay + "s)\n");
            ent.FireInput("Trigger", emptyVariant, scheduledDelay, player, player);
        }
        else if (lowerAction == "enable")
        {
            Msg("[Sequence] Step " + i + ": FireInput 'Enable' -> " + targetName + " (Delay: " + scheduledDelay + "s)\n");
            ent.FireInput("Enable", emptyVariant, scheduledDelay, player, player);
        }
        else if (lowerAction == "disable")
        {
            Msg("[Sequence] Step " + i + ": FireInput 'Disable' -> " + targetName + " (Delay: " + scheduledDelay + "s)\n");
            ent.FireInput("Disable", emptyVariant, scheduledDelay, player, player);
        }
        else if (lowerAction.locate("setvalue") == 0)
        {
            int spaceIdx = actionInput.locate(" ");
            int value = 0;
            if (spaceIdx != -1)
            {
                value = int(actionInput.substr(spaceIdx + 1).trim().toInt());
            }
            Variant val;
            val.SetInt(value);
            Msg("[Sequence] Step " + i + ": FireInput 'SetValue' (" + value + ") -> " + targetName + " (Delay: " + scheduledDelay + "s)\n");
            ent.FireInput("SetValue", val, scheduledDelay, player, player);
        }
        // Input Fallback: Standard Entity Action transmission (Perfect Console Emulation Mode)
        else
        {
            Msg("[Sequence] Step " + i + ": FireInput '" + actionInput + "' -> " + targetName + " (Delay: " + scheduledDelay + "s)\n");
            ent.FireInput(actionInput, emptyVariant, scheduledDelay, player, player);
        }
    }
}

}