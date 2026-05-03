'use strict';

declare var GameInterfaceAPI: any;

class ArchipelagoSync {
    static VERSION: string = "1.0.5";
    static ENABLE_DEBUG: boolean = true;

    static getCompletionSymbol(): string {
        return ($.persistentStorage.getItem('CompletionSymbol') ?? 0) === 1 ? "★" : "✓";
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

    static parseExtras(data: any): any {
        const chapters: any = {};
        const infoBlocks: any = {};

        for (const key in data) {
            if (key.toLowerCase().endsWith('_info')) {
                infoBlocks[key.substring(0, key.length - 5)] = data[key];
            }
        }

        for (const key in data) {
            const lowerKey = key.toLowerCase();
            if (lowerKey.startsWith('chapter')) {
                const majorId = key.match(/\d+/)?.[0];
                if (majorId) {
                    if (!chapters[majorId]) chapters[majorId] = { maps: [] };
                    if (key.includes('.') && !lowerKey.endsWith('_info')) {
                        const map = { id: key, ...data[key] };
                        if (infoBlocks[key]) {
                            map.statusIcons = infoBlocks[key].title;
                        }
                        chapters[majorId].maps.push(map);
                    } else if (!key.includes('.')) {
                        Object.assign(chapters[majorId], data[key]);
                    }
                }
            }
        }
        return chapters;
    }

    static getMapStatus(map: any, allData: any) {
        const mapCmdName = map.command ? map.command.replace("map ", "").trim().toLowerCase() : "";
        let statusIcons = (map.statusIcons || "").replace(/[~\-]/g, "").trim();
        const mItems = map.subtitle || "";

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

            if (!this.m_PollSchedule) this.startPolling();
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
            }
        });
    }

    static runSync(mapName: string) {
        const extrasKv = $.LoadKeyValuesFile("scripts/extras.txt") || $.LoadKeyValues3File("scripts/extras.txt");
        const data = extrasKv && extrasKv.Extras ? extrasKv.Extras : extrasKv;
        if (!data) return;

        const chapters = this.parseExtras(data);
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

        const statusIconsStr = (currentMapData.statusIcons || "");
        let ratmanStatus = (statusIconsStr.indexOf("ø") === -1) ? 1 : 0;
        
        let hasCheck = statusIconsStr.indexOf(this.getCompletionSymbol()) !== -1;
        let portalGunDone = (statusIconsStr.indexOf("þ") === -1 && statusIconsStr.indexOf("ý") === -1 && statusIconsStr.indexOf("ǫ") === -1 || hasCheck) ? 1 : 0;
        let potatosDone = (statusIconsStr.indexOf("ù") === -1 || hasCheck) ? 1 : 0;
        let wheatleyDone = 0;

        const symbols = statusIconsStr || "";

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

        GameInterfaceAPI.ConsoleCommand(`SetStatus ${serverStatus} ${ratmanStatus} ${portalGunDone} ${potatosDone} ${wheatleyDone} "${symbols}"`);
        
        if (this.m_Debug) {
            $.Msg("[AP] Status Updated: Map=" + serverStatus + " Symbols=[" + symbols + "]");
        }
    }
}

(UiToolkitAPI.GetGlobalObject() as any).ArchipelagoSync = ArchipelagoSync;
ArchipelagoSync.initSync();
