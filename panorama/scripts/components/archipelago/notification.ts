'use strict';

const notificationQueue: Panel[] = [];
let isTimerRunning = false;

// Rate limiter: max 3 notifications per 2-second window.
let rateLimitWindowStart = 0;
let rateLimitCount = 0;
const RATE_LIMIT_MAX = 3;
const RATE_LIMIT_WINDOW_MS = 2000;
const QUEUE_HARD_CAP = 5;
let rateLimitSuppressedCount = 0;
let rateLimitFlushSchedule: any = null;

// Debounced storage write for AP_LastProcessedNotificationId
let pendingNotifIdWrite: number | null = null;
let notifIdFlushSchedule: any = null;

function debouncedWriteNotifId(id: number) {
    pendingNotifIdWrite = id;
    if (!notifIdFlushSchedule) {
        notifIdFlushSchedule = $.Schedule(1.0, () => {
            notifIdFlushSchedule = null;
            if (pendingNotifIdWrite !== null) {
                $.persistentStorage.setItem("AP_LastProcessedNotificationId", pendingNotifIdWrite);
                pendingNotifIdWrite = null;
            }
        });
    }
}

function isRateLimitBypassed(type: string, apMsgType: string): boolean {
    return type === "255 50 50"      // deathlink
        || type === "rainbow"        // go mode
        || apMsgType === "receive";  // item received by own slot
}

function tryEnqueueNotification(type: string, apMsgType: string, buildFn: () => void) {
    if (isRateLimitBypassed(type, apMsgType)) {
        buildFn();
        return;
    }

    const now = Date.now();
    if (now - rateLimitWindowStart > RATE_LIMIT_WINDOW_MS) {
        rateLimitWindowStart = now;
        rateLimitCount = 0;

        if (rateLimitSuppressedCount > 0) {
            const suppressed = rateLimitSuppressedCount;
            rateLimitSuppressedCount = 0;
            OnArchipelagoNotify(JSON.stringify({
                title: "ARCHIPELAGO",
                html: `<font color='#aaaaaa'>+${suppressed} more</font>`,
                type: "success",
                play_sound: false
            }));
        }
    }

    if (rateLimitCount >= RATE_LIMIT_MAX || notificationQueue.length >= QUEUE_HARD_CAP) {
        rateLimitSuppressedCount++;
        if (!rateLimitFlushSchedule) {
            rateLimitFlushSchedule = $.Schedule(RATE_LIMIT_WINDOW_MS / 1000, () => {
                rateLimitFlushSchedule = null;
                if (rateLimitSuppressedCount > 0) {
                    const suppressed = rateLimitSuppressedCount;
                    rateLimitSuppressedCount = 0;
                    OnArchipelagoNotify(JSON.stringify({
                        title: "ARCHIPELAGO",
                        html: `<font color='#aaaaaa'>+${suppressed} more</font>`,
                        type: "success",
                        play_sound: false
                    }));
                }
            });
        }
        return;
    }

    rateLimitCount++;
    buildFn();
}

function registerSelfCleaningEvent(eventName: string, callback: (...args: any[]) => void) {
    const contextPanel = $.GetContextPanel();
    const wrapper = (...args: any[]) => {
        if (!contextPanel || !contextPanel.IsValid()) {
            $.UnregisterForUnhandledEvent(eventName, wrapper);
            return;
        }
        callback(...args);
    };
    $.RegisterForUnhandledEvent(eventName, wrapper);
}

function GetHudRoot(): Panel | null {
    let p = $.GetContextPanel();
    while (p) {
        if (p.id === "Hud") return p;
        p = p.GetParent();
    }
    return null;
}

function checkPersistentQueue() {
    const isHud = GetHudRoot() !== null;
    const uiState = GameInterfaceAPI.GetGameUIState();
    const isMenuState = (uiState === GameUIState.MAINMENU || uiState === GameUIState.PAUSEMENU);

    const shouldProcess = isHud ? !isMenuState : isMenuState;
    if (!shouldProcess) return;

    const globalObj: any = UiToolkitAPI.GetGlobalObject();
    if (globalObj.ArchipelagoMessageQueue && Array.isArray(globalObj.ArchipelagoMessageQueue)) {
        globalObj.ArchipelagoMessageQueue.forEach((msg: any) => {
            if (!msg.shown) {
                msg.shown = true;
                OnArchipelagoNotify(msg.payload);
            }
        });
    }
}

registerSelfCleaningEvent("ArchipelagoQueueUpdated", () => {
    checkPersistentQueue();
});

registerSelfCleaningEvent('ShowMainMenu', () => {
    checkPersistentQueue();
});

registerSelfCleaningEvent('ShowPauseMenu', () => {
    checkPersistentQueue();
});

registerSelfCleaningEvent('HideMainMenu', () => {
    $.Schedule(0.1, () => {
        $.DispatchEvent('ArchipelagoQueueUpdated', "");
    });
});

registerSelfCleaningEvent('HidePauseMenu', () => {
    $.Schedule(0.1, () => {
        $.DispatchEvent('ArchipelagoQueueUpdated', "");
    });
});

registerSelfCleaningEvent('ArchipelagoNotify', (payload: string) => {
    const globalObj: any = UiToolkitAPI.GetGlobalObject();
    if (!globalObj.ArchipelagoMessageQueue) {
        globalObj.ArchipelagoMessageQueue = [];
    }

    const exists = globalObj.ArchipelagoMessageQueue.some((msg: any) => msg.payload === payload && Date.now() - msg.timestamp < 1000);
    if (!exists) {
        globalObj.ArchipelagoMessageQueue.push({
            payload: payload,
            shown: false,
            timestamp: Date.now()
        });
        $.DispatchEvent('ArchipelagoQueueUpdated', "");
    }
});

(function () {
    const hud = GetHudRoot();
    if (hud) hud.RemoveClass("fade-active");
    checkPersistentQueue();
})();

// --- EVENT DEFINITIONS ---
try {
    $.DefineEvent("ArchipelagoQueueUpdated", 0);
    $.DefineEvent("ArchipelagoHideNotifications", 1, "time");
    $.DefineEvent("ArchipelagoDeath", 1, "message");
    $.DefineEvent("Archipelago_WarpToMenu", 1, "content", "Force map switch with fade buffer");
    $.DefineEvent("ArchipelagoDeathLinkHeartbeat", 0);
} catch (e) { }

try {
    if (!(UiToolkitAPI.GetGlobalObject() as any).ArchipelagoNotifyRegistered) {
        $.DefineEvent("ArchipelagoNotify", 1, "payload");
        (UiToolkitAPI.GetGlobalObject() as any).ArchipelagoNotifyRegistered = true;
    }
} catch (e) { }

// --- EVENT LISTENERS ---

registerSelfCleaningEvent("ArchipelagoDeath", (msg: string) => {
    let locTitle = $.Localize("#Archipelago_HUD_Deathlink");
    if (locTitle === "#Archipelago_HUD_Deathlink") locTitle = "DEATHLINK";

    OnArchipelagoNotify(JSON.stringify({
        title: locTitle,
        message: msg,
        type: "255 50 50",
        play_sound: true
    }));
});

function ProcessQueue() {
    const contextPanel = $.GetContextPanel();
    if (!contextPanel || !contextPanel.IsValid()) {
        return;
    }
    if (notificationQueue.length === 0) {
        isTimerRunning = false;
        const transition = (UiToolkitAPI.GetGlobalObject() as any).ArchipelagoTransition;
        if (transition?.hasPendingWarp()) {
            transition.onQueueDrained();
        }
        return;
    }

    isTimerRunning = true;
    const topPanel = notificationQueue[0];

    if (!topPanel || !topPanel.IsValid()) {
        notificationQueue.shift();
        ProcessQueue();
        return;
    }

    $.Schedule(4.0, () => {
        if (topPanel && topPanel.IsValid()) {
            topPanel.AddClass('exit-anim');
            $.Schedule(0.35, () => {
                if (topPanel && topPanel.IsValid()) topPanel.DeleteAsync(0);
                notificationQueue.shift();
                ProcessQueue();
            });
        } else {
            notificationQueue.shift();
            ProcessQueue();
        }
    });
}

// --- CHAT LISTENER (delta-based) ---
registerSelfCleaningEvent("ArchipelagoAPI_ChatUpdated", (delta: any) => {
    const api: any = (UiToolkitAPI.GetGlobalObject() as any).ArchipelagoAPI;
    if (!api) return;

    const isHud = GetHudRoot() !== null;

    if (isHud) {
        ProcessChat(delta);
    } else {
        $.Schedule(0.1, () => {
            ProcessChat(delta);
        });
    }
});

function ProcessChat(delta: any) {
    const isHud = GetHudRoot() !== null;
    const uiState = GameInterfaceAPI.GetGameUIState();
    const isMenuState = (uiState === GameUIState.MAINMENU || uiState === GameUIState.PAUSEMENU);

    const shouldProcess = isHud ? !isMenuState : isMenuState;
    if (!shouldProcess) return;

    try {
        let msgs = delta;
        if (typeof delta === 'string') msgs = JSON.parse(delta);
        if (!Array.isArray(msgs) || msgs.length === 0) return;

        let playerPrimaryColor = "64 160 255";
        let playerSecondaryColor = "255 160 32";
        try {
            if (typeof GameInterfaceAPI.GetSettingString === "function") {
                const pColor = GameInterfaceAPI.GetSettingString("cl_portal_sp_primary_color");
                if (pColor && pColor.trim() !== "") playerPrimaryColor = pColor;
                const sColor = GameInterfaceAPI.GetSettingString("cl_portal_sp_secondary_color");
                if (sColor && sColor.trim() !== "") playerSecondaryColor = sColor;
            }
        } catch (e) { }

        for (const msg of msgs) {
            if (!msg) continue;

            const apType = msg.ap_msg_type || "default";
            const isTrap = (apType === "trap") || (msg.html && msg.html.toLowerCase().includes("trap")) || (msg.text && msg.text.toLowerCase().includes("trap"));
            const trapManager = (UiToolkitAPI.GetGlobalObject() as any).ArchipelagoTrapManager;

            // Trap arrived in menu context — defer to gameplay.
            if (isTrap && !isHud) {
                trapManager?.addSkippedTrapId(msg.id);
                debouncedWriteNotifId(msg.id);
                continue;
            }

            // Trap surfacing from deferral — clean up.
            const isSkippedTrap = isHud && isTrap && trapManager?.isSkippedTrap(msg.id);
            if (isSkippedTrap) trapManager?.removeSkippedTrapId(msg.id);

            if (msg.muted === true) continue;

            let finalHtml = "";
            if (msg.html) {
                finalHtml = msg.html;
            } else if (msg.type === "json" && Array.isArray(msg.data)) {
                finalHtml = msg.data.map((p: any) => {
                    let t = p.text || "";
                    t = t.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
                    if (p.color) {
                        const cMap: Record<string, string> = {
                            "red": "#ff5555", "green": "#55ff55", "yellow": "#ffff55",
                            "blue": "#77aaff", "magenta": "#ee82ee", "cyan": "#55ffff",
                            "plum": "#dda0dd", "salmon": "#fa8072"
                        };
                        return `<font color='${cMap[p.color] || "#ffffff"}'>${t}</font>`;
                    } else if (p.type === "player_id" || p.type === "player_name") {
                        return `<font color='#ff7f50'>${t}</font>`;
                    } else if (p.type === "item_id" || p.type === "item_name") {
                        return `<font color='#55ffff'>${t}</font>`;
                    } else if (p.type === "location_id" || p.type === "location_name") {
                        return `<font color='#55ff55'>${t}</font>`;
                    }
                    return t;
                }).join("");
            } else {
                finalHtml = msg.text || "";
            }

            const isGoModeText = finalHtml.toLowerCase().includes("go mode") || finalHtml.toLowerCase().includes("feu vert");
            const isImportant = (msg.priority === true) || isGoModeText || (apType === "go_mode");

            if (isImportant && !msg.no_notification) {
                let notifyTitle = $.Localize("#Archipelago_HUD_Default");
                if (notifyTitle === "#Archipelago_HUD_Default") notifyTitle = "ARCHIPELAGO";
                let notifyType = "success";

                if (apType === "deathlink" || finalHtml.includes("DeathLink") || finalHtml.includes("mort")) {
                    notifyTitle = $.Localize("#Archipelago_HUD_Deathlink");
                    if (notifyTitle === "#Archipelago_HUD_Deathlink") notifyTitle = "DEATHLINK";
                    notifyType = "255 50 50";
                } else if (apType === "trap" || finalHtml.includes("Trap")) {
                    notifyTitle = $.Localize("#Archipelago_HUD_Trap");
                    if (notifyTitle === "#Archipelago_HUD_Trap") notifyTitle = "TRAP";
                    notifyType = "255 150 0";
                } else if (isGoModeText || apType === "go_mode") {
                    notifyTitle = $.Localize("#Archipelago_HUD_GoMode");
                    if (notifyTitle === "#Archipelago_HUD_GoMode") notifyTitle = "GO MODE";
                    let goModeMsg = $.Localize("#Archipelago_HUD_GoMode_Msg");
                    if (goModeMsg === "#Archipelago_HUD_GoMode_Msg") goModeMsg = "All victory conditions have been met!";
                    finalHtml = goModeMsg;
                    notifyType = "rainbow";
                } else if (apType === "found") {
                    notifyTitle = $.Localize("#Archipelago_HUD_Found");
                    if (notifyTitle === "#Archipelago_HUD_Found") notifyTitle = "ITEM FOUND";
                    notifyType = "50 255 50";
                } else if (apType === "receive") {
                    notifyTitle = $.Localize("#Archipelago_HUD_Receive");
                    if (notifyTitle === "#Archipelago_HUD_Receive") notifyTitle = "ITEM RECEIVED";
                    notifyType = playerPrimaryColor;
                } else if (apType === "send") {
                    notifyTitle = $.Localize("#Archipelago_HUD_Send");
                    if (notifyTitle === "#Archipelago_HUD_Send") notifyTitle = "ITEM SENT";
                    notifyType = playerSecondaryColor;
                } else if (apType === "hint") {
                    notifyTitle = $.Localize("#Archipelago_HUD_Hint");
                    if (notifyTitle === "#Archipelago_HUD_Hint") notifyTitle = "NEW HINT";
                    notifyType = "255 255 50";
                } else if (apType === "goal") {
                    notifyTitle = $.Localize("#Archipelago_HUD_Goal");
                    if (notifyTitle === "#Archipelago_HUD_Goal") notifyTitle = "GOAL ACHIEVED";
                    notifyType = "255 215 0";
                }

                const payload = JSON.stringify({ title: notifyTitle, html: finalHtml, type: notifyType, play_sound: true });
                tryEnqueueNotification(notifyType, apType, () => OnArchipelagoNotify(payload));
            }

            debouncedWriteNotifId(msg.id);
        }
    } catch (e) {
        $.Warning("[AP] Error parsing chat for notifications: " + e);
    }
}

function OnArchipelagoNotify(payload: string) {
    const container = $.GetContextPanel();
    if (!container) return;

    try {
        const data = JSON.parse(payload);
        const entry = $.CreatePanel('Panel', container, '');
        if (!entry) return;

        entry.AddClass('notify-entry');

        if (data.play_sound) {
            if (data.type === "255 50 50") entry.AddClass('sound-deathlink');
            else if (data.type === "255 150 0") entry.AddClass('sound-trap');
            else if (data.type === "255 215 0") entry.AddClass('sound-goal');
            else if (data.type === "0 255 255" || data.type === "198 33 223") entry.AddClass('sound-warp');
            else if (data.type === "rainbow") entry.AddClass('sound-rainbow');
            else entry.AddClass('sound-default');
        }

        const accentBar = $.CreatePanel('Panel', entry, 'AccentBar');
        accentBar.AddClass('accent-bar');

        const content = $.CreatePanel('Panel', entry, '');
        content.AddClass('content');

        const titleLabel = $.CreatePanel('Label', content, 'Title') as LabelPanel;
        titleLabel.AddClass('title');

        let defaultTitle = $.Localize("#Archipelago_HUD_Default");
        if (defaultTitle === "#Archipelago_HUD_Default") defaultTitle = "ARCHIPELAGO";
        titleLabel.text = data.title || defaultTitle;

        const messageContainer = $.CreatePanel('Panel', content, 'MessageArea');
        messageContainer.style.flowChildren = 'right';
        messageContainer.style.width = '100%';

        if (data.html) {
            const msgLabel = $.CreatePanel('Label', messageContainer, 'Message') as LabelPanel;
            msgLabel.AddClass('body');
            msgLabel.html = true;
            msgLabel.text = data.html;
        } else {
            const msgLabel = $.CreatePanel('Label', messageContainer, 'Message') as LabelPanel;
            msgLabel.AddClass('body');
            msgLabel.text = data.message || "";
        }

        if (accentBar && titleLabel) {
            if (data.type === "rainbow") {
                accentBar.AddClass('rainbow-bg');
                titleLabel.AddClass('rainbow-text');
            } else if (data.type && data.type.includes(" ")) {
                const rgb = "rgb(" + data.type.replace(/ /g, ",") + ")";
                accentBar.style.backgroundColor = rgb;
                titleLabel.style.color = rgb;
            }
        }

        notificationQueue.push(entry);
        if (!isTimerRunning) ProcessQueue();

    } catch (e) {
        $.Msg("Logic Error: " + e);
    }
}

(UiToolkitAPI.GetGlobalObject() as any).OnArchipelagoNotify = OnArchipelagoNotify;
(UiToolkitAPI.GetGlobalObject() as any).ArchipelagoProcessQueue = () => {
    if (!isTimerRunning) ProcessQueue();
};
