'use strict';

class ArchipelagoHUD {
    static m_HideSchedule: any = null;
    static m_Debug: boolean = false;

    static init() {
        if (this.m_Debug) $.Msg("[AP] ArchipelagoHUD initialized.");

        $.RegisterForUnhandledEvent("ArchipelagoDebug", (state: string) => {
            this.m_Debug = (state === "1");
        });

        // Listen for map change event from AngelScript
        $.RegisterForUnhandledEvent("ArchipelagoMapNameUpdated", (payload: string) => {
            if (this.m_Debug) $.Msg("[AP] ArchipelagoHUD: Received event with payload: " + payload);
            const parts = payload.split('|');
            const mapName = parts[0];
            const isManual = parts[1] === "1";

            if (this.m_Debug) $.Msg("[AP] ArchipelagoHUD: Map name updated to " + mapName + " (Manual: " + isManual + ")");
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

        if (this.m_Debug) $.Msg("[AP] ArchipelagoHUD: updateStatus called for map: " + currentMapName);

        if (!enabled && !isManual) {
            return;
        }

        const container = $.GetContextPanel();
        if (!container) return;

        if (!currentMapName || currentMapName === "main_menu" || currentMapName === "unknown") {
            return;
        }

        const extrasKv = $.LoadKeyValuesFile("scripts/extras.txt") || $.LoadKeyValues3File("scripts/extras.txt");
        const data = extrasKv && extrasKv.Extras ? extrasKv.Extras : extrasKv;
        if (!data) return;

        const syncHelper = (UiToolkitAPI.GetGlobalObject() as any).ArchipelagoSync;
        if (this.m_Debug && syncHelper) {
            $.Msg("[AP] ArchipelagoHUD using helper v" + syncHelper.VERSION);
        }
        
        if (!syncHelper) {
            if (this.m_Debug) $.Msg("[AP] ArchipelagoHUD ERROR: ArchipelagoSync helper not found!");
            return;
        }

        const chapters = syncHelper.parseExtras(data);
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

        if (!currentMapData) return;

        // Update UI
        const titleLabel = $('#MapTitle') as LabelPanel;
        const iconsContainer = $('#StatusIcons');
        const missingContainer = $('#MissingIcons');

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

        // If it's a manual show (key press), schedule it to hide after 5 seconds
        if (isManual) {
            if (this.m_HideSchedule) {
                $.CancelScheduled(this.m_HideSchedule);
            }
            this.m_HideSchedule = $.Schedule(5.0, () => {
                container.SetHasClass('visible', false);
                this.m_HideSchedule = null;
            });
        }
    }
}

ArchipelagoHUD.init();
