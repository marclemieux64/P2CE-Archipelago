'use strict';

class ArchipelagoMapStatusHUD {
    static m_HideSchedule: any = null;

    static init() {
        $.Msg("[AP] MapStatusHUD initialized.");
        
        // Listen for map change event from AngelScript
        $.RegisterForUnhandledEvent("ArchipelagoMapNameUpdated", (payload: string) => {
            $.Msg("[AP] MapStatusHUD: Received event with payload: " + payload);
            const parts = payload.split('|');
            const mapName = parts[0];
            const isManual = parts[1] === "1";

            $.Msg("[AP] MapStatusHUD: Map name updated to " + mapName + " (Manual: " + isManual + ")");
            // Cancel any pending hide
            if (this.m_HideSchedule) {
                $.CancelScheduled(this.m_HideSchedule);
                this.m_HideSchedule = null;
            }
            
            if (isManual) {
                // Manual override: show regardless of settings
                this.updateStatus(mapName, true);
            } else {
                // Small delay to ensure extras.txt has been updated by the client on map load
                $.Schedule(1.5, () => this.updateStatus(mapName, false));
            }
        });
    }

    static updateStatus(currentMapName: string, isManual: boolean) {
        const psValue = $.persistentStorage.getItem('ap_show_map_status_hud');
        // If it's manual, we ignore the 'enabled' check
        const enabled = (psValue ?? 1) == 1;
        
        $.Msg("[AP] MapStatusHUD: updateStatus called for map: " + currentMapName);
        $.Msg("[AP] MapStatusHUD: Enabled setting: " + enabled + " (Raw PS value: " + psValue + ") Manual: " + isManual);

        if (!enabled && !isManual) {
            $.Msg("[AP] MapStatusHUD: Returning because HUD is disabled in settings and this was an automatic update.");
            return;
        }

        const container = $.GetContextPanel();
        if (!container) {
            $.Msg("[AP] MapStatusHUD: ERROR - No context panel found!");
            return;
        }

        if (!currentMapName || currentMapName === "main_menu" || currentMapName === "unknown") {
            $.Msg("[AP] MapStatusHUD: Returning because map name is invalid or main menu: " + currentMapName);
            return;
        }

        const extrasKv = $.LoadKeyValuesFile("scripts/extras.txt") || $.LoadKeyValues3File("scripts/extras.txt");
        const data = extrasKv && extrasKv.Extras ? extrasKv.Extras : extrasKv;
        if (!data) {
            $.Msg("[AP] MapStatusHUD: ERROR - Could not load extras.txt");
            return;
        }

        // Parse chapters to use the helper
        const chapters: any = {};
        let currentMapData: any = null;

        for (const key in data) {
            const lowerKey = key.toLowerCase();
            if (lowerKey.startsWith('chapter')) {
                const majorId = key.match(/\d+/)?.[0];
                if (majorId) {
                    if (!chapters[majorId]) chapters[majorId] = { maps: [] };
                    if (key.includes('.')) {
                        const map = { id: key, ...data[key] };
                        chapters[majorId].maps.push(map);
                        
                        if (map.command) {
                            const cmdLower = map.command.toLowerCase();
                            const mapLower = currentMapName.toLowerCase();
                            if (cmdLower.indexOf(mapLower) !== -1) {
                                currentMapData = map;
                            }
                        }
                    } else {
                        Object.assign(chapters[majorId], data[key]);
                    }
                }
            }
        }

        if (!currentMapData) {
            $.Msg("[AP] MapStatusHUD ERROR: No map data found for " + currentMapName + " in extras.txt");
            return;
        }

        const mapStatusHelper = (UiToolkitAPI.GetGlobalObject() as any).ArchipelagoMapStatus;
        if (!mapStatusHelper) {
            $.Msg("[AP] MapStatusHUD ERROR: ArchipelagoMapStatus helper not found!");
            return;
        }
        const status = mapStatusHelper.getMapStatus(currentMapData, chapters);

        // Update UI
        const titleLabel = $('#MapTitle') as LabelPanel;
        const iconsContainer = $('#StatusIcons');
        const missingContainer = $('#MissingIcons');
        const missingLabel = $('#MissingLabel');
        
        const mapToken = `#portal2_MapName_${currentMapName}`;
        const localizedMapName = $.Localize(mapToken);
        titleLabel.text = (localizedMapName !== mapToken) ? localizedMapName : currentMapData.id;

        iconsContainer.RemoveAndDeleteChildren();
        missingContainer.RemoveAndDeleteChildren();

        const rawTitle = currentMapData.title || "";
        const statusIcons = (rawTitle.length > 4 ? rawTitle.substring(0, 4).trim() : "").replace(/[~\-]/g, "").trim();
        const mItems = currentMapData.subtitle || "";
        const mapCmdName = currentMapName;

        // 1. CHECKS
        for (let i = 0; i < statusIcons.length; i++) {
            const char = statusIcons[i];
            const icon = $.CreatePanel('Label', iconsContainer, '');
            icon.AddClass('status-icon');
            
            const completionSymbol = mapStatusHelper.getCompletionSymbol();
            if (char === completionSymbol) {
                icon.text = completionSymbol;
                icon.AddClass('status-icon--completed');
                continue;
            }

            let isGreen = false;
            if (char === "M") { isGreen = !(mItems && mItems.trim() !== ""); }
            else if (char === "þ") { isGreen = true; }
            else if (char === "ù") { isGreen = (mapCmdName === "sp_a3_transition01") ? (mItems.indexOf("û") === -1) : true; }
            else if (char === "R") {
                if (mapCmdName === "sp_a1_intro4") { isGreen = (mItems.indexOf("ç") === -1 && mItems.indexOf("æ") === -1); }
                else if (mapCmdName === "sp_a2_dual_lasers") { isGreen = true; }
                else if (mapCmdName === "sp_a2_trust_fling") { isGreen = (mItems.indexOf("û") === -1 && mItems.indexOf("õ") === -1); }
                else if (mapCmdName === "sp_a2_bridge_intro") { isGreen = true; }
                else if (mapCmdName === "sp_a2_bridge_the_gap") { isGreen = (mItems.indexOf("û") === -1); }
                else if (mapCmdName === "sp_a2_laser_vs_turret") { isGreen = (mItems.indexOf("û") === -1 && mItems.indexOf("í") === -1 && mItems.indexOf("æ") === -1 && mItems.indexOf("ì") === -1); }
                else if (mapCmdName === "sp_a2_pull_the_rug") { isGreen = (mItems.indexOf("û") === -1 && mItems.indexOf("¿") === -1); }
                else { isGreen = true; }
            } else if (char === "ÿ") {
                if (mapCmdName === "sp_a4_tb_intro") { isGreen = (mItems.indexOf("û") === -1 && mItems.indexOf("å") === -1 && mItems.indexOf("ð") === -1); }
                else if (mapCmdName === "sp_a4_tb_trust_drop") { isGreen = (mItems.indexOf("û") === -1 && mItems.indexOf("ñ") === -1 && mItems.indexOf("å") === -1 && mItems.indexOf("ð") === -1); }
                else if (mapCmdName === "sp_a4_tb_wall_button") { isGreen = (mItems.indexOf("û") === -1); }
                else if (mapCmdName === "sp_a4_tb_polarity") { isGreen = !mapStatusHelper.isSymbolMissingGlobally("ó", chapters); }
                else if (mapCmdName === "sp_a4_tb_catch") { isGreen = (mItems.indexOf("û") === -1 && mItems.indexOf("ð") === -1 && mItems.indexOf("å") === -1 && mItems.indexOf("õ") === -1 && mItems.indexOf("ñ") === -1); }
                else if (mapCmdName === "sp_a4_stop_the_box") { isGreen = (mItems.indexOf("õ") === -1); }
                else if (mapCmdName === "sp_a4_laser_catapult") { isGreen = (mItems.indexOf("û") === -1 && mItems.indexOf("ð") === -1 && mItems.indexOf("õ") === -1 && mItems.indexOf("å") === -1 && mItems.indexOf("ì") === -1 && mItems.indexOf("í") === -1 && mItems.indexOf("î") === -1); }
                else if (mapCmdName === "sp_a4_laser_platform") { isGreen = (mItems.indexOf("û") === -1 && mItems.indexOf("í") === -1 && mItems.indexOf("î") === -1 && mItems.indexOf("ì") === -1 && mItems.indexOf("ñ") === -1); }
                else if (mapCmdName === "sp_a4_speed_tb_catch") { isGreen = (mItems.indexOf("û") === -1); }
                else if (mapCmdName === "sp_a4_jump_polarity") { isGreen = (mItems.indexOf("û") === -1 && mItems.indexOf("¢") === -1 && mItems.indexOf("å") === -1 && mItems.indexOf("ó") === -1 && mItems.indexOf("æ") === -1 && mItems.indexOf("ñ") === -1); }
                else if (mapCmdName === "sp_a4_finale3") { isGreen = (mItems.indexOf("û") === -1 && mItems.indexOf("¢") === -1); }
                else { isGreen = true; }
            } else { isGreen = true; }

            icon.text = char;
            icon.AddClass(isGreen ? 'status-icon--green' : 'status-icon--red');
        }

        // 2. MISSING ITEMS
        let redCount = 0;
        
        $.Msg("[AP] MapStatusHUD: Subtitle for " + currentMapName + " is: '" + mItems + "'");

        for (let j = 0; j < mItems.length; j++) {
            const char = mItems[j];
            if (mapStatusHelper.isMissingItem(char)) {
                $.Msg("[AP] MapStatusHUD: Found missing item: " + char);
                const icon = $.CreatePanel('Label', missingContainer, '');
                icon.AddClass('status-icon');
                icon.AddClass('status-icon--white');
                icon.text = char;
                redCount++;
            }
        }

        // Hide the missing items section if there are none
        missingLabel.SetHasClass('collapse', redCount === 0);
        missingContainer.SetHasClass('collapse', redCount === 0);
        
        $.Msg("[AP] MapStatusHUD: Total missing items shown: " + redCount);

        // Show the panel
        $.Msg("[AP] MapStatusHUD: Setting visibility to TRUE");
        container.AddClass('visible');
        container.RemoveClass('collapse');

        // Hide after 5 seconds
        this.m_HideSchedule = $.Schedule(5.0, () => {
            $.Msg("[AP] MapStatusHUD: Timer expired, hiding panel.");
            container.RemoveClass('visible');
            this.m_HideSchedule = null;
        });
    }
}

ArchipelagoMapStatusHUD.init();
