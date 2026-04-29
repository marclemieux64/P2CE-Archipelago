'use strict';

declare var $: any;
declare var GameInterfaceAPI: any;
interface Panel { [key: string]: any; }
interface ImagePanel extends Panel { }
interface LabelPanel extends Panel { }

const CHAPTER_NAMES: { [key: string]: string } = {
    "1": "The Courtesy Call",
    "2": "The Cold Boot",
    "3": "The Return",
    "4": "The Surprise",
    "5": "The Escape",
    "6": "The Fall",
    "7": "The Reunion",
    "8": "The Itch",
    "9": "The Part Where He Kills You"
};

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

        if (data) {
            const chapters: any = {};
            for (const key in data) {
                const lowerKey = key.toLowerCase();
                if (lowerKey.startsWith('chapter')) {
                    if (key.includes('.')) {
                        const majorId = key.match(/\d+/)?.[0];
                        if (majorId) {
                            if (!chapters[majorId]) chapters[majorId] = { maps: [] };
                            chapters[majorId].maps.push({ id: key, ...data[key] });
                        }
                    } else {
                        const majorId = key.match(/\d+/)?.[0];
                        if (majorId) {
                            if (!chapters[majorId]) chapters[majorId] = { maps: [] };
                            Object.assign(chapters[majorId], data[key]);
                        }
                    }
                }
            }
            this.g_ChapterData = chapters;
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
                title: CHAPTER_NAMES[chapterId] || chapter.title || "Chapter " + chapterId,
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
        const mapSubtitleLabelSecondary = $('#MapSubtitleLabel_Secondary') as LabelPanel;
        const playButton = $('#PlayButton');

        const checks = $('#ChecksColumn');
        const reqs = $('#RequirementsColumn');

        if (previewImage) {
            let picPath = mapData.pic || "menu/p2ce-generic";
            if (picPath.startsWith('vgui/chapters/')) {
                picPath = `archipelago/${picPath.substring('vgui/chapters/'.length)}`;
            }
            previewImage.SetImage(`file://{images}/${picPath}.png`);
        }

        if (statusLabel) {
            let finalStatus = mapData.status || "";
            if (finalStatus.indexOf("M") !== -1) {
                const isMissing = mapData.subtitle && mapData.subtitle.trim() !== "";
                const mColor = isMissing ? "#ff4444" : "#44ff44";
                finalStatus = finalStatus.replace(/M/g, `<font color="${mColor}">M</font>`);
            }
            if (finalStatus.indexOf("þ") !== -1) {
                finalStatus = finalStatus.replace(/þ/g, `<font color="#44ff44">þ</font>`);
            }
            
            if (finalStatus.indexOf("ù") !== -1) {
                let mapName = "";
                if (mapData.command) {
                    const parts = mapData.command.split(" ");
                    if (parts.length >= 2) {
                        mapName = parts[1].trim().toLowerCase();
                    }
                }
                if (mapName === "sp_a3_transition01") {
                    const missingItems = mapData.subtitle || "";
                    const uColor = (missingItems.indexOf("û") !== -1) ? "#ff4444" : "#44ff44";
                    finalStatus = finalStatus.replace(/ù/g, `<font color="${uColor}">ù</font>`);
                }
            }
            
            if (finalStatus.indexOf("R") !== -1) {
                let mapName = "";
                if (mapData.command) {
                    const parts = mapData.command.split(" ");
                    if (parts.length >= 2) {
                        mapName = parts[1].trim().toLowerCase();
                    }
                }
                const missingItems = mapData.subtitle || "";
                let rColor = "";

                if (mapName === "sp_a1_intro4") {
                    rColor = (missingItems.indexOf("ç") !== -1 || missingItems.indexOf("æ") !== -1) ? "#ff4444" : "#44ff44";
                } else if (mapName === "sp_a2_dual_lasers") {
                    rColor = "#44ff44";
                } else if (mapName === "sp_a2_trust_fling") {
                    rColor = (missingItems.indexOf("û") !== -1 || missingItems.indexOf("õ") !== -1) ? "#ff4444" : "#44ff44";
                } else if (mapName === "sp_a2_bridge_intro") {
                    rColor = "#44ff44";
                } else if (mapName === "sp_a2_bridge_the_gap") {
                    rColor = (missingItems.indexOf("û") !== -1) ? "#ff4444" : "#44ff44";
                } else if (mapName === "sp_a2_laser_vs_turret") {
                    rColor = (missingItems.indexOf("û") !== -1 || missingItems.indexOf("í") !== -1 || missingItems.indexOf("æ") !== -1 || missingItems.indexOf("ì") !== -1) ? "#ff4444" : "#44ff44";
                } else if (mapName === "sp_a2_pull_the_rug") {
                    rColor = (missingItems.indexOf("û") !== -1 || missingItems.indexOf("¿") !== -1) ? "#ff4444" : "#44ff44";
                }

                if (rColor !== "") {
                    finalStatus = finalStatus.replace(/R/g, `<font color="${rColor}">R</font>`);
                }
            }

            if (finalStatus.indexOf("ÿ") !== -1) {
                let mapName = "";
                if (mapData.command) {
                    const parts = mapData.command.split(" ");
                    if (parts.length >= 2) {
                        mapName = parts[1].trim().toLowerCase();
                    }
                }
                const missingItems = mapData.subtitle || "";
                let yColor = "";

                if (mapName === "sp_a4_tb_intro") {
                    yColor = (missingItems.indexOf("û") !== -1 || missingItems.indexOf("å") !== -1 || missingItems.indexOf("ð") !== -1) ? "#ff4444" : "#44ff44";
                } else if (mapName === "sp_a4_tb_trust_drop") {
                    yColor = (missingItems.indexOf("û") !== -1 || missingItems.indexOf("ñ") !== -1 || missingItems.indexOf("å") !== -1 || missingItems.indexOf("ð") !== -1) ? "#ff4444" : "#44ff44";
                } else if (mapName === "sp_a4_tb_wall_button") {
                    yColor = (missingItems.indexOf("û") !== -1) ? "#ff4444" : "#44ff44";
                } else if (mapName === "sp_a4_tb_polarity") {
                    yColor = (missingItems.indexOf("ó") !== -1) ? "#ff4444" : "#44ff44";
                } else if (mapName === "sp_a4_tb_catch") {
                    yColor = (missingItems.indexOf("û") !== -1 || missingItems.indexOf("ð") !== -1 || missingItems.indexOf("å") !== -1 || missingItems.indexOf("õ") !== -1 || missingItems.indexOf("ñ") !== -1) ? "#ff4444" : "#44ff44";
                } else if (mapName === "sp_a4_stop_the_box") {
                    yColor = (missingItems.indexOf("õ") !== -1) ? "#ff4444" : "#44ff44";
                } else if (mapName === "sp_a4_laser_catapult") {
                    yColor = (missingItems.indexOf("û") !== -1 || missingItems.indexOf("ð") !== -1 || missingItems.indexOf("õ") !== -1 || missingItems.indexOf("å") !== -1 || missingItems.indexOf("ì") !== -1 || missingItems.indexOf("í") !== -1 || missingItems.indexOf("î") !== -1) ? "#ff4444" : "#44ff44";
                } else if (mapName === "sp_a4_laser_platform") {
                    yColor = (missingItems.indexOf("û") !== -1 || missingItems.indexOf("í") !== -1 || missingItems.indexOf("î") !== -1 || missingItems.indexOf("ì") !== -1 || missingItems.indexOf("ñ") !== -1) ? "#ff4444" : "#44ff44";
                } else if (mapName === "sp_a4_speed_tb_catch") {
                    yColor = (missingItems.indexOf("û") !== -1) ? "#ff4444" : "#44ff44";
                } else if (mapName === "sp_a4_jump_polarity") {
                    yColor = (missingItems.indexOf("û") !== -1 || missingItems.indexOf("¢") !== -1 || missingItems.indexOf("å") !== -1 || missingItems.indexOf("ó") !== -1 || missingItems.indexOf("æ") !== -1 || missingItems.indexOf("ñ") !== -1) ? "#ff4444" : "#44ff44";
                } else if (mapName === "sp_a4_finale3") {
                    yColor = (missingItems.indexOf("û") !== -1 || missingItems.indexOf("¢") !== -1) ? "#ff4444" : "#44ff44";
                }

                if (yColor !== "") {
                    finalStatus = finalStatus.replace(/ÿ/g, `<font color="${yColor}">ÿ</font>`);
                }
            }

            statusLabel.text = finalStatus;
            statusLabel.style.color = "#eeeeee"; 
        }
        if (mapSubtitleLabel) mapSubtitleLabel.text = mapData.title || "";
        if (mapSubtitleLabelSecondary) mapSubtitleLabelSecondary.text = mapData.subtitle || "";

        // SELECTIVE VISIBILITY: Hide details for root chapter selections
        const showDetails = !mapData.is_chapter;
        if (checks) checks.visible = showDetails;
        if (reqs) reqs.visible = showDetails;

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

        const sortedKeys = Object.keys(this.g_ChapterData).sort((a, b) => parseInt(a) - parseInt(b));

        for (const chId of sortedKeys) {
            const chapter = this.g_ChapterData[chId];

            const entry = $.CreatePanel('Panel', container, `ChapterEntry_${chId}`);
            entry.AddClass('chapter_entry');
            (entry as any).canfocus = true;

            entry.SetPanelEvent('onactivate', () => this.toggleChapter(chId));
            entry.SetPanelEvent('onfocus', () => {
                this.selectMap({
                    pic: chapter.pic,
                    title: CHAPTER_NAMES[chId] || chapter.title || "Chapter " + chId,
                    subtitle: "",
                    status: "",
                    command_deactivated: true,
                    is_chapter: true
                });
            });

            let chapterGreenCount = 0;
            let starCount = 0;
            chapter.maps.forEach((map: any) => {
                const rawTitle = map.title || "Unknown Map";
                const statusIcons = (rawTitle.length > 4 ? rawTitle.substring(0, 4).trim() : "").replace(/[~\-]/g, "").trim();
                
                const isAllStars = statusIcons.length > 0 && statusIcons.replace(/✓/g, "").length === 0;
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

                for (let i = 0; i < statusIcons.length; i++) {
                    const char = statusIcons[i];
                    let isGreen = false;

                    if (char === "M") {
                        isGreen = !(mItems && mItems.trim() !== "");
                    } else if (char === "þ") {
                        isGreen = true;
                    } else if (char === "ù") {
                        if (mapCmdName === "sp_a3_transition01") {
                            isGreen = (mItems.indexOf("û") === -1);
                        } else {
                            isGreen = true;
                        }
                    } else if (char === "R") {
                        if (mapCmdName === "sp_a1_intro4") {
                            isGreen = (mItems.indexOf("ç") === -1 && mItems.indexOf("æ") === -1);
                        } else if (mapCmdName === "sp_a2_dual_lasers") {
                            isGreen = true;
                        } else if (mapCmdName === "sp_a2_trust_fling") {
                            isGreen = (mItems.indexOf("û") === -1 && mItems.indexOf("õ") === -1);
                        } else if (mapCmdName === "sp_a2_bridge_intro") {
                            isGreen = true;
                        } else if (mapCmdName === "sp_a2_bridge_the_gap") {
                            isGreen = (mItems.indexOf("û") === -1);
                        } else if (mapCmdName === "sp_a2_laser_vs_turret") {
                            isGreen = (mItems.indexOf("û") === -1 && mItems.indexOf("í") === -1 && mItems.indexOf("æ") === -1 && mItems.indexOf("ì") === -1);
                        } else if (mapCmdName === "sp_a2_pull_the_rug") {
                            isGreen = (mItems.indexOf("û") === -1 && mItems.indexOf("¿") === -1);
                        } else {
                            isGreen = true; 
                        }
                    } else if (char === "ÿ") {
                        if (mapCmdName === "sp_a4_tb_intro") {
                            isGreen = (mItems.indexOf("û") === -1 && mItems.indexOf("å") === -1 && mItems.indexOf("ð") === -1);
                        } else if (mapCmdName === "sp_a4_tb_trust_drop") {
                            isGreen = (mItems.indexOf("û") === -1 && mItems.indexOf("ñ") === -1 && mItems.indexOf("å") === -1 && mItems.indexOf("ð") === -1);
                        } else if (mapCmdName === "sp_a4_tb_wall_button") {
                            isGreen = (mItems.indexOf("û") === -1);
                        } else if (mapCmdName === "sp_a4_tb_polarity") {
                            isGreen = (mItems.indexOf("ó") === -1);
                        } else if (mapCmdName === "sp_a4_tb_catch") {
                            isGreen = (mItems.indexOf("û") === -1 && mItems.indexOf("ð") === -1 && mItems.indexOf("å") === -1 && mItems.indexOf("õ") === -1 && mItems.indexOf("ñ") === -1);
                        } else if (mapCmdName === "sp_a4_stop_the_box") {
                            isGreen = (mItems.indexOf("õ") === -1);
                        } else if (mapCmdName === "sp_a4_laser_catapult") {
                            isGreen = (mItems.indexOf("û") === -1 && mItems.indexOf("ð") === -1 && mItems.indexOf("õ") === -1 && mItems.indexOf("å") === -1 && mItems.indexOf("ì") === -1 && mItems.indexOf("í") === -1 && mItems.indexOf("î") === -1);
                        } else if (mapCmdName === "sp_a4_laser_platform") {
                            isGreen = (mItems.indexOf("û") === -1 && mItems.indexOf("í") === -1 && mItems.indexOf("î") === -1 && mItems.indexOf("ì") === -1 && mItems.indexOf("ñ") === -1);
                        } else if (mapCmdName === "sp_a4_speed_tb_catch") {
                            isGreen = (mItems.indexOf("û") === -1);
                        } else if (mapCmdName === "sp_a4_jump_polarity") {
                            isGreen = (mItems.indexOf("û") === -1 && mItems.indexOf("¢") === -1 && mItems.indexOf("å") === -1 && mItems.indexOf("ó") === -1 && mItems.indexOf("æ") === -1 && mItems.indexOf("ñ") === -1);
                        } else if (mapCmdName === "sp_a4_finale3") {
                            isGreen = (mItems.indexOf("û") === -1 && mItems.indexOf("¢") === -1);
                        } else {
                            isGreen = true;
                        }
                    }

                    if (isGreen) {
                        chapterGreenCount++;
                    }
                }
            });

            if (starCount === chapter.maps.length && chapter.maps.length > 0) {
                const chStarLabel = $.CreatePanel('Label', entry, '');
                chStarLabel.text = "✓";
                chStarLabel.style.color = "#ffff44";
                chStarLabel.style.fontSize = "26px";
                chStarLabel.style.fontFamily = "APPortal-bold";
                chStarLabel.style.verticalAlign = "center";
                chStarLabel.style.horizontalAlign = "right";
                chStarLabel.style.marginRight = "15px";
            } else if (chapterGreenCount > 0) {
                const chGreenLabel = $.CreatePanel('Label', entry, '');
                chGreenLabel.text = chapterGreenCount.toString();
                chGreenLabel.style.color = "#44ff44";
                chGreenLabel.style.fontSize = "26px";
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
            title.text = chapter.title || "Chapter " + chId;
            title.AddClass('ChapterTitle');

            const desc = $.CreatePanel('Label', textWrapper, '');
            desc.text = CHAPTER_NAMES[chId] || chapter.subtitle || "";
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
                const statusIcons = (rawTitle.length > 4 ? rawTitle.substring(0, 4).trim() : "").replace(/[~\-]/g, "").trim();
                const cleanName = rawTitle.length > 4 ? rawTitle.substring(4).trim() : rawTitle;

                const onSelect = () => {
                    this.selectMap({ ...map, title: cleanName, subtitle: map.subtitle || "", status: statusIcons, is_chapter: false });
                };

                mapBtn.SetPanelEvent('onactivate', () => {
                    onSelect();

                    if (this.isController()) {
                        this.playSelectedMap();
                    }
                });
                mapBtn.SetPanelEvent('onfocus', onSelect);

                const mapContent = $.CreatePanel('Panel', mapBtn, '');
                mapContent.AddClass('map-title-container');

                const nameLabel = $.CreatePanel('Label', mapContent, '');
                nameLabel.text = cleanName;
                nameLabel.AddClass('MapPrimaryName');

                let greenCount = 0;
                let mapCmdName = "";
                if (map.command) {
                    const parts = map.command.split(" ");
                    if (parts.length >= 2) {
                        mapCmdName = parts[1].trim().toLowerCase();
                    }
                }
                const mItems = map.subtitle || "";

                for (let i = 0; i < statusIcons.length; i++) {
                    const char = statusIcons[i];
                    let isGreen = false;

                    if (char === "M") {
                        isGreen = !(mItems && mItems.trim() !== "");
                    } else if (char === "þ") {
                        isGreen = true;
                    } else if (char === "ù") {
                        if (mapCmdName === "sp_a3_transition01") {
                            isGreen = (mItems.indexOf("û") === -1);
                        } else {
                            isGreen = true;
                        }
                    } else if (char === "R") {
                        if (mapCmdName === "sp_a1_intro4") {
                            isGreen = (mItems.indexOf("ç") === -1 && mItems.indexOf("æ") === -1);
                        } else if (mapCmdName === "sp_a2_dual_lasers") {
                            isGreen = true;
                        } else if (mapCmdName === "sp_a2_trust_fling") {
                            isGreen = (mItems.indexOf("û") === -1 && mItems.indexOf("õ") === -1);
                        } else if (mapCmdName === "sp_a2_bridge_intro") {
                            isGreen = true;
                        } else if (mapCmdName === "sp_a2_bridge_the_gap") {
                            isGreen = (mItems.indexOf("û") === -1);
                        } else if (mapCmdName === "sp_a2_laser_vs_turret") {
                            isGreen = (mItems.indexOf("û") === -1 && mItems.indexOf("í") === -1 && mItems.indexOf("æ") === -1 && mItems.indexOf("ì") === -1);
                        } else if (mapCmdName === "sp_a2_pull_the_rug") {
                            isGreen = (mItems.indexOf("û") === -1 && mItems.indexOf("¿") === -1);
                        } else {
                            isGreen = true; 
                        }
                    } else if (char === "ÿ") {
                        if (mapCmdName === "sp_a4_tb_intro") {
                            isGreen = (mItems.indexOf("û") === -1 && mItems.indexOf("å") === -1 && mItems.indexOf("ð") === -1);
                        } else if (mapCmdName === "sp_a4_tb_trust_drop") {
                            isGreen = (mItems.indexOf("û") === -1 && mItems.indexOf("ñ") === -1 && mItems.indexOf("å") === -1 && mItems.indexOf("ð") === -1);
                        } else if (mapCmdName === "sp_a4_tb_wall_button") {
                            isGreen = (mItems.indexOf("û") === -1);
                        } else if (mapCmdName === "sp_a4_tb_polarity") {
                            isGreen = (mItems.indexOf("ó") === -1);
                        } else if (mapCmdName === "sp_a4_tb_catch") {
                            isGreen = (mItems.indexOf("û") === -1 && mItems.indexOf("ð") === -1 && mItems.indexOf("å") === -1 && mItems.indexOf("õ") === -1 && mItems.indexOf("ñ") === -1);
                        } else if (mapCmdName === "sp_a4_stop_the_box") {
                            isGreen = (mItems.indexOf("õ") === -1);
                        } else if (mapCmdName === "sp_a4_laser_catapult") {
                            isGreen = (mItems.indexOf("û") === -1 && mItems.indexOf("ð") === -1 && mItems.indexOf("õ") === -1 && mItems.indexOf("å") === -1 && mItems.indexOf("ì") === -1 && mItems.indexOf("í") === -1 && mItems.indexOf("î") === -1);
                        } else if (mapCmdName === "sp_a4_laser_platform") {
                            isGreen = (mItems.indexOf("û") === -1 && mItems.indexOf("í") === -1 && mItems.indexOf("î") === -1 && mItems.indexOf("ì") === -1 && mItems.indexOf("ñ") === -1);
                        } else if (mapCmdName === "sp_a4_speed_tb_catch") {
                            isGreen = (mItems.indexOf("û") === -1);
                        } else if (mapCmdName === "sp_a4_jump_polarity") {
                            isGreen = (mItems.indexOf("û") === -1 && mItems.indexOf("¢") === -1 && mItems.indexOf("å") === -1 && mItems.indexOf("ó") === -1 && mItems.indexOf("æ") === -1 && mItems.indexOf("ñ") === -1);
                        } else if (mapCmdName === "sp_a4_finale3") {
                            isGreen = (mItems.indexOf("û") === -1 && mItems.indexOf("¢") === -1);
                        } else {
                            isGreen = true;
                        }
                    }

                    if (isGreen) {
                        greenCount++;
                    }
                }

                if (greenCount > 0) {
                    const greenLabel = $.CreatePanel('Label', mapBtn, '');
                    greenLabel.text = greenCount.toString();
                    greenLabel.style.color = "#44ff44";
                    greenLabel.style.fontSize = "26px";
                    greenLabel.style.fontFamily = "APPortal-bold";
                    greenLabel.style.verticalAlign = "center";
                    greenLabel.style.marginRight = "10px";
                } else if (statusIcons.length > 0 && statusIcons.replace(/✓/g, "").length === 0) {
                    const starLabel = $.CreatePanel('Label', mapBtn, '');
                    starLabel.text = "✓";
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