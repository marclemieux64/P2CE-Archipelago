'use strict';

class PauseMenu {
    static buttons: MenuButton[] = [
        {
            id: 'ArchipelagoSelectMapBtn',
            headline: '#PauseMenu_Navigation_Archipelago',
            tagline: '#PauseMenu_Navigation_Archipelago_Tagline',
            activated: () => {
                $.DispatchEvent('MainMenuOpenNestedPage', 'mapselect', 'archipelago/map-select', undefined);
            },
            hovered: () => { },
            focusIsHover: true
        },
        {
            id: 'ResumeBtn',
            headline: '#MainMenu_Home_Resume',
            tagline: '#MainMenu_Home_Resume_Tagline',
            activated: () => {
                $.DispatchEvent('MainMenuResumeGame');
            },
            hovered: () => { },
            unhovered: () => { },
            focusIsHover: true
        },
        {
            id: 'ReloadMapBtn',
            headline: '#PauseMenu_Navigation_Reload',
            tagline: '#PauseMenu_Navigation_Reload_Tagline',
            activated: () => {
                GameInterfaceAPI.ConsoleCommand('reload');
                $.DispatchEvent('MainMenuResumeGame');
            },
            hovered: () => { },
            unhovered: () => { },
            focusIsHover: true
        },
        {
            id: 'SettingsKeyboardBtn',
            headline: '#MainMenu_Navigation_Options',
            tagline: '#MainMenu_Navigation_Options_Tagline',
            activated: () => {
                $.DispatchEvent('MainMenuOpenNestedPage', 'Settings', 'settings/settings', undefined);
            },
            hovered: () => { },
            focusIsHover: true
        },
        {
            id: 'QuitBtn',
            headline: '#MainMenu_Navigation_QuitGame',
            tagline: '#MainMenu_Navigation_QuitGame_Tagline',
            activated: () => {
                UiToolkitAPI.ShowGenericPopupThreeOptionsBgStyle(
                    $.Localize('#Action_Quit'),
                    $.Localize('#Action_Quit_InGame_Message'),
                    'warning-2-popup',
                    $.Localize('#Action_ReturnToMenu'),
                    () => {
                        GameInterfaceAPI.ConsoleCommand('disconnect');
                        $.DispatchEvent('MainMenuCloseAllPages');
                    },
                    $.Localize('#Action_QuitToDesktop'),
                    () => {
                        GameInterfaceAPI.ConsoleCommand('quit');
                    },
                    $.Localize('#Action_Return'),
                    () => { },
                    'blur'
                );
            },
            hovered: () => { },
            focusIsHover: true
        }
    ];

    // Continue system removed
    static latestSave = undefined;

    static onLoad() {
        for (const btn of this.buttons) {
            $.DispatchEvent('MainMenuAddButton', btn);
        }

        $.DispatchEvent('MainMenuHideBackgroundMovie');
        $.DispatchEvent('MainMenuHideBackgroundImage', true);
        $.DispatchEvent('MainMenuSwitchReverse', true);

        const p = $.CreatePanel('Panel', $.GetContextPanel(), 'MenuBackgroundLayer');
        p.SetReadyForDisplay(false);
        p.LoadLayoutSnippet('MenuBackgroundLayer');
        $.DispatchEvent('MainMenuAddBgPanel', p);

        // Remove pause blur logic for ContinueBox
        const blur = p.FindChildTraverse('PauseMenuMainMenuBlur');
        if (blur) blur.AddClass('mainmenu__pause-blur__anim');
    }

    // Continue system removed
    static setContinueDetails() {
        return;
    }
}
