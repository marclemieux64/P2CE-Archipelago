const notificationQueue: Panel[] = [];
let isTimerRunning = false;
let isWarpPending = false;
let pendingWarpMapName = "";

/**
 * Find the root HUD panel by searching upwards through parents.
 */
function GetHudRoot(): Panel | null {
    let p = $.GetContextPanel();
    while (p) {
        if (p.id === "Hud") return p;
        p = p.GetParent();
    }
    return null;
}

// RESET: Ensure we aren't stuck in a fade state from a previous map or reload
(function () {
    const hud = GetHudRoot();
    if (hud) hud.RemoveClass("fade-active");
})();

// 1. DEFINITIONS: Ensure the engine understands these event types before we register listeners
$.DefineEvent("ArchipelagoQueueUpdated", 0);
$.DefineEvent("ArchipelagoNotify", 1, "payload");

// Only define this one if it hasn't been defined by another panel (avoids console warnings)
try {
    $.DefineEvent("Archipelago_WarpToMenu", 1, "content", "Force map switch with fade buffer");
} catch (e) {
    // Already defined, safe to ignore
}

// 2. WARP LISTENER: Catches the signal to end the level
$.RegisterForUnhandledEvent("Archipelago_WarpToMenu", (content: string) => {
    $.Msg("[AP] WarpToMenu received for map: " + content + ". Starting black fade buffer...");

    isWarpPending = true;
    pendingWarpMapName = content;

    // Trigger the black fade on the HUD root
    const hud = GetHudRoot();
    if (hud) {
        hud.AddClass("fade-active");
    }

    // If the queue is already empty, wait a 1.5s buffer for final network packets, then warp
    if (notificationQueue.length === 0) {
        $.Schedule(1.5, () => {
            if (isWarpPending) ProcessQueue();
        });
    }
});

function ProcessQueue() {
    // If nothing is left in our memory queue
    if (notificationQueue.length === 0) {
        isTimerRunning = false;

        // WARP CHECK: If we were waiting for the queue to clear before switching levels
        if (isWarpPending) {
            $.Msg("[AP] Notification queue clear. Moving to menu bookmark...");
            // Save the bookmark so the Base Menu script sees it after the world is destroyed
            $.persistentStorage.setItem("ap_return_to_map_select", "true");

            $.Schedule(0.5, () => {
                const useSmartWarp = $.persistentStorage.getItem('ap_smart_warp');
                if (useSmartWarp == 1) {
                    (UiToolkitAPI.GetGlobalObject() as any).SmartWarpNextMap(pendingWarpMapName);
                } else {
                    GameInterfaceAPI.ConsoleCommand("disconnect");
                }
            });
        }
        return;
    }

    // Lock the timer so we don't process multiple panels at once
    isTimerRunning = true;

    // Grab the very first panel in our memory array
    const topPanel = notificationQueue[0];

    // Safety check: if the panel was destroyed externally (like a map reload), skip it
    if (!topPanel || !topPanel.IsValid()) {
        notificationQueue.shift(); // Remove the dead panel from the array
        ProcessQueue();            // Immediately check the next one
        return;
    }

    $.Msg("[AP] 3-second timer started for top panel.");

    // 3 second reading timer
    $.Schedule(3.0, () => {
        if (topPanel && topPanel.IsValid()) {
            topPanel.AddClass('exit-anim');
            $.Msg("[AP] Top panel exiting. Sliding queue.");

            // Wait 0.35s for the CSS collapse animation to finish before deleting
            $.Schedule(0.35, () => {
                if (topPanel && topPanel.IsValid()) {
                    topPanel.DeleteAsync(0);
                }

                notificationQueue.shift();
                ProcessQueue();
            });
        } else {
            notificationQueue.shift();
            ProcessQueue();
        }
    });
}

function OnArchipelagoNotify(payload: string) {
    const container = $.GetContextPanel();
    if (!container) return;

    try {
        const data = JSON.parse(payload);

        $.PlaySoundEvent('Instructor.LessonStart');

        // 1. Create the main entry wrapper
        const entry = $.CreatePanel('Panel', container, '');
        entry.AddClass('notify-entry');

        // 2. Create the colored accent bar
        const accentBar = $.CreatePanel('Panel', entry, 'AccentBar');
        accentBar.AddClass('accent-bar');

        // 3. Create the content container that holds the text
        const content = $.CreatePanel('Panel', entry, '');
        content.AddClass('content');

        // 4. Create and populate the Title label
        const titleLabel = $.CreatePanel('Label', content, 'Title');
        titleLabel.AddClass('title');
        titleLabel.text = data.title || "ARCHIPELAGO";

        // 5. Create and populate the Message label
        const Msgabel = $.CreatePanel('Label', content, 'Message');
        Msgabel.AddClass('body');
        Msgabel.text = data.message || "";

        // Handle the RGB string ("255 100 0")
        if (data.type && data.type.includes(" ")) {
            const rgb = "rgb(" + data.type.replace(/ /g, ",") + ")";
            accentBar.style.backgroundColor = rgb;
            titleLabel.style.color = rgb;
        }

        // PUSH TO MEMORY: Instead of checking the UI, we just push the panel object to our array
        notificationQueue.push(entry);

        // If the queue isn't already ticking, kickstart it!
        if (!isTimerRunning) {
            ProcessQueue();
        }

    } catch (e) {
        $.Msg("Logic Error: " + e);
    }
}

$.RegisterForUnhandledEvent("ArchipelagoQueueUpdated", CheckQueue);

function CheckQueue() {
    const global: any = UiToolkitAPI.GetGlobalObject();
    if (!global || !global.ArchipelagoMessageQueue) return;
    const pending = global.ArchipelagoMessageQueue.filter((msg: any) => !msg.shown);
    for (const msg of pending) {
        msg.shown = true;
        OnArchipelagoNotify(msg.payload);
    }
}
CheckQueue();
