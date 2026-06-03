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
            api.registerStatusListener($.GetContextPanel(), (payload: any) => {
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

        // PROTECTION CONTRE L'ÉTIREMENT : Bloque immédiatement les dimensions au strict minimum requis par les enfants
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

        // FALLBACK DES EN-TÊTES : Empêche l'effondrement à 0px de hauteur si le fichier de traduction est absent
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

        // RE-MAPPING DES CLÉS : Extraction alignée sur la structure d'ArchipelagoSync (statusIcons)
        const statusIconsList = currentMapData.statusIcons || [];
        const currentStatusKey = statusIconsList.join(",");
        if (ArchipelagoMapStatusHUD.m_LastStatusKey !== currentStatusKey) {
            ArchipelagoMapStatusHUD.m_LastStatusKey = currentStatusKey;
            statusIconsContainer.RemoveAndDeleteChildren();
            statusIconsList.forEach((svgName: string, i: number) => {
                const img = $.CreatePanel('Image', statusIconsContainer, 'StatusHUDIcon_' + i) as ImagePanel;
                if (img) {
                    img.AddClass('status_svg_icon');
                    img.SetImage(`file://{images}/archipelago/icons/${svgName}.svg`);
                }
            });
        }

        // RENDU DES OBJETS REQUIS MANQUANTS
        const missingItemsList = currentMapData.required_item_icons || [];
        const currentMissingKey = missingItemsList.join(",");
        if (ArchipelagoMapStatusHUD.m_LastMissingKey !== currentMissingKey) {
            ArchipelagoMapStatusHUD.m_LastMissingKey = currentMissingKey;
            missingIconsContainer.RemoveAndDeleteChildren();
            [...missingItemsList].sort((a, b) => (ArchipelagoMapStatusHUD.ITEM_SORT_ORDER[a] || 99) - (ArchipelagoMapStatusHUD.ITEM_SORT_ORDER[b] || 99))
                .forEach((svgName: string, i: number) => {
                    const img = $.CreatePanel('Image', missingIconsContainer, 'MissingHUDIcon_' + i) as ImagePanel;
                    if (img) {
                        img.AddClass('requirement_svg_icon');
                        img.SetImage(`file://{images}/archipelago/icons/${svgName}.svg`);
                    }
                });
        }
    }
};

ArchipelagoMapStatusHUD.init();