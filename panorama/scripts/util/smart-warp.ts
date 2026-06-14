'use strict';
if (!$.Msg) { $.Msg = (UiToolkitAPI.GetGlobalObject() as any).Msg; }

let g_IsSmartWarping = false;

function SmartWarpNextMap(currentMapName: string) {
    if (g_IsSmartWarping) return;
    g_IsSmartWarping = true;

    // NETTOYAGE DU NOM DE LA MAP : Éliminer les préfixes et l'extension .bsp
    let cleanCurrentMap = currentMapName || "";
    if (cleanCurrentMap.indexOf("maps/") === 0 || cleanCurrentMap.indexOf("maps\\") === 0) {
        cleanCurrentMap = cleanCurrentMap.substring(5);
    }
    if (cleanCurrentMap.toLowerCase().endsWith(".bsp")) {
        cleanCurrentMap = cleanCurrentMap.substring(0, cleanCurrentMap.length - 4);
    }
    cleanCurrentMap = cleanCurrentMap.trim().toLowerCase();

    $.Msg("[AP] Smart Warp triggered. Active clean map: " + cleanCurrentMap + ". Synchronizing API status...");

    const api = (UiToolkitAPI.GetGlobalObject() as any).ArchipelagoAPI;
    const syncHelper = (UiToolkitAPI.GetGlobalObject() as any).ArchipelagoSync;
    
    const apiStatus = api ? api.getStatus() : null;
    if (!apiStatus || !apiStatus.menu) {
        GameInterfaceAPI.ConsoleCommand("disconnect");
        g_IsSmartWarping = false;
        return;
    }

    // MISE À JOUR : Forcer la reconstruction complète du cache d'état
    let chapters: any = {};
    if (syncHelper && typeof syncHelper.parseApiStatus === "function") {
        chapters = syncHelper.parseApiStatus(apiStatus);
        syncHelper.m_CachedChapters = chapters;
        if (api.m_MenuVersion !== undefined) {
            syncHelper.m_LastParsedMenuVersion = api.m_MenuVersion;
        }
    }

    if (!chapters || Object.keys(chapters).length === 0) {
        GameInterfaceAPI.ConsoleCommand("disconnect");
        g_IsSmartWarping = false;
        return;
    }

    const fullyDoableMaps: any[] = [];    // État Vert (valid_count === total_count)
    const partiallyDoableMaps: any[] = []; // État Jaune (valid_count > 0 && valid_count < total_count)

    for (const chId in chapters) {
        const chapter = chapters[chId];
        if (chapter.maps) {
            for (const map of chapter.maps) {
                // 1. SÉCURITÉ : Ignorer impérativement les boutons désactivés ou sans commande
                const isDeactivated = map.command_deactivated !== null && map.command_deactivated !== false && map.command_deactivated !== undefined;
                if (isDeactivated || !map.command) continue;

                // Nettoyer la commande de la map cible pour la comparaison (ex: "map sp_a1_intro1" -> "sp_a1_intro1")
                let targetMapName = map.command.replace("map ", "").trim().toLowerCase();

                // 2. EXCLUSION DE LA MAP ACTUELLE : On compare les deux noms nettoyés
                if (targetMapName === cleanCurrentMap) continue;

                // 3. CLASSIFICATION DES 4 ÉTATS : Basée sur les compteurs synchronisés
                const isCompleted = map.completed === true || map.progress_text === "0/0";
                if (isCompleted) continue; // État Complété -> Remplacé par check.svg, exclu du warp

                const validCount = map.valid_count || 0;
                const totalCount = map.total_count || 0;

                if (totalCount > 0) {
                    if (validCount === totalCount) {
                        // État Vert : Tous les checks de la map sont accessibles
                        fullyDoableMaps.push(map);
                    } else if (validCount > 0 && validCount < totalCount) {
                        // État Jaune : Une partie seulement des checks est faisable
                        partiallyDoableMaps.push(map);
                    }
                    // État Rouge : validCount === 0 -> Aucun check faisable, la boucle l'ignore
                }
            }
        }
    }

    // 4. PIPELINE DE SÉLECTION HIÉRARCHISÉ : Vert -> Jaune -> Menu Principal
    let targetMap: any = null;
    if (fullyDoableMaps.length > 0) {
        const randomIndex = Math.floor(Math.random() * fullyDoableMaps.length);
        targetMap = fullyDoableMaps[randomIndex];
        $.Msg("[AP] Smart Warp selected an available GREEN map.");
    } else if (partiallyDoableMaps.length > 0) {
        const randomIndex = Math.floor(Math.random() * partiallyDoableMaps.length);
        targetMap = partiallyDoableMaps[randomIndex];
        $.Msg("[AP] Smart Warp selected an available YELLOW map.");
    }

    const notifyFn = (UiToolkitAPI.GetGlobalObject() as any).OnArchipelagoNotify;

    if (targetMap && targetMap.command) {
        const technicalName = targetMap.command.replace("map ", "").trim();
        const mapToken = `#portal2_MapName_${technicalName}`;
        const localizedMapName = $.Localize(mapToken);
        const mapNameDisplay = ((localizedMapName !== mapToken) ? localizedMapName : (targetMap.title || technicalName)).trim();

        let locTitle = $.Localize("#Archipelago_HUD_Warp_Title");
        if (!locTitle || locTitle.trim() === "" || locTitle === "#Archipelago_HUD_Warp_Title") {
            locTitle = "SMART WARP";
        }

        let locDest = $.Localize("#Archipelago_HUD_Warp_Dest");
        if (!locDest || locDest.trim() === "" || locDest === "#Archipelago_HUD_Warp_Dest") {
            locDest = "Destination: %s1";
        }

        if (locDest.indexOf("%s1") !== -1) {
            locDest = locDest.replace("%s1", "<font color='#00ffff'>" + mapNameDisplay + "</font>");
        } else {
            locDest = locDest + " <font color='#00ffff'>" + mapNameDisplay + "</font>";
        }

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
        // Aucune map éligible trouvée -> Retour au menu principal
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