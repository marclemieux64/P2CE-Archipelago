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
    if (isWarpPending) return; 
    
    isWarpPending = true;
    pendingWarpMapName = content;
    const hud = GetHudRoot();
    if (hud) hud.AddClass("fade-active");

    const useSmartWarp = $.persistentStorage.getItem('ap_smart_warp');
    
    if (useSmartWarp !== "1" && useSmartWarp !== 1) {
        let locTitle = $.Localize("#Archipelago_HUD_Warp_Menu");
        if (locTitle === "#Archipelago_HUD_Warp_Menu") locTitle = "WARP TO MENU";
        
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
            let lastId = api.getLastNotificationId();
            
            if (lastId === -1) {
                lastId = chat[chat.length - 1].id;
                api.setLastNotificationId(lastId);
                return;
            }

            // --- NOUVEAU : Récupération des couleurs du joueur ---
            let playerPrimaryColor = "64 160 255";   // Fallback : Blue
            let playerSecondaryColor = "255 160 32"; // Fallback : Orange
            try {
                if (typeof GameInterfaceAPI.GetSettingString === "function") {
                    const pColor = GameInterfaceAPI.GetSettingString("cl_portal_sp_primary_color");
                    if (pColor && pColor.trim() !== "") playerPrimaryColor = pColor;
                    
                    const sColor = GameInterfaceAPI.GetSettingString("cl_portal_sp_secondary_color");
                    if (sColor && sColor.trim() !== "") playerSecondaryColor = sColor;
                }
            } catch (e) {
                $.Msg("[AP] Impossible de lire les couleurs du joueur, utilisation des valeurs par défaut.");
            }

            for (const msg of chat) {
                if (msg.id > lastId) {
                    lastId = msg.id;
                    api.setLastNotificationId(lastId);

                    if (msg.priority === true && !msg.no_notification) { 
                        let finalHtml = msg.text || "";
                        
                        // RECONSTRUCTION DE LA PHRASE COMPLÈTE (Avec couleurs !)
                        if (msg.type === "json" && Array.isArray(msg.data)) {
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
                                    return `<font color='#ff7f50'>${t}</font>`; // Joueur = Orange
                                } else if (p.type === "item_id" || p.type === "item_name") {
                                    return `<font color='#55ffff'>${t}</font>`; // Objet = Cyan
                                } else if (p.type === "location_id" || p.type === "location_name") {
                                    return `<font color='#55ff55'>${t}</font>`; // Lieu = Vert
                                }
                                return t;
                            }).join("");
                        }
                        
                        // SÉLECTION DU TITRE ET DE LA COULEUR SELON LE TAG
                        let notifyTitle = $.Localize("#Archipelago_HUD_Default");
                        if (notifyTitle === "#Archipelago_HUD_Default") notifyTitle = "ARCHIPELAGO"; 
                        let notifyType = "success"; 
                        
                        const apType = msg.ap_msg_type || "default";

                        // --- CORRECTION : On ne se fie plus au texte, uniquement au flag natif ! ---
                        if (apType === "deathlink") {
                            notifyTitle = $.Localize("#Archipelago_HUD_Deathlink");
                            if (notifyTitle === "#Archipelago_HUD_Deathlink") notifyTitle = "DEATHLINK";
                            notifyType = "255 50 50"; // Rouge
                            
                        } else if (apType === "trap" || finalHtml.includes("Trap")) {
                            notifyTitle = $.Localize("#Archipelago_HUD_Trap");
                            if (notifyTitle === "#Archipelago_HUD_Trap") notifyTitle = "TRAP";
                            notifyType = "255 150 0"; // Orange
                            
                        } else if (apType === "found") {
                            notifyTitle = $.Localize("#Archipelago_HUD_Found");
                            if (notifyTitle === "#Archipelago_HUD_Found") notifyTitle = "ITEM FOUND";
                            notifyType = "50 255 50"; // Vert vif
                            
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
                            notifyType = "255 255 50"; // Jaune
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
    } catch (e) {
        $.Warning("[AP] Error parsing chat for notifications: " + e);
    }
});

function PlayCustomSoundAtUIVolume(soundName: string) {
    let uiVol = 1.0; 
    
    try {
        // Utilisation exacte de l'API selon le Wiki de Strata Source
        uiVol = GameInterfaceAPI.GetSettingFloat("snd_volume_ui");
    } catch (e) {
        $.Msg("[AP Audio] Erreur avec GetSettingFloat : " + e);
    }

    // Sécurisation de la valeur (au cas où le jeu renvoie null ou un texte)
    if (isNaN(uiVol) || uiVol < 0.0) uiVol = 1.0;
    if (uiVol > 1.0) uiVol = 1.0;

    // Formatage propre (ex: 0.50)
    const finalVol = uiVol.toFixed(2); 
    
    // Message de débogage CRUCIAL
    $.Msg(`[AP Audio] Application du volume : playvol ${soundName} ${finalVol}`);

    // Exécution de la commande
    GameInterfaceAPI.ConsoleCommand(`playvol ${soundName} ${finalVol}`);
}

function OnArchipelagoNotify(payload: string) {
    const container = $.GetContextPanel();
    if (!container) return;

    try {
        const data = JSON.parse(payload);
        const entry = $.CreatePanel('Panel', container, '');
        if (!entry) return;

        // --- MISE À JOUR : Utilisation de la nouvelle fonction pour les sons ---
        if (data.play_sound) {
            if (data.type === "255 50 50") { 
                // Deathlink (Son en jeu forcé au volume UI)
                PlayCustomSoundAtUIVolume("physics/body/body_medium_break2.wav"); 
            } else if (data.type === "255 150 0") { 
                // Trap (Son en jeu forcé au volume UI)
                PlayCustomSoundAtUIVolume('Error');
            } else if (data.type === "0 255 255" || data.type === "198 33 223") { 
                // Warp (Son UI natif, gère déjà snd_volume_ui automatiquement)
                PlayCustomSoundAtUIVolume("ambient/alarms/portal_elevator_chime.wav");
            } else {
                // Défaut (Son UI natif, gère déjà snd_volume_ui automatiquement)
                PlayCustomSoundAtUIVolume("#ui/beepclear.wav");
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

(UiToolkitAPI.GetGlobalObject() as any).OnArchipelagoNotify = OnArchipelagoNotify;