'use strict';

declare var GameInterfaceAPI: any;
declare var UiToolkitAPI: any;
declare var $: any;

(function() {
    if ((UiToolkitAPI.GetGlobalObject() as any).ArchipelagoLogic) return;

    class ArchipelagoLogic {
        static getConvarColorHex(convarName: string, defaultHex: string): string {
            if (!GameInterfaceAPI || !GameInterfaceAPI.GetSettingString) {
                return defaultHex;
            }
            const val = GameInterfaceAPI.GetSettingString(convarName);
            if (!val || val === "") {
                return defaultHex;
            }
            const parts = val.split(' ');
            if (parts.length < 3) return defaultHex;
            const r = parseInt(parts[0]);
            const g = parseInt(parts[1]);
            const b = parseInt(parts[2]);
            return "#" + ((1 << 24) + (r << 16) + (g << 8) + b).toString(16).slice(1);
        }

        static getColorMap(): { [key: string]: string } {
            const primary = this.getConvarColorHex("cl_portal_sp_primary_color", "#00a5ff");
            const secondary = this.getConvarColorHex("cl_portal_sp_secondary_color", "#ff6a00");
            const blueGel = this.getConvarColorHex("bounce_paint_color", "#00a5ff");
            const orangeGel = this.getConvarColorHex("speed_paint_color", "#ff6a00");
            const whiteGel = this.getConvarColorHex("portal_paint_color", "#fafafa");

            return {
                "ý": primary,   
                "þ": secondary, 
                "û": secondary, 
                "à": blueGel,   
                "á": orangeGel, 
                "â": whiteGel,  
                "S.ô": "#ffc904", 
                "A.ô": "#e790c2", 
                "F.ô": "#1ec10d", 
            };
        }

        static g_MapRequirements: { [key: string]: string[] } = {
            "sp_a1_intro1": ["ç", "æ"], "sp_a1_intro2": ["ñ", "ç", "æ"], "sp_a1_intro3": [],
            "sp_a1_intro4": ["ç", "æ"], "sp_a1_intro5": ["ñ", "ç", "æ"], "sp_a1_intro6": ["ç", "æ"],
            "sp_a1_intro7": [], "sp_a1_wakeup": [], "sp_a2_intro": ["û"], "sp_a2_laser_intro": ["û", "í", "î"],
            "sp_a2_laser_stairs": ["û", "ì", "æ", "í", "î"], "sp_a2_dual_lasers": ["û", "ì", "í", "î"],
            "sp_a2_laser_over_goo": ["ñ", "æ", "ç", "û", "í", "î"], "sp_a2_catapult_intro": ["õ", "ñ", "ç", "æ"],
            "sp_a2_trust_fling": ["û", "õ", "ñ", "ç", "æ"], "sp_a2_pit_flings": ["û", "ç", "í", "î", "æ"],
            "sp_a2_fizzler_intro": ["û", "í", "ì", "î", "ñ"], "sp_a2_sphere_peek": ["û", "õ", "ñ", "ì", "í", "î"],
            "sp_a2_ricochet": ["û", "õ", "ç", "í", "î", "ì", "æ", "ñ"], "sp_a2_bridge_intro": ["û", "¿", "æ", "ñ", "ç"],
            "sp_a2_bridge_the_gap": ["û", "¿", "æ", "ñ", "ç"], "sp_a2_turret_intro": ["û", "ç", "æ", "ó"],
            "sp_a2_laser_relays": ["û", "í", "ì", "ï"], "sp_a2_turret_blocker": ["û", "¿", "õ", "æ", "ç"],
            "sp_a2_laser_vs_turret": ["û", "í", "î", "ç", "ì", "æ"], "sp_a2_pull_the_rug": ["û", "¿", "ç", "æ", "í", "î"],
            "sp_a2_column_blocker": ["û", "¿", "í", "î", "ï", "ñ", "ì", "õ"], "sp_a2_laser_chaining": ["û", "í", "î", "ï", "ì", "õ"],
            "sp_a2_triple_laser": ["û", "í", "î", "ì"], "sp_a2_bts1": ["û", "¿", "ñ", "ç"], "sp_a2_bts2": ["û", "ó"],
            "sp_a2_bts3": ["û"], "sp_a2_bts4": ["û", "ó"], "sp_a2_bts5": ["û", "í"], "sp_a2_bts6": [],
            "sp_a2_core": ["û", "ñ", "ó"], "sp_a3_00": [], "sp_a3_01": ["û"], "sp_a3_03": ["û"],
            "sp_a3_jump_intro": ["û", "à", "ò", "è", "é"], "sp_a3_bomb_flings": ["û", "ò", "à"],
            "sp_a3_crazy_box": ["û", "ò", "à", "é", "è"], "sp_a3_transition01": ["û", "ù"],
            "sp_a3_speed_ramp": ["û", "à", "á", "é", "è", "ò"], "sp_a3_speed_flings": ["û", "à", "á", "é", "è"],
            "sp_a3_portal_intro": ["û", "à", "á", "â"], "sp_a3_end": ["û", "à", "á", "â"],
            "sp_a4_intro": ["û", "ð", "æ", "ñ"], "sp_a4_tb_intro": ["û", "å", "ð", "æ"],
            "sp_a4_tb_trust_drop": ["û", "å", "ð", "æ", "ñ"], "sp_a4_tb_wall_button": ["û", "å", "ð", "æ", "ñ", "õ"],
            "sp_a4_tb_polarity": ["û", "å", "ð", "æ"], "sp_a4_tb_catch": ["û", "å", "ð", "æ", "ñ", "õ"],
            "sp_a4_stop_the_box": ["û", "ð", "æ", "ñ", "õ", "¿"], "sp_a4_laser_catapult": ["û", "ð", "æ", "õ", "ì", "í", "î", "å"],
            "sp_a4_laser_platform": ["û", "ñ", "ì", "í", "î", "å"], "sp_a4_speed_tb_catch": ["û", "æ", "å", "ñ", "ð", "á"],
            "sp_a4_jump_polarity": ["û", "à", "â", "å", "æ", "ñ"], "sp_a4_finale1": ["û", "õ", "å", "â"],
            "sp_a4_finale2": ["û", "å", "à", "æ", "ó"], "sp_a4_finale3": ["û", "á", "â", "å"],
            "sp_a4_finale4": ["û", "ù", "à", "á", "â", "A.ô", "S.ô", "F.ô"]
        };

        static g_SpeedrunRequirements: { [key: string]: string[] } = {
            "sp_a1_intro2": ["ñ", "æ"], "sp_a1_intro4": ["æ"], "sp_a1_intro5": ["æ"],
            "sp_a2_intro": [], "sp_a2_laser_intro": ["û"], "sp_a2_laser_stairs": ["û", "æ"],
            "sp_a2_dual_lasers": ["û", "í", "î"], "sp_a2_laser_over_goo": ["û", "æ"],
            "sp_a2_catapult_intro": ["û", "æ"], "sp_a2_trust_fling": ["û", "õ", "æ"],
            "sp_a2_pit_flings": ["û"], "sp_a2_fizzler_intro": ["û"],
            "sp_a2_ricochet": ["û", "ç"], "sp_a2_bridge_intro": ["û", "æ"],
            "sp_a2_bridge_the_gap": ["ç", "ñ", "æ"], "sp_a2_turret_intro": ["æ"],
            "sp_a2_laser_relays": ["ï", "í", "ì"], "sp_a2_turret_blocker": ["æ"],
            "sp_a2_laser_vs_turret": ["û", "í", "î"], "sp_a2_pull_the_rug": ["æ", "ç", "¿", "û"],
            "sp_a2_column_blocker": ["û"], "sp_a2_laser_chaining": ["ì", "í", "ï"],
            "sp_a2_triple_laser": ["ì", "û"], "sp_a2_bts1": ["û", "ñ", "ç"],
            "sp_a2_bts2": [], "sp_a2_bts4": ["û"], "sp_a2_bts5": ["û"], "sp_a2_core": ["ó"],
            "sp_a3_jump_intro": ["à", "è", "û"], "sp_a3_bomb_flings": ["û", "à", "ò"],
            "sp_a3_crazy_box": ["û", "è"], "sp_a3_speed_ramp": ["û"], 
            "sp_a3_speed_flings": ["û", "é"], "sp_a3_portal_intro": ["û"], "sp_a3_end": ["û", "à"],
            "sp_a4_tb_intro": ["æ", "å"], "sp_a4_tb_trust_drop": ["æ", "ð", "ñ", "û"],
            "sp_a4_tb_wall_button": ["æ", "ð", "ñ", "û"], "sp_a4_tb_polarity": ["å"],
            "sp_a4_tb_catch": ["û"], "sp_a4_stop_the_box": ["æ", "û"], 
            "sp_a4_laser_catapult": ["û"], "sp_a4_laser_platform": ["û", "å"],
            "sp_a4_speed_tb_catch": ["ñ", "ð"], "sp_a4_jump_polarity": ["ó", "ñ", "à"],
            "sp_a4_finale1": ["û", "ð", "õ"], "sp_a4_finale2": ["û"], "sp_a4_finale3": ["û", "å"],
            "sp_a4_finale4": ["û", "ù", "à", "â", "A.ô", "S.ô", "F.ô"]
        };

        static g_RatmanRequirements: { [key: string]: string[][] } = {
            "sp_a1_intro4": [["ç", "æ"]], "sp_a2_dual_lasers": [[]], "sp_a2_trust_fling": [["û", "õ"]],
            "sp_a2_bridge_intro": [[]], "sp_a2_bridge_the_gap": [["û", "¿"]],
            "sp_a2_laser_vs_turret": [["û", "í", "æ", "ì"]], "sp_a2_pull_the_rug": [["û", "¿"]]
        };

        static g_WheatleyRequirements: { [key: string]: string[][] } = {
            "sp_a4_tb_intro": [["û", "å", "ð"]], "sp_a4_tb_trust_drop": [["û", "ñ", "å", "ð"]],
            "sp_a4_tb_wall_button": [["û"]], "sp_a4_tb_polarity": [["ó"]],
            "sp_a4_tb_catch": [["û", "ð", "å", "õ", "ñ"], ["û", "ð", "å", "õ", "ñ"]],
            "sp_a4_stop_the_box": [["õ"]], "sp_a4_laser_catapult": [["û", "ð", "õ", "ì", "í", "î", "å"]],
            "sp_a4_laser_platform": [["û", "í", "î", "ì", "ñ"]], "sp_a4_speed_tb_catch": [["û"]],
            "sp_a4_jump_polarity": [["û", "à", "â", "å", "æ", "ñ", "ó"]], "sp_a4_finale3": [["û", "á", "â"]]
        };

        static getIndicatorStatus(char: string, mapCmdName: string, mItems: string, charIndex: number, fullStatus: string = ""): { isCompleted: boolean, isAvailable: boolean } {
            const isCompleted = (char === "£" || char === "★");

            if (isCompleted) {
                return { isCompleted: true, isAvailable: true };
            }

            let normalizedMItems = mItems || "";
            // Le manque d'un composant de Portal Gun implique l'absence du Portal Gun de base pour la logique locale.
            if (normalizedMItems.indexOf("ý") !== -1 || normalizedMItems.indexOf("þ") !== -1 || normalizedMItems.indexOf("ǫ") !== -1) {
                normalizedMItems += "û"; 
            }

            let isAvailable = true;
            
            if (char === "ã") {
                const diffVal = $.persistentStorage.getItem("ArchipelagoLogicDifficulty");
                const diff = (diffVal !== null && diffVal !== undefined) ? parseInt(diffVal as string) : 0;
                const reqTable = (diff === 1) ? this.g_SpeedrunRequirements : this.g_MapRequirements;
                const reqs = reqTable[mapCmdName] || this.g_MapRequirements[mapCmdName];
                isAvailable = reqs ? reqs.every(req => normalizedMItems.indexOf(req) === -1) : true;
            } else if (char === "ø") {
                const reqsList = this.g_RatmanRequirements[mapCmdName];
                if (reqsList) {
                    const reqs = reqsList[charIndex] || reqsList[0];
                    isAvailable = reqs.every(req => normalizedMItems.indexOf(req) === -1);
                }
            } else if (char === "ÿ") {
                const reqsList = this.g_WheatleyRequirements[mapCmdName];
                if (reqsList) {
                    const reqs = reqsList[charIndex] || reqsList[0];
                    isAvailable = reqs.every(req => normalizedMItems.indexOf(req) === -1);
                }
            } else if (char === "¢" || char === "ù") {
                // S'applique aux portes vitrifiées (¢) et à PotatOS (ù)
                isAvailable = (normalizedMItems.indexOf("û") === -1);
            } else {
                let searchChar = char;
                if (char === "ý" || char === "þ" || char === "ǫ") searchChar = "û";
                isAvailable = (normalizedMItems.indexOf(searchChar) === -1);
            }

            return { isCompleted: false, isAvailable };
        }

        static getFormattedIcons(rawStatus: string, mapCmdName: string, mItems: string): { char: string, color: string, isCompleted: boolean }[] {
            const colorMap = this.getColorMap();
            
            const results = [];
            let k = 0;
            const cleanStatus = rawStatus.replace(/[~\-]/g, "").trim();
            const charCounts: { [key: string]: number } = {};

            while (k < cleanStatus.length) {
                let resultChar = cleanStatus[k];
                let increment = 1;

                if (k + 2 < cleanStatus.length && cleanStatus[k + 1] === "." && cleanStatus[k + 2] === "ô") {
                    resultChar = cleanStatus.substring(k, k + 3);
                    increment = 3;
                }

                if (!charCounts[resultChar]) charCounts[resultChar] = 0;
                const indexIcon = charCounts[resultChar]++;

                const status = this.getIndicatorStatus(resultChar, mapCmdName, mItems, indexIcon, rawStatus);
                let isCompleted = status.isCompleted;
                let isAvailable = status.isAvailable;

                let color = "#ffffff";
                const isCompletionChar = (resultChar === "£" || resultChar === "★");
                const isPortalGun = (resultChar === "ý" || resultChar === "þ" || resultChar === "ǫ");
                const hasCustomColor = !!colorMap[resultChar];

                if (isCompleted && isCompletionChar) {
                    color = "#ffff44";
                } else if (isPortalGun && hasCustomColor) {
                    color = colorMap[resultChar];
                } else if (isAvailable) {
                    color = hasCustomColor ? colorMap[resultChar] : "#44ff44";
                } else {
                    color = "#ff4444";
                }
                
                results.push({ char: resultChar, color, isCompleted });
                k += increment;
            }
            return results;
        }

        static formatSubtitle(subtitle: string): string {
            const missingItems = this.getMissingItemsList(subtitle);
            let finalStatus = "";
            for (const itemData of missingItems) {
                finalStatus += `<font color="${itemData.color}">${itemData.char}</font> `;
            }
            return finalStatus.trim();
        }

        static getMissingItemsList(itemsStr: string): { char: string, color: string }[] {
            const ICON_COLORS = this.getColorMap();
            const items: { char: string, color: string }[] = [];
            let k = 0;
            while (k < itemsStr.length) {
                const char = itemsStr[k];
                if (char === " ") { k++; continue; }
                let resultChar = char;
                if (k + 2 < itemsStr.length && itemsStr[k + 1] === "." && itemsStr[k + 2] === "ô") {
                    resultChar = itemsStr.substring(k, k + 3);
                    k += 3;
                } else {
                    k++;
                }
                
                let color = "#ffffff"; 
                const isGel = (resultChar === "à" || resultChar === "á" || resultChar === "â" || resultChar === "ò" || resultChar === "è");
                const isCore = (resultChar === "S.ô" || resultChar === "A.ô" || resultChar === "F.ô");
                const isGun = (resultChar === "û" || resultChar === "ý" || resultChar === "þ" || resultChar === "ǫ");
                
                if (isGel || isCore || isGun) {
                    color = ICON_COLORS[resultChar] || "#ffffff";
                }
                
                items.push({ char: resultChar, color });
            }
            return items;
        }
    }

    (UiToolkitAPI.GetGlobalObject() as any).ArchipelagoLogic = ArchipelagoLogic;
    $.Msg("[AP] ArchipelagoLogic loaded");
})();