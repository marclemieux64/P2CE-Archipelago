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

$.RegisterForUnhandledEvent("ArchipelagoQueueUpdated", () => {
    checkPersistentQueue();
});

$.RegisterForUnhandledEvent('ShowMainMenu', () => {
    checkPersistentQueue();
});

$.RegisterForUnhandledEvent('ShowPauseMenu', () => {
    checkPersistentQueue();
});

$.RegisterForUnhandledEvent('HideMainMenu', () => {
    $.Schedule(0.1, () => {
        $.DispatchEvent('ArchipelagoQueueUpdated', "");
    });
});

$.RegisterForUnhandledEvent('HidePauseMenu', () => {
    $.Schedule(0.1, () => {
        $.DispatchEvent('ArchipelagoQueueUpdated', "");
    });
});

$.RegisterForUnhandledEvent('ArchipelagoNotify', (payload: string) => {
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

// --- DÉCLARATIONS DES ÉVÉNEMENTS PANORAMA ---
try {
    $.DefineEvent("ArchipelagoQueueUpdated", 0);
    $.DefineEvent("ArchipelagoHideNotifications", 1, "time");
    $.DefineEvent("ArchipelagoDeath", 1, "message");
    $.DefineEvent("Archipelago_WarpToMenu", 1, "content", "Force map switch with fade buffer");
    
    // CORRECTIF : Déclaration obligatoire de l'événement personnalisé pour le Heartbeat silencieux
    $.DefineEvent("ArchipelagoDeathLinkHeartbeat", 0);
} catch (e) { }

// Sécurisation adaptative de la définition pour éviter le message "already registered"
try {
    if (!(UiToolkitAPI.GetGlobalObject() as any).ArchipelagoNotifyRegistered) {
        $.DefineEvent("ArchipelagoNotify", 1, "payload");
        (UiToolkitAPI.GetGlobalObject() as any).ArchipelagoNotifyRegistered = true;
    }
} catch (e) { }

// --- ÉCOUTEURS D'ÉVÉNEMENTS ---

$.RegisterForUnhandledEvent("ArchipelagoDeath", (msg: string) => {
    let locTitle = $.Localize("#Archipelago_HUD_Deathlink");
    if (locTitle === "#Archipelago_HUD_Deathlink") locTitle = "DEATHLINK";

    OnArchipelagoNotify(JSON.stringify({
        title: locTitle,
        message: msg,
        type: "255 50 50",
        play_sound: true
    }));
});

$.RegisterForUnhandledEvent("Archipelago_WarpToMenu", (content: string) => {
    if (isWarpPending) return; 
    
    isWarpPending = true;
    pendingWarpMapName = content;
    const hud = GetHudRoot();
    if (hud) hud.AddClass("fade-active");

    const useSmartWarp = $.persistentStorage.getItem('ap_smart_warp');
    
    if (useSmartWarp !== "1" && useSmartWarp !== 1) {
        let locTitle = $.Localize("#Archipelago_HUD_Warp_Menu_Title");
        if (locTitle === "#Archipelago_HUD_Warp_Menu_Title") locTitle = "WARP TO MENU";
        
        let locLoading = $.Localize("#Archipelago_HUD_Warp_Loading");
        if (locLoading === "#Archipelago_HUD_Warp_Loading") locLoading = "Returning to map select... Loading...";

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
            $.persistentStorage.setItem("ap_return_to_map_select", "true");
            $.Schedule(0.5, () => {
                isWarpPending = false; 
                
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

// --- ÉCOUTE DU CHAT ---
$.RegisterForUnhandledEvent("ArchipelagoAPI_ChatUpdated", (payload: any) => {
    const api: any = (UiToolkitAPI.GetGlobalObject() as any).ArchipelagoAPI;
    if (!api) return;

    const isHud = GetHudRoot() !== null;

    if (isHud) {
        ProcessChat(payload);
    } else {
        $.Schedule(0.1, () => {
            ProcessChat(payload);
        });
    }
});

function getSkippedTrapIds(): number[] {
    const val = $.persistentStorage.getItem("AP_SkippedTrapIds");
    if (!val) return [];
    try {
        const arr = JSON.parse(val);
        return Array.isArray(arr) ? arr : [];
    } catch (e) {
        return [];
    }
}

function addSkippedTrapId(id: number) {
    const arr = getSkippedTrapIds();
    if (arr.indexOf(id) === -1) {
        arr.push(id);
        $.persistentStorage.setItem("AP_SkippedTrapIds", JSON.stringify(arr));
    }
}

function removeSkippedTrapId(id: number) {
    const arr = getSkippedTrapIds();
    const idx = arr.indexOf(id);
    if (idx !== -1) {
        arr.splice(idx, 1);
        $.persistentStorage.setItem("AP_SkippedTrapIds", JSON.stringify(arr));
    }
}

function ProcessChat(payload: any) {
    const isHud = GetHudRoot() !== null;
    const uiState = GameInterfaceAPI.GetGameUIState();
    const isMenuState = (uiState === GameUIState.MAINMENU || uiState === GameUIState.PAUSEMENU);
    
    const shouldProcess = isHud ? !isMenuState : isMenuState;
    if (!shouldProcess) return;

    try {
        // CORRECTIF INTERCEPTEUR V8 : Détection adaptative du type de données (Objet vs String)
        let chat = payload;
        if (typeof payload === 'string') {
            chat = JSON.parse(payload);
        }
        
        if (!Array.isArray(chat) || chat.length === 0) return;

        let lastIdVal = $.persistentStorage.getItem("AP_LastProcessedNotificationId");
        let lastId = (lastIdVal !== null && lastIdVal !== undefined) ? parseInt(lastIdVal.toString()) : -1;
        if (isNaN(lastId)) lastId = -1;

        const latestMsgId = chat[chat.length - 1].id;

        if (lastId !== -1 && latestMsgId < lastId) {
            lastId = -1;
        }

        if (lastId === -1) {
            $.persistentStorage.setItem("AP_LastProcessedNotificationId", latestMsgId);
            return;
        }

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

        for (const msg of chat) {
            const apType = msg.ap_msg_type || "default";
            const isTrap = (apType === "trap") || (msg.html && msg.html.toLowerCase().includes("trap")) || (msg.text && msg.text.toLowerCase().includes("trap"));
            const isSkippedTrap = isHud && isTrap && getSkippedTrapIds().indexOf(msg.id) !== -1;

            if (msg.id > lastId || isSkippedTrap) {
                if (isTrap && !isHud) {
                    addSkippedTrapId(msg.id);
                    lastId = Math.max(lastId, msg.id);
                    $.persistentStorage.setItem("AP_LastProcessedNotificationId", lastId);
                    continue;
                }

                if (isSkippedTrap) {
                    removeSkippedTrapId(msg.id);
                }

                lastId = Math.max(lastId, msg.id);
                $.persistentStorage.setItem("AP_LastProcessedNotificationId", lastId);

                if (msg.muted === true) {
                    continue; 
                }

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
                            const c = cMap[p.color] || "#ffffff";
                            return `<font color='${c}'>${t}</font>`;
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
                
                const apType = msg.ap_msg_type || "default";
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
                    }
                    else if (apType === "goal") {
                        notifyTitle = $.Localize("#Archipelago_HUD_Goal");
                        if (notifyTitle === "#Archipelago_HUD_Goal") notifyTitle = "GOAL ACHIEVED";
                        notifyType = "255 215 0"; 
                    }

                    OnArchipelagoNotify(JSON.stringify({
                        title: notifyTitle,
                        html: finalHtml,
                        type: notifyType,
                        play_sound: true 
                    }));
                }
            }
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