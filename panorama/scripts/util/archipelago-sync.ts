'use strict';

declare var GameInterfaceAPI: any;

class ArchipelagoSync {
    static VERSION: string = "1.0.6"; // Incrément de version suite au correctif SVG array
    static ENABLE_DEBUG: boolean = false;

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
                maps: chapter.maps.map((map: any) => ({
                    title: map.title,
                    subtitle: map.subtitle,
                    command: map.command,
                    command_deactivated: map.command_deactivated,
                    pic: map.pic,
                    statusIcons: map.statusIcons, // Il s'agit maintenant d'un tableau de chaînes depuis Python (ex: ["flag", "monitor"])
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

        // --- CONVERSION ET SÉCURISATION DU TYPE ---
        // Si statusIcons arrive sous forme de tableau (nouvel outil SVG), on le convertit en chaîne 
        // ou on l'évalue proprement pour ne pas faire crasher le pont V8
        let statusIconsStr = "";
        if (map.statusIcons) {
            if (Array.isArray(map.statusIcons)) {
                // Si c'est le nouveau format d'icônes SVG en liste, on simule l'équivalent textuel 
                // pour que le vieux code de synchronisation d'état de la carte continue de fonctionner
                statusIconsStr = map.statusIcons.map((icon: string) => {
                    if (icon === "check") return "£";
                    if (icon === "flag") return "ã";
                    if (icon === "monitor") return "ÿ";
                    if (icon === "ratmansdent") return "ø";
                    if (icon === "door") return "¢";
                    if (icon === "portalgun1") return "ý";
                    if (icon === "portalgun2") return "þ";
                    if (icon === "potatos") return "ù";
                    return "";
                }).join("");
            } else if (typeof map.statusIcons === 'string') {
                statusIconsStr = map.statusIcons;
            }
        }
        
        let statusIcons = statusIconsStr.replace(/[~\-]/g, "").trim();

        const symbol = this.getCompletionSymbol();
        const isCompleted = statusIcons.length > 0 && statusIcons.replace(new RegExp(symbol, 'g'), "").length === 0;
        if (isCompleted) return { completed: true, greenCount: 0, total: statusIcons.length, doable: false, fullyDoable: false };

        let greenCount = 0;
        const logicHelper = (UiToolkitAPI.GetGlobalObject() as any).ArchipelagoLogic;
        const charCounts: { [key: string]: number } = {};

        for (let i = 0; i < statusIcons.length; i++) {
            const char = statusIcons[i];
            if (!charCounts[char]) charCounts[char] = 0;
            const index = charCounts[char]++;

            const status = logicHelper ? logicHelper.getIndicatorStatus(char, mapCmdName, mItems, index) : { isCompleted: false, isAvailable: true };
            if (status.isAvailable) greenCount++;
        }

        return {
            completed: false,
            greenCount: greenCount,
            total: statusIcons.length,
            doable: greenCount > 0,
            fullyDoable: (greenCount === statusIcons.length && statusIcons.length > 0)
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

        const chapters = this.parseApiStatus(apiStatus);
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

        // --- ADAPTATION DES COMPORTEMENTS SUR LE TABLEAU D'ICÔNES ---
        let statusIconsList: string[] = [];
        if (Array.isArray(currentMapData.statusIcons)) {
            statusIconsList = currentMapData.statusIcons;
        } else if (typeof currentMapData.statusIcons === 'string') {
            // Rétrocompatibilité si une chaîne brute passe par là
            statusIconsList = currentMapData.statusIcons.split("");
        }

        let ratmanStatus = (statusIconsList.indexOf("ratmansdent") === -1 && statusIconsList.indexOf("ø") === -1) ? 1 : 0;
        let hasCheck = statusIconsList.indexOf("check") !== -1 || statusIconsList.indexOf(this.getCompletionSymbol()) !== -1;
        
        let portalGunDone = (
            (statusIconsList.indexOf("portalgun1") === -1 && 
             statusIconsList.indexOf("portalgun2") === -1 && 
             statusIconsList.indexOf("ý") === -1 && 
             statusIconsList.indexOf("þ") === -1) || hasCheck
        ) ? 1 : 0;
        
        let potatosDone = (statusIconsList.indexOf("potatos") === -1 && statusIconsList.indexOf("ù") === -1 || hasCheck) ? 1 : 0;
        let wheatleyDone = 0;

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