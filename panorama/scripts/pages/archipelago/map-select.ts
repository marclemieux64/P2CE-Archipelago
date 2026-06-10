'use strict';

declare var $: any;
declare var UiToolkitAPI: any;
declare var GameInterfaceAPI: any;
interface Panel { [key: string]: any; }
interface ImagePanel extends Panel { }
interface LabelPanel extends Panel { }

class ArchipelagoMapSelect {
    static g_ChapterData: any = {};
    static g_SelectedMapCommand: string = '';
    static g_LastApiJson: string = '';
    static g_OpenChapterId: string = '';
    static g_SelectedMapData: any = null;
    static g_ClickedMapData: any = null; 
    static g_ResetSchedule: any = null;
    static g_IsTransitioning: boolean = false; 

    static ITEM_SORT_ORDER: { [key: string]: number } = {
        "portalgun1": 1, "portalgun2": 2, "weightedcube": 3, "lasercube": 4,
        "button": 5, "weightedfloorbutton": 6, "cubebutton": 7, "ballfloorbutton": 8,
        "ballcube": 9, "laser": 10, "laserrelay": 11, "lasercatcher": 12,
        "lightbridge": 13, "turret": 14, "faithplate": 15, "potatos": 16,
        "jumpgel": 17, "speedgel": 18, "portalgel": 19, "funnel": 20,
        "antiqueweightedcube": 21,"antiquebutton": 22, "antiquefloorbutton": 23,
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

    static LOCALIZED_TOKEN_MAP: { [key: string]: string } = {
        "flag": "#Archipelago_Help_Check_Generic",
        "ratmansdent": "#Archipelago_Help_Check_Ratman",
        "monitor": "#Archipelago_Help_Check_Wheatley",
        "door": "#Archipelago_Help_Check_Door",
        "portalgun1": "#Archipelago_Help_Check_PGunBlue",
        "portalgun2": "#Archipelago_Help_Check_PGunOrange",
        "potatos": "#Archipelago_Help_Check_Potatos",
        "check": "#Archipelago_Help_Status_Unlocked",
        "weightedcube": "#Archipelago_Help_Item_CubeWeighted",
        "lasercube": "#Archipelago_Help_Item_CubeReflect",
        "ballcube": "#Archipelago_Help_Item_CubeSphere",
        "antiqueweightedcube": "#Archipelago_Help_Item_CubeAntique",
        "frankencube": "#Archipelago_Help_Item_Franken",
        "button": "#Archipelago_Help_Item_Button",
        "antiquebutton": "#Archipelago_Help_Item_ButtonOld",
        "weightedfloorbutton": "#Archipelago_Help_Item_ButtonFloor",
        "antiquefloorbutton": "#Archipelago_Help_Item_ButtonFloorOld",
        "cubebutton": "#Archipelago_Help_Item_Button",
        "ballfloorbutton": "#Archipelago_Help_Item_Button",
        "paint": "#Archipelago_Help_Item_GelBlue",
        "jumpgel": "#Archipelago_Help_Item_GelBlue",
        "speedgel": "#Archipelago_Help_Item_GelOrange",
        "portalgel": "#Archipelago_Help_Item_GelWhite",
        "laser": "#Archipelago_Help_Item_Laser",
        "laserrelay": "#Archipelago_Help_Item_LaserRelay",
        "lasercatcher": "#Archipelago_Help_Item_LaserCatcher",
        "faithplate": "#Archipelago_Help_Item_FaithPlate",
        "funnel": "#Archipelago_Help_Item_TractorBeam",
        "lightbridge": "#Archipelago_Help_Item_Bridge",
        "turret": "#Archipelago_Help_Item_Turrets",
        "advcore": "#Archipelago_Help_Item_CoreAdv",
        "spacecore": "#Archipelago_Help_Item_CoreSpace",
        "factcore": "#Archipelago_Help_Item_CoreFact"
    };

    static isController() {
        let p = $.GetContextPanel();
        while (p) {
            if (p.id === 'MainMenu' || p.HasClass('MainMenuRootPanel')) return p.HasClass('InputController');
            p = p.GetParent();
        }
        return false;
    }

    static toggleConsole() {
        const api = (UiToolkitAPI.GetGlobalObject() as any).ArchipelagoAPI;
        if (!api || !api.getStatus()) return;
        $.PlaySoundEvent('UIPanorama.P2CE.MenuAccept');
        $.DispatchEvent('MainMenuOpenNestedPage', 'ap_console', 'archipelago/console', undefined);
    }

    static updateConnectionState() {
        const globalObj = (UiToolkitAPI.GetGlobalObject() as any);
        const api = globalObj.ArchipelagoAPI;
        const status = api ? api.getStatus() : null;
        const root = $.GetContextPanel();
        if (!root || !root.IsValid()) return;

        const overlay = root.FindChildTraverse('NotConnectedOverlay');
        const content = root.FindChildTraverse('ConnectedContent');
        if (!overlay || !overlay.IsValid()) return;

        let overlayLabel = overlay.FindChildTraverse('NotConnectedLabel') as LabelPanel;
        let overlayButton = null;

        const children = overlay.Children();
        for (let i = 0; i < children.length; i++) {
            if (children[i].paneltype === "Label" && (!overlayLabel || !overlayLabel.IsValid())) overlayLabel = children[i];
            if (children[i].paneltype === "Button" && (!overlayButton || !overlayButton.IsValid())) overlayButton = children[i];
        }

        if (!api || !status || status.client_offline) {
            overlay.RemoveClass('hide');
            if (content && content.IsValid()) content.AddClass('hide');
            if (overlayButton && overlayButton.IsValid()) overlayButton.AddClass('hide');
            if (overlayLabel && overlayLabel.IsValid()) overlayLabel.text = $.Localize("#Archipelago_Status_NoClient") + "\n" + $.Localize("#Archipelago_Status_LaunchClient");
        } else if (status.connected && !status.menu) {
            overlay.RemoveClass('hide');
            if (content && content.IsValid()) content.AddClass('hide');
            if (overlayButton && overlayButton.IsValid()) overlayButton.AddClass('hide');
            if (overlayLabel && overlayLabel.IsValid()) overlayLabel.text = $.Localize("#Archipelago_Status_Loading") + "\n(Authenticating Slot...)";
        } else if (status && !status.connected) {
            overlay.RemoveClass('hide');
            if (content && content.IsValid()) content.AddClass('hide');
            if (overlayButton && overlayButton.IsValid()) overlayButton.RemoveClass('hide');
            if (overlayLabel && overlayLabel.IsValid()) overlayLabel.text = $.Localize("#Archipelago_Status_NotConnected");
        } else {
            overlay.AddClass('hide');
            if (content && content.IsValid()) content.RemoveClass('hide');
        }
    }

    static updateChapterStyle(panel: Panel, valid: number, total: number, allCompleted: boolean) {
        if (!panel || !panel.IsValid()) return;
        panel.RemoveClass('progress--red');
        panel.RemoveClass('progress--yellow');
        panel.RemoveClass('progress--green');

        if (allCompleted) {
            panel.AddClass('progress--green');
            panel.style.color = "#33cc33";
        } else if (total === 0 || valid === 0) {
            panel.AddClass('progress--red');
            panel.style.color = "#ff4444";
        } else if (valid < total) {
            panel.AddClass('progress--yellow');
            panel.style.color = "#ffcc00";
        } else if (valid === total) {
            panel.AddClass('progress--green');
            panel.style.color = "#33cc33";
        }
    }

    static onLoad() {
        this.g_LastApiJson = '';
        $.DispatchEvent('MainMenuSetPageLines', $.Localize('#Archipelago_Maps_Title'), $.Localize('#Archipelago_Maps_Tagline'));

        const contextPanel = $.GetContextPanel();
        if (contextPanel && contextPanel.IsValid()) {
            contextPanel.SetAcceptsFocus(true);
            contextPanel.SetFocus();
        }

        const syncInputMode = () => {
            const cp = $.GetContextPanel();
            if (cp && cp.IsValid()) {
                cp.SetHasClass('is-controller-mode', this.isController());
                $.Schedule(1.0, syncInputMode);
            }
        };
        syncInputMode();

        $.Schedule(0.1, () => {
            const playButton = $('#PlayButton');
            if (playButton && playButton.IsValid()) {
                playButton.enabled = false;
                playButton.RemoveClass('play_button--active');
            }
            const container = $('#LeftListInner');
            if (container && container.IsValid() && container.GetChildCount() > 0) {
                container.GetChild(0).SetFocus();
            }
        });

        const api = (UiToolkitAPI.GetGlobalObject() as any).ArchipelagoAPI;
        if (api) {
            api.registerStatusListener($.GetContextPanel(), (status: any) => {
                if (!status) return;
                const jsonString = JSON.stringify(status);
                if (jsonString === this.g_LastApiJson) return;
                this.g_LastApiJson = jsonString;

                if (!status.connected || !status.menu) {
                    this.g_ChapterData = {};
                    this.generateList();
                    this.updateConnectionState();
                    return;
                }

                const mappedData: any = {};
                if (status.menu && status.menu.chapters) {
                    status.menu.chapters.forEach((ch: any) => {
                        mappedData[ch.chapter_number] = ch;
                    });
                }
                this.g_ChapterData = mappedData;

                const savedChapter = this.g_OpenChapterId;
                const savedCommand = this.g_SelectedMapCommand;

                this.generateList();
                this.updateConnectionState();

                if (savedChapter) {
                    const mapList = $('#ChapterMaps_' + savedChapter);
                    const entry = $('#ChapterEntry_' + savedChapter);
                    const wrapper = $('#ChapterWrapper_' + savedChapter);
                    if (mapList && mapList.IsValid() && entry && entry.IsValid()) {
                        entry.AddClass('chapter_entry--active');
                        if (wrapper && wrapper.IsValid()) wrapper.AddClass('chapter_wrapper--active');
                        mapList.RemoveClass('hide');
                        mapList.style.height = 'fit-children';
                        mapList.style.opacity = '1.0';
                    }
                }

                if (savedCommand) this.restoreSelection(savedCommand);
            });
        }
        this.updateConnectionState();
    }

    static restoreSelection(savedCommand: string) {
        for (const chId in this.g_ChapterData) {
            for (const map of this.g_ChapterData[chId].maps) {
                const isDeactivated = map.command_deactivated !== null && map.command_deactivated !== false && map.command_deactivated !== undefined;
                const cmd = (!isDeactivated && map.command) ? map.command : (typeof map.command_deactivated === 'string' ? map.command_deactivated : "");
                if (cmd === savedCommand) {
                    this.g_SelectedMapData = map;
                    this.g_ClickedMapData = map; 
                    this.selectMap(map, true);
                    this.restoreActiveSelectionVisuals();
                    break;
                }
            }
        }
    }

    static runTransition(openPanel: any, closePanel: any, clickedEntry: any, scrollContainer: any) {
        const duration = 0.3;
        const startTime = Date.now();
        const openStartH = 0;
        const openEndH = (openPanel && openPanel.IsValid()) ? openPanel.actuallayoutheight : 0;
        const closeStartH = (closePanel && closePanel.IsValid()) ? closePanel.actuallayoutheight : 0;
        const closeEndH = 0;

        const scrollBar: any = (scrollContainer && scrollContainer.IsValid()) ? scrollContainer.FindChildTraverse('VerticalScrollBar') : null;
        const startScroll = (scrollBar && scrollBar.IsValid()) ? scrollBar.ScrollPosition : 0;
        const entryScreenY = (clickedEntry && clickedEntry.IsValid()) ? clickedEntry.GetPositionWithinWindow().y : 0;
        const containerScreenY = (scrollContainer && scrollContainer.IsValid()) ? scrollContainer.GetPositionWithinWindow().y : 0;
        const targetScroll = startScroll + (entryScreenY - containerScreenY) - 10;

        const step = () => {
            if ((closePanel && !closePanel.IsValid()) || (openPanel && !openPanel.IsValid())) return;
            const elapsed = (Date.now() - startTime) / 1000;
            const progress = Math.min(elapsed / duration, 1.0);
            const ease = progress * (2 - progress);

            if (closePanel && closePanel.IsValid()) {
                closePanel.style.height = `${closeStartH + (closeEndH - closeStartH) * ease}px`;
                closePanel.style.opacity = `${1.0 - progress}`;
            }
            if (openPanel && openPanel.IsValid()) {
                openPanel.style.height = `${openStartH + (openEndH - openStartH) * ease}px`;
                openPanel.style.opacity = `${progress}`;
            }
            if (scrollBar && scrollBar.IsValid()) {
                scrollBar.ScrollPosition = startScroll + (targetScroll - startScroll) * ease;
            }

            if (progress < 1.0) $.Schedule(0.0, step);
            else {
                if (closePanel && closePanel.IsValid()) {
                    closePanel.AddClass('hide');
                    closePanel.style.height = '0px';
                }
                if (openPanel && openPanel.IsValid()) {
                    openPanel.style.height = 'fit-children';
                    openPanel.style.opacity = '1.0';
                }
                
                ArchipelagoMapSelect.g_IsTransitioning = false; 
                if (clickedEntry && clickedEntry.IsValid()) clickedEntry.SetFocus();
            }
        };
        step();
    }

    static toggleChapter(chapterId: string) {
        const container = $('#LeftListInner');
        const scrollContainer = $('#LeftList');
        if (!container || !container.IsValid() || !scrollContainer || !scrollContainer.IsValid()) return;

        const mapList = container.FindChild(`ChapterMaps_${chapterId}`);
        if (mapList && mapList.IsValid()) {
            const entry = $('#ChapterEntry_' + chapterId);
            const bOpening = mapList.HasClass('hide');

            for (const key in this.g_ChapterData) {
                const ce = $('#ChapterEntry_' + key);
                if (ce && ce.IsValid()) ce.RemoveClass('chapter_entry--active');
                const cw = $('#ChapterWrapper_' + key);
                if (cw && cw.IsValid()) cw.RemoveClass('chapter_wrapper--active');
            }

            let activePanel = null;
            for (const child of container.Children()) {
                if (child.id.startsWith('ChapterMaps_') && !child.HasClass('hide')) {
                    if (child.id !== `ChapterMaps_${chapterId}`) activePanel = child;
                }
            }

            ArchipelagoMapSelect.g_IsTransitioning = true;

            if (bOpening) {
                this.g_OpenChapterId = chapterId;
                if (entry && entry.IsValid()) entry.AddClass('chapter_entry--active');
                const wrapper = $('#ChapterWrapper_' + chapterId);
                if (wrapper && wrapper.IsValid()) wrapper.AddClass('chapter_wrapper--active');
                
                mapList.RemoveClass('hide');
                mapList.style.height = 'fit-children';
                mapList.style.opacity = '1.0';

                $.Schedule(0.01, () => {
                    if (mapList.IsValid()) {
                        mapList.style.height = '0px';
                        mapList.style.opacity = '0.0';
                        this.runTransition(mapList, activePanel, entry, scrollContainer);
                    }
                });
            } else {
                this.g_OpenChapterId = '';
                this.runTransition(null, mapList, entry, scrollContainer);
            }
        }

        const chapter = this.g_ChapterData[chapterId];
        if (chapter) {
            this.selectMap({
                chapter_number: chapterId,
                title: $.Localize(`#portal2_Chapter${chapterId}_Title`) || chapter.title,
                subtitle: "", status_text_list: [], command_deactivated: true, is_chapter: true, required_item_icons: []
            }, false);
        }
    }

    static createIconCell(parentPanel: any, cellId: string, svgName: string, isMissingItem: boolean, mapData: any, iconIndex: number) {
        const cell = $.CreatePanel('Panel', parentPanel, cellId);
        cell.AddClass('hud_icon_cell');

        const img = $.CreatePanel('Image', cell, cellId + '_Image') as ImagePanel;
        img.AddClass(isMissingItem ? 'requirement_svg_icon' : 'status_svg_icon');

        let targetBadgeText = "";
        const activeSubs = mapData.active_sub_keys || [];
        const typeKey = activeSubs[iconIndex - 1];

        if (!isMissingItem) {
            img.SetImage(`file://{images}/archipelago/icons/${svgName}.svg`);

            if (iconIndex === 0) {
                targetBadgeText = "#Archipelago_Maps_Check_Tag";
            } else if (typeKey && ArchipelagoMapSelect.ICON_BADGE_MAP[typeKey]) {
                targetBadgeText = ArchipelagoMapSelect.ICON_BADGE_MAP[typeKey];
            } else if (svgName && ArchipelagoMapSelect.ICON_BADGE_MAP[svgName]) {
                targetBadgeText = ArchipelagoMapSelect.ICON_BADGE_MAP[svgName];
            }

            if (svgName === "uncheck") {
                img.AddClass('status_icon--locked'); 
            }
        } else {
            img.SetImage(`file://{images}/archipelago/icons/${svgName}.svg`);
        }

        if (targetBadgeText !== "") {
            const badge = $.CreatePanel('Label', cell, cellId + '_Badge') as LabelPanel;
            badge.AddClass('hud_icon_badge');
            badge.text = $.Localize(targetBadgeText);
            if (svgName === "uncheck") badge.AddClass('hud_icon_badge--locked'); 
        }

        return cell;
    }

    static clearMapSelectionVisuals() {
        const listInner = $('#LeftListInner');
        if (!listInner || !listInner.IsValid()) return;

        for (let i = 0; i < listInner.GetChildCount(); i++) {
            const c = listInner.GetChild(i);
            if (c && c.IsValid() && c.HasClass('map_list')) {
                for (let j = 0; j < c.GetChildCount(); j++) {
                    const w = c.GetChild(j);
                    if (w && w.IsValid()) {
                        const mb = w.GetChild(0);
                        if (mb && mb.IsValid()) mb.RemoveClass('map_button--selected');
                    }
                }
            }
        }
    }

    static restoreActiveSelectionVisuals() {
        const listInner = $('#LeftListInner');
        if (!listInner || !listInner.IsValid()) return;

        for (let i = 0; i < listInner.GetChildCount(); i++) {
            const c = listInner.GetChild(i);
            if (c && c.IsValid() && c.HasClass('map_list')) {
                const count = c.GetChildCount();
                for (let j = 0; j < count; j++) {
                    const w = c.GetChild(j);
                    if (w && w.IsValid() && w.m_MapData) {
                        const mb = w.GetChild(0);
                        if (mb && mb.IsValid()) {
                            if (this.g_ClickedMapData && w.m_MapData.command === this.g_ClickedMapData.command) {
                                mb.AddClass('map_button--selected');
                            } else {
                                mb.RemoveClass('map_button--selected');
                            }
                        }
                    }
                }
            }
        }
    }

    static selectMap(mapData: any, bShowPlayButton: boolean = true) {
        const previewImage = $('#PreviewImage') as ImagePanel;
        const mapSubtitleLabel = $('#MapSubtitleLabel') as LabelPanel;
        
        const indicatorsContainer = $('#MapStatusIconsIconsPreview');
        const iconsContainer = $('#MapRequiredItemsIconsPreview'); 

        const checks = $('#ChecksColumn');
        const reqs = $('#RequirementsColumn');
        const playButton = $('#PlayButton');
        const missingItemsHeader = $('#MissingItemsHeader');
        const checksHeader = $('#ChecksHeader');

        if (previewImage && previewImage.IsValid()) {
            if (mapData.is_chapter) {
                previewImage.SetImage(`file://{images}/archipelago/chapter${mapData.chapter_number}.png`);
            } else {
                let picPath = mapData.pic || "menu/p2ce-generic";
                if (picPath.startsWith('vgui/chapters/')) {
                    picPath = `archipelago/${picPath.substring('vgui/chapters/'.length)}`;
                }
                previewImage.SetImage(`file://{images}/${picPath}.png`);
            }
        }

        if (mapSubtitleLabel && mapSubtitleLabel.IsValid()) {
            if (mapData.is_chapter) {
                mapSubtitleLabel.text = mapData.title || "";
            } else {
                let mapCleanToken = mapData.title || "";
                mapSubtitleLabel.text = $.Localize(`#portal2_MapName_${mapCleanToken}`);
            }
        }

        if (indicatorsContainer && indicatorsContainer.IsValid()) {
            indicatorsContainer.RemoveAndDeleteChildren();
            const statusList = mapData.status_text_list || [];
            statusList.forEach((svgName: string, i: number) => {
                ArchipelagoMapSelect.createIconCell(indicatorsContainer, 'SelectStatusCell_' + i, svgName, false, mapData, i);
            });
        }

        const missingItemsList = mapData.required_item_icons || [];

        if (iconsContainer && iconsContainer.IsValid()) {
            iconsContainer.RemoveAndDeleteChildren();
            if (missingItemsList.length > 0) {
                const sortedItemIcons = [...missingItemsList];
                sortedItemIcons.sort((a: string, b: string) => {
                    const orderA = ArchipelagoMapSelect.ITEM_SORT_ORDER[a] || 99;
                    const orderB = ArchipelagoMapSelect.ITEM_SORT_ORDER[b] || 99;
                    return orderA - orderB;
                });

                sortedItemIcons.forEach((svgName: string, i: number) => {
                    ArchipelagoMapSelect.createIconCell(iconsContainer, 'SelectReqCell_' + i, svgName, true, mapData, i);
                });
            }
        }

        const isChapter = mapData.is_chapter;
        const hasMissingItems = missingItemsList.length > 0;

        if (checks && checks.IsValid()) checks.visible = !isChapter;
        if (checksHeader && checksHeader.IsValid()) checksHeader.style.visibility = !isChapter ? 'visible' : 'collapse';

        if (reqs && reqs.IsValid()) reqs.visible = (!isChapter && hasMissingItems);
        if (missingItemsHeader && missingItemsHeader.IsValid()) {
            missingItemsHeader.style.visibility = (!isChapter && hasMissingItems) ? 'visible' : 'collapse';
        }

        if (playButton && playButton.IsValid()) {
            playButton.visible = (!isChapter && bShowPlayButton);
            const isDeactivated = mapData.command_deactivated !== null && mapData.command_deactivated !== false && mapData.command_deactivated !== undefined;
            
            if (!isDeactivated && mapData.command) {
                playButton.enabled = true;
                playButton.AddClass('play_button--active');
            } else {
                playButton.enabled = false;
                playButton.RemoveClass('play_button--active');
            }
        }
    }

    static playSelectedMap() {
        if (this.g_SelectedMapData && !this.g_SelectedMapData.is_chapter) {
            const cmd = this.g_SelectedMapData.command;
            const isDeactivated = this.g_SelectedMapData.command_deactivated !== null && this.g_SelectedMapData.command_deactivated !== false && this.g_SelectedMapCommand !== undefined;
            if (cmd && !isDeactivated) GameInterfaceAPI.ConsoleCommand(cmd);
        }
    }

    static generateList() {
        const container = $('#LeftListInner');
        if (!container || !container.IsValid()) return;

        const api = (UiToolkitAPI.GetGlobalObject() as any).ArchipelagoAPI;
        const status = api ? api.getStatus() : null;

        if (!this.g_ChapterData || Object.keys(this.g_ChapterData).length === 0) {
            container.RemoveAndDeleteChildren();
            const entry = $.CreatePanel('Panel', container, 'ErrorEntry');
            entry.AddClass('error_entry');
            const label = $.CreatePanel('Label', entry, '') as LabelPanel;

            if (!api || (status && status.client_offline)) {
                label.text = $.Localize("#Archipelago_Status_NoClient") + "\n" + $.Localize("#Archipelago_Status_LaunchClient");
            } else if (status && !status.connected) {
                label.text = $.Localize("#Archipelago_Status_NotConnected");
            } else {
                label.text = $.Localize("#Archipelago_Status_Loading");
            }
            return;
        }

        const errEntry = container.FindChild('ErrorEntry');
        if (errEntry && errEntry.IsValid()) errEntry.DeleteAsync(0);

        const isHidingCounts = ($.persistentStorage.getItem('ap_hide_location_counts') ?? "0").toString() === "1";
        const sortedKeys = Object.keys(this.g_ChapterData).sort((a, b) => parseInt(a) - parseInt(b));

        for (const chId of sortedKeys) {
            const chapter = this.g_ChapterData[chId];
            let wrapper = container.FindChild(`ChapterWrapper_${chId}`);
            let entry: any = wrapper ? wrapper.FindChild(`ChapterEntry_${chId}`) : null;

            if (!wrapper || !wrapper.IsValid() || !entry || !entry.IsValid()) {
                if (wrapper && wrapper.IsValid()) wrapper.DeleteAsync(0);

                wrapper = $.CreatePanel('Panel', container, `ChapterWrapper_${chId}`);
                wrapper.AddClass('chapter_entry_wrapper');
                (wrapper as any).canfocus = true;

                entry = $.CreatePanel('Panel', wrapper, `ChapterEntry_${chId}`);
                entry.AddClass('chapter_entry');

                wrapper.SetPanelEvent('onmouseover', () => {
                    if (this.g_ResetSchedule) { $.CancelScheduled(this.g_ResetSchedule); this.g_ResetSchedule = null; }
                    $.PlaySoundEvent('UIPanorama.P2CE.MenuFocus');
                });

                wrapper.SetPanelEvent('onmouseout', () => {
                    if (this.g_ResetSchedule) { $.CancelScheduled(this.g_ResetSchedule); this.g_ResetSchedule = null; }
                    this.g_ResetSchedule = $.Schedule(0.15, () => {
                        if (this.g_ClickedMapData) {
                            this.selectMap(this.g_ClickedMapData, true);
                            this.restoreActiveSelectionVisuals();
                        } else {
                            const targetChapterId = this.g_OpenChapterId || chId;
                            const openCh = this.g_ChapterData[targetChapterId];
                            if (openCh) {
                                this.selectMap({
                                    chapter_number: targetChapterId,
                                    title: $.Localize(`#portal2_Chapter${targetChapterId}_Title`) || openCh.title,
                                    subtitle: "", status_text_list: [], command_deactivated: true, is_chapter: true, required_item_icons: []
                                }, false);
                            }
                            this.clearMapSelectionVisuals();
                        }
                        this.g_ResetSchedule = null;
                    });
                });

                wrapper.SetPanelEvent('onactivate', () => {
                    $.PlaySoundEvent('UIPanorama.P2CE.MenuAccept');
                    this.g_ClickedMapData = null; 
                    this.g_SelectedMapData = null; 
                    this.clearMapSelectionVisuals(); 
                    this.toggleChapter(chId);
                });

                wrapper.SetPanelEvent('onfocus', () => {
                    if (this.g_ClickedMapData) {
                        this.selectMap(this.g_ClickedMapData, false);
                    } else {
                        this.clearMapSelectionVisuals(); 
                        this.selectMap({
                            chapter_number: chId,
                            title: $.Localize(`#portal2_Chapter${chId}_Title`) || chapter.title,
                            subtitle: "", status_text_list: [], command_deactivated: true, is_chapter: true, required_item_icons: []
                        }, false);
                    }
                });

                entry.style.flowChildren = "none";
                const textWrapper = $.CreatePanel('Panel', entry, '');
                textWrapper.style.flowChildren = "down";
                textWrapper.style.verticalAlign = "center";

                const title = $.CreatePanel('Label', textWrapper, `ChapterTitle_${chId}`) as LabelPanel;
                title.AddClass('ChapterTitle');

                const desc = $.CreatePanel('Label', textWrapper, `ChapterSubtitle_${chId}`) as LabelPanel;
                desc.AddClass('ChapterSubtitle');

                const statusLabel = $.CreatePanel('Label', entry, `ChapterStatus_${chId}`) as LabelPanel;
                statusLabel.style.verticalAlign = "center";
                statusLabel.style.horizontalAlign = "right";
                statusLabel.style.marginRight = "15px";
            }

            const chStatus = entry.FindChildTraverse('ChapterStatus_' + chId) as LabelPanel;
            if (chStatus && chStatus.IsValid()) {
                if (chapter.all_completed) {
                    chStatus.text = "check";
                    chStatus.visible = true;
                    this.updateChapterStyle(chStatus, 1, 1, true);
                } else if (chapter.progress_text && !isHidingCounts) {
                    chStatus.text = chapter.progress_text;
                    chStatus.visible = true;
                    this.updateChapterStyle(chStatus, chapter.valid_count || 0, chapter.total_count || 0, false);
                } else chStatus.visible = false;
            }

            const chTitle = entry.FindChildTraverse('ChapterTitle_' + chId) as LabelPanel;
            if (chTitle && chTitle.IsValid()) chTitle.text = $.Localize(`#portal2_Chapter${chId}_Title`) || chapter.title;

            const chDesc = entry.FindChildTraverse('ChapterSubtitle_' + chId) as LabelPanel;
            if (chDesc && chDesc.IsValid()) chDesc.text = $.Localize(`#portal2_Chapter${chId}_Subtitle`) || chapter.subtitle || "";

            let mapList = container.FindChild(`ChapterMaps_${chId}`);
            if (!mapList || !mapList.IsValid()) {
                mapList = $.CreatePanel('Panel', container, `ChapterMaps_${chId}`);
                mapList.AddClass('map_list');
                mapList.AddClass('hide');
            }

            if (chapter.maps) {
                chapter.maps.forEach((map: any, index: number) => {
                    let wrapper = mapList.FindChild(`MapWrapper_${chId}_${index}`);
                    let mapBtn: any = wrapper ? wrapper.FindChild(`MapButton_${chId}_${index}`) : null;

                    if (!wrapper || !wrapper.IsValid() || !mapBtn || !mapBtn.IsValid()) {
                        if (wrapper && wrapper.IsValid()) wrapper.DeleteAsync(0);

                        wrapper = $.CreatePanel('Panel', mapList, `MapWrapper_${chId}_${index}`);
                        wrapper.AddClass('map_button_wrapper');
                        (wrapper as any).canfocus = true;

                        mapBtn = $.CreatePanel('Panel', wrapper, `MapButton_${chId}_${index}`);
                        mapBtn.AddClass('map_button');

                        wrapper.SetPanelEvent('onmouseover', () => {
                            if (ArchipelagoMapSelect.g_IsTransitioning) return;

                            const currentData = (wrapper as any).m_MapData;
                            if (this.g_ResetSchedule) { $.CancelScheduled(this.g_ResetSchedule); this.g_ResetSchedule = null; }
                            $.PlaySoundEvent('UIPanorama.P2CE.MenuFocus');
                            
                            this.selectMap(currentData, false);
                        });

                        wrapper.SetPanelEvent('onmouseout', () => {
                            if (ArchipelagoMapSelect.g_IsTransitioning) return;

                            if (this.g_ResetSchedule) { $.CancelScheduled(this.g_ResetSchedule); this.g_ResetSchedule = null; }
                            this.g_ResetSchedule = $.Schedule(0.15, () => {
                                if (this.g_ClickedMapData) {
                                    this.selectMap(this.g_ClickedMapData, true);
                                } else {
                                    const openCh = this.g_ChapterData[this.g_OpenChapterId || chId];
                                    if (openCh) {
                                        this.selectMap({
                                            chapter_number: this.g_OpenChapterId || chId,
                                            title: $.Localize(`#portal2_Chapter${this.g_OpenChapterId || chId}_Title`) || openCh.title,
                                            subtitle: "", status_text_list: [], command_deactivated: true, is_chapter: true, required_item_icons: []
                                        }, false);
                                    }
                                }
                                this.restoreActiveSelectionVisuals(); 
                                this.g_ResetSchedule = null;
                            });
                        });

                        wrapper.SetPanelEvent('onactivate', () => {
                            const currentData = (wrapper as any).m_MapData;
                            if (this.g_ResetSchedule) { $.CancelScheduled(this.g_ResetSchedule); this.g_ResetSchedule = null; }
                            $.PlaySoundEvent('UIPanorama.P2CE.MenuAccept');
                            
                            this.g_ClickedMapData = currentData; 
                            this.g_SelectedMapData = currentData; 
                            this.selectMap(currentData, true);
                            this.restoreActiveSelectionVisuals();

                            if (this.isController()) this.playSelectedMap();
                        });

                        wrapper.SetPanelEvent('oncancel', () => {
                            $.PlaySoundEvent('UIPanorama.P2CE.MenuCancel');
                            this.toggleChapter(chId);
                            const chE = $('#ChapterWrapper_' + chId);
                            if (chE && chE.IsValid()) chE.SetFocus();
                        });

                        wrapper.SetPanelEvent('onfocus', () => {
                            const currentData = (wrapper as any).m_MapData;
                            if (this.g_ResetSchedule) { $.CancelScheduled(this.g_ResetSchedule); this.g_ResetSchedule = null; }
                            
                            this.g_ClickedMapData = currentData;
                            this.g_SelectedMapData = currentData; 
                            this.selectMap(currentData, false);
                            this.restoreActiveSelectionVisuals();
                        });

                        const mapContent = $.CreatePanel('Panel', mapBtn, '');
                        mapContent.AddClass('map-title-container');
                        const nameLabel = $.CreatePanel('Label', mapContent, `MapName_${chId}_${index}`) as LabelPanel;
                        nameLabel.AddClass('MapPrimaryName');

                        const progressLabel = $.CreatePanel('Label', mapBtn, `MapProgress_${chId}_${index}`) as LabelPanel;
                        progressLabel.style.verticalAlign = "center";
                        progressLabel.style.marginRight = "10px";

                        const lockIcon = $.CreatePanel('Image', mapBtn, `MapLock_${chId}_${index}`) as ImagePanel;
                        lockIcon.AddClass('MapLockIcon');
                        lockIcon.SetAttributeString('scaling', 'stretch-to-fit-preserve-aspect');
                    }

                    (wrapper as any).m_MapData = map; 
                    const isDeactivated = map.command_deactivated !== null && map.command_deactivated !== false && map.command_deactivated !== undefined;

                    if (isDeactivated) {
                        wrapper.enabled = false;
                        (wrapper as any).canfocus = false;
                        mapBtn.AddClass('map_button--deactivated');
                    } else {
                        wrapper.enabled = true;
                        (wrapper as any).canfocus = true;
                        mapBtn.RemoveClass('map_button--deactivated');
                    }

                    if (this.g_ClickedMapData && map.command === this.g_ClickedMapData.command) {
                        mapBtn.AddClass('map_button--selected');
                    } else {
                        mapBtn.RemoveClass('map_button--selected');
                    }

                    const nameLabel = mapBtn.FindChildTraverse(`MapName_${chId}_${index}`) as LabelPanel;
                    if (nameLabel && nameLabel.IsValid()) {
                        let listCodeName = map.title || "";
                        nameLabel.text = $.Localize(`#portal2_MapName_${listCodeName}`);
                    }

                    const progressLabel = mapBtn.FindChildTraverse(`MapProgress_${chId}_${index}`) as LabelPanel;
                    if (progressLabel && progressLabel.IsValid()) {
                        if (map.progress_text && !isHidingCounts && !isDeactivated) {
                            progressLabel.text = map.progress_text;
                            progressLabel.visible = true;
                            this.updateChapterStyle(progressLabel, map.valid_count || 0, map.total_count || 0, false);
                        } else if (map.completed && !isDeactivated) {
                            progressLabel.text = "check";
                            progressLabel.visible = true;
                            this.updateChapterStyle(progressLabel, 1, 1, true);
                        } else progressLabel.visible = false;
                    }

                    const lockIcon = mapBtn.FindChildTraverse(`MapLock_${chId}_${index}`) as ImagePanel;
                    if (lockIcon && lockIcon.IsValid()) {
                        // Nettoyage explicite des classes mutuellement exclusives pour éviter les conflits d'alignement/rendu du layout
                        lockIcon.RemoveClass('icon--locked');
                        lockIcon.RemoveClass('icon--unlocked');
                        
                        lockIcon.SetImage(isDeactivated ? 'file://{images}/archipelago/lock-solid.svg' : 'file://{images}/archipelago/unlock-solid.svg');
                        lockIcon.AddClass(isDeactivated ? 'icon--locked' : 'icon--unlocked');
                    }
                });
            }
        }
    }

    static showHelp() {
        $.PlaySoundEvent('UIPanorama.P2CE.MenuAccept');
        UiToolkitAPI.ShowCustomLayoutPopup('', 'file://{resources}/layout/modals/archipelago/help-popup.xml');
    }
}

Object.assign($.GetContextPanel(), { ArchipelagoMapSelect });