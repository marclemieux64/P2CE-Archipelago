'use strict';
if (!$.Msg) { $.Msg = (UiToolkitAPI.GetGlobalObject() as any).Msg; }

let g_IsSmartWarping = false;

function SmartWarpNextMap(currentMapName: string) {
    if (g_IsSmartWarping) return;
    g_IsSmartWarping = true;

    $.Msg("[AP] Smart Warp triggered for map: " + currentMapName + ". Searching for best next map...");
    
    if (!currentMapName) currentMapName = "";

    const api = (UiToolkitAPI.GetGlobalObject() as any).ArchipelagoAPI;
    const syncHelper = (UiToolkitAPI.GetGlobalObject() as any).ArchipelagoSync;
    
    const apiStatus = api ? api.getStatus() : null;
    if (!apiStatus || !apiStatus.menu) {
        GameInterfaceAPI.ConsoleCommand("disconnect");
        g_IsSmartWarping = false;
        return;
    }

    const chapters = syncHelper ? syncHelper.parseApiStatus(apiStatus) : {};
    
    if (Object.keys(chapters).length === 0) {
        GameInterfaceAPI.ConsoleCommand("disconnect");
        g_IsSmartWarping = false;
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

    let targetMap: any = null;
    if (fullyDoableMaps.length > 0) {
        const randomIndex = Math.floor(Math.random() * fullyDoableMaps.length);
        targetMap = fullyDoableMaps[randomIndex];
    } else if (partiallyDoableMaps.length > 0) {
        const randomIndex = Math.floor(Math.random() * partiallyDoableMaps.length);
        targetMap = partiallyDoableMaps[randomIndex];
    }

    const notifyFn = (UiToolkitAPI.GetGlobalObject() as any).OnArchipelagoNotify;

    if (targetMap && targetMap.command) {
        const technicalName = targetMap.command.replace("map ", "").trim();
        const mapToken = `#portal2_MapName_${technicalName}`;
        const localizedMapName = $.Localize(mapToken);
        const mapNameDisplay = ((localizedMapName !== mapToken) ? localizedMapName : (targetMap.title || technicalName)).trim();

        // TITRE
        let locTitle = $.Localize("#Archipelago_HUD_Warp_Title");
        if (!locTitle || locTitle.trim() === "" || locTitle === "#Archipelago_HUD_Warp_Title") {
            locTitle = "SMART WARP";
        }

        // DESTINATION (Correction du bug de la chaîne vide)
        let locDest = $.Localize("#Archipelago_HUD_Warp_Dest");
        if (!locDest || locDest.trim() === "" || locDest === "#Archipelago_HUD_Warp_Dest") {
            locDest = "Destination: %s1"; // Fallback garanti
        }

        if (locDest.indexOf("%s1") !== -1) {
            locDest = locDest.replace("%s1", "<font color='#00ffff'>" + mapNameDisplay + "</font>");
        } else {
            locDest = locDest + " <font color='#00ffff'>" + mapNameDisplay + "</font>";
        }

        // DELAI
        let locDelay = $.Localize("#Archipelago_HUD_Warp_Delay");
        if (!locDelay || locDelay.trim() === "" || locDelay === "#Archipelago_HUD_Warp_Delay") {
            locDelay = "Warping in 3 seconds...";
        }

        if (notifyFn) {
            notifyFn(JSON.stringify({
                title: locTitle,
                html: `${locDest}<br/><font color='#aaaaaa'><i>${locDelay}</i></font>`,
                type: "0 255 255", 
                play_sound: true
            }));
        }

        $.Schedule(3.0, () => {
            GameInterfaceAPI.ConsoleCommand(targetMap.command);
            g_IsSmartWarping = false; 
        });

    } else {
        // MENU WARP FALLBACKS
        let locTitle = $.Localize("#Archipelago_HUD_Warp_Menu_Title");
        if (!locTitle || locTitle.trim() === "" || locTitle === "#Archipelago_HUD_Warp_Menu_Title") {
            locTitle = "WARP TO MENU";
        }

        let locNoMaps = $.Localize("#Archipelago_HUD_Warp_NoMaps");
        if (!locNoMaps || locNoMaps.trim() === "" || locNoMaps === "#Archipelago_HUD_Warp_NoMaps") {
            locNoMaps = "No doable maps found.";
        }

        let locLoading = $.Localize("#Archipelago_HUD_Warp_Loading");
        if (!locLoading || locLoading.trim() === "" || locLoading === "#Archipelago_HUD_Warp_Loading") {
            locLoading = "Returning to map select... Loading...";
        }

        if (notifyFn) {
            notifyFn(JSON.stringify({
                title: locTitle,
                html: `${locNoMaps}<br/><font color='#aaaaaa'><i>${locLoading}</i></font>`,
                type: "198 33 223", 
                play_sound: true
            }));
        }

        $.Schedule(3.0, () => {
            GameInterfaceAPI.ConsoleCommand("disconnect");
            g_IsSmartWarping = false;
        });
    }
}

(UiToolkitAPI.GetGlobalObject() as any).SmartWarpNextMap = SmartWarpNextMap;