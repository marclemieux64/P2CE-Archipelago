'use strict';

declare var $: any;
declare var UiToolkitAPI: any;

var ArchipelagoMapStatusHUD = class {
    static m_HideSchedule: any = null;
    static m_Debug: boolean = false;
    static m_CurrentMapName: string = "";
    static m_PendingShow: boolean = false;
    
    static m_LastStatusKey: string = "";
    static m_LastMissingKey: string = "";

    static init() {
        $.RegisterForUnhandledEvent("ArchipelagoMapNameUpdated", (payload: string) => {
            const parts = payload.split('|');
            this.m_CurrentMapName = parts[0];
            const isManual = parts[1] === "1";

            if (this.m_HideSchedule) {
                $.CancelScheduled(this.m_HideSchedule);
                this.m_HideSchedule = null;
            }

            this.m_LastStatusKey = "";
            this.m_LastMissingKey = "";

            if (isManual) {
                this.updateStatus(this.m_CurrentMapName, true, true);
            } else {
                $.Schedule(0.5, () => this.updateStatus(this.m_CurrentMapName, false, true));
            }
        });

        $.RegisterForUnhandledEvent("ArchipelagoAPI_StatusUpdated", (json: string) => {
            if (this.m_CurrentMapName) {
                this.updateStatus(this.m_CurrentMapName, false, this.m_PendingShow);
            }
        });
    }

    static updateStatus(currentMapName: string, isManual: boolean, forceShow: boolean) {
        const psValue = $.persistentStorage.getItem('ap_show_map_status_hud');
        const enabled = (psValue === null || psValue === undefined || psValue == 1 || psValue === "1");
        if (!enabled && !isManual) return;

        const container = $.GetContextPanel();
        if (!container || !currentMapName || currentMapName === "main_menu") return;

        const api = (UiToolkitAPI.GetGlobalObject() as any).ArchipelagoAPI;
        const syncHelper = (UiToolkitAPI.GetGlobalObject() as any).ArchipelagoSync;
        const logicHelper = (UiToolkitAPI.GetGlobalObject() as any).ArchipelagoLogic;
        
        const apiStatus = api ? api.getStatus() : null;
        if (!apiStatus || !apiStatus.menu || !syncHelper || !logicHelper) {
            if (forceShow) this.m_PendingShow = true;
            return;
        }

        this.m_PendingShow = false;

        const chapters = syncHelper.parseApiStatus(apiStatus);
        let currentMapData: any = null;
        for (const chId in chapters) {
            for (const map of chapters[chId].maps) {
                if (map.command && map.command.toLowerCase().indexOf(currentMapName.toLowerCase()) !== -1) {
                    currentMapData = map;
                    break;
                }
            }
            if (currentMapData) break;
        }

        if (!currentMapData) return;

        if (forceShow) {
            container.AddClass('visible');
            container.RemoveClass('collapse');
            if (this.m_HideSchedule) $.CancelScheduled(this.m_HideSchedule);
            this.m_HideSchedule = $.Schedule(5.0, () => {
                container.RemoveClass('visible');
                this.m_HideSchedule = null;
            });
        }

        if (!container.HasClass('visible')) return;

        // --- CORRECTION 1: Extraction robuste du nom de la carte (comme dans map-select.ts) ---
        let mapCmdName = currentMapName;
        const fullCommand = currentMapData.command || currentMapData.command_deactivated || "";
        if (fullCommand) {
            const parts = fullCommand.split(" ");
            if (parts.length >= 2) mapCmdName = parts[1].trim().toLowerCase();
        }

        const titleLabel = $('#MapTitle');
        const mapToken = `#portal2_MapName_${mapCmdName}`;
        titleLabel.text = $.Localize(mapToken) !== mapToken ? $.Localize(mapToken) : currentMapData.id;

        const statusIconsRaw = (currentMapData.statusIcons || currentMapData.info || "").replace(/[~\-]/g, "").trim();
        const mItemsRaw = currentMapData.subtitle || "";
        
        // --- CORRECTION 2: Ajout du statut "en jeu" dans la clé pour forcer le HUD à se rafraîchir ---
        const mapStatusFromEngine = $.persistentStorage.getItem("ArchipelagoLastMapStatus") || 0;
        const currentStatusKey = statusIconsRaw + mItemsRaw + mapCmdName + mapStatusFromEngine;

        if (this.m_LastStatusKey !== currentStatusKey) {
            this.m_LastStatusKey = currentStatusKey;
            const iconsContainer = $('#StatusIcons');
            iconsContainer.RemoveAndDeleteChildren();
            
            // On utilise mapCmdName (strict) au lieu du nom brut
            const formattedIcons = logicHelper.getFormattedIcons(statusIconsRaw, mapCmdName, mItemsRaw);
            for (const iconData of formattedIcons) {
                const icon = $.CreatePanel('Label', iconsContainer, '');
                icon.text = iconData.char;
                icon.AddClass('status-icon');
                
                icon.style.color = iconData.color; 

                if (iconData.isCompleted) {
                    icon.AddClass('status-icon--completed');
                }
            }
        }

        // --- GESTION DES MISSING ITEMS (Section du bas - Masquable) ---
        const missingItemsList = logicHelper.getMissingItemsList(mItemsRaw);
        let currentMissingKey = "";
        let redCount = 0;

        missingItemsList.forEach((itemData: any) => {
            if (syncHelper.isMissingItem(itemData.char)) {
                currentMissingKey += itemData.char;
                redCount++;
            }
        });

        const missingContainer = $('#MissingIcons');
        const missingLabel = $('#MissingLabel');

        if (this.m_LastMissingKey !== currentMissingKey) {
            this.m_LastMissingKey = currentMissingKey;
            missingContainer.RemoveAndDeleteChildren();

            for (const itemData of missingItemsList) {
                if (syncHelper.isMissingItem(itemData.char)) {
                    const icon = $.CreatePanel('Label', missingContainer, '');
                    icon.AddClass('status-icon');
                    icon.style.color = itemData.color;
                    icon.text = itemData.char;
                }
            }
        }

        if (missingLabel && missingContainer) {
            const shouldCollapse = (redCount === 0);
            missingLabel.SetHasClass('collapse', shouldCollapse);
            missingContainer.SetHasClass('collapse', shouldCollapse);
        }
    }
};

ArchipelagoMapStatusHUD.init();