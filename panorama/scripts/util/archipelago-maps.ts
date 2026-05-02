'use strict';

class ArchipelagoMapStatus {
    // Toggle this to true to see status updates in the console
    static ENABLE_DEBUG: boolean = true;

    static getCompletionSymbol(): string {
        return ($.persistentStorage.getItem('ap_completion_symbol') ?? 0) === 1 ? "★" : "✓";
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

    static isMissingItem(char: string): boolean {
        if (!char || char === " ") return false;
        return true;
    }

    static isSymbolMissingGlobally(symbol: string, data: any): boolean {
        for (const chId in data) {
            const chapter = data[chId];
            if (chapter.maps) {
                for (const map of chapter.maps) {
                    if (map.subtitle && map.subtitle.indexOf(symbol) !== -1) {
                        return true;
                    }
                }
            }
        }
        return false;
    }

    static getMapStatus(map: any, allData: any) {
        const rawTitle = map.title || "";
        const mapCmdName = map.command ? map.command.replace("map ", "").trim() : "";

        // Use map.statusIcons if provided by the new parsing logic, otherwise fallback to old title-prefix logic
        let statusIcons = (map.statusIcons || "").replace(/[~\-]/g, "").trim();
        if (!statusIcons && rawTitle.length > 4 && (rawTitle.startsWith("~") || rawTitle.startsWith("-") || rawTitle.startsWith("═"))) {
            statusIcons = rawTitle.substring(0, 4).replace(/[~\-]/g, "").trim();
        }

        const mItems = map.subtitle || "";

        const isCompleted = statusIcons.length > 0 && (statusIcons.replace(/★/g, "").length === 0 || statusIcons.replace(/✓/g, "").length === 0);

        if (isCompleted) return { completed: true, greenCount: 0, total: statusIcons.length, doable: false, fullyDoable: false };

        let greenCount = 0;
        for (let i = 0; i < statusIcons.length; i++) {
            const char = statusIcons[i];
            let isGreen = false;

            if (char === "ã") {
                isGreen = !(mItems && mItems.trim() !== "");
            } else if (char === "þ" || char === "ý" || char === "ǫ") {
                // Portal Gun checks: green if the specific required gun symbols aren't missing
                isGreen = true;
            } else if (char === "¢") {
                // Vitrified Door checks: require the Portal Gun (û)
                isGreen = (mItems.indexOf("û") === -1);
            } else if (char === "ù") {
                if (mapCmdName === "sp_a3_transition01") {
                    isGreen = (mItems.indexOf("û") === -1);
                } else {
                    isGreen = (mItems.indexOf("ù") === -1);
                }
            } else if (char === "ø") {
                if (mapCmdName === "sp_a1_intro4") {
                    isGreen = (mItems.indexOf("ç") === -1 && mItems.indexOf("æ") === -1);
                } else if (mapCmdName === "sp_a2_dual_lasers") {
                    isGreen = true;
                } else if (mapCmdName === "sp_a2_trust_fling") {
                    isGreen = (mItems.indexOf("û") === -1 && mItems.indexOf("õ") === -1);
                } else if (mapCmdName === "sp_a2_bridge_intro") {
                    isGreen = true;
                } else if (mapCmdName === "sp_a2_bridge_the_gap") {
                    isGreen = (mItems.indexOf("û") === -1);
                } else if (mapCmdName === "sp_a2_laser_vs_turret") {
                    isGreen = (mItems.indexOf("û") === -1 && mItems.indexOf("í") === -1 && mItems.indexOf("æ") === -1 && mItems.indexOf("ì") === -1);
                } else if (mapCmdName === "sp_a2_pull_the_rug") {
                    isGreen = (mItems.indexOf("û") === -1 && mItems.indexOf("¿") === -1);
                } else {
                    isGreen = true;
                }
            } else if (char === "ÿ") {
                if (mapCmdName === "sp_a4_tb_intro") {
                    isGreen = (mItems.indexOf("û") === -1 && mItems.indexOf("å") === -1 && mItems.indexOf("ð") === -1);
                } else if (mapCmdName === "sp_a4_tb_trust_drop") {
                    isGreen = (mItems.indexOf("û") === -1 && mItems.indexOf("ñ") === -1 && mItems.indexOf("å") === -1 && mItems.indexOf("ð") === -1);
                } else if (mapCmdName === "sp_a4_tb_wall_button") {
                    isGreen = (mItems.indexOf("û") === -1);
                } else if (mapCmdName === "sp_a4_tb_polarity") {
                    isGreen = !this.isSymbolMissingGlobally("ó", allData);
                } else if (mapCmdName === "sp_a4_tb_catch") {
                    isGreen = (mItems.indexOf("û") === -1 && mItems.indexOf("ð") === -1 && mItems.indexOf("å") === -1 && mItems.indexOf("õ") === -1 && mItems.indexOf("ñ") === -1);
                } else if (mapCmdName === "sp_a4_stop_the_box") {
                    isGreen = (mItems.indexOf("õ") === -1);
                } else if (mapCmdName === "sp_a4_laser_catapult") {
                    isGreen = (mItems.indexOf("û") === -1 && mItems.indexOf("ð") === -1 && mItems.indexOf("õ") === -1 && mItems.indexOf("å") === -1 && mItems.indexOf("ì") === -1 && mItems.indexOf("í") === -1 && mItems.indexOf("î") === -1);
                } else if (mapCmdName === "sp_a4_laser_platform") {
                    isGreen = (mItems.indexOf("û") === -1 && mItems.indexOf("í") === -1 && mItems.indexOf("î") === -1 && mItems.indexOf("ì") === -1 && mItems.indexOf("ñ") === -1);
                } else if (mapCmdName === "sp_a4_speed_tb_catch") {
                    isGreen = (mItems.indexOf("û") === -1);
                } else if (mapCmdName === "sp_a4_jump_polarity") {
                    isGreen = (mItems.indexOf("û") === -1 && mItems.indexOf("¢") === -1 && mItems.indexOf("å") === -1 && mItems.indexOf("ó") === -1 && mItems.indexOf("æ") === -1 && mItems.indexOf("ñ") === -1);
                } else if (mapCmdName === "sp_a4_finale3") {
                    isGreen = (mItems.indexOf("û") === -1 && mItems.indexOf("¢") === -1);
                } else {
                    isGreen = true;
                }
            } else {
                // Default behavior: green if it's NOT in the missing items list
                isGreen = (mItems.indexOf(char) === -1);
            }

            if (isGreen) greenCount++;
        }

        return {
            completed: false,
            greenCount: greenCount,
            total: statusIcons.length,
            doable: greenCount > 0,
            fullyDoable: greenCount === statusIcons.length && statusIcons.length > 0
        };
    }

    static m_CurrentMap: string = "";
    static m_PollSchedule: any = null;

    // Track last sent status to avoid spamming the console
    static m_LastServerStatus: number = -1;
    static m_LastRatmanStatus: number = -1;
    static m_LastPortalGunStatus: number = -1;
    static m_LastPotatosStatus: number = -1;
    static m_LastWheatleyStatus: number = -1;
    static m_LastSymbols: string = "INITIAL_SYNC_PENDING";

    static m_Initialized: boolean = false;

    private static m_Debug: boolean = false;

    static init() {
        $.RegisterForUnhandledEvent("ArchipelagoDebug", (state: string) => {
            this.m_Debug = (state === "1");
            $.Msg("[AP] Panorama Debug logging is now " + (this.m_Debug ? "ENABLED" : "DISABLED"));
        });
    }

    static initSync() {
        this.init();
        if (this.m_Debug) $.Msg("[AP] archipelago-maps.ts loading...");
        if (this.m_Debug) $.Msg("[AP] ArchipelagoMapStatus.initSync() master synchronization loop ACTIVATED.");
        const global: any = UiToolkitAPI.GetGlobalObject();

        // Register this class as the authoritative instance
        global.ArchipelagoMapStatusInstance = ArchipelagoMapStatus;
        GameInterfaceAPI.ConsoleCommand("RefreshMapName");

        if (this.m_Initialized) return;
        this.m_Initialized = true;

        // Register the event listener ONCE on the singleton
        $.RegisterForUnhandledEvent("ArchipelagoMapNameUpdated", (payload: string) => {
            const global: any = UiToolkitAPI.GetGlobalObject();
            if (global.ArchipelagoMapStatusInstance !== ArchipelagoMapStatus) {
                // Not the active instance, ignore this event
                return;
            }

            if (this.m_Debug) $.Msg("[AP] Received ArchipelagoMapNameUpdated event with payload: " + payload);
            const parts = payload.split('|');
            const mapName = parts[0];
            if (!mapName || mapName === "main_menu") return;

            this.m_LastSymbols = "MAP_CHANGE_DETECTED";
            this.m_CurrentMap = mapName;
            this.runSync(mapName);

            // Ensure polling is active
            if (!this.m_PollSchedule) {
                if (this.m_Debug) $.Msg("[AP] Starting background polling loop...");
                this.startPolling();
            }
        });

        // Ask the mod to identify the map immediately
        GameInterfaceAPI.ConsoleCommand("RefreshMapName");
    }

    static startPolling() {
        if (this.m_PollSchedule) $.CancelScheduled(this.m_PollSchedule);

        this.m_PollSchedule = $.Schedule(2.0, () => {
            const global: any = UiToolkitAPI.GetGlobalObject();

            // SELF-DESTRUCT: If we aren't the official instance anymore, stop polling!
            if (global.ArchipelagoMapStatusInstance && global.ArchipelagoMapStatusInstance !== ArchipelagoMapStatus) {
                if (this.m_Debug) $.Msg("[AP] Legacy polling loop detected. SHUTTING DOWN.");
                this.m_PollSchedule = null;
                return;
            }

            if (this.m_CurrentMap && this.m_CurrentMap !== "main_menu") {
                this.runSync(this.m_CurrentMap);
                this.m_PollSchedule = null; // Reset so it can be scheduled again
                this.startPolling();
            }
        });
    }

    static runSync(mapName: string) {
        // $.Msg("[AP] runSync ticking for map: " + mapName);
        const extrasKv = $.LoadKeyValuesFile("scripts/extras.txt") || $.LoadKeyValues3File("scripts/extras.txt");
        const data = extrasKv && extrasKv.Extras ? extrasKv.Extras : extrasKv;
        if (!data) {
            if (this.m_Debug) $.Msg("[AP] runSync ERROR: Could not load extras.txt");
            return;
        }

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

        if (!currentMapData) {
            // $.Msg("[AP] runSync: No data found for map " + mapName + " in extras.txt");
            return;
        }

        const status = this.getMapStatus(currentMapData, chapters);
        let serverStatus = 0; // Red

        // Map=2 (Checkmark) only if the entire map is fully complete
        if (status.total > 0 && status.greenCount === status.total) {
            serverStatus = 2;
        } else if (status.greenCount > 0 || status.fullyDoable) {
            serverStatus = 1; // Green (Partial or Doable)
        }

        // Calculate Ratman Status (1 if ø is missing, 0 if ø is present)
        let ratmanStatus = 0;
        const statusIconsStr = (currentMapData.statusIcons || "");
        if (statusIconsStr.indexOf("ø") === -1) ratmanStatus = 1;

        // Calculate Portal Gun Done state (þ, ý, or ✓)
        let portalGunDone = 0;
        // It's done if the symbols are missing OR if a checkmark is present
        const isMissingPG = statusIconsStr.indexOf("þ") === -1 && statusIconsStr.indexOf("ý") === -1 && statusIconsStr.indexOf("ǫ") === -1;
        const hasCheck = statusIconsStr.indexOf(this.getCompletionSymbol()) !== -1;
        if (isMissingPG || hasCheck) portalGunDone = 1;

        // PotatOS Done (ù)
        let potatosDone = 0;
        if (statusIconsStr.indexOf("ù") === -1 || hasCheck) potatosDone = 1;

        // Wheatley Done (ÿ) - Handled natively in AngelScript now
        let wheatleyDone = 0;

        const symbols = statusIconsStr || "";
        const statusIcons = symbols.replace(/[~\-]/g, "").trim();
        const mapTitle = (currentMapData.title || "").replace(/[~\-]/g, "").trim();

        // SPAM PREVENTION: Only send if something actually changed
        if (serverStatus === this.m_LastServerStatus &&
            ratmanStatus === this.m_LastRatmanStatus &&
            portalGunDone === this.m_LastPortalGunStatus &&
            potatosDone === this.m_LastPotatosStatus &&
            wheatleyDone === this.m_LastWheatleyStatus &&
            symbols === this.m_LastSymbols) {
            return;
        }

        this.m_LastServerStatus = serverStatus;
        this.m_LastRatmanStatus = ratmanStatus;
        this.m_LastPortalGunStatus = portalGunDone;
        this.m_LastPotatosStatus = potatosDone;
        this.m_LastWheatleyStatus = wheatleyDone;
        this.m_LastSymbols = symbols;
        $.persistentStorage.setItem("ArchipelagoLastSymbols", symbols);
        $.persistentStorage.setItem("ArchipelagoLastMapStatus", serverStatus);

        GameInterfaceAPI.ConsoleCommand(`SetStatus ${serverStatus} ${ratmanStatus} ${portalGunDone} ${potatosDone} ${wheatleyDone} "${symbols}"`);

        if (this.m_Debug) {
            $.Msg("[AP] Status Updated: Map=" + serverStatus + " Ratman=" + ratmanStatus + " PortalGun=" + portalGunDone + " PotatOS=" + potatosDone + " Wheatley=" + wheatleyDone + " Symbols=[" + statusIcons + "] MapName=[" + mapTitle + "]");
        }
    }
}

// Global exposure
(UiToolkitAPI.GetGlobalObject() as any).ArchipelagoMapStatus = (UiToolkitAPI.GetGlobalObject() as any).ArchipelagoMapStatusInstance || ArchipelagoMapStatus;
ArchipelagoMapStatus.initSync();
