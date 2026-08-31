'use strict';

// All notifications show immediately, staggered by STAGGER_DELAY per in-flight entry.
// Each manages its own 4-second lifetime independently.
const activeNotifications: Panel[] = [];
let pendingCount = 0; // scheduled but not yet created (tracks stagger offset)

const NOTIFY_DURATION  = 4.0;
const STAGGER_DELAY    = 0.25; // seconds between each notification's entry

// Rate limiter: max 3 per 2-second window (bypassed for critical types).
let rateLimitWindowStart = 0;
let rateLimitCount = 0;
const RATE_LIMIT_MAX       = 3;
const RATE_LIMIT_WINDOW_MS = 2000;
let rateLimitSuppressedCount = 0;
let rateLimitFlushSchedule: any = null;

const s_NotificationContainer = $.GetContextPanel();

let pendingNotifIdWrite: number | null = null;
let notifIdFlushSchedule: any = null;

function debouncedWriteNotifId(id: number) {
    pendingNotifIdWrite = id;
    if (!notifIdFlushSchedule) {
        const ctx = $.GetContextPanel();
        notifIdFlushSchedule = $.Schedule(1.0, () => {
            notifIdFlushSchedule = null;
            if (pendingNotifIdWrite !== null && ctx && ctx.IsValid()) {
                $.persistentStorage.setItem("AP_LastProcessedNotificationId", pendingNotifIdWrite);
                pendingNotifIdWrite = null;
            }
        });
    }
}

function registerSelfCleaningEvent(eventName: string, callback: (...args: any[]) => void) {
    const contextPanel = $.GetContextPanel();
    let _handle: number = -1;
    const wrapper = (...args: any[]) => {
        if (!contextPanel || !contextPanel.IsValid()) {
            $.UnregisterForUnhandledEvent(eventName, _handle);
            return;
        }
        callback(...args);
    };
    _handle = $.RegisterForUnhandledEvent(eventName, wrapper);
}

function GetHudRoot(): Panel | null {
    let p = $.GetContextPanel();
    while (p) {
        if (p.id === "Hud") return p;
        p = p.GetParent();
    }
    return null;
}

function purgeInvalidNotifications() {
    for (let i = activeNotifications.length - 1; i >= 0; i--) {
        if (!(activeNotifications[i] as any).IsValid()) {
            activeNotifications.splice(i, 1);
        }
    }
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
        globalObj.ArchipelagoMessageQueue = globalObj.ArchipelagoMessageQueue.filter((msg: any) => !msg.shown);
    }
}

registerSelfCleaningEvent("ArchipelagoQueueUpdated", () => checkPersistentQueue());
registerSelfCleaningEvent('ShowMainMenu',  () => checkPersistentQueue());
registerSelfCleaningEvent('ShowPauseMenu', () => checkPersistentQueue());
registerSelfCleaningEvent('HideMainMenu',  () => {
    const ctx = $.GetContextPanel();
    $.Schedule(0.1, () => { if (ctx && ctx.IsValid()) checkPersistentQueue(); });
});
registerSelfCleaningEvent('HidePauseMenu', () => {
    const ctx = $.GetContextPanel();
    $.Schedule(0.1, () => { if (ctx && ctx.IsValid()) checkPersistentQueue(); });
});

// On map change/reload, HUD panels are destroyed. Reset stagger state so the
// active-slot count corrects itself for the next batch of notifications.
registerSelfCleaningEvent('MapLoaded', (_map: string, _bg: boolean) => {
    purgeInvalidNotifications();
    pendingCount = 0;
});

registerSelfCleaningEvent('ArchipelagoNotify', (payload: string) => {
    const globalObj: any = UiToolkitAPI.GetGlobalObject();
    if (!globalObj.ArchipelagoMessageQueue) globalObj.ArchipelagoMessageQueue = [];
    const exists = globalObj.ArchipelagoMessageQueue.some((msg: any) => msg.payload === payload && Date.now() - msg.timestamp < 1000);
    if (!exists) {
        globalObj.ArchipelagoMessageQueue.push({ payload, shown: false, timestamp: Date.now() });
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

// --- RATE LIMITER ---

function isRateLimitBypassed(type: string, apMsgType: string): boolean {
    return type === "255 50 50"
        || type === "rainbow"
        || apMsgType === "receive"
        || apMsgType === "found"
        || apMsgType === "send"
        || apMsgType === "trap"
        || apMsgType === "deathlink"
        || apMsgType === "goal";
}

function tryEnqueueNotification(payload: string, type: string, apMsgType: string) {
    if (isRateLimitBypassed(type, apMsgType)) {
        OnArchipelagoNotify(payload);
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
                title: "ARCHIPELAGO", message: `+${suppressed} more`,
                dimmed: true, type: "success", play_sound: false
            }));
        }
    }

    if (rateLimitCount >= RATE_LIMIT_MAX) {
        rateLimitSuppressedCount++;
        if (!rateLimitFlushSchedule) {
            const ctx = $.GetContextPanel();
            rateLimitFlushSchedule = $.Schedule(RATE_LIMIT_WINDOW_MS / 1000, () => {
                rateLimitFlushSchedule = null;
                if (rateLimitSuppressedCount > 0 && ctx && ctx.IsValid()) {
                    const suppressed = rateLimitSuppressedCount;
                    rateLimitSuppressedCount = 0;
                    OnArchipelagoNotify(JSON.stringify({
                        title: "ARCHIPELAGO", message: `+${suppressed} more`,
                        dimmed: true, type: "success", play_sound: false
                    }));
                }
            });
        }
        return;
    }

    rateLimitCount++;
    OnArchipelagoNotify(payload);
}

// --- EVENT LISTENERS ---

registerSelfCleaningEvent("ArchipelagoDeath", (msg: string) => {
    let locTitle = $.Localize("#Archipelago_HUD_Deathlink");
    if (locTitle === "#Archipelago_HUD_Deathlink") locTitle = "DEATHLINK";
    OnArchipelagoNotify(JSON.stringify({ title: locTitle, message: msg, type: "255 50 50", play_sound: true }));
});

// --- DISPLAY ENGINE ---

function buildNotificationPanel(payload: string): Panel | null {
    const container = s_NotificationContainer;
    if (!container || !container.IsValid()) return null;

    try {
        const data = JSON.parse(payload);
        const entry = $.CreatePanel('Panel', container, '');
        if (!entry) return null;

        entry.AddClass('notify-entry');

        if (data.play_sound) {
            if      (data.type === "255 50 50")  entry.AddClass('sound-deathlink');
            else if (data.type === "255 150 0")  entry.AddClass('sound-trap');
            else if (data.type === "255 215 0")  entry.AddClass('sound-goal');
            else if (data.type === "0 255 255" || data.type === "198 33 223") entry.AddClass('sound-warp');
            else if (data.type === "rainbow")    entry.AddClass('sound-rainbow');
            else                                 entry.AddClass('sound-default');
        }

        const mainRow = $.CreatePanel('Panel', entry, '');
        mainRow.AddClass('notify-main-row');

        const accentBar = $.CreatePanel('Panel', mainRow, 'AccentBar');
        accentBar.AddClass('accent-bar');

        const content = $.CreatePanel('Panel', mainRow, '');
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
            if (data.dimmed) msgLabel.AddClass('body-dim');
            msgLabel.text = data.message || "";
        }

        const timerBar = $.CreatePanel('Panel', entry, 'TimerBar');
        timerBar.AddClass('timer-bar');

        if (data.type === "rainbow") {
            accentBar.AddClass('rainbow-bg');
            titleLabel.AddClass('rainbow-text');
            timerBar.AddClass('rainbow-bg');
        } else if (data.type && data.type.includes(" ")) {
            const rgb = "rgb(" + data.type.replace(/ /g, ",") + ")";
            accentBar.style.backgroundColor = rgb;
            titleLabel.style.color = rgb;
            timerBar.style.backgroundColor = rgb;
        }

        return entry;
    } catch (e) {
        $.Msg("Error building notification: " + e);
        return null;
    }
}

function exitNotification(panel: Panel) {
    const idx = activeNotifications.indexOf(panel);
    if (idx !== -1) activeNotifications.splice(idx, 1);

    if (!panel.IsValid()) {
        checkWarpDrain();
        return;
    }

    panel.AddClass('exit-slide');
    $.Schedule(0.22, () => {
        if (panel.IsValid()) panel.AddClass('exit-collapse');
        $.Schedule(0.22, () => {
            if (panel.IsValid()) panel.DeleteAsync(0);
            checkWarpDrain();
        });
    });
}

function checkWarpDrain() {
    if (activeNotifications.length === 0 && pendingCount === 0) {
        const transition = (UiToolkitAPI.GetGlobalObject() as any).ArchipelagoTransition;
        if (transition?.hasPendingWarp()) transition.onQueueDrained();
    }
}

function OnArchipelagoNotify(payload: string) {
    purgeInvalidNotifications();

    // Stagger entry: each notification in a rapid burst waits an extra STAGGER_DELAY.
    const delay = pendingCount * STAGGER_DELAY;
    pendingCount++;

    $.Schedule(delay, () => {
        pendingCount = Math.max(0, pendingCount - 1);

        const panel = buildNotificationPanel(payload);
        if (!panel) return;

        activeNotifications.push(panel);

        // Start timer bar on the next frame so the CSS transition has a committed start value.
        const timerBar = (panel as any).FindChild('TimerBar');
        $.Schedule(0, () => {
            if (timerBar && timerBar.IsValid()) timerBar.AddClass('timer-depleting');
        });

        $.Schedule(NOTIFY_DURATION, () => {
            if (panel.IsValid()) {
                exitNotification(panel);
            } else {
                // Destroyed externally (map change/reload) — free the slot.
                const idx = activeNotifications.indexOf(panel);
                if (idx !== -1) activeNotifications.splice(idx, 1);
                checkWarpDrain();
            }
        });
    });
}

// --- CHAT LISTENER ---

registerSelfCleaningEvent("ArchipelagoAPI_ChatUpdated", (delta: any) => {
    const isHud = GetHudRoot() !== null;
    if (isHud) {
        ProcessChat(delta);
    } else {
        const ctx = $.GetContextPanel();
        $.Schedule(0.1, () => { if (ctx && ctx.IsValid()) ProcessChat(delta); });
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

            if (isTrap && !isHud) {
                trapManager?.addSkippedTrapId(msg.id);
                debouncedWriteNotifId(msg.id);
                continue;
            }

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
                tryEnqueueNotification(payload, notifyType, apType);
            }

            // Countdown: forward [Server]: <N> and [Server]: GO as HUD notifications.
            // Calls OnArchipelagoNotify directly to bypass the rate limiter, since
            // countdown ticks arrive at 1-per-second and must never be suppressed.
            {
                const rawText = (msg.text || "").trim();
                const numMatch = rawText.match(/^\[Server\]:\s*(\d+)\s*$/);
                const isCountdownGo = /^\[Server\]:\s*GO\s*$/i.test(rawText);
                if (numMatch) {
                    let cdLabel = $.Localize("#Archipelago_Countdown_Label");
                    if (cdLabel === "#Archipelago_Countdown_Label") cdLabel = "COUNTDOWN";
                    OnArchipelagoNotify(JSON.stringify({ title: numMatch[1], message: cdLabel, play_sound: false }));
                } else if (isCountdownGo) {
                    let goLabel = $.Localize("#Archipelago_Countdown_GO");
                    if (goLabel === "#Archipelago_Countdown_GO") goLabel = "GO!";
                    OnArchipelagoNotify(JSON.stringify({ title: goLabel, message: "", type: "50 200 50", play_sound: true }));
                }
            }

            debouncedWriteNotifId(msg.id);
        }
    } catch (e) {
        $.Warning("[AP] Error parsing chat for notifications: " + e);
    }
}

(UiToolkitAPI.GetGlobalObject() as any).OnArchipelagoNotify = OnArchipelagoNotify;
(UiToolkitAPI.GetGlobalObject() as any).ArchipelagoProcessQueue = () => {
    purgeInvalidNotifications();
    checkWarpDrain();
};
