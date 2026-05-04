'use strict';

declare var $: any;
declare var GameInterfaceAPI: any;
interface Panel { [key: string]: any; }
interface ImagePanel extends Panel { }
interface LabelPanel extends Panel { }



class ArchipelagoMapSelect {
    static g_ChapterData: any = {};
    static g_SelectedMapCommand: string = '';

    static isController() {
        let p = $.GetContextPanel();
        while (p) {
            // MainMenu is the root panel where the engine toggles InputController class
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

    static getCompletionSymbol(): string {
        return ($.persistentStorage.getItem('ap_completion_symbol') ?? 0) === 1 ? "★" : "✓";
    }

    static onLoad() {
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

        const extrasKv = $.LoadKeyValuesFile("scripts/extras.txt") || $.LoadKeyValues3File("scripts/extras.txt");
        const data = extrasKv && extrasKv.Extras ? extrasKv.Extras : extrasKv;

        const syncHelper = (UiToolkitAPI.GetGlobalObject() as any).ArchipelagoSync;
        if (syncHelper && syncHelper.ENABLE_DEBUG) $.Msg("[AP] MapSelect using helper v" + syncHelper.VERSION);
        if (data) {
            this.g_ChapterData = syncHelper ? syncHelper.parseExtras(data) : {};
            this.generateList();
        }
    }

    static runTransition(openPanel: any, closePanel: any, clickedEntry: any, scrollContainer: any) {
        const duration = 0.3;
        const startTime = Date.now();

        const openStartH = 0;
        const openEndH = openPanel ? openPanel.actuallayoutheight : 0;
        const closeStartH = closePanel ? closePanel.actuallayoutheight : 0;
        const closeEndH = 0;

        const scrollBar: any = scrollContainer.FindChildTraverse('VerticalScrollBar');
        const startScroll = scrollBar ? scrollBar.ScrollPosition : 0;

        const entryScreenY = clickedEntry.GetPositionWithinWindow().y;
        const containerScreenY = scrollContainer.GetPositionWithinWindow().y;
        const targetScroll = startScroll + (entryScreenY - containerScreenY) - 10;

        const step = () => {
            const now = Date.now();
            const elapsed = (now - startTime) / 1000;
            const progress = Math.min(elapsed / duration, 1.0);
            const ease = progress * (2 - progress);

            if (closePanel) {
                closePanel.style.height = `${closeStartH + (closeEndH - closeStartH) * ease}px`;
                closePanel.style.opacity = `${1.0 - progress}`;
            }

            if (openPanel) {
                openPanel.style.height = `${openStartH + (openEndH - openStartH) * ease}px`;
                openPanel.style.opacity = `${progress}`;
            }

            if (scrollBar) {
                scrollBar.ScrollPosition = startScroll + (targetScroll - startScroll) * ease;
            }

            if (progress < 1.0) {
                $.Schedule(0.0, step);
            } else {
                if (closePanel) {
                    closePanel.AddClass('hide');
                    closePanel.style.height = '0px';
                }
                if (openPanel) {
                    openPanel.style.height = 'fit-children';
                    openPanel.style.opacity = '1.0';
                }
                clickedEntry.SetFocus();
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
                entry.AddClass('chapter_entry--active');
                mapList.RemoveClass('hide');
                mapList.style.height = 'fit-children';
                mapList.style.opacity = '1.0';

                $.Schedule(0.01, () => {
                    mapList.style.height = '0px';
                    mapList.style.opacity = '0.0';
                    this.runTransition(mapList, activePanel, entry, scrollContainer);
                });
            } else {
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

        const mapStatusHelper = (UiToolkitAPI.GetGlobalObject() as any).ArchipelagoMapStatus;

        // Fetch custom logic and colors once from the central hub
        const logicHelper = (UiToolkitAPI.GetGlobalObject() as any).ArchipelagoLogic;
        const ICON_COLORS = logicHelper ? logicHelper.getColorMap() : {};

        if (subtitle_secondary) {
            subtitle_secondary.text = logicHelper ? logicHelper.formatSubtitle(mapData.subtitle || "") : (mapData.subtitle || "");
        }

        const checks = $('#ChecksColumn');
        const reqs = $('#RequirementsColumn');
        const playButton = $('#PlayButton');

        if (previewImage) {
            let picPath = mapData.pic || "menu/p2ce-generic";
            if (picPath.startsWith('vgui/chapters/')) {
                picPath = `archipelago/${picPath.substring('vgui/chapters/'.length)}`;
            }
            previewImage.SetImage(`file://{images}/${picPath}.png`);
        }

        if (statusLabel) {
            const rawStatus = mapData.status || "";
            let finalStatus = "";
            let mapCmdName = "";
            if (mapData.command) {
                const parts = mapData.command.split(" ");
                if (parts.length >= 2) mapCmdName = parts[1].trim().toLowerCase();
            }
            const mItems = mapData.subtitle || "";

            const formattedIcons = logicHelper ? logicHelper.getFormattedIcons(rawStatus, mapCmdName, mItems) : [];
            for (const iconData of formattedIcons) {
                finalStatus += `<font color="${iconData.color}">${iconData.char}</font>`;
            }
            statusLabel.text = finalStatus;
            statusLabel.style.color = "#eeeeee";
        }
        if (mapSubtitleLabel) mapSubtitleLabel.text = mapData.title || "";
        // Subtitle secondary is handled above with color formatting

        // SELECTIVE VISIBILITY: Hide details for root chapter selections
        const showDetails = !mapData.is_chapter;
        if (checks) checks.visible = showDetails;
        if (reqs) reqs.visible = showDetails;
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
        if (!syncHelper) {
            $.Msg("[AP] ERROR: ArchipelagoSync helper not found in MapSelect!");
        }

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

            // Deduplicate maps in the same chapter to avoid double-counting/double-rendering
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
            let starCount = 0;
            chapter.maps.forEach((map: any) => {
                const rawTitle = map.title || "Unknown Map";
                let statusIcons = (map.statusIcons || "").replace(/[~\-]/g, "").trim();
                if (!statusIcons && rawTitle.length > 4 && (rawTitle.startsWith("~") || rawTitle.startsWith("-") || rawTitle.startsWith("═"))) {
                    statusIcons = rawTitle.substring(0, 4).replace(/[~\-]/g, "").trim();
                }

                const symbol = ArchipelagoMapSelect.getCompletionSymbol();
                const isAllStars = statusIcons.length > 0 && statusIcons.replace(new RegExp(symbol, 'g'), "").length === 0;
                if (isAllStars) {
                    starCount++;
                }

                let mapCmdName = "";
                if (map.command) {
                    const parts = map.command.split(" ");
                    if (parts.length >= 2) {
                        mapCmdName = parts[1].trim().toLowerCase();
                    }
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

            if (starCount === chapter.maps.length && chapter.maps.length > 0) {
                const chStarLabel = $.CreatePanel('Label', entry, '');
                chStarLabel.text = ArchipelagoMapSelect.getCompletionSymbol();
                chStarLabel.style.color = "#ffff44";
                chStarLabel.style.fontSize = "26px";
                chStarLabel.style.fontFamily = "APPortal-bold";
                chStarLabel.style.verticalAlign = "center";
                chStarLabel.style.horizontalAlign = "right";
                chStarLabel.style.marginRight = "15px";
            } else if (chapterTotalCount > 0 && ($.persistentStorage.getItem('HideLocationCounts') ?? 0) === 0) {
                const chGreenLabel = $.CreatePanel('Label', entry, '');
                chGreenLabel.text = `${chapterGreenCount}/${chapterTotalCount}`;

                let color = "#ff4444"; // Red (0 available)
                if (chapterGreenCount === chapterTotalCount) {
                    color = "#44ff44"; // Green (All pending are available)
                } else if (chapterGreenCount > 0) {
                    color = "#ffff44"; // Yellow (Some available, some blocked)
                }
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

                let mapCmdName = "";
                if (map.command) {
                    const parts = map.command.split(" ");
                    if (parts.length >= 2) {
                        mapCmdName = parts[1].trim().toLowerCase();
                    }
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

                    if (this.isController()) {
                        this.playSelectedMap();
                    }
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

                if (mapTotalLeft > 0 && ($.persistentStorage.getItem('HideLocationCounts') ?? 0) === 0) {
                    const progressLabel = $.CreatePanel('Label', mapBtn, '');
                    progressLabel.text = `${mapGreenCount}/${mapTotalLeft}`;
                    
                    let color = "#ff4444"; // Red (0 available)
                    if (mapGreenCount === mapTotalLeft) {
                        color = "#44ff44"; // Green (All pending are available)
                    } else if (mapGreenCount > 0) {
                        color = "#ffff44"; // Yellow (Some available, some blocked)
                    }
                    progressLabel.style.color = color;
                    progressLabel.style.fontSize = "22px";
                    progressLabel.style.fontFamily = "APPortal-bold";
                    progressLabel.style.verticalAlign = "center";
                    progressLabel.style.marginRight = "10px";
                } else if (statusIcons.length > 0 && (statusIcons.replace(/★/g, "").length === 0 || statusIcons.replace(/✓/g, "").length === 0)) {
                    const starLabel = $.CreatePanel('Label', mapBtn, '');
                    starLabel.text = ArchipelagoMapSelect.getCompletionSymbol();
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
}

Object.assign($.GetContextPanel(), { ArchipelagoMapSelect });
