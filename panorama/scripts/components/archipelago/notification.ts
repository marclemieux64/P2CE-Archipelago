'use strict';

const notificationQueue: Panel[] = [];
let isTimerRunning = false;
let isWarpPending = false;
let pendingWarpMapName = "";

function GetHudRoot(): Panel | null {
    let p = $.GetContextPanel();
    while (p) {
        if (p.id === "Hud") return p;
        p = p.GetParent();
    }
    return null;
}

(function () {
    const hud = GetHudRoot();
    if (hud) hud.RemoveClass("fade-active");
})();

$.DefineEvent("ArchipelagoQueueUpdated", 0);
$.DefineEvent("ArchipelagoNotify", 1, "payload");
$.DefineEvent("ArchipelagoHideNotifications", 1, "time");
$.DefineEvent("ArchipelagoDeath", 1, "message");

$.RegisterForUnhandledEvent("ArchipelagoDeath", (msg: string) => {
    OnArchipelagoNotify(JSON.stringify({
        title: "DEATHLINK",
        message: msg,
        type: "255 50 50",
        play_sound: true
    }));
});

try {
    $.DefineEvent("Archipelago_WarpToMenu", 1, "content", "Force map switch with fade buffer");
} catch (e) {}

$.RegisterForUnhandledEvent("Archipelago_WarpToMenu", (content: string) => {
    isWarpPending = true;
    pendingWarpMapName = content;
    const hud = GetHudRoot();
    if (hud) hud.AddClass("fade-active");

    const useSmartWarp = $.persistentStorage.getItem('ap_smart_warp');
    
    if (useSmartWarp !== "1" && useSmartWarp !== 1) {
        const locTitle = $.Localize("#Archipelago_HUD_Warp_Menu");
        const locLoading = $.Localize("#Archipelago_HUD_Warp_Loading");
        OnArchipelagoNotify(JSON.stringify({
            title: locTitle,
            html: locLoading,
            type: "198 33 223",
            play_sound: true
        }));
    } else {
        if (!isTimerRunning) ProcessQueue();
    }
});

function ProcessQueue() {
    if (notificationQueue.length === 0) {
        isTimerRunning = false;
        if (isWarpPending) {
            isWarpPending = false; 
            
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

$.RegisterForUnhandledEvent("ArchipelagoAPI_ChatUpdated", (json: string) => {
    const api: any = (UiToolkitAPI.GetGlobalObject() as any).ArchipelagoAPI;
    if (!api) return;

    try {
        const chat = JSON.parse(json);
        if (Array.isArray(chat) && chat.length > 0) {
            let lastId = api.getLastNotificationId();
            
            if (lastId === -1) {
                lastId = chat[chat.length - 1].id;
                api.setLastNotificationId(lastId);
                return;
            }

            for (const msg of chat) {
                if (msg.id > lastId) {
                    lastId = msg.id;
                    api.setLastNotificationId(lastId);

                    if (msg.priority === true && !msg.no_notification) { 
                        let finalMessage = msg.text || "";
                        let isDeathMsg = false;
                        let isTrapMsg = false;

                        if (msg.type === "json" && Array.isArray(msg.data)) {
                            finalMessage = msg.data.map((p: any) => p.text || "").join("");
                            isDeathMsg = msg.data.some((p: any) => p.is_death === true);
                            isTrapMsg = msg.data.some((p: any) => p.is_trap === true);
                        }

                        if (!isDeathMsg && !isTrapMsg) {
                            isDeathMsg = finalMessage.includes("DeathLink") || finalMessage.includes("mort");
                            isTrapMsg = finalMessage.includes("Trap");
                        }
                        
                        let notifyTitle = $.Localize("#Archipelago_HUD_Default");
                        let notifyType = "success"; 

                        if (isDeathMsg) {
                            notifyTitle = $.Localize("#Archipelago_HUD_Deathlink");
                            notifyType = "255 50 50"; // Rouge
                        } else if (isTrapMsg) {
                            notifyTitle = $.Localize("#Archipelago_HUD_Trap");
                            notifyType = "255 150 0"; // Orange
                        }

                        OnArchipelagoNotify(JSON.stringify({
                            title: notifyTitle,
                            message: finalMessage,
                            html: msg.html || "",
                            type: notifyType,
                            play_sound: true 
                        }));
                    }
                }
            }
        }
    } catch (e) {
        $.Warning("[AP] Error parsing chat for notifications: " + e);
    }
});

function OnArchipelagoNotify(payload: string) {
    const container = $.GetContextPanel();
    if (!container) return;

    try {
        const data = JSON.parse(payload);
        const entry = $.CreatePanel('Panel', container, '');
        if (!entry) return;

        if (data.play_sound) {
            if (data.type === "255 50 50") { 
                $.PlaySoundEvent('Player.FallGib'); 
            } else if (data.type === "255 150 0") { 
                GameInterfaceAPI.ConsoleCommand("snd_playsounds Error");
            } else if (data.type === "0 255 255" || data.type === "198 33 223") { 
                $.PlaySoundEvent('Portal.elevator_chime');
            } else {
                $.PlaySoundEvent('Instructor.LessonStart');
            }
        }

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

        if (data.html) {
            const msgLabel = $.CreatePanel('Label', messageContainer, 'Message');
            msgLabel.AddClass('body');
            msgLabel.html = true;
            msgLabel.text = data.html;
        } else {
            const msgLabel = $.CreatePanel('Label', messageContainer, 'Message');
            msgLabel.AddClass('body');
            msgLabel.text = data.message || "";
        }

        if (data.type && data.type.includes(" ")) {
            const rgb = "rgb(" + data.type.replace(/ /g, ",") + ")";
            accentBar.style.backgroundColor = rgb;
            titleLabel.style.color = rgb;
        } else if (data.type) {
            entry.AddClass('type-' + data.type);
        }

        notificationQueue.push(entry);
        if (!isTimerRunning) ProcessQueue();

    } catch (e) {
        $.Msg("Logic Error: " + e);
    }
}

// Export the notification system so Smart Warp can use it
(UiToolkitAPI.GetGlobalObject() as any).OnArchipelagoNotify = OnArchipelagoNotify;