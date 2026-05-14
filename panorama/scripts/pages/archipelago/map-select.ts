'use strict';

declare var $: any;
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
    static g_ResetSchedule: any = null;

    static isController() {
        let p = $.GetContextPanel();
        while (p) {
            if (p.id === 'MainMenu' || p.HasClass('MainMenuRootPanel')) {
                return p.HasClass('InputController');
            }
            p = p.GetParent();
        }
        return false;
    }

    static isSymbolMissingGlobally(symbol: string): boolean {
        for (const chId in this.g_ChapterData) {
            const chapter = this.g_ChapterData[chId];
            if (chapter.maps) {
                for (const map of chapter.maps) {
                    if (map.subtitle && map.subtitle.indexOf(symbol) !== -1) {
                        return true;
                    }
                }
            }
        }
        return false; 
    }

    static onConsoleFocus() {
        $.PlaySoundEvent('UIPanorama.P2CE.MenuFocus');
        const tooltip = $('#ConsoleHelpTooltip');
        if (tooltip && tooltip.IsValid()) {
            tooltip.AddClass('visible');
        }
    }

    static onConsoleBlur() {
        const tooltip = $('#ConsoleHelpTooltip');
        if (tooltip && tooltip.IsValid()) {
            tooltip.RemoveClass('visible');
        }
    }

    static toggleConsole() {
        const api = (UiToolkitAPI.GetGlobalObject() as any).ArchipelagoAPI;
        if (!api || !api.getStatus()) return; 

        $.PlaySoundEvent('UIPanorama.P2CE.MenuAccept');
        $.DispatchEvent('MainMenuOpenNestedPage', 'ap_console', 'archipelago/console', undefined);
    }

    static onConsoleLoad() {
        $.DispatchEvent('MainMenuSetPageLines', $.Localize('#Archipelago_Console_Title'), $.Localize('#Archipelago_Console_Tagline'));
        
        const global = (UiToolkitAPI.GetGlobalObject() as any);
        if (global.ArchipelagoConsole) {
            global.ArchipelagoConsole.init();
        }
    }

    static getCompletionSymbol(): string {
        return ($.persistentStorage.getItem('ap_completion_symbol') ?? 0) === 1 ? "\u2605" : "\u2713";
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
            if (children[i].paneltype === "Label" && (!overlayLabel || !overlayLabel.IsValid())) {
                overlayLabel = children[i];
            }
            if (children[i].paneltype === "Button" && (!overlayButton || !overlayButton.IsValid())) {
                overlayButton = children[i];
            }
        }

        if (!api || (status && status.client_offline)) {
            overlay.RemoveClass('hide');
            if (content && content.IsValid()) content.AddClass('hide');
            if (overlayButton && overlayButton.IsValid()) overlayButton.AddClass('hide'); 
            
            if (overlayLabel && overlayLabel.IsValid()) {
                overlayLabel.text = $.Localize("#Archipelago_Status_NoClient") + "\n" + $.Localize("#Archipelago_Status_LaunchClient");
                overlayLabel.style.color = "#ffbb00"; 
            }
        } else if (!status) {
            overlay.RemoveClass('hide');
            if (content && content.IsValid()) content.AddClass('hide');
            if (overlayButton && overlayButton.IsValid()) overlayButton.AddClass('hide'); 
            
            if (overlayLabel && overlayLabel.IsValid()) {
                overlayLabel.text = $.Localize("#Archipelago_Status_Loading");
                overlayLabel.style.color = "#eeeeee"; 
            }
        } else if (!status.connected) {
            overlay.RemoveClass('hide');
            if (content && content.IsValid()) content.AddClass('hide');
            if (overlayButton && overlayButton.IsValid()) overlayButton.RemoveClass('hide'); 
            
            if (overlayLabel && overlayLabel.IsValid()) {
                overlayLabel.text = $.Localize("#Archipelago_Status_NotConnected");
                overlayLabel.style.color = "#ff4444"; 
            }
        } else {
            overlay.AddClass('hide');
            if (content && content.IsValid()) content.RemoveClass('hide');
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

        const syncHelper = (UiToolkitAPI.GetGlobalObject() as any).ArchipelagoSync;
        if (syncHelper && syncHelper.ENABLE_DEBUG) $.Msg("[AP] MapSelect using helper v" + syncHelper.VERSION);

        const api = (UiToolkitAPI.GetGlobalObject() as any).ArchipelagoAPI;
        if (api) {
            const updateFromApi = (json: string) => {
                this.updateConnectionState();

                if (json === this.g_LastApiJson) return;
                this.g_LastApiJson = json;

                try {
                    const status = JSON.parse(json);
                    if (status) {
                        const connected = !!status.connected;

                        if (!connected) {
                            this.g_ChapterData = {};
                            this.generateList();
                            return;
                        }

                        if (status.menu) {
                            // FIX: Permet de savoir s'il s'agit du tout premier chargement pour ne pas voler le focus du joueur.
                            const isFirstLoad = Object.keys(this.g_ChapterData).length === 0;

                            this.g_ChapterData = syncHelper ? syncHelper.parseApiStatus(status) : {};
                            
                            const savedChapter = this.g_OpenChapterId;
                            const savedCommand = this.g_SelectedMapCommand;

                            this.generateList();

                            // Ne forcer le focus sur le premier élément qu'au premier chargement.
                            if (isFirstLoad) {
                                $.Schedule(0.05, () => {
                                    const container = $('#LeftListInner');
                                    if (container && container.IsValid() && container.GetChildCount() > 0) {
                                        container.GetChild(0).SetFocus(); 
                                    } else {
                                        const cp = $.GetContextPanel();
                                        if (cp && cp.IsValid()) {
                                            cp.SetAcceptsFocus(true);
                                            cp.SetFocus();
                                        }
                                    }
                                });
                            }

                            if (savedChapter) {
                                const mapList = $('#ChapterMaps_' + savedChapter);
                                const entry = $('#ChapterEntry_' + savedChapter);
                                if (mapList && mapList.IsValid() && entry && entry.IsValid()) {
                                    entry.AddClass('chapter_entry--active');
                                    mapList.RemoveClass('hide');
                                    mapList.style.height = 'fit-children';
                                    mapList.style.opacity = '1.0';
                                }
                            }

                            if (savedCommand) {
                                this.restoreSelection(savedCommand);
                            }
                        }
                    } 
                } catch (e) {
                    $.Warning("[AP] Error updating MapSelect from API: " + e);
                }
            };
            $.RegisterForUnhandledEvent("ArchipelagoAPI_StatusUpdated", updateFromApi);
            if (api.getStatus()) {
                updateFromApi(JSON.stringify(api.getStatus()));
            }
        }

        const mainBox = $.GetContextPanel().FindChildTraverse('MainBox');
        if (mainBox && mainBox.IsValid()) {
            $.RegisterKeyBind(mainBox, "key_c", () => {
                this.toggleConsole();
            });
            $.RegisterKeyBind(mainBox, "pad_y", () => {
                if (this.isController()) this.toggleConsole();
            });
        }
    }

    static restoreSelection(savedCommand: string) {
        for (const chId in this.g_ChapterData) {
            for (const map of this.g_ChapterData[chId].maps) {
                const cmd = map.command || map.command_deactivated || "";
                if (cmd === savedCommand) {
                    const rawTitle = map.title || $.Localize("#Archipelago_Map_Unknown");
                    let statusIcons = (map.statusIcons || "").replace(/[~\-]/g, "").trim();
                    let cleanName = rawTitle;
                    
                    if (!statusIcons && rawTitle.length > 4 && (rawTitle.startsWith("~") || rawTitle.startsWith("-") || rawTitle.startsWith("═"))) {
                        statusIcons = rawTitle.substring(0, 4).replace(/[~\-]/g, "").trim();
                        cleanName = rawTitle.substring(4).trim();
                    }
                    
                    let mapCmdName = "";
                    if (cmd) {
                        const parts = cmd.split(" ");
                        if (parts.length >= 2) mapCmdName = parts[1].trim().toLowerCase();
                    }
                    
                    const mapToken = `#portal2_MapName_${mapCmdName}`;
                    const localizedMapName = $.Localize(mapToken);
                    const finalMapName = (localizedMapName !== mapToken) ? localizedMapName : cleanName;

                    const mapData = { 
                        ...map, 
                        title: finalMapName, 
                        subtitle: map.subtitle || "", 
                        status: statusIcons, 
                        command: cmd,
                        is_chapter: false 
                    };
                    this.g_SelectedMapData = mapData;
                    this.selectMap(mapData, true);
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

            const now = Date.now();
            const elapsed = (now - startTime) / 1000;
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

            if (progress < 1.0) {
                $.Schedule(0.0, step);
            } else {
                if (closePanel && closePanel.IsValid()) {
                    closePanel.AddClass('hide');
                    closePanel.style.height = '0px';
                }
                if (openPanel && openPanel.IsValid()) {
                    openPanel.style.height = 'fit-children';
                    openPanel.style.opacity = '1.0';
                }
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

            for (const child of container.Children()) {
                if (child.id.startsWith('ChapterEntry_')) child.RemoveClass('chapter_entry--active');
            }

            let activePanel = null;
            for (const child of container.Children()) {
                if (child.id.startsWith('ChapterMaps_') && !child.HasClass('hide')) {
                    if (child.id !== `ChapterMaps_${chapterId}`) activePanel = child;
                }
            }

            if (bOpening) {
                this.g_OpenChapterId = chapterId; 
                if (entry && entry.IsValid()) entry.AddClass('chapter_entry--active');
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
                pic: chapter.pic,
                title: $.Localize(`#portal2_Chapter${chapterId}_Title`) || chapter.title || $.Localize("#Archipelago_Chapter_Title") + " " + chapterId,
                subtitle: "",
                status: "",
                command_deactivated: true,
                is_chapter: true
            }, false); 
        }
    }

    static selectMap(mapData: any, bShowPlayButton: boolean = true) {
        const previewImage = $('#PreviewImage') as ImagePanel;
        const statusLabel = $('#MapStatusIconsPreview') as LabelPanel;
        const mapSubtitleLabel = $('#MapSubtitleLabel') as LabelPanel;
        const subtitle_secondary = $('#MapSubtitleLabel_Secondary') as LabelPanel;

        const logicHelper = (UiToolkitAPI.GetGlobalObject() as any).ArchipelagoLogic;

        if (subtitle_secondary && subtitle_secondary.IsValid()) {
            subtitle_secondary.text = logicHelper ? logicHelper.formatSubtitle(mapData.subtitle || "") : (mapData.subtitle || "");
        }

        const checks = $('#ChecksColumn');
        const reqs = $('#RequirementsColumn');
        const playButton = $('#PlayButton');
        const missingItemsHeader = $('#MissingItemsHeader');
        const checksHeader = $('#ChecksHeader');

        if (previewImage && previewImage.IsValid()) {
            let picPath = mapData.pic || "menu/p2ce-generic";
            if (picPath.startsWith('vgui/chapters/')) {
                picPath = `archipelago/${picPath.substring('vgui/chapters/'.length)}`;
            }
            previewImage.SetImage(`file://{images}/${picPath}.png`);
        }

        if (statusLabel && statusLabel.IsValid()) {
            const rawStatus = mapData.status || mapData.statusIcons || "";
            let mapCmdName = "";
            if (mapData.command) {
                const parts = mapData.command.split(" ");
                if (parts.length >= 2) mapCmdName = parts[1].trim().toLowerCase();
            }
            const mItems = mapData.subtitle || "";
            const formattedIcons = logicHelper ? logicHelper.getFormattedIcons(rawStatus, mapCmdName, mItems) : [];
            let finalStatusHtml = "";
            for (const iconData of formattedIcons) {
                finalStatusHtml += `<font color="${iconData.color}">${iconData.char}</font>`;
            }
            statusLabel.text = finalStatusHtml;
            statusLabel.style.color = "#eeeeee"; 
        }
        
        if (mapSubtitleLabel && mapSubtitleLabel.IsValid()) {
            mapSubtitleLabel.text = mapData.title || "";
        }

        const showDetails = !mapData.is_chapter;

        // --- POPULATION SÉCURISÉE DES CHECKS (SMART UPDATE) ---
        if (checks && checks.IsValid()) {
            // Nettoie uniquement les labels dynamiques pour protéger le XML
            const children = checks.Children();
            for (let i = children.length - 1; i >= 0; i--) {
                if (children[i].id && children[i].id.startsWith("DynamicLoc_")) {
                    children[i].DeleteAsync(0);
                }
            }
            
            if (showDetails && mapData.location_names) {
                mapData.location_names.forEach((loc: string, index: number) => {
                    const l = $.CreatePanel('Label', checks, `DynamicLoc_${index}`);
                    l.text = loc;
                    l.AddClass('DetailLabel');
                });
            }
            checks.visible = showDetails ? true : false;
        }

        // --- POPULATION SÉCURISÉE DES REQUIREMENTS (SMART UPDATE) ---
        if (reqs && reqs.IsValid()) {
            // Nettoie uniquement les labels dynamiques pour protéger le XML
            const children = reqs.Children();
            for (let i = children.length - 1; i >= 0; i--) {
                if (children[i].id && children[i].id.startsWith("DynamicReq_")) {
                    children[i].DeleteAsync(0);
                }
            }
            
            if (showDetails && mapData.required_items) {
                mapData.required_items.forEach((item: string, index: number) => {
                    const l = $.CreatePanel('Label', reqs, `DynamicReq_${index}`);
                    l.text = item;
                    l.AddClass('DetailLabel');
                });
            }
            reqs.visible = showDetails ? true : false;
        }

        if (missingItemsHeader && missingItemsHeader.IsValid()) {
            missingItemsHeader.style.visibility = showDetails ? 'visible' : 'collapse';
        }
        if (checksHeader && checksHeader.IsValid()) {
            checksHeader.style.visibility = showDetails ? 'visible' : 'collapse';
        }

        if (playButton && playButton.IsValid()) {
            playButton.visible = (showDetails && bShowPlayButton) ? true : false;
            this.g_SelectedMapCommand = mapData.command || mapData.command_deactivated || "";
            if (!mapData.command_deactivated && mapData.command) {
                playButton.enabled = true;
                playButton.AddClass('play_button--active');
            } else {
                playButton.enabled = false;
                playButton.RemoveClass('play_button--active');
            }
        }
    }

    static playSelectedMap() {
        if (this.g_SelectedMapCommand) {
            GameInterfaceAPI.ConsoleCommand(this.g_SelectedMapCommand);
        }
    }

    // --- MISE À JOUR INTELLIGENTE DE LA LISTE ---
    static generateList() {
        const container = $('#LeftListInner');
        if (!container || !container.IsValid()) return;

        const syncHelper = (UiToolkitAPI.GetGlobalObject() as any).ArchipelagoSync;
        const api = (UiToolkitAPI.GetGlobalObject() as any).ArchipelagoAPI;
        const status = api ? api.getStatus() : null;
        const isConnected = status && status.connected;

        if (!this.g_ChapterData || Object.keys(this.g_ChapterData).length === 0) {
            container.RemoveAndDeleteChildren(); 
            const entry = $.CreatePanel('Panel', container, 'ErrorEntry');
            entry.AddClass('error_entry');
            const label = $.CreatePanel('Label', entry, '') as LabelPanel;
            
            if (!api || (status && status.client_offline)) {
                label.text = $.Localize("#Archipelago_Status_NoClient") + "\n" + $.Localize("#Archipelago_Status_LaunchClient");
                label.style.color = "#ffbb00"; 
            } else if (!isConnected) {
                label.text = $.Localize("#Archipelago_Status_NotConnected");
                label.style.color = "#ff4444"; 
            } else {
                label.text = $.Localize("#Archipelago_Status_Loading");
                label.style.color = "#eeeeee";
            }
            
            label.style.fontSize = "22px";
            label.style.fontWeight = "bold";
            label.style.width = "100%";
            label.style.textAlign = "center";
            label.style.marginTop = "20px";
            return;
        }

        const errEntry = container.FindChild('ErrorEntry');
        if (errEntry && errEntry.IsValid()) errEntry.DeleteAsync(0);

        const completionSymbol = ArchipelagoMapSelect.getCompletionSymbol();
        const sortedKeys = Object.keys(this.g_ChapterData).sort((a, b) => parseInt(a) - parseInt(b));

        for (const chId of sortedKeys) {
            const chapter = this.g_ChapterData[chId];
            
            let entry = container.FindChild(`ChapterEntry_${chId}`);
            if (!entry || !entry.IsValid()) {
                entry = $.CreatePanel('Panel', container, `ChapterEntry_${chId}`);
                entry.AddClass('chapter_entry');
                (entry as any).canfocus = true;

                entry.SetPanelEvent('onmouseover', () => {
                    if (this.g_ResetSchedule) { $.CancelScheduled(this.g_ResetSchedule); this.g_ResetSchedule = null; }
                    $.PlaySoundEvent('UIPanorama.P2CE.MenuFocus');
                });

                entry.SetPanelEvent('onmouseout', () => {
                    if (this.g_ResetSchedule) { $.CancelScheduled(this.g_ResetSchedule); this.g_ResetSchedule = null; }
                    this.g_ResetSchedule = $.Schedule(0.15, () => {
                        if (this.g_SelectedMapData) this.selectMap(this.g_SelectedMapData, true);
                        this.g_ResetSchedule = null;
                    });
                });

                entry.SetPanelEvent('onactivate', () => {
                    $.PlaySoundEvent('UIPanorama.P2CE.MenuAccept');
                    this.toggleChapter(chId);
                });

                entry.SetPanelEvent('onfocus', () => {
                    this.selectMap({
                        pic: chapter.pic,
                        title: $.Localize(`#portal2_Chapter${chId}_Title`) || chapter.title || $.Localize("#Archipelago_Chapter_Title") + " " + chId,
                        subtitle: "",
                        status: "",
                        command_deactivated: true,
                        is_chapter: true
                    }, false);
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
                statusLabel.style.fontFamily = "APPortal-bold";
            }

            const uniqueMaps: any[] = [];
            const seenCmds = new Set();
            if (chapter.maps) {
                chapter.maps.forEach((m: any) => {
                    if (m.command && !seenCmds.has(m.command)) {
                        seenCmds.add(m.command);
                        uniqueMaps.push(m);
                    } else if (!m.command) {
                        uniqueMaps.push(m);
                    }
                });
                chapter.maps = uniqueMaps;
            }

            let chapterGreenCount = 0;
            let chapterTotalCount = 0;
            let mapsWithIconsCount = 0;
            let mapsCompletedCount = 0;

            chapter.maps.forEach((map: any) => {
                if (map.command_deactivated) return;
                const rawTitle = map.title || $.Localize("#Archipelago_Map_Unknown");
                let statusIcons = (map.statusIcons || "").replace(/[~\-]/g, "").trim();
                if (!statusIcons && rawTitle.length > 4 && (rawTitle.startsWith("~") || rawTitle.startsWith("-") || rawTitle.startsWith("═"))) {
                    statusIcons = rawTitle.substring(0, 4).replace(/[~\-]/g, "").trim();
                }

                if (statusIcons.length > 0) {
                    mapsWithIconsCount++;
                    const cleanStatus = statusIcons.split(completionSymbol).join("").split("★").join("").split("£").join("").split("✓").join("");
                    if (cleanStatus.length === 0) {
                        mapsCompletedCount++;
                        map._isComplete = true; 
                    } else {
                        map._isComplete = false;
                    }
                }

                const fullCommand = map.command || map.command_deactivated || "";
                let mapCmdName = "";
                if (fullCommand) {
                    const parts = fullCommand.split(" ");
                    if (parts.length >= 2) mapCmdName = parts[1].trim().toLowerCase();
                }
                const mItems = map.subtitle || "";
                const charCounts: { [key: string]: number } = {};
                for (let i = 0; i < statusIcons.length; i++) {
                    const char = statusIcons[i];
                    if (!charCounts[char]) charCounts[char] = 0;
                    const indexIcon = charCounts[char]++;
                    const status = syncHelper ? syncHelper.getIndicatorStatus(char, mapCmdName, mItems, indexIcon) : { isCompleted: false, isAvailable: true };
                    if (status.isAvailable && !status.isCompleted) chapterGreenCount++;
                    if (!status.isCompleted) chapterTotalCount++;
                }
            });

            const chStatus = entry.FindChildTraverse(`ChapterStatus_${chId}`) as LabelPanel;
            if (chStatus && chStatus.IsValid()) {
                if (mapsCompletedCount === mapsWithIconsCount && mapsWithIconsCount > 0) {
                    chStatus.text = completionSymbol;
                    chStatus.style.color = "#ffff44";
                    chStatus.style.fontSize = "26px";
                } else if (chapterTotalCount > 0 && ($.persistentStorage.getItem('HideLocationCounts') ?? 0) === 0) {
                    chStatus.text = `${chapterGreenCount}/${chapterTotalCount}`;
                    chStatus.style.color = (chapterGreenCount === chapterTotalCount) ? "#44ff44" : (chapterGreenCount > 0 ? "#ffff44" : "#ff4444");
                    chStatus.style.fontSize = "22px";
                } else {
                    chStatus.text = "";
                }
            }

            const chTitle = entry.FindChildTraverse(`ChapterTitle_${chId}`) as LabelPanel;
            if (chTitle && chTitle.IsValid()) chTitle.text = $.Localize(`#portal2_Chapter${chId}_Title`) || chapter.title || $.Localize("#Archipelago_Chapter_Title") + " " + chId;

            const chDesc = entry.FindChildTraverse(`ChapterSubtitle_${chId}`) as LabelPanel;
            if (chDesc && chDesc.IsValid()) chDesc.text = $.Localize(`#portal2_Chapter${chId}_Subtitle`) || chapter.subtitle || "";

            let mapList = container.FindChild(`ChapterMaps_${chId}`);
            if (!mapList || !mapList.IsValid()) {
                mapList = $.CreatePanel('Panel', container, `ChapterMaps_${chId}`);
                mapList.AddClass('map_list');
                mapList.AddClass('hide');
            }

            chapter.maps.forEach((map: any, index: number) => {
                const rawTitle = map.title || $.Localize("#Archipelago_Map_Unknown");
                let statusIcons = (map.statusIcons || "").replace(/[~\-]/g, "").trim();
                let cleanName = rawTitle;
                if (!statusIcons && rawTitle.length > 4 && (rawTitle.startsWith("~") || rawTitle.startsWith("-") || rawTitle.startsWith("═"))) {
                    statusIcons = rawTitle.substring(0, 4).replace(/[~\-]/g, "").trim();
                    cleanName = rawTitle.substring(4).trim();
                }
                const fullCommand = map.command || map.command_deactivated || "";
                let mapCmdName = "";
                if (fullCommand) {
                    const parts = fullCommand.split(" ");
                    if (parts.length >= 2) mapCmdName = parts[1].trim().toLowerCase();
                }
                const mItems = map.subtitle || "";
                const mapToken = `#portal2_MapName_${mapCmdName}`;
                const localizedMapName = $.Localize(mapToken);
                const finalMapName = (localizedMapName !== mapToken) ? localizedMapName : cleanName;

                const mapData = { 
                    ...map, 
                    title: finalMapName, 
                    subtitle: map.subtitle || "", 
                    status: statusIcons, 
                    command: fullCommand,
                    is_chapter: false 
                };

                let mapBtn = mapList.FindChild(`MapButton_${chId}_${index}`);
                if (!mapBtn || !mapBtn.IsValid()) {
                    mapBtn = $.CreatePanel('Panel', mapList, `MapButton_${chId}_${index}`);
                    mapBtn.AddClass('map_button');
                    (mapBtn as any).canfocus = true;

                    mapBtn.SetPanelEvent('onmouseover', () => {
                        const currentData = (mapBtn as any).m_MapData;
                        if (this.g_ResetSchedule) { $.CancelScheduled(this.g_ResetSchedule); this.g_ResetSchedule = null; }
                        $.PlaySoundEvent('UIPanorama.P2CE.MenuFocus');
                        this.selectMap(currentData, false); 
                    });

                    mapBtn.SetPanelEvent('onmouseout', () => {
                        if (this.g_ResetSchedule) { $.CancelScheduled(this.g_ResetSchedule); this.g_ResetSchedule = null; }
                        this.g_ResetSchedule = $.Schedule(0.15, () => {
                            if (this.g_SelectedMapData) this.selectMap(this.g_SelectedMapData, true);
                            this.g_ResetSchedule = null;
                        });
                    });

                    mapBtn.SetPanelEvent('onactivate', () => {
                        const currentData = (mapBtn as any).m_MapData;
                        if (this.g_ResetSchedule) { $.CancelScheduled(this.g_ResetSchedule); this.g_ResetSchedule = null; }
                        $.PlaySoundEvent('UIPanorama.P2CE.MenuAccept');
                        this.g_SelectedMapData = currentData; 
                        this.selectMap(currentData, true);

                        const listInner = $('#LeftListInner');
                        if (listInner && listInner.IsValid()) {
                            for (let i = 0; i < listInner.GetChildCount(); i++) {
                                const c = listInner.GetChild(i);
                                if (c && c.IsValid() && c.HasClass('map_list')) {
                                    for (let j = 0; j < c.GetChildCount(); j++) {
                                        const mc = c.GetChild(j);
                                        if (mc && mc.IsValid()) mc.RemoveClass('map_button--selected');
                                    }
                                }
                            }
                        }
                        mapBtn.AddClass('map_button--selected');

                        if (this.isController()) this.playSelectedMap();
                    });
                    
                    mapBtn.SetPanelEvent('oncancel', () => {
                        $.PlaySoundEvent('UIPanorama.P2CE.MenuCancel');
                        this.toggleChapter(chId);
                        const chE = $('#ChapterEntry_' + chId);
                        if (chE && chE.IsValid()) chE.SetFocus();
                    });

                    mapBtn.SetPanelEvent('onfocus', () => {
                        const currentData = (mapBtn as any).m_MapData;
                        if (this.g_ResetSchedule) { $.CancelScheduled(this.g_ResetSchedule); this.g_ResetSchedule = null; }
                        this.selectMap(currentData, false);
                    });

                    const mapContent = $.CreatePanel('Panel', mapBtn, '');
                    mapContent.AddClass('map-title-container');
                    const nameLabel = $.CreatePanel('Label', mapContent, `MapName_${chId}_${index}`) as LabelPanel;
                    nameLabel.AddClass('MapPrimaryName');

                    const progressLabel = $.CreatePanel('Label', mapBtn, `MapProgress_${chId}_${index}`) as LabelPanel;
                    progressLabel.style.verticalAlign = "center";
                    progressLabel.style.marginRight = "10px";
                    progressLabel.style.fontFamily = "APPortal-bold";

                    const lockIcon = $.CreatePanel('Image', mapBtn, `MapLock_${chId}_${index}`) as ImagePanel;
                    lockIcon.AddClass('MapLockIcon');
                    lockIcon.SetAttributeString('scaling', 'stretch-to-fit-preserve-aspect');
                }

                (mapBtn as any).m_MapData = mapData;

                if (map.command_deactivated) {
                    mapBtn.enabled = false;
                    mapBtn.AddClass('map_button--deactivated');
                    (mapBtn as any).canfocus = false;
                } else {
                    mapBtn.enabled = true;
                    mapBtn.RemoveClass('map_button--deactivated');
                    (mapBtn as any).canfocus = true;
                }

                if (this.g_SelectedMapData && this.g_SelectedMapData.command === mapData.command) {
                    mapBtn.AddClass('map_button--selected');
                } else {
                    mapBtn.RemoveClass('map_button--selected');
                }

                const mName = mapBtn.FindChildTraverse(`MapName_${chId}_${index}`) as LabelPanel;
                if (mName && mName.IsValid()) mName.text = finalMapName;

                let mapGreenCount = 0;
                let mapTotalLeft = 0;
                const charCounts: { [key: string]: number } = {};
                for (let i = 0; i < statusIcons.length; i++) {
                    const char = statusIcons[i];
                    if (!charCounts[char]) charCounts[char] = 0;
                    const indexIcon = charCounts[char]++;
                    const status = syncHelper ? syncHelper.getIndicatorStatus(char, mapCmdName, mItems, indexIcon) : { isCompleted: false, isAvailable: true };
                    if (status.isAvailable && !status.isCompleted) mapGreenCount++;
                    if (!status.isCompleted) mapTotalLeft++;
                }

                const mProg = mapBtn.FindChildTraverse(`MapProgress_${chId}_${index}`) as LabelPanel;
                if (mProg && mProg.IsValid()) {
                    if (mapTotalLeft > 0 && ($.persistentStorage.getItem('HideLocationCounts') ?? 0) === 0 && !map.command_deactivated) {
                        mProg.text = `${mapGreenCount}/${mapTotalLeft}`;
                        let color = "#ff4444"; 
                        if (mapGreenCount === mapTotalLeft) color = "#44ff44"; 
                        else if (mapGreenCount > 0) color = "#ffff44"; 
                        mProg.style.color = color;
                        mProg.style.fontSize = "22px";
                        mProg.visible = true;
                    } else if (map._isComplete && !map.command_deactivated) {
                        mProg.text = completionSymbol;
                        mProg.style.color = "#ffff44";
                        mProg.style.fontSize = "26px";
                        mProg.visible = true;
                    } else {
                        mProg.visible = false;
                    }
                }

                const mLock = mapBtn.FindChildTraverse(`MapLock_${chId}_${index}`) as ImagePanel;
                if (mLock && mLock.IsValid()) {
                    if (map.command_deactivated) {
                        mLock.SetImage('file://{images}/archipelago/lock-solid.svg');
                        mLock.AddClass('icon--locked');
                        mLock.RemoveClass('icon--unlocked');
                    } else {
                        mLock.SetImage('file://{images}/archipelago/unlock-solid.svg');
                        mLock.AddClass('icon--unlocked');
                        mLock.RemoveClass('icon--locked');
                    }
                }
            });

            if (mapList && mapList.IsValid()) {
                for (let i = chapter.maps.length; i < mapList.GetChildCount(); i++) {
                    const toDelete = mapList.FindChild(`MapButton_${chId}_${i}`);
                    if (toDelete && toDelete.IsValid()) toDelete.DeleteAsync(0);
                }
            }
        }
    }

    static showHelp() {
        $.PlaySoundEvent('UIPanorama.P2CE.MenuAccept');
        UiToolkitAPI.ShowCustomLayoutPopup('', 'file://{resources}/layout/modals/archipelago/help-popup.xml');
    }
}

Object.assign($.GetContextPanel(), { ArchipelagoMapSelect });