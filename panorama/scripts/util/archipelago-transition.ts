'use strict';

declare var $: any;
declare var UiToolkitAPI: any;
declare var GameInterfaceAPI: any;

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

function getHudPanel(): Panel | null {
    const ctx = $.GetContextPanel();
    // Try as descendant first (works from hud.xml root script context)
    const asChild = (ctx as any)?.FindChildTraverse ? (ctx as any).FindChildTraverse("Hud") : null;
    if (asChild) return asChild;
    // Fallback: traverse up (works from Frame context)
    let p: any = ctx;
    while (p) {
        if (p.id === "Hud") return p;
        p = p.GetParent();
    }
    return null;
}

const SMART_WARP_DELAY_SECONDS = 4.0;

class ArchipelagoTransition {
    static m_IsWarpPending: boolean = false;
    static m_PendingMapName: string = "";
    static m_IsSmartWarping: boolean = false;

    static requestWarp(mapName: string) {
        if (this.m_IsWarpPending) return;
        this.m_IsWarpPending = true;
        this.m_PendingMapName = mapName;

        // Stop polling now — panels will be torn down during the upcoming map transition.
        // Polling resumes automatically when ArchipelagoMapNameUpdated fires on the new map.
        const api = (UiToolkitAPI.GetGlobalObject() as any).ArchipelagoAPI;
        if (api && api.pausePolling) api.pausePolling();

        const hud = getHudPanel();
        if (hud) (hud as any).AddClass("fade-active");

        const useSmartWarp = $.persistentStorage.getItem('cv_SmartWarp');

        if (useSmartWarp !== "1" && useSmartWarp !== 1) {
            // Menu warp: show notification, queue will drain → onQueueDrained → disconnect
            const notifyFn = (UiToolkitAPI.GetGlobalObject() as any).OnArchipelagoNotify;
            if (notifyFn) {
                let locTitle = $.Localize("#Archipelago_HUD_Warp_Menu_Title");
                if (!locTitle || locTitle === "#Archipelago_HUD_Warp_Menu_Title") locTitle = "WARP TO MENU";
                let locLoading = $.Localize("#Archipelago_HUD_Warp_Loading");
                if (!locLoading || locLoading === "#Archipelago_HUD_Warp_Loading") locLoading = "Returning to map select... Loading...";
                notifyFn(JSON.stringify({ title: locTitle, html: locLoading, type: "198 33 223", play_sound: true }));
            }
        } else {
            // Smart warp: no pre-warp notification — trigger queue processing so it drains immediately
            const processQueue = (UiToolkitAPI.GetGlobalObject() as any).ArchipelagoProcessQueue;
            if (processQueue) processQueue();
        }
    }

    static hasPendingWarp(): boolean {
        return this.m_IsWarpPending;
    }

    static onQueueDrained() {
        $.persistentStorage.setItem("ap_return_to_map_select", "true");
        const ctx = $.GetContextPanel();
        $.Schedule(0.5, () => {
            if (!ctx || !ctx.IsValid()) return;
            const mapName = this.m_PendingMapName;
            this.m_IsWarpPending = false;
            this.m_PendingMapName = "";
            const useSmartWarp = $.persistentStorage.getItem('cv_SmartWarp');
            if (useSmartWarp === "1" || useSmartWarp === 1) {
                this.smartWarpNextMap(mapName);
            } else {
                GameInterfaceAPI.ConsoleCommand("disconnect");
            }
        });
    }

    static smartWarpNextMap(currentMapName: string) {
        if (this.m_IsSmartWarping) return;
        this.m_IsSmartWarping = true;
        const ctx = $.GetContextPanel();

        let cleanCurrentMap = currentMapName || "";
        if (cleanCurrentMap.indexOf("maps/") === 0 || cleanCurrentMap.indexOf("maps\\") === 0)
            cleanCurrentMap = cleanCurrentMap.substring(5);
        if (cleanCurrentMap.toLowerCase().endsWith(".bsp"))
            cleanCurrentMap = cleanCurrentMap.substring(0, cleanCurrentMap.length - 4);
        cleanCurrentMap = cleanCurrentMap.trim().toLowerCase();

        $.Msg("[AP] Smart Warp triggered. Active clean map: " + cleanCurrentMap);

        const global = UiToolkitAPI.GetGlobalObject() as any;
        const api = global.ArchipelagoAPI;
        const syncHelper = global.ArchipelagoSync;
        const notifyFn = global.OnArchipelagoNotify;

        const apiStatus = api ? api.getStatus() : null;
        if (!apiStatus || !apiStatus.menu) {
            GameInterfaceAPI.ConsoleCommand("disconnect");
            this.m_IsSmartWarping = false;
            return;
        }

        let chapters: any = {};
        if (syncHelper && typeof syncHelper.parseApiStatus === "function") {
            chapters = syncHelper.parseApiStatus(apiStatus);
            syncHelper.m_CachedChapters = chapters;
            if (api.m_MenuVersion !== undefined) syncHelper.m_LastParsedMenuVersion = api.m_MenuVersion;
        }

        if (!chapters || Object.keys(chapters).length === 0) {
            GameInterfaceAPI.ConsoleCommand("disconnect");
            this.m_IsSmartWarping = false;
            return;
        }

        const fullyDoableMaps: any[] = [];
        const partiallyDoableMaps: any[] = [];

        for (const chId in chapters) {
            const chapter = chapters[chId];
            if (!chapter.maps) continue;
            for (const map of chapter.maps) {
                const isDeactivated = map.command_deactivated !== null &&
                    map.command_deactivated !== false &&
                    map.command_deactivated !== undefined;
                if (isDeactivated || !map.command) continue;

                const targetMapName = map.command.replace("map ", "").trim().toLowerCase();
                if (targetMapName === cleanCurrentMap) continue;

                if (map.completed === true || map.progress_text === "0/0") continue;

                const validCount = map.valid_count || 0;
                const totalCount = map.total_count || 0;
                if (totalCount > 0) {
                    if (validCount === totalCount) fullyDoableMaps.push(map);
                    else if (validCount > 0) partiallyDoableMaps.push(map);
                }
            }
        }

        let targetMap: any = null;
        if (fullyDoableMaps.length > 0) {
            targetMap = fullyDoableMaps[Math.floor(Math.random() * fullyDoableMaps.length)];
            $.Msg("[AP] Smart Warp selected a GREEN map.");
        } else if (partiallyDoableMaps.length > 0) {
            targetMap = partiallyDoableMaps[Math.floor(Math.random() * partiallyDoableMaps.length)];
            $.Msg("[AP] Smart Warp selected a YELLOW map.");
        }

        if (targetMap && targetMap.command) {
            const technicalName = targetMap.command.replace("map ", "").trim();
            const mapToken = `#portal2_MapName_${technicalName}`;
            const localizedMapName = $.Localize(mapToken);
            const mapNameDisplay = (localizedMapName !== mapToken
                ? localizedMapName
                : (targetMap.title || technicalName)).trim();

            let locTitle = $.Localize("#Archipelago_HUD_Warp_Title");
            if (!locTitle || locTitle === "#Archipelago_HUD_Warp_Title") locTitle = "SMART WARP";

            let locDest = $.Localize("#Archipelago_HUD_Warp_Dest");
            if (!locDest || locDest === "#Archipelago_HUD_Warp_Dest") locDest = "Destination: %s1";
            locDest = locDest.indexOf("%s1") !== -1
                ? locDest.replace("%s1", `<font color='#00ffff'>${mapNameDisplay}</font>`)
                : `${locDest} <font color='#00ffff'>${mapNameDisplay}</font>`;

            let locDelay = $.Localize("#Archipelago_HUD_Warp_Delay");
            if (!locDelay || locDelay === "#Archipelago_HUD_Warp_Delay") locDelay = "Warping in 4 seconds...";

            if (notifyFn) notifyFn(JSON.stringify({
                title: locTitle,
                html: `${locDest}<br/><font color='#aaaaaa'><i>${locDelay}</i></font>`,
                type: "0 255 255",
                play_sound: true
            }));

            $.Schedule(SMART_WARP_DELAY_SECONDS, () => {
                if (!ctx || !ctx.IsValid()) { this.m_IsSmartWarping = false; return; }
                GameInterfaceAPI.ConsoleCommand(targetMap.command);
                this.m_IsSmartWarping = false;
            });
        } else {
            let locTitle = $.Localize("#Archipelago_HUD_Warp_Menu_Title");
            if (!locTitle || locTitle === "#Archipelago_HUD_Warp_Menu_Title") locTitle = "WARP TO MENU";

            let locNoMaps = $.Localize("#Archipelago_HUD_Warp_NoMaps");
            if (!locNoMaps || locNoMaps === "#Archipelago_HUD_Warp_NoMaps") locNoMaps = "No doable maps found.";

            let locLoading = $.Localize("#Archipelago_HUD_Warp_Loading");
            if (!locLoading || locLoading === "#Archipelago_HUD_Warp_Loading") locLoading = "Returning to map select... Loading...";

            if (notifyFn) notifyFn(JSON.stringify({
                title: locTitle,
                html: `${locNoMaps}<br/><font color='#aaaaaa'><i>${locLoading}</i></font>`,
                type: "198 33 223",
                play_sound: true
            }));

            $.Schedule(SMART_WARP_DELAY_SECONDS, () => {
                if (!ctx || !ctx.IsValid()) { this.m_IsSmartWarping = false; return; }
                GameInterfaceAPI.ConsoleCommand("disconnect");
                this.m_IsSmartWarping = false;
            });
        }
    }
}

(UiToolkitAPI.GetGlobalObject() as any).ArchipelagoTransition = ArchipelagoTransition;
// Keep SmartWarpNextMap on global for any external callers
(UiToolkitAPI.GetGlobalObject() as any).SmartWarpNextMap = (mapName: string) => ArchipelagoTransition.smartWarpNextMap(mapName);

registerSelfCleaningEvent("Archipelago_WarpToMenu", (content: string) => {
    ArchipelagoTransition.requestWarp(content);
});
