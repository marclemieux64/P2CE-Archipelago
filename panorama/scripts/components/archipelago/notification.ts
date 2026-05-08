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

    if (notificationQueue.length === 0) {
        $.Schedule(1.5, () => {
            if (isWarpPending) ProcessQueue();
        });
    }
});

function ProcessQueue() {
    if (notificationQueue.length === 0) {
        isTimerRunning = false;
        if (isWarpPending) {
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
                            // Initialisation : on se cale sur le DERNIER message existant
                            lastId = chat[chat.length - 1].id;
                            if (api) api.setLastNotificationId(lastId);
                            $.Schedule(0.25, PollForNotifications);
                            return;
                        }

                        for (const msg of chat) {
                            if (msg.id > lastId) {
                                lastId = msg.id;
                                if (api) api.setLastNotificationId(lastId);

                                // Seuls les messages prioritaires (Items, Goal, Mort) vont au HUD
                                if (msg.priority === true && !msg.no_notification) { 
                                    
                                    let finalMessage = msg.text || "";
                                    let isDeathMsg = false;

                                    // Extraction propre du texte et vérification du tag secret
                                    if (msg.type === "json" && Array.isArray(msg.data)) {
                                        finalMessage = msg.data.map((p: any) => p.text || "").join("");
                                        // Si l'un des morceaux du JSON possède le tag "is_death: true"
                                        isDeathMsg = msg.data.some((p: any) => p.is_death === true);
                                    }

                                    // Sécurité supplémentaire au cas où
                                    if (!isDeathMsg) {
                                        isDeathMsg = finalMessage.includes("DeathLink") || finalMessage.includes("mort") || finalMessage.includes("euthanized");
                                    }
                                    
                                    OnArchipelagoNotify(JSON.stringify({
                                        title: isDeathMsg ? "DEATHLINK" : "ARCHIPELAGO",
                                        message: finalMessage, // Texte propre garanti
                                        html: msg.html || "",
                                        type: isDeathMsg ? "255 50 50" : "success", // ROUGE VIF pour la mort
                                        play_sound: true 
                                    }));
                                }
                            }
                        } // Fin du for
                    } // Fin du if Array
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
        if (data.play_sound) {
            if (data.title === "DEATHLINK") {
                // Son d'erreur/alerte (vous pouvez le changer)
                $.PlaySoundEvent('Player.FallGib'); 
            } else {
                // Son positif par défaut (Items, Objectifs)
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