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
}

(UiToolkitAPI.GetGlobalObject() as any).ArchipelagoMapStatus = ArchipelagoMapStatus;
