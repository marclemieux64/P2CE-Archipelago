$.Msg(">>> Archipelago Notification Bridge (Memory Queue Mode)!");

// Track our panels purely in memory to bypass Panorama's DOM lag
const notificationQueue: Panel[] = [];
let isTimerRunning = false;

function ProcessQueue() {
    // If nothing is left in our memory queue, we stop the loop
    if (notificationQueue.length === 0) {
        isTimerRunning = false;
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

    // 3 econd reading timer
    $.Schedule(3.0, () => {
        if (topPanel && topPanel.IsValid()) {
            topPanel.AddClass('exit-anim');
            $.Msg("[AP] Top panel exiting. Sliding queue.");

            // Wait 0.35s for the CSS collapse animation to finish before deleting
            $.Schedule(0.35, () => {
                if (topPanel && topPanel.IsValid()) {
                    topPanel.DeleteAsync(0);
                }

                // 1. Remove the finished panel from our memory array
                notificationQueue.shift();

                // 2. Immediately process the next panel in line!
                ProcessQueue();
            });
        } else {
            // If it became invalid during the 5 seconds, just move on
            notificationQueue.shift();
            ProcessQueue();
        }
    });
}

function OnAPNotify(payload: string) {
    const container = $.GetContextPanel();
    if (!container) return;

    try {
        const data = JSON.parse(payload);

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
        const msgLabel = $.CreatePanel('Label', content, 'Message');
        msgLabel.AddClass('body');
        msgLabel.text = data.message || "";

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

$.RegisterForUnhandledEvent("AP_Notify", OnAPNotify);