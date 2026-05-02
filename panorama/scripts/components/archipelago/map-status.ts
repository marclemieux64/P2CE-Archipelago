'use strict';

class ArchipelagoMapStatusHUD {
    static m_HideSchedule: any = null;
    static m_Debug: boolean = false;

    static init() {
        if (this.m_Debug) $.Msg("[AP] MapStatusHUD initialized.");

        $.RegisterForUnhandledEvent("ArchipelagoDebug", (state: string) => {
            this.m_Debug = (state === "1");
        });

        // Listen for map change event from AngelScript
        $.RegisterForUnhandledEvent("ArchipelagoMapNameUpdated", (payload: string) => {
            if (this.m_Debug) $.Msg("[AP] MapStatusHUD: Received event with payload: " + payload);
            const parts = payload.split('|');
            const mapName = parts[0];
            const isManual = parts[1] === "1";

            if (this.m_Debug) $.Msg("[AP] MapStatusHUD: Map name updated to " + mapName + " (Manual: " + isManual + ")");
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
                $.Schedule(0.5, () => this.updateStatus(mapName, false));
            }
        });
    }

    static updateStatus(currentMapName: string, isManual: boolean) {
        const psValue = $.persistentStorage.getItem('ap_show_map_status_hud');
        // If it's manual, we ignore the 'enabled' check
        const enabled = (psValue ?? 1) == 1;

        if (this.m_Debug) $.Msg("[AP] MapStatusHUD: updateStatus called for map: " + currentMapName);
        if (this.m_Debug) $.Msg("[AP] MapStatusHUD: Enabled setting: " + enabled + " (Raw PS value: " + psValue + ") Manual: " + isManual);

        if (!enabled && !isManual) {
            if (this.m_Debug) $.Msg("[AP] MapStatusHUD: Returning because HUD is disabled in settings and this was an automatic update.");
            return;
        }

        const container = $.GetContextPanel();
        if (!container) {
            if (this.m_Debug) $.Msg("[AP] MapStatusHUD: ERROR - No context panel found!");
            return;
        }

        if (!currentMapName || currentMapName === "main_menu" || currentMapName === "unknown") {
            if (this.m_Debug) $.Msg("[AP] MapStatusHUD: Returning because map name is invalid or main menu: " + currentMapName);
            return;
        }

        const extrasKv = $.LoadKeyValuesFile("scripts/extras.txt") || $.LoadKeyValues3File("scripts/extras.txt");
        const data = extrasKv && extrasKv.Extras ? extrasKv.Extras : extrasKv;
        if (!data) {
            if (this.m_Debug) $.Msg("[AP] MapStatusHUD: ERROR - Could not load extras.txt");
            return;
        }

        const mapStatusHelper = (UiToolkitAPI.GetGlobalObject() as any).ArchipelagoMapStatus;
        if (!mapStatusHelper) {
            if (this.m_Debug) $.Msg("[AP] MapStatusHUD ERROR: ArchipelagoMapStatus helper not found!");
            return;
        }

        const chapters = mapStatusHelper.parseExtras(data);
        let currentMapData: any = null;
        for (const chId in chapters) {
            for (const map of chapters[chId].maps) {
                if (map.command) {
                    const cmdLower = map.command.toLowerCase();
                    const mapLower = currentMapName.toLowerCase();
                    if (cmdLower.indexOf(mapLower) !== -1) {
                        currentMapData = map;
                        break;
                    }
                }
            }
            if (currentMapData) break;
        }

        if (!currentMapData) {
            if (this.m_Debug) $.Msg("[AP] MapStatusHUD ERROR: No map data found for " + currentMapName + " in extras.txt");
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
        let statusIcons = (currentMapData.statusIcons || "").replace(/[~\-]/g, "").trim();
        if (!statusIcons && rawTitle.length > 4 && (rawTitle.startsWith("~") || rawTitle.startsWith("-") || rawTitle.startsWith("═"))) {
            statusIcons = rawTitle.substring(0, 4).replace(/[~\-]/g, "").trim();
        }
        const mItems = currentMapData.subtitle || "";
        const mapCmdName = currentMapName;

        // 1. CHECKS
        // Use the actual symbols string from the engine if available
        const symbolsFromEngine = $.persistentStorage.getItem("ArchipelagoLastSymbols") || "";
        const mapStatusFromEngine = $.persistentStorage.getItem("ArchipelagoLastMapStatus") || 0;

        for (let i = 0; i < statusIcons.length; i++) {
            const char = statusIcons[i];
            const icon = $.CreatePanel('Label', iconsContainer, '');
            icon.text = char;
            icon.AddClass('status-icon');

            if (char === "★" || char === "✓") {
                icon.AddClass('status-icon--completed');
                continue;
            }

            let isGreen = true;
            if (char === "ã") {
                // Map is green if server says it's playable (1) or done (2)
                isGreen = (mapStatusFromEngine >= 1);
            } else if (symbolsFromEngine !== "") {
                isGreen = (symbolsFromEngine.indexOf(char) === -1);
            } else {
                isGreen = (mItems.indexOf(char) === -1);
            }

            icon.AddClass(isGreen ? 'status-icon--green' : 'status-icon--red');
        }

        // 2. MISSING ITEMS
        let redCount = 0;

        if (this.m_Debug) $.Msg("[AP] MapStatusHUD: Subtitle for " + currentMapName + " is: '" + mItems + "'");

        for (let j = 0; j < mItems.length; j++) {
            const char = mItems[j];
            if (mapStatusHelper.isMissingItem(char)) {
                if (this.m_Debug) $.Msg("[AP] MapStatusHUD: Found missing item: " + char);
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

        if (this.m_Debug) $.Msg("[AP] MapStatusHUD: Total missing items shown: " + redCount);

        // Show the panel
        if (this.m_Debug) $.Msg("[AP] MapStatusHUD: Setting visibility to TRUE");
        container.AddClass('visible');
        container.RemoveClass('collapse');

        // Hide after 5 seconds
        this.m_HideSchedule = $.Schedule(5.0, () => {
            if (this.m_Debug) $.Msg("[AP] MapStatusHUD: Timer expired, hiding panel.");
            container.RemoveClass('visible');
            this.m_HideSchedule = null;
        });
    }
}

ArchipelagoMapStatusHUD.init();
