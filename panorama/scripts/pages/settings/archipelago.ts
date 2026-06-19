'use strict';

/**
 * ARCHIPELAGO SETTINGS MANAGER
 * Pure JavaScript runtime version safe from compilation type-errors.
 */

if (!$.Msg) { $.Msg = UiToolkitAPI.GetGlobalObject().Msg; }

/**
 * Helper to run a console command only if currently in-game (server context is active).
 */
function RunConsoleCommandIfInGame(cmd: string) {
    if (GameInterfaceAPI.GetGameUIState() === GameUIState.PAUSEMENU) {
        GameInterfaceAPI.ConsoleCommand(cmd);
    }
}

function SaveHideCountsSetting() {
    const enumPanel = $('#HideCountsSetting');
    if (enumPanel) {
        const children = enumPanel.FindChildTraverse('values')?.Children() || [];
        for (let i = 0; i < children.length; i++) {
            if (children[i].paneltype === "RadioButton" && children[i].IsSelected()) {
                const val = children[i].GetAttributeString('value', '0');
                $.persistentStorage.setItem('ap_hide_location_counts', val);
                $.Msg(`[AP] Hide Location Counts setting saved as: ${val}`);
                break;
            }
        }
    }
}

function SaveMapStatusHUDSetting() {
    const enumPanel = $('#MapStatusHUDSetting');
    if (enumPanel) {
        const children = enumPanel.FindChildTraverse('values')?.Children() || [];
        for (let i = 0; i < children.length; i++) {
            if (children[i].paneltype === "RadioButton" && children[i].IsSelected()) {
                const val = children[i].GetAttributeString('value', '0');
                $.persistentStorage.setItem('ap_show_map_status_hud', val);
                
                RunConsoleCommandIfInGame(`ap_show_map_status_hud ${val}`);
                $.Msg(`[AP] Show Map Status HUD saved and pushed to Server: ${val}`);
                break;
            }
        }
        UpdateMapStatusHUDKeyBinder();

        const mapStatusHUD = UiToolkitAPI.GetGlobalObject().ArchipelagoMapStatusHUD;
        if (mapStatusHUD && mapStatusHUD.m_CurrentMapName) {
            const isHiding = ($.persistentStorage.getItem('ap_show_map_status_hud') ?? "1") === "1";
            mapStatusHUD.updateStatus(mapStatusHUD.m_CurrentMapName, false, !isHiding);
        }
    }
}

function SaveSmartWarpSetting() {
    const dropdown = $('#TransitionTypeSetting');
    if (dropdown) {
        const realDropdown = dropdown.FindChildTraverse('DropDown');
        if (realDropdown) {
            const selected = realDropdown.GetSelected();
            if (selected) {
                const val = selected.GetAttributeInt('value', -1);
                $.persistentStorage.setItem('ap_smart_warp', val);
                
                GameInterfaceAPI.SetSettingInt('ap_smart_warp', val);
                $.Msg(`[AP] Smart Warp setting saved: ${val}`);
            }
        }
    }
}

function SaveHideHologramsSetting() {
    const dropdown = $('#HideHologramsSetting');
    if (dropdown) {
        const realDropdown = dropdown.FindChildTraverse('DropDown');
        if (realDropdown) {
            const selected = realDropdown.GetSelected();
            if (selected) {
                const val = selected.GetAttributeInt('value', 0);
                $.persistentStorage.setItem('ap_hide_holograms', val);
                
                GameInterfaceAPI.SetSettingInt('ap_hide_holograms', val);
                RunConsoleCommandIfInGame('UpdateHologramsVisibility');
                $.Msg(`[AP] Hide Holograms setting saved: ${val}`);
            }
        }
    }
}

function SaveStatusIndicatorModeSetting() {
    const dropdown = $('#StatusIndicatorModeSetting');
    if (dropdown) {
        const realDropdown = dropdown.FindChildTraverse('DropDown');
        if (realDropdown) {
            const val = realDropdown.GetSelected().GetAttributeInt('value', 0);
            $.persistentStorage.setItem('ap_status_indicator_mode', val);
            
            const statusIndicator = UiToolkitAPI.GetGlobalObject().ArchipelagoStatusIndicator;
            if (statusIndicator) {
                statusIndicator.refreshVisibility();
            }
            $.Msg(`[AP] Status Indicator Mode saved: ${val}`);
        }
    }
}

function SaveSkipBirdSceneSetting() {
    const enumPanel = $('#SkipBirdSceneSetting');
    if (enumPanel) {
        const children = enumPanel.FindChildTraverse('values')?.Children() || [];
        for (let i = 0; i < children.length; i++) {
            if (children[i].paneltype === "RadioButton" && children[i].IsSelected()) {
                const val = children[i].GetAttributeString('value', '0');
                $.persistentStorage.setItem('cv_SkipBirdScene', val);
                
                RunConsoleCommandIfInGame(`cv_SkipBirdScene ${val}`);
                $.Msg(`[AP] Skip Bird Scene setting saved and synced: ${val}`);
                break;
            }
        }
    }
}

function SaveSkipCeilingSceneSetting() {
    const enumPanel = $('#SkipCeilingSceneSetting');
    if (enumPanel) {
        const children = enumPanel.FindChildTraverse('values')?.Children() || [];
        for (let i = 0; i < children.length; i++) {
            if (children[i].paneltype === "RadioButton" && children[i].IsSelected()) {
                const val = children[i].GetAttributeString('value', '0');
                $.persistentStorage.setItem('cv_SkipCeilingScene', val);
                
                RunConsoleCommandIfInGame(`cv_SkipCeilingScene ${val}`);
                $.Msg(`[AP] Skip Ceiling Scene setting saved and synced: ${val}`);
                break;
            }
        }
    }
}

function SaveSkipIntroContainerSetting() {
    const enumPanel = $('#SkipIntroContainerSetting');
    if (enumPanel) {
        const children = enumPanel.FindChildTraverse('values')?.Children() || [];
        for (let i = 0; i < children.length; i++) {
            if (children[i].paneltype === "RadioButton" && children[i].IsSelected()) {
                const val = children[i].GetAttributeString('value', '0');
                $.persistentStorage.setItem('cv_SkipIntroContainerScene', val);
                
                RunConsoleCommandIfInGame(`cv_SkipIntroContainerScene ${val}`);
                $.Msg(`[AP] Skip Intro Container setting saved and synced: ${val}`);
                break;
            }
        }
    }
}

function UpdateMapStatusHUDKeyBinder() {
    const keyBinder = $('#MapStatusKeyBinder');
    if (keyBinder) {
        keyBinder.hittest = true;
        keyBinder.hittestchildren = true;
        keyBinder.RemoveClass('disabled');
        keyBinder.SetPanelEvent('onactivate', () => {
            $.DispatchEvent('SettingsKeyBinderActivate', keyBinder);
        });

        try {
            if (typeof (Object.create(null).OptionsMenuAPI) !== 'undefined' || UiToolkitAPI.GetGlobalObject().OptionsMenuAPI) {
                const api = UiToolkitAPI.GetGlobalObject().OptionsMenuAPI || Object.create(null).OptionsMenuAPI;
                if (api && typeof api.RefreshKeybdMouseBindingDefaults === 'function') {
                    api.RefreshKeybdMouseBindingDefaults();
                }
            }
        } catch (e) {
            $.Msg("[AP ERROR] Failed to refresh key binding system natively.");
        }

        if (keyBinder.OnShow) {
            keyBinder.OnShow();
        }
    }
}

function LoadArchipelagoSettings() {
    if ($.persistentStorage.getItem('ap_show_map_status_hud') === null) {
        $.persistentStorage.setItem('ap_show_map_status_hud', '1');
    }
    if ($.persistentStorage.getItem('ap_hide_location_counts') === null) {
        $.persistentStorage.setItem('ap_hide_location_counts', '0');
    }
    if ($.persistentStorage.getItem('cv_SkipBirdScene') === null) {
        $.persistentStorage.setItem('cv_SkipBirdScene', '0');
    }
    if ($.persistentStorage.getItem('cv_SkipCeilingScene') === null) {
        $.persistentStorage.setItem('cv_SkipCeilingScene', '0');
    }
    if ($.persistentStorage.getItem('cv_SkipIntroContainerScene') === null) {
        $.persistentStorage.setItem('cv_SkipIntroContainerScene', '0');
    }

    const hideCountsVal = $.persistentStorage.getItem('ap_hide_location_counts') ?? "0";
    const hideCountsPanel = $('#HideCountsSetting');
    if (hideCountsPanel) {
        const children = hideCountsPanel.FindChildTraverse('values')?.Children() || [];
        for (let i = 0; i < children.length; i++) {
            if (children[i].GetAttributeString('value', '0') === hideCountsVal.toString()) {
                children[i].checked = true;
                break;
            }
        }
    }

    const hudVal = $.persistentStorage.getItem('ap_show_map_status_hud') ?? "1";
    const hudPanel = $('#MapStatusHUDSetting');
    if (hudPanel) {
        const children = hudPanel.FindChildTraverse('values')?.Children() || [];
        for (let i = 0; i < children.length; i++) {
            if (children[i].GetAttributeString('value', '0') === hudVal.toString()) {
                children[i].checked = true;
                break;
            }
        }
    }

    const warpVal = $.persistentStorage.getItem('ap_smart_warp') ?? "0";
    const warpDropdown = $('#TransitionTypeSetting')?.FindChildTraverse('DropDown');
    if (warpDropdown) warpDropdown.SetSelected(warpVal.toString() === "1" ? 'ap_transition_smart' : 'ap_transition_menu');
    
    const hideHoloValRaw = $.persistentStorage.getItem('ap_hide_holograms') ?? "0";
    const hideHoloDropdown = $('#HideHologramsSetting')?.FindChildTraverse('DropDown');
    if (hideHoloDropdown) hideHoloDropdown.SetSelected('ap_hide_holograms_' + hideHoloValRaw.toString());
    GameInterfaceAPI.SetSettingInt('ap_hide_holograms', parseInt(hideHoloValRaw.toString(), 10) || 0);

    const statusIndVal = $.persistentStorage.getItem('ap_status_indicator_mode') ?? "0";
    const statusIndDropdown = $('#StatusIndicatorModeSetting')?.FindChildTraverse('DropDown');
    if (statusIndDropdown) statusIndDropdown.SetSelected('ap_status_indicator_mode_' + statusIndVal.toString());

    const skipBirdVal = $.persistentStorage.getItem('cv_SkipBirdScene') ?? "0";
    const skipBirdPanel = $('#SkipBirdSceneSetting');
    if (skipBirdPanel) {
        const children = skipBirdPanel.FindChildTraverse('values')?.Children() || [];
        for (let i = 0; i < children.length; i++) {
            if (children[i].GetAttributeString('value', '0') === skipBirdVal.toString()) {
                children[i].checked = true;
                break;
            }
        }
    }
    RunConsoleCommandIfInGame(`cv_SkipBirdScene ${skipBirdVal}`);

    const skipCeilingVal = $.persistentStorage.getItem('cv_SkipCeilingScene') ?? "0";
    const skipCeilingPanel = $('#SkipCeilingSceneSetting');
    if (skipCeilingPanel) {
        const children = skipCeilingPanel.FindChildTraverse('values')?.Children() || [];
        for (let i = 0; i < children.length; i++) {
            if (children[i].GetAttributeString('value', '0') === skipCeilingVal.toString()) {
                children[i].checked = true;
                break;
            }
        }
    }
    RunConsoleCommandIfInGame(`cv_SkipCeilingScene ${skipCeilingVal}`);

    const skipIntroContainerVal = $.persistentStorage.getItem('cv_SkipIntroContainerScene') ?? "0";
    const skipIntroContainerPanel = $('#SkipIntroContainerSetting');
    if (skipIntroContainerPanel) {
        const children = skipIntroContainerPanel.FindChildTraverse('values')?.Children() || [];
        for (let i = 0; i < children.length; i++) {
            if (children[i].GetAttributeString('value', '0') === skipIntroContainerVal.toString()) {
                children[i].checked = true;
                break;
            }
        }
    }
    RunConsoleCommandIfInGame(`cv_SkipIntroContainerScene ${skipIntroContainerVal}`);

    UpdateMapStatusHUDKeyBinder();

    $.Schedule(0.2, () => {
        RunConsoleCommandIfInGame('UpdateHologramsVisibility');
    });
}

UiToolkitAPI.GetGlobalObject().SaveHideCountsSetting = SaveHideCountsSetting;
UiToolkitAPI.GetGlobalObject().SaveMapStatusHUDSetting = SaveMapStatusHUDSetting;
UiToolkitAPI.GetGlobalObject().SaveSmartWarpSetting = SaveSmartWarpSetting;
UiToolkitAPI.GetGlobalObject().SaveHideHologramsSetting = SaveHideHologramsSetting;
UiToolkitAPI.GetGlobalObject().SaveStatusIndicatorModeSetting = SaveStatusIndicatorModeSetting;
UiToolkitAPI.GetGlobalObject().SaveSkipBirdSceneSetting = SaveSkipBirdSceneSetting;
UiToolkitAPI.GetGlobalObject().SaveSkipCeilingSceneSetting = SaveSkipCeilingSceneSetting;
UiToolkitAPI.GetGlobalObject().SaveSkipIntroContainerSetting = SaveSkipIntroContainerSetting;
UiToolkitAPI.GetGlobalObject().LoadArchipelagoSettings = LoadArchipelagoSettings;
UiToolkitAPI.GetGlobalObject().UpdateMapStatusHUDKeyBinder = UpdateMapStatusHUDKeyBinder;

$.GetContextPanel().OnShow = () => {
    LoadArchipelagoSettings();
};

LoadArchipelagoSettings();