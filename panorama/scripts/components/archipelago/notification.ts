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
    // Le HUD construit le JSON lui-même de manière sécurisée
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
    
    // CONDITION : N'afficher "WARP TO MENU" ici que si le Smart Warp est OFF
    // --- Dans notification.ts (Événement Archipelago_WarpToMenu) ---

if (useSmartWarp !== "1" && useSmartWarp !== 1) {
    const locTitle = $.Localize("#Archipelago_HUD_Warp_Menu"); // Utilisation de la nouvelle clé
    const locLoading = $.Localize("#Archipelago_HUD_Warp_Loading");
    OnArchipelagoNotify(JSON.stringify({
        title: locTitle,
        html: locLoading,
        type: "198 33 223",
        play_sound: true
    }));
}else {
        // Si Smart Warp est ON, on lance ProcessQueue immédiatement pour traiter le Warp sans message initial
        if (!isTimerRunning) ProcessQueue();
    }
});

function ProcessQueue() {
    if (notificationQueue.length === 0) {
        isTimerRunning = false;
        if (isWarpPending) {
            // CRITICAL FIX: Reset the flag immediately so we don't infinite loop 
            // if Smart Warp adds a new notification to the queue!
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
                        
                        if (lastId === -1) {
                            lastId = chat[chat.length - 1].id;
                            if (api) api.setLastNotificationId(lastId);
                            $.Schedule(0.25, PollForNotifications);
                            return;
                        }

                        for (const msg of chat) {
                            if (msg.id > lastId) {
                                lastId = msg.id;
                                if (api) api.setLastNotificationId(lastId);

                                // Seuls les messages prioritaires (Items, Goal, Mort, Trap) vont au HUD
                                if (msg.priority === true && !msg.no_notification) { 
                                    
                                    let finalMessage = msg.text || "";
                                    let isDeathMsg = false;
                                    let isTrapMsg = false;

                                    // Extraction propre du texte et vérification des tags secrets
                                    if (msg.type === "json" && Array.isArray(msg.data)) {
                                        finalMessage = msg.data.map((p: any) => p.text || "").join("");
                                        
                                        // Détection des tags envoyés par Portal2Client.py
                                        isDeathMsg = msg.data.some((p: any) => p.is_death === true);
                                        isTrapMsg = msg.data.some((p: any) => p.is_trap === true);
                                    }

                                    // Sécurité par mots-clés si les tags sont absents
                                    if (!isDeathMsg && !isTrapMsg) {
                                        isDeathMsg = finalMessage.includes("DeathLink") || finalMessage.includes("mort");
                                        isTrapMsg = finalMessage.includes("Trap");
                                    }
                                    
                                    // Détermination du style visuel
                                   // --- Dans notification.ts (Fonction PollForNotifications) ---

// Détermination du style visuel et du titre localisé
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
    if (!container) return; // Si le HUD est crashé ou absent, pas de son.

    try {
        const data = JSON.parse(payload);
        
        // On ne crée le panel QUE maintenant
        const entry = $.CreatePanel('Panel', container, '');
        if (!entry) return;

        // LE SON : On le joue uniquement si le panel a pu être créé
        // LE SON : Choix selon le titre
        if (data.play_sound) {
            if (data.title === "DEATHLINK") {
                $.PlaySoundEvent('Player.FallGib'); 
            } else if (data.title === "TRAP TRIGGERED") {
                // Son de fizzle/erreur pour les pièges
                GameInterfaceAPI.ConsoleCommand("snd_playsounds Error");
            } else if (data.title === "SMART WARP" || data.title === "WARP TO MENU") {
                // smart warp and warp to menu sound
                $.PlaySoundEvent('Portal.elevator_chime');
                
            } else {
                $.PlaySoundEvent('Instructor.LessonStart');
            }
        }

        entry.AddClass('notify-entry');;

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

(function () {
    const context = $.GetContextPanel();
    if (context) {
        PollForNotifications();
    }
})();

// Export the notification system so Smart Warp can use it
(UiToolkitAPI.GetGlobalObject() as any).OnArchipelagoNotify = OnArchipelagoNotify;