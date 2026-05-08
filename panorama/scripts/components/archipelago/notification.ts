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
                if (useSmartWarp === "1" || useSmartWarp === 1) {
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

    // 3 second reading timer
    $.Schedule(3.0, () => {
        if (topPanel && topPanel.IsValid()) {
            topPanel.AddClass('exit-anim');

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

const API_BASE = "http://127.0.0.1:8910";
function PollForNotifications() {
    const api: any = (UiToolkitAPI.GetGlobalObject() as any).ArchipelagoAPI;
    
    $.AsyncWebRequest(API_BASE + "/chat", {
        type: 'GET',
        complete: (res: any) => {
            if (res.status === 200 && res.responseText) {
                try {
                    const cleanJson = res.responseText.trim().replace(/\0/g, '');
                    const chat = JSON.parse(cleanJson);
                    if (Array.isArray(chat) && chat.length > 0) {
                        let lastId = api ? api.getLastNotificationId() : -1;
                        
                        // On first run, initialize to the latest message minus one to show the last message
                        if (lastId === -1) {
                            lastId = chat[chat.length - 1].id - 1;
                            if (api) api.setLastNotificationId(lastId);
                        }

                        for (const msg of chat) {
                            if (msg.id > lastId) {
                                OnArchipelagoNotify(JSON.stringify({
                                    title: "ARCHIPELAGO",
                                    message: msg.type === "json" ? JSON.stringify(msg.data) : msg.text,
                                    html: msg.html || "",
                                    type: "success"
                                }));
                                lastId = msg.id;
                                if (api) api.setLastNotificationId(lastId);
                            }
                        }
                    }
                } catch (e) {
                    $.Warning("[AP] Error parsing chat: " + e);
                }
            }
            $.Schedule(0.25, PollForNotifications);
        },
        error: () => {
            $.Schedule(2.0, PollForNotifications);
        }
    });
}

function OnArchipelagoNotify(payload: string) {
    const container = $.GetContextPanel();
    if (!container) return;

    try {
        const data = JSON.parse(payload);
        
        $.PlaySoundEvent('Instructor.LessonStart');

        const rawMsg = data.message || "";
        // $.Msg("[AP HUD] Rendering message: " + rawMsg.substring(0, 20));

        // Create the main entry manually for maximum compatibility with P2CE
        const entry = $.CreatePanel('Panel', container, '');
        entry.AddClass('notify-entry');

        const accentBar = $.CreatePanel('Panel', entry, 'AccentBar');
        accentBar.AddClass('accent-bar');

        const content = $.CreatePanel('Panel', entry, '');
        content.AddClass('content');

        const titleLabel = $.CreatePanel('Label', content, 'Title');
        titleLabel.AddClass('title');
        titleLabel.text = data.title || "ARCHIPELAGO";

        const messageContainer = $.CreatePanel('Panel', content, 'MessageArea');
        messageContainer.style.flowChildren = 'right';
        messageContainer.style.width = '100%';

        // Check if the message is a JSON array of parts
        let parts: any[] = [];
        try {
            const trimmed = rawMsg.trim();
            if (trimmed.startsWith('[')) {
                parts = JSON.parse(trimmed);
            }
        } catch (e) {
            parts = [];
        }

        // If we have HTML from the Python client, use it for perfect color parity
        if (data.html) {
            const msgLabel = $.CreatePanel('Label', messageContainer, 'Message');
            msgLabel.AddClass('body');
            msgLabel.html = true;
            msgLabel.text = data.html;
        } else if (parts.length > 0) {
            for (const part of parts) {
                const label = $.CreatePanel('Label', messageContainer, '');
                label.AddClass('body');
                label.text = part.text || "";
                
                // Use CSS classes for coloring (defined in notification.scss)
                if (part.type) label.AddClass('color-' + part.type);
                if (part.color) label.AddClass('color-' + part.color);
            }
        } else {
            const msgLabel = $.CreatePanel('Label', messageContainer, 'Message');
            msgLabel.AddClass('body');
            msgLabel.text = data.message || "";
        }

        // Handle the accent color
        if (data.type && data.type.includes(" ")) {
            const rgb = "rgb(" + data.type.replace(/ /g, ",") + ")";
            accentBar.style.backgroundColor = rgb;
            titleLabel.style.color = rgb;
        } else if (data.type) {
            entry.AddClass('type-' + data.type);
        }

        notificationQueue.push(entry);

        if (!isTimerRunning) {
            ProcessQueue();
        }

    } catch (e) {
        $.Msg("Logic Error: " + e);
    }
}

// ============================================================================
// INITIALIZATION
// ============================================================================

(function () {
    const context = $.GetContextPanel();
    if (context) {
        $.Msg("[AP] Notification HUD Initialized (API Polling Mode)");
        PollForNotifications();

        // No longer listening for ArchipelagoNotify event to avoid duplicates from legacy sources
        
        const global: any = UiToolkitAPI.GetGlobalObject();
        if (global.ArchipelagoMessageQueue) {
            $.Schedule(0.5, () => {
                const pending = global.ArchipelagoMessageQueue.filter((msg: any) => !msg.shown);
                for (const msg of pending) {
                    msg.shown = true;
                    OnArchipelagoNotify(msg.payload);
                }
            });
        }
    }
})();
