'use strict';

class ArchipelagoMapStatus {
    static getCompletionSymbol(): string {
        return ($.persistentStorage.getItem('ap_completion_symbol') ?? 0) === 1 ? "★" : "✓";
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
        const statusIcons = (rawTitle.length > 4 ? rawTitle.substring(0, 4).trim() : "").replace(/[~\-]/g, "").trim();
        const mItems = map.subtitle || "";
        
        const completionSymbol = this.getCompletionSymbol();
        const isCompleted = statusIcons.length > 0 && statusIcons.replace(new RegExp(completionSymbol, 'g'), "").length === 0;
        
        if (isCompleted) return { completed: true, greenCount: 0, total: statusIcons.length, doable: false, fullyDoable: false };

        let greenCount = 0;
        for (let i = 0; i < statusIcons.length; i++) {
            const char = statusIcons[i];
            let isGreen = false;

            if (char === "M") {
                isGreen = !(mItems && mItems.trim() !== "");
            } else if (char === "þ") {
                isGreen = true;
            } else if (char === "ù") {
                if (mapCmdName === "sp_a3_transition01") {
                    isGreen = (mItems.indexOf("û") === -1);
                } else {
                    isGreen = true;
                }
            } else if (char === "R") {
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
                isGreen = true;
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
    static m_LastSymbols: string = "INITIAL_SYNC_PENDING";

    static m_Initialized: boolean = false;

    static initSync() {
        $.Msg("[AP] ArchipelagoMapStatus.initSync() waking up...");

        // ALWAYS register the event listener first. 
        // Panorama handles duplicate listeners gracefully, and this ensures a working listener 
        // even if a previous loop is already running in the background.
        $.RegisterForUnhandledEvent("AP_MapNameUpdated", (payload: string) => {
            $.Msg("[AP] Received AP_MapNameUpdated event with payload: " + payload);
            const parts = payload.split('|');
            const mapName = parts[0];
            if (!mapName || mapName === "main_menu") return;
            
            this.m_LastSymbols = "MAP_CHANGE_DETECTED";
            this.m_CurrentMap = mapName;
            this.runSync(mapName);
            
            // Ensure polling is active
            if (!this.m_PollSchedule) {
                $.Msg("[AP] Starting background polling loop...");
                this.startPolling();
            }
        });
        
        // Ask the mod to identify the map immediately
        GameInterfaceAPI.ConsoleCommand("ap_refresh_map_name");

        const global: any = UiToolkitAPI.GetGlobalObject();
        if (global.ArchipelagoMapStatusInitialized) {
            $.Msg("[AP] System already initialized. Handing over map request.");
            return;
        }
        global.ArchipelagoMapStatusInitialized = true;

        $.Msg("[AP] ArchipelagoMapStatus.initSync() master synchronization loop ACTIVATED.");
    }

    static startPolling() {
        if (this.m_PollSchedule) $.CancelScheduled(this.m_PollSchedule);
        this.m_PollSchedule = $.Schedule(2.0, () => {
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
            $.Msg("[AP] runSync ERROR: Could not load extras.txt");
            return;
        }

        let currentMapData: any = null;
        const chapters: any = {};

        for (const key in data) {
            if (key.toLowerCase().startsWith('chapter')) {
                const majorId = key.match(/\d+/)?.[0];
                if (majorId) {
                    if (!chapters[majorId]) chapters[majorId] = { maps: [] };
                    if (key.includes('.')) {
                        const map = { id: key, ...data[key] };
                        chapters[majorId].maps.push(map);
                        
                        // Resilient match: check if the map name is part of the command as a whole word
                        const cmd = (map.command || "").toLowerCase();
                        const search = mapName.toLowerCase();
                        if (cmd.indexOf(search) !== -1) {
                            currentMapData = map;
                        }
                    } else {
                        Object.assign(chapters[majorId], data[key]);
                    }
                }
            }
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
        
        // Ratman Specific Sync
        let ratmanStatus = 0;
        const rawTitleStr = currentMapData.title || "";
        if (rawTitleStr.indexOf("R") !== -1 && rawTitleStr.indexOf(this.getCompletionSymbol()) !== -1) {
            ratmanStatus = 1;
        }

        // Calculate Portal Gun Done state (þ, ý, or ✓)
        let portalGunDone = 0;
        if (currentMapData.title) {
            const t = currentMapData.title;
            // It's done if the symbols are missing OR if a checkmark is present
            const isMissing = t.indexOf("þ") === -1 && t.indexOf("ý") === -1;
            const hasCheck = t.indexOf(this.getCompletionSymbol()) !== -1;
            
            // Special case: If the map only has one check and it's the checkmark, it's done
            if (isMissing || hasCheck) portalGunDone = 1;
        }

        // PotatOS Done (ù)
        let potatosDone = 0;
        if (currentMapData.title) {
            const t = currentMapData.title;
            if (t.indexOf("ù") === -1 || t.indexOf(this.getCompletionSymbol()) !== -1) potatosDone = 1;
        }

        // Wheatley Done (ÿ)
        let wheatleyDone = 0;
        if (currentMapData.title) {
            const t = currentMapData.title;
            if (t.indexOf("ÿ") === -1 || t.indexOf(this.getCompletionSymbol()) !== -1) wheatleyDone = 1;
        }

        const symbols = currentMapData.title || "";
        const statusIcons = (symbols.length > 4 ? symbols.substring(0, 4).trim() : "").replace(/[~\-]/g, "").trim();
        const mapTitle = symbols.replace(statusIcons, "").replace(/[~\-]/g, "").trim();

        this.m_LastServerStatus = serverStatus;
        this.m_LastRatmanStatus = ratmanStatus;
        this.m_LastSymbols = symbols;

        GameInterfaceAPI.ConsoleCommand("ap_set_map_status " + serverStatus + " " + ratmanStatus + " " + portalGunDone + " " + potatosDone + " " + wheatleyDone + " " + symbols);
        $.Msg("[AP] Status Updated: Map=" + serverStatus + " Ratman=" + ratmanStatus + " PortalGun=" + portalGunDone + " PotatOS=" + potatosDone + " Wheatley=" + wheatleyDone + " Symbols=[" + statusIcons + "] MapName=[" + mapTitle + "]");
    }
}

ArchipelagoMapStatus.initSync();
(UiToolkitAPI.GetGlobalObject() as any).ArchipelagoMapStatus = ArchipelagoMapStatus;
