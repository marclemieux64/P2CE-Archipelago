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
        $( '#ConsoleHelpTooltip' )?.AddClass('visible');
    }

    static onConsoleBlur() {
        $( '#ConsoleHelpTooltip' )?.RemoveClass('visible');
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
        
        const overlay = $.GetContextPanel().FindChildTraverse('NotConnectedOverlay');
        const content = $.GetContextPanel().FindChildTraverse('ConnectedContent');
        
        if (!overlay) return;

        let overlayLabel = overlay.FindChildTraverse('NotConnectedLabel');
        let overlayButton = null;

        const children = overlay.Children();
        for (let i = 0; i < children.length; i++) {
            if (children[i].paneltype === "Label" && !overlayLabel) {
                overlayLabel = children[i];
            }
            if (children[i].paneltype === "Button" && !overlayButton) {
                overlayButton = children[i];
            }
        }

        if (!api || (status && status.client_offline)) {
            overlay.RemoveClass('hide');
            if (content) content.AddClass('hide');
            if (overlayButton) overlayButton.AddClass('hide'); 
            
            if (overlayLabel) {
                overlayLabel.text = $.Localize("#Archipelago_Status_NoClient") + "\n" + $.Localize("#Archipelago_Status_LaunchClient");
                overlayLabel.style.color = "#ffbb00"; 
            }
        } else if (!status) {
            overlay.RemoveClass('hide');
            if (content) content.AddClass('hide');
            if (overlayButton) overlayButton.AddClass('hide'); 
            
            if (overlayLabel) {
                overlayLabel.text = $.Localize("#Archipelago_Status_Loading");
                overlayLabel.style.color = "#eeeeee"; 
            }
        } else if (!status.connected) {
            overlay.RemoveClass('hide');
            if (content) content.AddClass('hide');
            if (overlayButton) overlayButton.RemoveClass('hide'); 
            
            if (overlayLabel) {
                overlayLabel.text = $.Localize("#Archipelago_Status_NotConnected");
                overlayLabel.style.color = "#ff4444"; 
            }
        } else {
            overlay.AddClass('hide');
            if (content) content.RemoveClass('hide');
        }
    }

    static onLoad() {
        $.DispatchEvent('MainMenuSetPageLines', $.Localize('#Archipelago_Maps_Title'), $.Localize('#Archipelago_Maps_Tagline'));

        const syncInputMode = () => {
            $.GetContextPanel().SetHasClass('is-controller-mode', this.isController());
            $.Schedule(1.0, syncInputMode);
        };
        syncInputMode();

        $.Schedule(0.1, () => {
            const playButton = $('#PlayButton');
            if (playButton) {
                playButton.enabled = false;
                playButton.RemoveClass('play_button--active');
            }

            const container = $('#LeftListInner');
            if (container && container.GetChildCount() > 0) {
                container.GetChild(0).SetFocus();
            }
        });

        const syncHelper = (UiToolkitAPI.GetGlobalObject() as any).ArchipelagoSync;
        if (syncHelper && syncHelper.ENABLE_DEBUG) $.Msg("[AP] MapSelect using helper v" + syncHelper.VERSION);

        const api = (UiToolkitAPI.GetGlobalObject() as any).ArchipelagoAPI;
        if (api) {
            const updateFromApi = (json: string) => {
                if (json === this.g_LastApiJson) return;
                this.g_LastApiJson = json;

                this.updateConnectionState();

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
                            this.g_ChapterData = syncHelper ? syncHelper.parseApiStatus(status) : {};
                            
                            const savedChapter = this.g_OpenChapterId;
                            const savedCommand = this.g_SelectedMapCommand;

                            this.generateList();

                            if (savedChapter) {
                                const mapList = $('#ChapterMaps_' + savedChapter);
                                const entry = $('#ChapterEntry_' + savedChapter);
                                if (mapList && entry) {
                                    entry.AddClass('chapter_entry--active');
                                    mapList.RemoveClass('hide');
                                    mapList.style.height = 'fit-children';
                                    mapList.style.opacity = '1.0';
                                }
                            }

                            if (savedCommand) {
                                for (const chId in this.g_ChapterData) {
                                    for (const map of this.g_ChapterData[chId].maps) {
                                        const cmd = map.command || map.command_deactivated || "";
                                        if (cmd === savedCommand) {
                                            const rawTitle = map.title || "Unknown Map";
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

                                            this.selectMap({ 
                                                ...map, 
                                                title: finalMapName, 
                                                subtitle: map.subtitle || "", 
                                                status: statusIcons, 
                                                is_chapter: false 
                                            });
                                            break;
                                        }
                                    }
                                }
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
        if (mainBox) {
            $.RegisterKeyBind(mainBox, "key_c", () => {
                this.toggleConsole();
            });
        }

        this.updateConnectionState();
    }

    static runTransition(openPanel: any, closePanel: any, clickedEntry: any, scrollContainer: any) {
        const duration = 0.3;
        const startTime = Date.now();

        // FIX : Vérification d'intégrité avant de lire les hauteurs
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
            // FIX CRITIQUE : Si les panneaux ont été détruits par un rafraichissement pendant l'animation, on annule l'animation !
            if ((closePanel && !closePanel.IsValid()) || (openPanel && !openPanel.IsValid())) {
                return;
            }

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
                if (clickedEntry && clickedEntry.IsValid()) {
                    clickedEntry.SetFocus();
                }
            }
        };
        step();
    }

    static toggleChapter(chapterId: string) {
        const container = $('#LeftListInner');
        const scrollContainer = $('#LeftList');
        if (!container || !scrollContainer) return;

        const mapList = container.FindChild(`ChapterMaps_${chapterId}`);
        if (mapList) {
            const entry = $('#ChapterEntry_' + chapterId);
            const bOpening = mapList.HasClass('hide');

            for (const child of container.Children()) {
                if (child.id.startsWith('ChapterEntry_')) {
                    child.RemoveClass('chapter_entry--active');
                }
            }

            let activePanel = null;
            for (const child of container.Children()) {
                if (child.id.startsWith('ChapterMaps_') && !child.HasClass('hide')) {
                    if (child.id !== `ChapterMaps_${chapterId}`) {
                        activePanel = child;
                    }
                }
            }

            if (bOpening) {
                this.g_OpenChapterId = chapterId; 

                entry.AddClass('chapter_entry--active');
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
                title: $.Localize(`#portal2_Chapter${chapterId}_Title`) || chapter.title || "Chapter " + chapterId,
                subtitle: "",
                status: "",
                command_deactivated: true,
                is_chapter: true
            });
        }
    }

    static selectMap(mapData: any) {
        const previewImage = $('#PreviewImage') as ImagePanel;
        const statusLabel = $('#MapStatusIconsPreview') as LabelPanel;
        const mapSubtitleLabel = $('#MapSubtitleLabel') as LabelPanel;
        const subtitle_secondary = $('#MapSubtitleLabel_Secondary') as LabelPanel;

        const logicHelper = (UiToolkitAPI.GetGlobalObject() as any).ArchipelagoLogic;

        if (subtitle_secondary) {
            subtitle_secondary.text = logicHelper ? logicHelper.formatSubtitle(mapData.subtitle || "") : (mapData.subtitle || "");
        }

        const checks = $('#ChecksColumn');
        const reqs = $('#RequirementsColumn');
        const playButton = $('#PlayButton');
        const missingItemsHeader = $('#MissingItemsHeader');
        const checksHeader = $('#ChecksHeader');

        if (previewImage) {
            let picPath = mapData.pic || "menu/p2ce-generic";
            if (picPath.startsWith('vgui/chapters/')) {
                picPath = `archipelago/${picPath.substring('vgui/chapters/'.length)}`;
            }
            previewImage.SetImage(`file://{images}/${picPath}.png`);
        }

        if (statusLabel) {
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
        if (mapSubtitleLabel) mapSubtitleLabel.text = mapData.title || "";

        const showDetails = !mapData.is_chapter;
        if (checks) checks.visible = showDetails;
        if (reqs) reqs.visible = showDetails;
        if (missingItemsHeader) missingItemsHeader.style.visibility = showDetails ? 'visible' : 'collapse';
        if (checksHeader) checksHeader.style.visibility = showDetails ? 'visible' : 'collapse';
        if (playButton) playButton.visible = showDetails;

        if (playButton) {
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

    static generateList() {
        const container = $('#LeftListInner');
        if (!container) return;
        container.RemoveAndDeleteChildren();

        const syncHelper = (UiToolkitAPI.GetGlobalObject() as any).ArchipelagoSync;
        const api = (UiToolkitAPI.GetGlobalObject() as any).ArchipelagoAPI;
        const status = api ? api.getStatus() : null;
        const isConnected = status && status.connected;

        if (!this.g_ChapterData || Object.keys(this.g_ChapterData).length === 0) {
            const entry = $.CreatePanel('Panel', container, '');
            entry.AddClass('error_entry');
            const label = $.CreatePanel('Label', entry, '');
            
            if (!api || (status && status.client_offline)) {
                label.text = $.Localize("#Archipelago_Status_NoClient") + "\n" + $.Localize("#Archipelago_Status_LaunchClient");
                label.style.color = "#ffbb00"; 
            } else if (!status) {
                label.text = $.Localize("#Archipelago_Status_Loading");
                label.style.color = "#eeeeee";
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

        const completionSymbol = ArchipelagoMapSelect.getCompletionSymbol();
        const sortedKeys = Object.keys(this.g_ChapterData).sort((a, b) => parseInt(a) - parseInt(b));

        for (const chId of sortedKeys) {
            const chapter = this.g_ChapterData[chId];
            const entry = $.CreatePanel('Panel', container, `ChapterEntry_${chId}`);
            entry.AddClass('chapter_entry');
            (entry as any).canfocus = true;

            entry.SetPanelEvent('onmouseover', () => $.PlaySoundEvent('UIPanorama.P2CE.MenuFocus'));
            entry.SetPanelEvent('onactivate', () => {
                $.PlaySoundEvent('UIPanorama.P2CE.MenuAccept');
                this.toggleChapter(chId);
            });
            entry.SetPanelEvent('onfocus', () => {
                this.selectMap({
                    pic: chapter.pic,
                    title: $.Localize(`#portal2_Chapter${chId}_Title`) || chapter.title || "Chapter " + chId,
                    subtitle: "",
                    status: "",
                    command_deactivated: true,
                    is_chapter: true
                });
            });

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

            // PREMIER PASSAGE : on calcule les stats complètes du chapitre
            chapter.maps.forEach((map: any) => {
                if (map.command_deactivated) return;
                
                const rawTitle = map.title || "Unknown Map";
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
                    const index = charCounts[char]++;
                    const status = syncHelper ? syncHelper.getIndicatorStatus(char, mapCmdName, mItems, index) : { isCompleted: false, isAvailable: true };
                    if (status.isAvailable && !status.isCompleted) chapterGreenCount++;
                    if (!status.isCompleted) chapterTotalCount++;
                }
            });

            // AFFICHAGE DU HEADER DU CHAPITRE
            if (mapsCompletedCount === mapsWithIconsCount && mapsWithIconsCount > 0) {
                const chStarLabel = $.CreatePanel('Label', entry, '');
                chStarLabel.text = completionSymbol;
                chStarLabel.style.color = "#ffff44";
                chStarLabel.style.fontSize = "26px";
                chStarLabel.style.fontFamily = "APPortal-bold";
                chStarLabel.style.verticalAlign = "center";
                chStarLabel.style.horizontalAlign = "right";
                chStarLabel.style.marginRight = "15px";
            } else if (chapterTotalCount > 0 && ($.persistentStorage.getItem('HideLocationCounts') ?? 0) === 0) {
                const chGreenLabel = $.CreatePanel('Label', entry, '');
                chGreenLabel.text = `${chapterGreenCount}/${chapterTotalCount}`;
                let color = "#ff4444"; 
                if (chapterGreenCount === chapterTotalCount) color = "#44ff44"; 
                else if (chapterGreenCount > 0) color = "#ffff44"; 
                chGreenLabel.style.color = color;
                chGreenLabel.style.fontSize = "22px";
                chGreenLabel.style.fontFamily = "APPortal-bold";
                chGreenLabel.style.verticalAlign = "center";
                chGreenLabel.style.horizontalAlign = "right";
                chGreenLabel.style.marginRight = "15px";
            }

            entry.style.flowChildren = "none";
            const textWrapper = $.CreatePanel('Panel', entry, '');
            textWrapper.style.flowChildren = "down";
            textWrapper.style.verticalAlign = "center";
            const title = $.CreatePanel('Label', textWrapper, '');
            title.text = $.Localize(`#portal2_Chapter${chId}_Title`) || chapter.title || "Chapter " + chId;
            title.AddClass('ChapterTitle');
            const desc = $.CreatePanel('Label', textWrapper, '');
            desc.text = $.Localize(`#portal2_Chapter${chId}_Subtitle`) || chapter.subtitle || "";
            desc.AddClass('ChapterSubtitle');

            const mapList = $.CreatePanel('Panel', container, `ChapterMaps_${chId}`);
            mapList.AddClass('map_list');
            mapList.AddClass('hide');

            // DEUXIÈME PASSAGE : Création des cartes individuelles
            chapter.maps.forEach((map: any) => {
                const mapBtn = $.CreatePanel('Panel', mapList, '');
                mapBtn.AddClass('map_button');
                (mapBtn as any).canfocus = true;
                if (map.command_deactivated) {
                    mapBtn.enabled = false;
                    mapBtn.AddClass('map_button--deactivated');
                    (mapBtn as any).canfocus = false;
                }
                const rawTitle = map.title || "Unknown Map";
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

                const onSelect = () => {
                    this.selectMap({ ...map, title: finalMapName, subtitle: map.subtitle || "", status: statusIcons, is_chapter: false });
                };
                mapBtn.SetPanelEvent('onmouseover', () => $.PlaySoundEvent('UIPanorama.P2CE.MenuFocus'));
                mapBtn.SetPanelEvent('onactivate', () => {
                    $.PlaySoundEvent('UIPanorama.P2CE.MenuAccept');
                    onSelect();
                    if (this.isController()) this.playSelectedMap();
                });
                mapBtn.SetPanelEvent('onfocus', onSelect);

                const mapContent = $.CreatePanel('Panel', mapBtn, '');
                mapContent.AddClass('map-title-container');
                const nameLabel = $.CreatePanel('Label', mapContent, '');
                nameLabel.text = finalMapName;
                nameLabel.AddClass('MapPrimaryName');

                let mapGreenCount = 0;
                let mapTotalLeft = 0;
                const charCounts: { [key: string]: number } = {};
                for (let i = 0; i < statusIcons.length; i++) {
                    const char = statusIcons[i];
                    if (!charCounts[char]) charCounts[char] = 0;
                    const index = charCounts[char]++;
                    const status = syncHelper ? syncHelper.getIndicatorStatus(char, mapCmdName, mItems, index) : { isCompleted: false, isAvailable: true };
                    if (status.isAvailable && !status.isCompleted) mapGreenCount++;
                    if (!status.isCompleted) mapTotalLeft++;
                }

                if (mapTotalLeft > 0 && ($.persistentStorage.getItem('HideLocationCounts') ?? 0) === 0 && !map.command_deactivated) {
                    const progressLabel = $.CreatePanel('Label', mapBtn, '');
                    progressLabel.text = `${mapGreenCount}/${mapTotalLeft}`;
                    let color = "#ff4444"; 
                    if (mapGreenCount === mapTotalLeft) color = "#44ff44"; 
                    else if (mapGreenCount > 0) color = "#ffff44"; 
                    progressLabel.style.color = color;
                    progressLabel.style.fontSize = "22px";
                    progressLabel.style.fontFamily = "APPortal-bold";
                    progressLabel.style.verticalAlign = "center";
                    progressLabel.style.marginRight = "10px";
                } else if (map._isComplete && !map.command_deactivated) {
                    const starLabel = $.CreatePanel('Label', mapBtn, '');
                    starLabel.text = completionSymbol;
                    starLabel.style.color = "#ffff44";
                    starLabel.style.fontSize = "26px";
                    starLabel.style.fontFamily = "APPortal-bold";
                    starLabel.style.verticalAlign = "center";
                    starLabel.style.marginRight = "10px";
                }
                const lockIcon = $.CreatePanel('Image', mapBtn, '');
                lockIcon.AddClass('MapLockIcon');
                (lockIcon as ImagePanel).SetAttributeString('scaling', 'stretch-to-fit-preserve-aspect');
                if (map.command_deactivated) {
                    (lockIcon as ImagePanel).SetImage('file://{images}/archipelago/lock-solid.tga');
                    lockIcon.AddClass('icon--locked');
                } else {
                    (lockIcon as ImagePanel).SetImage('file://{images}/archipelago/unlock-solid.tga');
                    lockIcon.AddClass('icon--unlocked');
                }
            });
        }
    }

    static showHelp() {
        UiToolkitAPI.ShowCustomLayoutPopup('', 'file://{resources}/layout/modals/archipelago/help-popup.xml');
    }
}

Object.assign($.GetContextPanel(), { ArchipelagoMapSelect });