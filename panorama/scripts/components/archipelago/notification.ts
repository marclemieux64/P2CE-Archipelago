'use strict';

// --- GESTION LOCALE POUR ÉVITER LES CONFLITS HUD/MENU ---
let localLastId = -1;
const notificationQueue: Panel[] = [];
let isTimerRunning = false;
let isWarpPending = false;
let pendingWarpMapName = "";

function GetRoot(): Panel | null {
    let p = $.GetContextPanel();
    while (p) {
        if (p.id === "Hud" || p.id === "MainMenu" || p.id === "MenuMode_MainMenu") return p;
        p = p.GetParent();
    }
    return null;
}

(function () {
    const root = GetRoot();
    if (root) root.RemoveClass("fade-active");
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

$.RegisterForUnhandledEvent("Archipelago_WarpToMenu", (content: string) => {
    if (isWarpPending) return; 
    isWarpPending = true;
    pendingWarpMapName = content;
    const root = GetRoot();
    if (root) root.AddClass("fade-active");

    OnArchipelagoNotify(JSON.stringify({
        title: "RETOUR AU MENU",
        html: "Chargement de la sélection de cartes...",
        type: "198 33 223",
        play_sound: true
    }));
});

function ProcessQueue() {
    if (notificationQueue.length === 0) {
        isTimerRunning = false;
        if (isWarpPending) {
            $.Schedule(0.5, () => {
                isWarpPending = false; 
                GameInterfaceAPI.ConsoleCommand("disconnect");
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

    $.Schedule(5.0, () => {
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
            
            // INITIALISATION : On synchronise le premier polling
            if (localLastId === -1) {
                localLastId = chat[chat.length - 1].id;
                return;
            }

            const inGame = GameInterfaceAPI.GetMapName() !== "";
            const root = GetRoot();
            const isHud = root && root.id === "Hud";

            // Sécurité : Le HUD ne traite pas les messages si on est au menu, et vice versa
            if (isHud && !inGame) return;
            if (!isHud && inGame) return;

            for (const msg of chat) {
                if (msg.id > localLastId) {
                    localLastId = msg.id;

                    if (msg.priority === true && !msg.no_notification) { 
                        let finalHtml = msg.text || "";
                        if (msg.type === "json" && Array.isArray(msg.data)) {
                            finalHtml = msg.data.map((p: any) => {
                                let t = p.text || "";
                                t = t.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
                                if (p.color) {
                                    const cMap: Record<string, string> = {
                                        "red": "#ff5555", "green": "#55ff55", "yellow": "#ffff55",
                                        "blue": "#77aaff", "magenta": "#ee82ee", "cyan": "#55ffff"
                                    };
                                    return `<font color='${cMap[p.color] || "#ffffff"}'>${t}</font>`;
                                }
                                return t;
                            }).join("");
                        }
                        
                        let notifyTitle = "ARCHIPELAGO"; 
                        let notifyType = "success"; 
                        const apType = msg.ap_msg_type || "default";

                        if (apType === "deathlink") {
                            notifyTitle = "DEATHLINK";
                            notifyType = "255 50 50"; 
                        } else if (apType === "trap") {
                            notifyTitle = "PIÈGE";
                            notifyType = "255 150 0"; 
                        } else if (apType === "go_mode") {
                            // --- GO MODE (FEU VERT) ---
                            notifyTitle = "FEU VERT (GO MODE)";
                            notifyType = "rainbow"; 
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
        }
    } catch (e) { }
});

function PlayCustomSoundAtUIVolume(soundName: string) {
    let uiVol = 1.0; 
    try { uiVol = GameInterfaceAPI.GetSettingFloat("snd_volume_ui"); } catch (e) { }
    if (isNaN(uiVol) || uiVol < 0.0) uiVol = 1.0;
    const finalVol = (uiVol > 1.0 ? 1.0 : uiVol).toFixed(2); 
    GameInterfaceAPI.ConsoleCommand(`playvol ${soundName} ${finalVol}`);
}

function OnArchipelagoNotify(payload: string) {
    const container = $.GetContextPanel();
    if (!container) return;

    try {
        const data = JSON.parse(payload);
        const entry = $.CreatePanel('Panel', container, '');
        if (!entry) return;

        if (data.play_sound) {
            if (data.type === "255 50 50") PlayCustomSoundAtUIVolume("physics/body/body_medium_break2.wav"); 
            else if (data.type === "rainbow") {
                // --- SON SMASH WHEATLEY ---
                PlayCustomSoundAtUIVolume("sphere03.bw_a4_finale01_smash03");
            } else PlayCustomSoundAtUIVolume("#ui/beepclear.wav");
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
        const msgLabel = $.CreatePanel('Label', messageContainer, 'Message');
        msgLabel.AddClass('body');
        msgLabel.html = true;
        msgLabel.text = data.html || data.message || "";

        // --- EFFET ARC-EN-CIEL ---
        if (data.type === "rainbow") {
            accentBar.style.backgroundColor = "gradient( linear, 0% 0%, 0% 100%, from( #f00 ), color-stop( 0.2, #ff0 ), color-stop( 0.4, #0f0 ), color-stop( 0.6, #0ff ), color-stop( 0.8, #00f ), to( #f0f ) )";
            titleLabel.style.color = "white";
            titleLabel.style.textShadow = "0px 0px 10px #ffffffaa";
        } else if (data.type && data.type.includes(" ")) {
            const rgb = "rgb(" + data.type.replace(/ /g, ",") + ")";
            accentBar.style.backgroundColor = rgb;
            titleLabel.style.color = rgb;
        }

        notificationQueue.push(entry);
        if (!isTimerRunning) ProcessQueue();
    } catch (e) { }
}

(UiToolkitAPI.GetGlobalObject() as any).OnArchipelagoNotify = OnArchipelagoNotify;