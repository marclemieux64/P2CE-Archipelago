'use strict';
if (!$.Msg) { $.Msg = (UiToolkitAPI.GetGlobalObject() as any).Msg; }

function SmartWarpNextMap(currentMapName: string) {
    $.Msg("[AP] Smart Warp triggered for map: " + currentMapName + ". Searching for best next map...");
    
    if (!currentMapName) currentMapName = "";

    const api = (UiToolkitAPI.GetGlobalObject() as any).ArchipelagoAPI;
    const syncHelper = (UiToolkitAPI.GetGlobalObject() as any).ArchipelagoSync;
    
    const apiStatus = api ? api.getStatus() : null;
    if (!apiStatus || !apiStatus.menu) {
        $.Msg("[AP] Smart Warp failed: Archipelago API status not available or incomplete.");
        GameInterfaceAPI.ConsoleCommand("disconnect");
        return;
    }

    const chapters = syncHelper ? syncHelper.parseApiStatus(apiStatus) : {};
    
    if (Object.keys(chapters).length === 0) {
        $.Msg("[AP] Smart Warp failed: No map data found in API status.");
        GameInterfaceAPI.ConsoleCommand("disconnect");
        return;
    }

    const currentMapCmd = "map " + currentMapName;
    const fullyDoableMaps: any[] = [];
    const partiallyDoableMaps: any[] = [];

    for (const chId in chapters) {
        const chapter = chapters[chId];
        if (chapter.maps) {
            for (const map of chapter.maps) {
                if (!map.command) continue;
                if (map.command.trim() === currentMapCmd.trim()) continue;

                const status = syncHelper ? syncHelper.getMapStatus(map, chapters) : { completed: false, doable: false, fullyDoable: false };
                if (status.completed) continue;

                if (status.fullyDoable) {
                    fullyDoableMaps.push(map);
                } else if (status.doable) {
                    partiallyDoableMaps.push(map);
                }
            }
        }
    }

    let targetMap = null;
    if (fullyDoableMaps.length > 0) {
        const randomIndex = Math.floor(Math.random() * fullyDoableMaps.length);
        targetMap = fullyDoableMaps[randomIndex];
    } else if (partiallyDoableMaps.length > 0) {
        const randomIndex = Math.floor(Math.random() * partiallyDoableMaps.length);
        targetMap = partiallyDoableMaps[randomIndex];
    }

    const notifyFn = (UiToolkitAPI.GetGlobalObject() as any).OnArchipelagoNotify;

    if (targetMap && targetMap.command) {
        // --- LOGIQUE DE NOM LOCALISÉ (comme dans le HUD) ---
        const technicalName = targetMap.command.replace("map ", "").trim();
        const mapToken = `#portal2_MapName_${technicalName}`;
        const localizedMapName = $.Localize(mapToken);
        const mapNameDisplay = (localizedMapName !== mapToken) ? localizedMapName : (targetMap.title || technicalName);

        $.Msg("[AP] Smart Warp Success: Sending player to " + mapNameDisplay);
        
        if (notifyFn) {
            notifyFn(JSON.stringify({
                title: "SMART WARP",
                html: "Destination: <font color='#00ffff'>" + mapNameDisplay + "</font><br/><font color='#aaaaaa'><i>Warping in 3 seconds...</i></font>",
                type: "0 255 255", // Cyan
                play_sound: true
            }));
        }

        $.Schedule(3.0, () => {
            GameInterfaceAPI.ConsoleCommand(targetMap.command);
        });

    } else {
        // --- CAS : AUCUNE CARTE TROUVÉE ---
        $.Msg("[AP] Smart Warp: No doable maps found. Returning to menu.");
        
        if (notifyFn) {
            notifyFn(JSON.stringify({
                title: "WARP TO MENU",
                html: "Aucun niveau disponible.<br/><font color='#aaaaaa'><i>Retour au menu...</i></font>",
                type: "198 33 223", // Violet (cohérent avec le menu)
                play_sound: true
            }));
        }

        // On attend 1.5s pour que le joueur puisse lire le message d'échec avant de déconnecter
        $.Schedule(1.5, () => {
            GameInterfaceAPI.ConsoleCommand("disconnect");
        });
    }
}

(UiToolkitAPI.GetGlobalObject() as any).SmartWarpNextMap = SmartWarpNextMap;