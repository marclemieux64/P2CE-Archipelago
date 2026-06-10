'use strict';

declare var $: any;
declare var UiToolkitAPI: any;

var ArchipelagoMapStatusHUD = class {
    static m_HideSchedule: any = null;
    static m_CurrentMapName: string = "";
    static m_PendingShow: boolean = false;
    static m_LastStatusKey: string = "";
    static m_LastMissingKey: string = "";

    static ITEM_SORT_ORDER: { [key: string]: number } = {
        "portalgun1": 1, "portalgun2": 2, "weightedcube": 3, "lasercube": 4,
        "button": 5, "weightedfloorbutton": 6, "cubebutton": 7, "ballfloorbutton": 8,
        "ballcube": 9, "laser": 10, "laserrelay": 11, "lasercatcher": 12,
        "lightbridge": 13, "turret": 14, "faithplate": 15, "potatos": 16,
        "jumpgel": 17, "speedgel": 18, "portalgel": 19, "funnel": 20,
        "antiqueweightedcube": 21, "antiquebutton": 22, "antiquefloorbutton": 23,
        "frankencube": 24, "advcore": 25, "spacecore": 26, "factcore": 27
    };

    static ICON_BADGE_MAP: { [key: string]: string } = {
        "flag": "#Archipelago_Maps_Check_Tag", 
        "ratmansdent": "#Archipelago_Ratmens_Dens_Check_Tag", 
        "portalgun1": "#Archipelago_Portal_Guns1_Check_Tag", 
        "portalgun2": "#Archipelago_Portal_Guns2_Check_Tag", 
        "door": "#Archipelago_Vitrified_Doors_Check_Tag", 
        "potatos": "#Archipelago_Potatos_Check_Tag", 
        "monitor": "#Archipelago_Wheathley_Monitor_Check_Tag"
    };

    static init() {
        $.RegisterForUnhandledEvent("ArchipelagoMapNameUpdated", (payload: string) => {
            if (!payload) return;
            const parts = payload.split('|');
            ArchipelagoMapStatusHUD.m_CurrentMapName = parts[0] || "";
            const isManual = parts[1] === "1";
            
            if (ArchipelagoMapStatusHUD.m_HideSchedule) { 
                $.CancelScheduled(ArchipelagoMapStatusHUD.m_HideSchedule); 
                ArchipelagoMapStatusHUD.m_HideSchedule = null; 
            }
            
            ArchipelagoMapStatusHUD.m_LastStatusKey = "";
            ArchipelagoMapStatusHUD.m_LastMissingKey = "";
            
            if (isManual) { 
                ArchipelagoMapStatusHUD.updateStatus(ArchipelagoMapStatusHUD.m_CurrentMapName, true, true); 
            } else { 
                $.Schedule(0.5, () => ArchipelagoMapStatusHUD.updateStatus(ArchipelagoMapStatusHUD.m_CurrentMapName, false, true)); 
            }
        });

        const api = (UiToolkitAPI.GetGlobalObject() as any).ArchipelagoAPI;
        if (api) {
            api.registerStatusListener($.GetContextPanel(), (status: any) => {
                if (ArchipelagoMapStatusHUD.m_CurrentMapName) {
                    ArchipelagoMapStatusHUD.updateStatus(ArchipelagoMapStatusHUD.m_CurrentMapName, false, ArchipelagoMapStatusHUD.m_PendingShow);
                }
            });
        }
    }

    static updateStatus(currentMapName: string, isManual: boolean, forceShow: boolean) {
        if (!currentMapName || typeof currentMapName !== 'string') return;

        const container = $.GetContextPanel();
        if (!container || !container.IsValid()) return;

        container.style.width = "fit-children";
        container.style.height = "fit-children";
        container.style.horizontalAlign = "left";

        const mainContainerPanel = container.FindChildTraverse('MainContainer');
        if (mainContainerPanel) {
            mainContainerPanel.style.width = "fit-children";
            mainContainerPanel.style.height = "fit-children";
        }

        const wrapperPanel = container.FindChildTraverse('HUDColumnsWrapper');
        if (wrapperPanel) {
            wrapperPanel.style.width = "fit-children";
            wrapperPanel.style.height = "fit-children";
        }

        const hudSetting = $.persistentStorage.getItem('ap_show_map_status_hud');
        if (hudSetting !== null && (hudSetting == 1 || hudSetting == '1' || hudSetting === true)) {
            container.RemoveClass('visible');
            container.AddClass('collapse');
            return;
        }

        const api = (UiToolkitAPI.GetGlobalObject() as any).ArchipelagoAPI;
        const syncHelper = (UiToolkitAPI.GetGlobalObject() as any).ArchipelagoSync;
        
        let apiStatus = api ? api.getStatus() : null;
        if (!apiStatus || !apiStatus.menu) { 
            if (forceShow) ArchipelagoMapStatusHUD.m_PendingShow = true; 
            return; 
        }

        ArchipelagoMapStatusHUD.m_PendingShow = false;
        const chapters = syncHelper.parseApiStatus(apiStatus);
        let currentMapData: any = null;
        
        for (const chId in chapters) {
            if (!chapters[chId] || !chapters[chId].maps) continue;
            for (const map of chapters[chId].maps) {
                const fullCmdStr = map.command || map.command_deactivated || "";
                if (fullCmdStr && fullCmdStr.toLowerCase().indexOf(currentMapName.toLowerCase()) !== -1) {
                    currentMapData = map;
                    break;
                }
            }
            if (currentMapData) break;
        }

        if (!currentMapData) return;

        const titleLabel = container.FindChildTraverse('MapTitle') as LabelPanel;
        const statusIconsContainer = container.FindChildTraverse('StatusIcons');
        const missingIconsContainer = container.FindChildTraverse('MissingIcons');

        if (!titleLabel || !statusIconsContainer || !missingIconsContainer) return;

        if (forceShow) {
            container.AddClass('visible');
            container.RemoveClass('collapse');
            container.RemoveClass('hide');
            container.RemoveClass('hidden');

            if (ArchipelagoMapStatusHUD.m_HideSchedule) $.CancelScheduled(ArchipelagoMapStatusHUD.m_HideSchedule);
            ArchipelagoMapStatusHUD.m_HideSchedule = $.Schedule(5.0, () => { 
                if (container.IsValid()) {
                    container.RemoveClass('visible');
                }
                ArchipelagoMapStatusHUD.m_HideSchedule = null; 
            });
        }

        if (!container.HasClass('visible')) return;

        let mapCmdName = currentMapName;
        const fullCommand = currentMapData.command || currentMapData.command_deactivated || "";
        if (fullCommand) {
            const parts = fullCommand.split(" ");
            if (parts.length >= 2) mapCmdName = parts[1].trim().toLowerCase();
        }

        const mapToken = `#portal2_MapName_${mapCmdName.startsWith("sp_") ? "SP_" + mapCmdName.substring(3) : mapCmdName.startsWith("coop_") ? "COOP_" + mapCmdName.substring(5) : mapCmdName}`;
        titleLabel.text = $.Localize(mapToken);

        const checksColumn = container.FindChildTraverse('ChecksColumn');
        if (checksColumn) {
            checksColumn.style.width = "fit-children";
            checksColumn.style.height = "fit-children";
            const label = checksColumn.GetChild(0) as LabelPanel;
            if (label) {
                const localizedText = $.Localize("#Archipelago_Map_Checks");
                label.text = (localizedText === "#Archipelago_Map_Checks" || localizedText === "") ? "Checks Found" : localizedText;
            }
        }

        const reqsColumn = container.FindChildTraverse('RequirementsColumn');
        if (reqsColumn) {
            reqsColumn.style.width = "fit-children";
            reqsColumn.style.height = "fit-children";
            const label = reqsColumn.GetChild(0) as LabelPanel;
            if (label) {
                const localizedText = $.Localize("#Archipelago_Map_MissingItems");
                label.text = (localizedText === "#Archipelago_Map_MissingItems" || localizedText === "") ? "Missing Items Required" : localizedText;
            }
        }

        const statusIconsList = currentMapData.statusIcons || [];
        const currentStatusKey = statusIconsList.join(",");
        if (ArchipelagoMapStatusHUD.m_LastStatusKey !== currentStatusKey) {
            ArchipelagoMapStatusHUD.m_LastStatusKey = currentStatusKey;
            statusIconsContainer.RemoveAndDeleteChildren();
            statusIconsList.forEach((svgName: string, i: number) => {
                const cell = $.CreatePanel('Panel', statusIconsContainer, 'StatusHUDCell_' + i);
                cell.AddClass('hud_icon_cell');

                const img = $.CreatePanel('Image', cell, 'StatusHUDIcon_' + i) as ImagePanel;
                if (img) {
                    img.AddClass('status_svg_icon');
                    img.SetImage(`file://{images}/archipelago/icons/${svgName}.svg`);
                }

                let targetBadgeText = "";
                const activeSubs = currentMapData.active_sub_keys || [];
                const typeKey = activeSubs[i - 1];

                if (i === 0) {
                    targetBadgeText = "#Archipelago_Maps_Check_Tag";
                } else if (typeKey && ArchipelagoMapStatusHUD.ICON_BADGE_MAP[typeKey]) {
                    targetBadgeText = ArchipelagoMapStatusHUD.ICON_BADGE_MAP[typeKey];
                } else if (svgName && ArchipelagoMapStatusHUD.ICON_BADGE_MAP[svgName]) {
                    targetBadgeText = ArchipelagoMapStatusHUD.ICON_BADGE_MAP[svgName];
                }

                if (svgName === "uncheck") {
                    img.AddClass('status_icon--locked');
                }

                if (targetBadgeText !== "") {
                    const badge = $.CreatePanel('Label', cell, 'StatusHUDBadge_' + i) as LabelPanel;
                    badge.AddClass('hud_icon_badge');
                    badge.text = $.Localize(targetBadgeText);
                    if (svgName === "uncheck") badge.AddClass('hud_icon_badge--locked');
                }
            });
        }

        // RECALCUL DYNAMIQUE DES PRÉREQUIS POUR LE HUD IN-GAME
        let dynamicItemIcons: string[] = [];
        if (apiStatus && apiStatus.missing_items !== undefined) {
            const rawMissingString: string = apiStatus.missing_items;
            const originalIcons: string[] = currentMapData.required_item_icons || [];
            
            // Filtre à la volée : si l'item n'est plus marqué comme manquant par le serveur, on vire l'icône du HUD
            dynamicItemIcons = originalIcons.filter((iconName: string) => {
                return rawMissingString.indexOf(iconName) !== -1;
            });
        } else {
            dynamicItemIcons = currentMapData.required_item_icons || [];
        }

        const sortedItemIcons = [...dynamicItemIcons];
        sortedItemIcons.sort((a: string, b: string) => {
            const orderA = ArchipelagoMapStatusHUD.ITEM_SORT_ORDER[a] || 99;
            const orderB = ArchipelagoMapStatusHUD.ITEM_SORT_ORDER[b] || 99;
            return orderA - orderB;
        });

        if (reqsColumn) {
            if (sortedItemIcons.length === 0) {
                reqsColumn.AddClass('collapse');
                reqsColumn.style.visibility = 'collapse';
            } else {
                reqsColumn.RemoveClass('collapse');
                reqsColumn.style.visibility = 'visible';
            }
        }

        const currentMissingKey = sortedItemIcons.join(",");
        if (ArchipelagoMapStatusHUD.m_LastMissingKey !== currentMissingKey) {
            ArchipelagoMapStatusHUD.m_LastMissingKey = currentMissingKey;
            missingIconsContainer.RemoveAndDeleteChildren();
            sortedItemIcons.forEach((svgName: string, i: number) => {
                const cell = $.CreatePanel('Panel', missingIconsContainer, 'MissingHUDCell_' + i);
                cell.AddClass('hud_icon_cell');

                const img = $.CreatePanel('Image', cell, 'MissingHUDIcon_' + i) as ImagePanel;
                if (img) {
                    img.AddClass('requirement_svg_icon');
                    img.SetImage(`file://{images}/archipelago/icons/${svgName}.svg`);
                }
            });
        }
    }
};

ArchipelagoMapStatusHUD.init();