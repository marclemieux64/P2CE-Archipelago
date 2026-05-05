class ArchipelagoHUD {
    static m_HideSchedule: any = null;
    static m_LastApiData: any = null;
    static m_CurrentMapName: string = "";
    static m_Debug: boolean = false;

    static init() {
        if (this.m_Debug) $.Msg("[AP] ArchipelagoHUD initialized.");

        $.RegisterForUnhandledEvent("ArchipelagoDebug", (state: string) => {
            this.m_Debug = (state === "1");
        });

        // Listen for status updates from the API bridge
        $.RegisterForUnhandledEvent("ArchipelagoAPI_StatusUpdated", (json: string) => {
            try {
                this.m_LastApiData = JSON.parse(json);
                // Refresh if we already have a map name
                if (this.m_CurrentMapName) {
                    this.updateStatus(this.m_CurrentMapName, false);
                }
            } catch (e) {
                $.Warning("[AP] HUD failed to parse API update: " + e);
            }
        });

        // Listen for map change event from AngelScript
        $.RegisterForUnhandledEvent("ArchipelagoMapNameUpdated", (payload: string) => {
            if (this.m_Debug) $.Msg("[AP] ArchipelagoHUD: Received event with payload: " + payload);
            const parts = payload.split('|');
            const mapName = parts[0];
            const isManual = parts[1] === "1";

            this.m_CurrentMapName = mapName;

            if (this.m_Debug) $.Msg("[AP] ArchipelagoHUD: Map name updated to " + mapName + " (Manual: " + isManual + ")");
            
            // Cancel any pending hide
            if (this.m_HideSchedule) {
                $.CancelScheduled(this.m_HideSchedule);
                this.m_HideSchedule = null;
            }

            // If it's a map load (not manual) and we have hide enabled, 
            // we still want to show it briefly per the setting's description
            const psValue = $.persistentStorage.getItem('ap_show_map_status_hud');
            const hideByDefault = (psValue ?? 0) == 1;

            if (isManual || (!isManual && hideByDefault)) {
                this.updateStatus(mapName, true);
            } else {
                // If it's always-on mode, just do a regular update
                $.Schedule(0.1, () => this.updateStatus(mapName, false));
            }
        });

        // Initial sync if API is already ready
        const api = (UiToolkitAPI.GetGlobalObject() as any).ArchipelagoAPI;
        if (api && api.getStatus()) {
            this.m_LastApiData = api.getStatus();
        }
    }

    static updateStatus(currentMapName: string, isManual: boolean) {
        const psValue = $.persistentStorage.getItem('ap_show_map_status_hud');
        // Setting is "Hide Map Progress HUD" (1 = HIDE/DISABLED, 0 = SHOW/TRANSIENT)
        const isDisabled = (psValue ?? 0) == 1;

        const container = $.GetContextPanel();
        if (!container) return;

        if (isDisabled) {
            if (this.m_Debug) $.Msg("[AP] HUD is disabled by user setting.");
            container.SetHasClass('visible', false);
            if (this.m_HideSchedule) {
                $.CancelScheduled(this.m_HideSchedule);
                this.m_HideSchedule = null;
            }
            return;
        }

        if (!currentMapName || currentMapName === "main_menu" || currentMapName === "unknown") {
            container.SetHasClass('visible', false);
            return;
        }

        // If this is a background update (API polling), only proceed if the HUD is already on screen
        const isCurrentlyVisible = container.HasClass('visible');
        if (!isManual && !isCurrentlyVisible) {
            return;
        }

        const syncHelper = (UiToolkitAPI.GetGlobalObject() as any).ArchipelagoSync;
        if (!syncHelper || !this.m_LastApiData || !this.m_LastApiData.menu) {
            if (this.m_Debug) $.Msg("[AP] ArchipelagoHUD: Waiting for syncHelper or API data...");
            return;
        }

        const chapters = syncHelper.parseApiStatus(this.m_LastApiData);
        let currentMapData: any = null;
        
        // Find the map in the parsed chapters
        for (const chId in chapters) {
            for (const map of chapters[chId].maps) {
                const fullCommand = (map.command || map.command_deactivated || "").toLowerCase();
                const mapLower = currentMapName.toLowerCase();
                
                // Match command (e.g. "map sp_a1_intro1") with current map name
                if (fullCommand.indexOf(mapLower) !== -1) {
                    currentMapData = map;
                    break;
                }
            }
            if (currentMapData) break;
        }

        if (!currentMapData) {
            if (this.m_Debug) $.Msg("[AP] ArchipelagoHUD: No data found for map " + currentMapName);
            return;
        }

        // Update UI
        const titleLabel = $('#MapTitle') as LabelPanel;
        const iconsContainer = $('#StatusIcons');
        const missingContainer = $('#MissingIcons');

        const mapToken = `#portal2_MapName_${currentMapName}`;
        const localizedMapName = $.Localize(mapToken);
        titleLabel.text = (localizedMapName !== mapToken) ? localizedMapName : (currentMapData.title || currentMapName);

        iconsContainer.RemoveAndDeleteChildren();
        missingContainer.RemoveAndDeleteChildren();

        const rawTitle = currentMapData.title || "";
        let statusIcons = (currentMapData.statusIcons || currentMapData.info || "").replace(/[~\-]/g, "").trim();
        
        // Fallback for icons embedded in title
        if (!statusIcons && rawTitle.length > 4 && (rawTitle.startsWith("~") || rawTitle.startsWith("-") || rawTitle.startsWith("═"))) {
            statusIcons = rawTitle.substring(0, 4).replace(/[~\-]/g, "").trim();
        }
        
        const mItems = currentMapData.subtitle || "";
        const mapCmdName = currentMapName;
        const logicHelper = (UiToolkitAPI.GetGlobalObject() as any).ArchipelagoLogic;

        // 1. CHECKS
        const formattedIcons = logicHelper ? logicHelper.getFormattedIcons(statusIcons, mapCmdName, mItems) : [];

        for (const iconData of formattedIcons) {
            const icon = $.CreatePanel('Label', iconsContainer, '');
            icon.text = iconData.char;
            icon.AddClass('status-icon');

            if (iconData.isCompleted) {
                icon.AddClass('status-icon--completed');
            } else {
                icon.style.color = iconData.color;
            }
        }

        // 2. MISSING ITEMS
        const missingItems = logicHelper ? logicHelper.getMissingItemsList(mItems) : [];

        for (const itemData of missingItems) {
            if (syncHelper.isMissingItem(itemData.char)) {
                const icon = $.CreatePanel('Label', missingContainer, '');
                icon.AddClass('status-icon');
                icon.style.color = itemData.color;
                icon.text = itemData.char;
            }
        }

        // --- VISIBILITY CONTROL ---
        container.SetHasClass('visible', true);

        // Always show for 5 seconds when triggered (manually or by map load)
        // Background API updates (isManual=false) will NOT reset the timer
        if (isManual) {
            if (this.m_HideSchedule) {
                $.CancelScheduled(this.m_HideSchedule);
            }
            this.m_HideSchedule = $.Schedule(5.0, () => {
                container.SetHasClass('visible', false);
                this.m_HideSchedule = null;
            });
        } else if (!this.m_HideSchedule) {
            // Triggered by map load or first entry
            this.m_HideSchedule = $.Schedule(5.0, () => {
                container.SetHasClass('visible', false);
                this.m_HideSchedule = null;
            });
        }
    }
}

ArchipelagoHUD.init();
