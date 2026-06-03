'use strict';

declare var GameInterfaceAPI: any;

class ArchipelagoSync {
    static VERSION: string = "1.1.0"; 
    static ENABLE_DEBUG: boolean = false;
    
    // Cache local pour eviter l'evaluation repetitive de parseApiStatus()
    static m_LastParsedMenuVersion: number = -1;
    static m_CachedChapters: any = null;

    static getCompletionSymbol(): string {
        return ($.persistentStorage.getItem('CompletionSymbol') ?? 0) === 1 ? "★" : "£";
    }

    /**
     * Legacy helper to evaluate indicator status, redirects to ArchipelagoLogic.
     */
    static getIndicatorStatus(char: string, mapCmdName: string, mItems: string, charIndexInStatus: number): { isCompleted: boolean, isAvailable: boolean } {
        const logicHelper = (UiToolkitAPI.GetGlobalObject() as any).ArchipelagoLogic;
        if (logicHelper) {
            return logicHelper.getIndicatorStatus(char, mapCmdName, mItems, charIndexInStatus);
        }
        return { isCompleted: false, isAvailable: true };
    }

    /**
     * Determines if an item is missing based on the current map's subtitle.
     */
    static isMissingItem(itemChar: string): boolean {
        return (itemChar && itemChar !== " ");
    }

    static parseApiStatus(status: any): any {
        if (!status || !status.menu || !status.menu.chapters) return {};
        const chapters: any = {};
        for (const chapter of status.menu.chapters) {
            const chId = chapter.chapter_number.toString();
            chapters[chId] = {
                title: chapter.title,
                subtitle: chapter.subtitle,
                pic: chapter.pic,
                valid_count: chapter.valid_count,
                total_count: chapter.total_count,
                progress_text: chapter.progress_text,
                maps: chapter.maps.map((map: any) => ({
                    title: map.title,
                    subtitle: map.subtitle,
                    command: map.command,
                    command_deactivated: map.command_deactivated,
                    pic: map.pic,
                    statusIcons: map.status_text_list || map.statusIcons || [], 
                    required_item_icons: map.required_item_icons || [],
                    valid_count: map.valid_count,
                    total_count: map.total_count,
                    progress_text: map.progress_text,
                    completed: map.completed
                }))
            };
        }
        return chapters;
    }

    static getMapStatus(map: any, allData: any) {
        const fullCommand = map.command || map.command_deactivated || "";
        const mapCmdName = fullCommand ? fullCommand.replace("map ", "").trim().toLowerCase() : "";
        const mItems = map.subtitle || "";

        const statusIconsList: string[] = map.statusIcons || [];

        const symbol = this.getCompletionSymbol();
        const isCompleted = map.completed === true || (statusIconsList.length > 0 && statusIconsList.every(icon => icon === "check"));
        if (isCompleted) return { completed: true, greenCount: 0, total: statusIconsList.length, doable: false, fullyDoable: false };

        let greenCount = 0;
        statusIconsList.forEach((iconName: string) => {
            if (iconName !== "uncheck") {
                greenCount++;
            }
        });

        return {
            completed: false,
            greenCount: greenCount,
            total: statusIconsList.length,
            doable: greenCount > 0,
            fullyDoable: (greenCount === statusIconsList.length && statusIconsList.length > 0)
        };
    }

    static m_CurrentMap: string = "";
    static m_PollSchedule: any = null;
    static m_LastServerStatus: number = -1;
    static m_LastRatmanStatus: number = -1;
    static m_LastPortalGunStatus: number = -1;
    static m_LastPotatosStatus: number = -1;
    static m_LastWheatleyStatus: number = -1;
    static m_LastSymbols: string = "INITIAL_SYNC_PENDING";
    static m_Initialized: boolean = false;
    private static m_Debug: boolean = false;

    static initSync() {
        if (this.ENABLE_DEBUG) $.Msg("[AP] Exposed ArchipelagoSync v" + this.VERSION);
        
        $.RegisterForUnhandledEvent("ArchipelagoDebug", (state: string) => {
            this.m_Debug = (state === "1");
            $.Msg("[AP] Panorama Sync Debug logging is now " + (this.m_Debug ? "ENABLED" : "DISABLED"));
        });

        const global: any = UiToolkitAPI.GetGlobalObject();
        global.ArchipelagoSyncInstance = ArchipelagoSync;

        if (this.m_Initialized) return;
        this.m_Initialized = true;

        $.RegisterForUnhandledEvent("ArchipelagoMapNameUpdated", (payload: string) => {
            if (global.ArchipelagoSyncInstance !== ArchipelagoSync) return;
            const parts = payload.split('|');
            const mapName = parts[0];
            if (!mapName || mapName === "main_menu") return;
            this.m_LastSymbols = "MAP_CHANGE_DETECTED";
            this.m_CurrentMap = mapName;
            this.runSync(mapName);
        });

        $.RegisterForUnhandledEvent("MapLoaded", (map: string, bg: boolean) => {
            if (bg) return;
            
            let cleanMap = map;
            if (cleanMap.indexOf("maps/") === 0 || cleanMap.indexOf("maps\\") === 0) {
                cleanMap = cleanMap.substring(5);
            }
            if (cleanMap.toLowerCase().endsWith(".bsp")) {
                cleanMap = cleanMap.substring(0, cleanMap.length - 4);
            }

            const api = (UiToolkitAPI.GetGlobalObject() as any).ArchipelagoAPI;
            if (api && api.getStatus() && !api.getStatus().connected) {
                $.DispatchEvent("ArchipelagoNotify", JSON.stringify({
                    text: "#Archipelago_Status_NotConnected",
                    type: "error",
                    duration: 10.0
                }));
            }
        });

        GameInterfaceAPI.ConsoleCommand("RefreshMapName");
    }

    static startPolling() {
        if (this.m_PollSchedule) {
            try { $.CancelScheduled(this.m_PollSchedule); } catch(e) {}
        }
        this.m_PollSchedule = $.Schedule(2.0, () => {
            const global: any = UiToolkitAPI.GetGlobalObject();
            if (global.ArchipelagoSyncInstance && global.ArchipelagoSyncInstance !== ArchipelagoSync) {
                this.m_PollSchedule = null;
                return;
            }

            if (this.m_CurrentMap && this.m_CurrentMap !== "main_menu") {
                this.runSync(this.m_CurrentMap);
                this.m_PollSchedule = null;
                this.startPolling();
            } else {
                this.m_PollSchedule = null;
                this.startPolling();
            }
        });
    }

    static runSync(mapName: string) {
        const api = (UiToolkitAPI.GetGlobalObject() as any).ArchipelagoAPI;
        const apiStatus = api ? api.getStatus() : null;
        if (!apiStatus || !apiStatus.menu) return;

        // Verification du tracking de version pour sauter le processing lourd
        const currentMenuVersion = api.m_MenuVersion || 0;
        if (currentMenuVersion !== this.m_LastParsedMenuVersion || !this.m_CachedChapters) {
            this.m_CachedChapters = this.parseApiStatus(apiStatus);
            this.m_LastParsedMenuVersion = currentMenuVersion;
        }
        
        const chapters = this.m_CachedChapters;
        let currentMapData: any = null;

        for (const chId in chapters) {
            for (const map of chapters[chId].maps) {
                if (map.command) {
                    const cmdLower = map.command.toLowerCase();
                    const search = mapName.toLowerCase();
                    if (cmdLower.indexOf(search) !== -1) {
                        currentMapData = map;
                        break;
                    }
                }
            }
            if (currentMapData) break;
        }

        if (!currentMapData) return;

        const status = this.getMapStatus(currentMapData, chapters);
        let serverStatus = (status.total > 0 && status.greenCount === status.total) ? 2 : (status.greenCount > 0 ? 1 : 0);

        const statusIconsList: string[] = currentMapData.statusIcons || [];

        let ratmanStatus = (statusIconsList.indexOf("ratmansdent") === -1) ? 1 : 0;
        let hasCheck = statusIconsList.indexOf("check") !== -1;
        
        let portalGunDone = (
            (statusIconsList.indexOf("portalgun1") === -1 && 
             statusIconsList.indexOf("portalgun2") === -1) || hasCheck
        ) ? 1 : 0;
        
        let potatosDone = (statusIconsList.indexOf("potatos") === -1 || hasCheck) ? 1 : 0;

        const symbols = statusIconsList.join(",");

        if (serverStatus === this.m_LastServerStatus &&
            ratmanStatus === this.m_LastRatmanStatus &&
            portalGunDone === this.m_LastPortalGunStatus &&
            potatosDone === this.m_LastPotatosStatus &&
            symbols === this.m_LastSymbols) {
            return;
        }

        this.m_LastServerStatus = serverStatus;
        this.m_LastRatmanStatus = ratmanStatus;
        this.m_LastPortalGunStatus = portalGunDone;
        this.m_LastPotatosStatus = potatosDone;
        this.m_LastSymbols = symbols;
        
        $.persistentStorage.setItem("ArchipelagoLastSymbols", symbols);
        $.persistentStorage.setItem("ArchipelagoLastMapStatus", serverStatus);
        $.persistentStorage.setItem("ArchipelagoLastMapName", mapName);

        if (this.m_Debug) {
            $.Msg("[AP] Status Updated: Map=" + serverStatus + " Symbols=[" + symbols + "]");
        }
    }
}

(UiToolkitAPI.GetGlobalObject() as any).ArchipelagoSync = ArchipelagoSync;
ArchipelagoSync.initSync();
ArchipelagoSync.startPolling();