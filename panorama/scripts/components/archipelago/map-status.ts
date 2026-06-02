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
            const parts = payload.split('|');
            this.m_CurrentMapName = parts[0];
            const isManual = parts[1] === "1";
            if (this.m_HideSchedule) { $.CancelScheduled(this.m_HideSchedule); this.m_HideSchedule = null; }
            this.m_LastStatusKey = "";
            this.m_LastMissingKey = "";
            if (isManual) { this.updateStatus(this.m_CurrentMapName, true, true); } 
            else { $.Schedule(0.5, () => this.updateStatus(this.m_CurrentMapName, false, true)); }
        });

        const api = (UiToolkitAPI.GetGlobalObject() as any).ArchipelagoAPI;
        if (api) {
            api.registerStatusListener($.GetContextPanel(), (payload: any) => {
                if (this.m_CurrentMapName) this.updateStatus(this.m_CurrentMapName, false, this.m_PendingShow);
            });
        }
    }

    static updateStatus(currentMapName: string, isManual: boolean, forceShow: boolean) {
        if ($.persistentStorage.getItem('ap_show_map_status_hud') == 1) return;

        const container = $.GetContextPanel();
        const api = (UiToolkitAPI.GetGlobalObject() as any).ArchipelagoAPI;
        const syncHelper = (UiToolkitAPI.GetGlobalObject() as any).ArchipelagoSync;
        
        let apiStatus = api ? api.getStatus() : null;
        if (!apiStatus || !apiStatus.menu) { if (forceShow) this.m_PendingShow = true; return; }

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

        let mapCmdName = currentMapName;
        const fullCommand = currentMapData.command || currentMapData.command_deactivated || "";
        if (fullCommand) {
            const parts = fullCommand.split(" ");
            if (parts.length >= 2) mapCmdName = parts[1].trim().toLowerCase();
        }

        const mapToken = `#portal2_MapName_${mapCmdName.startsWith("sp_") ? "SP_" + mapCmdName.substring(3) : mapCmdName.startsWith("coop_") ? "COOP_" + mapCmdName.substring(5) : mapCmdName}`;
        
        if (forceShow) {
            container.AddClass('visible');
            container.RemoveClass('collapse');
            if (this.m_HideSchedule) $.CancelScheduled(this.m_HideSchedule);
            this.m_HideSchedule = $.Schedule(5.0, () => { container.RemoveClass('visible'); this.m_HideSchedule = null; });
        }

        if (!container.HasClass('visible')) return;

        // TITRE : Localisation simple, sans coloration dynamique
        $('#MapTitle').text = $.Localize(mapToken);

        // ICÔNES STATUT
        const statusIconsList = currentMapData.statusIcons || [];
        const currentStatusKey = statusIconsList.join(",");
        if (this.m_LastStatusKey !== currentStatusKey) {
            this.m_LastStatusKey = currentStatusKey;
            const iconsContainer = $('#StatusIcons');
            iconsContainer.RemoveAndDeleteChildren();
            statusIconsList.forEach((svgName: string, i: number) => {
                const img = $.CreatePanel('Image', iconsContainer, 'StatusHUDIcon_' + i) as ImagePanel;
                img.AddClass('status_svg_icon');
                img.SetImage(`file://{images}/archipelago/icons/${svgName}.svg`);
            });
        }

        // ICÔNES PRÉREQUIS
        const missingItemsList = currentMapData.required_item_icons || [];
        const currentMissingKey = missingItemsList.join(",");
        if (this.m_LastMissingKey !== currentMissingKey) {
            this.m_LastMissingKey = currentMissingKey;
            const missingContainer = $('#MissingIcons');
            missingContainer.RemoveAndDeleteChildren();
            [...missingItemsList].sort((a, b) => (ArchipelagoMapStatusHUD.ITEM_SORT_ORDER[a] || 99) - (ArchipelagoMapStatusHUD.ITEM_SORT_ORDER[b] || 99))
                .forEach((svgName: string, i: number) => {
                    const img = $.CreatePanel('Image', missingContainer, 'MissingHUDIcon_' + i) as ImagePanel;
                    img.AddClass('requirement_svg_icon');
                    img.SetImage(`file://{images}/archipelago/icons/${svgName}.svg`);
                });
        }
    }
};

ArchipelagoMapStatusHUD.init();