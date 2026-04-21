'use strict';

class BaseMenu {
    static buttons: MenuButton[] = [
        {
            id: 'PlayBtn',
            headline: '#MainMenu_Navigation_Play_Archipelago',
            tagline: '#MainMenu_Navigation_Play_Archipelago_Tagline',
            activated: () => {
                $.DispatchEvent('MainMenuOpenNestedPage', 'mapselect', 'archipelago/map-select', undefined);
            },
            focused: () => {
                this.hideContinueDetails();
            }
        },
        {
            id: 'SettingsKeyboardBtn',
            headline: '#MainMenu_Navigation_Options',
            tagline: '#MainMenu_Navigation_Options_Tagline',
            activated: () => {
                $.DispatchEvent('MainMenuOpenNestedPage', 'Settings', 'settings/settings', undefined);
            },
            focused: () => { }
        },
        {
            id: 'QuitBtn',
            headline: '#MainMenu_Navigation_QuitGame',
            tagline: '#MainMenu_Navigation_QuitGame_Tagline',
            activated: () => {
                UiToolkitAPI.ShowGenericPopupTwoOptionsBgStyle(
                    $.Localize('#Action_Quit'),
                    $.Localize('#Action_Quit_Message'),
                    'warning-popup',
                    $.Localize('#Action_Quit'),
                    () => GameInterfaceAPI.ConsoleCommand('quit'),
                    $.Localize('#Action_Return'),
                    () => { },
                    'blur'
                );
            },
            focused: () => { }
        }
    ];

    // Continue system removed
    static latestSave = undefined;
    static savCampaign = undefined;
    static savChapter = undefined;
    static isContinueActive = false;

    static bgMapLoad: uuid | undefined = undefined;

    static mapSelection = 0;
    static maps = [
        'p2ce_background_chmb18_ovg',
        'p2ce_background_laser_intro',
        'p2ce_background_gentle_hum',
        'p2ce_background_mikatastrophe-dark'
    ];
    static music;

    static onLoad() {
        for (const btn of this.buttons) {
            $.DispatchEvent('MainMenuAddButton', btn);
        }

        $.RegisterForUnhandledEvent('MainBackgroundLoaded', () => {
            this.showPrereleaseWarning();
            if (GameStateAPI.IsPlaytest()) this.showPlaytestConsentPopup();

            const music = `UIPanorama.Music.P2CE.Menu${Math.floor(Math.random() * 7) + 1}`;
            this.music = $.PlaySoundEvent(music);
        });

        $.RegisterForUnhandledEvent('MapUnloaded', () => {
            this.stopMusic();

            // Because P2CE strips the `script_panorama` command and actively blocks native server 
            // drops via 'FCVAR_SERVER_CAN_EXECUTE', we know the Archipelago Python client handles 
            // dragging the user out of the completed map into the Main Menu. 
            // Thus, we can natively listen for `MapUnloaded` the exact moment they land back 
            // in the menu, and automatically open the Map Select page buttonless seamlessly!
            $.Schedule(0.2, () => {
                $.DispatchEvent('MainMenuOpenNestedPage', 'mapselect', 'archipelago/map-select', undefined);
            });
        });
        $.RegisterForUnhandledEvent('MainMenuModeRequestCleanup', () => this.stopMusic());

        $.RegisterForUnhandledEvent('MainMenuAnimatedSwitch', (c: string) => {
            GameInterfaceAPI.ConsoleCommand('disconnect');
            $.Schedule(0.01, () => {
                $.DispatchEvent('MainMenuSwitchFade', true, true);
                $.Schedule(0.01, () => {
                    $.Msg('BASE MENU: Switching campaign');
                    if (!CampaignAPI.SetActiveCampaign(c)) {
                        $.Warning(`BASE MENU: Failed to set campaign to ${c}!!!!`);
                    }
                });
            });
        });

        // Set your custom logo
        $.DispatchEvent('MainMenuSetLogo', 'file://{images}/logo.png');
        $.DispatchEvent('MainMenuSetLogoSize', CampaignLogoSizePreset.STANDARD);

        // Background layer
        const p = $.CreatePanel('Panel', $.GetContextPanel(), 'MenuBackgroundLayer');
        p.SetReadyForDisplay(false);
        p.LoadLayoutSnippet('MenuBackgroundLayer');
        $.DispatchEvent('MainMenuAddBgPanel', p);

        // Continue system removed — no logo lookup, no errors
        $.DispatchEvent('MainMenuHideBackgroundMovie');

        // Load background
        this.loadBackground();
    }

    static stopMusic() {
        if (this.music) $.StopSoundEvent(this.music);
        this.music = undefined;
    }

    // Continue system removed
    static hideContinueDetails() {
        return;
    }

    static rerollMap() {
        this.mapSelection = Math.floor(Math.random() * this.maps.length);
        $.Msg(`BASE MENU: Rolled background map: ${this.mapSelection}, ${this.maps[this.mapSelection]}`);
        $.DispatchEvent(
            'MainMenuSetBackgroundImage',
            `file://{images}/menu/featured/${this.maps[this.mapSelection]}.png`
        );
    }

    static loadNoRoll() {
        this.loadStaticBg();
    }

    static loadBackground() {
        this.rerollMap();
        this.loadNoRoll();
    }

    static loadStaticBg() {
        $.DispatchEvent('MainMenuShowBackgroundImage', undefined, true);
        $.DispatchEvent('MainMenuSwitchReverse', false);

        $.RegisterForUnhandledEvent('MapLoaded', (map: string, bg: boolean) => {
            if (bg) {
                $.Msg('BASE MENU: Background map load detected. Turning off background image/movie.');
                $.DispatchEvent('MainMenuHideBackgroundImage', undefined);
                $.DispatchEvent('MainMenuHideBackgroundMovie');
            }
        });

        $.DispatchEvent('MainBackgroundLoaded');
    }

    static loadLiveBg() {
        $.DispatchEvent('MainMenuSetLoadingIndicatorVisibility', true);
        $.DispatchEvent('MainMenuShowBackgroundImage', undefined, false);

        if (this.bgMapLoad === undefined) {
            this.bgMapLoad = GameInterfaceAPI.RegisterGameEventHandler(
                'map_load_failed',
                (mapName: string, isBackgroundMap: boolean) => {
                    if (!isBackgroundMap || mapName !== `maps\\${this.maps[this.mapSelection]}.bsp`) return;
                    $.Warning('!!!!! Could not load featured background map !!!!!');
                    $.Schedule(0.001, () => {
                        $.DispatchEvent('MainMenuSwitchReverse', false);
                        $.DispatchEvent('MainBackgroundLoaded');
                    });
                }
            );
        }

        $.RegisterForUnhandledEvent('MapLoaded', (map: string, bg: boolean) => {
            if (bg && map === `maps\\${this.maps[this.mapSelection]}.bsp`) {
                $.DispatchEvent('MainMenuHideBackgroundImage', false);
                $.DispatchEvent('MainMenuSwitchReverse', false);
                $.DispatchEvent('MainBackgroundLoaded');
            } else {
                $.Warning(
                    `BASE MENU: Map loaded, but it failed to pass base bg map check. bgLevel = ${this.maps[this.mapSelection]}, map = ${map}, bg: ${bg}`
                );
            }
        });

        $.Schedule(0.1, () => {
            GameInterfaceAPI.ConsoleCommand('disconnect');
            GameInterfaceAPI.ConsoleCommand(`map_background "${this.maps[this.mapSelection]}"`);
        });
    }

    static showPlaytestConsentPopup() {
        if (!DosaHandler.checkDosa('playtestConsent'))
            UiToolkitAPI.ShowCustomLayoutPopupParameters(
                '',
                'file://{resources}/layout/modals/popups/playtest-consent.xml',
                'dosaKey=playtestConsent&dosaNameToken=Dosa_PlaytestConsent'
            );
    }

    static showPrereleaseWarning() {
        if (!DosaHandler.checkDosa('prereleaseAck'))
            UiToolkitAPI.ShowCustomLayoutPopupParameters(
                '',
                'file://{resources}/layout/modals/popups/prerelease-warn-dialog.xml',
                'dosaKey=prereleaseAck&dosaNameToken=Dosa_PrereleaseAck'
            );
    }
}

// ============================================================================
// ARCHIPELAGO: RECOVERY ROUTINE (BLACK FADE VERSION)
// ============================================================================

if ($.persistentStorage.getItem("ap_return_to_map_select") === "true") {
    $.persistentStorage.setItem("ap_return_to_map_select", "false");

    const contextPanel = $.GetContextPanel();
    if (contextPanel) {
        // On force le panneau en noir total immédiatement
        contextPanel.style.backgroundColor = "black";
        // On s'assure que le menu n'est pas visible à travers le noir
        contextPanel.style.opacity = "1";
    }

    $.Msg("[Archipelago] Recovery active. Rendering black overlay during transition...");

    // Le délai de 0.05s permet au moteur d'instancier le contenu XML de map-select
    $.Schedule(0.05, () => {
        $.Msg("[Archipelago] Dispatching nested page event...");
        $.DispatchEvent('MainMenuOpenNestedPage', 'mapselect', 'archipelago/map-select', undefined);

        // On attend que la transition soit finie (0.5s) pour retirer le fond noir
        // afin que le menu principal redevienne normal pour la suite.
        $.Schedule(0.5, () => {
            if (contextPanel) {
                // On remet la couleur par défaut (généralement transparent ou défini par le CSS)
                contextPanel.style.backgroundColor = "none";
            }
        });
    });
}