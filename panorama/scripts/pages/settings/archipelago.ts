'use strict';

/**
 * ARCHIPELAGO SETTINGS MANAGER
 * Gère la persistance des réglages entre les sessions de jeu.
 */

if (!$.Msg) { $.Msg = (UiToolkitAPI.GetGlobalObject() as any).Msg; }

function SaveHideCountsSetting() {
    const enumPanel = $('#HideCountsSetting');
    if (enumPanel) {
        const children = enumPanel.FindChildTraverse('RadioButtonsContainer')?.Children() || [];
        for (let i = 0; i < children.length; i++) {
            if (children[i].paneltype === "RadioButton" && children[i].IsSelected()) {
                const val = children[i].GetAttributeString('value', '0');
                $.persistentStorage.setItem('ap_hide_location_counts', val);
                $.Msg(`[AP] Hide Location Counts setting saved as: ${val}`);
                break;
            }
        }
        UpdateCompletionSymbolStatus();
    }
}

function SaveCompletionSymbolSetting() {
    const dropdown = $('#CompletionSymbolSetting');
    if (dropdown) {
        const realDropdown = dropdown.FindChildTraverse('DropDown') as any;
        if (realDropdown) {
            const selected = realDropdown.GetSelected();
            if (selected) {
                const val = selected.GetAttributeInt('value', 0);
                $.persistentStorage.setItem('ap_completion_symbol', val);
                $.Msg(`[AP] Completion Symbol setting saved as: ${val}`);
            }
        }
    }
}

function SaveMapStatusHUDSetting() {
    const enumPanel = $('#MapStatusHUDSetting');
    if (enumPanel) {
        const children = enumPanel.FindChildTraverse('RadioButtonsContainer')?.Children() || [];
        for (let i = 0; i < children.length; i++) {
            if (children[i].paneltype === "RadioButton" && children[i].IsSelected()) {
                const val = children[i].GetAttributeString('value', '0');
                $.persistentStorage.setItem('ap_show_map_status_hud', val);
                
                GameInterfaceAPI.ConsoleCommand(`ap_show_map_status_hud ${val}`);
                $.Msg(`[AP] Show Map Status HUD saved and pushed to Server: ${val}`);
                break;
            }
        }
        UpdateMapStatusHUDKeyBinder();
    }
}

function SaveSmartWarpSetting() {
    const dropdown = $('#TransitionTypeSetting');
    if (dropdown) {
        const realDropdown = dropdown.FindChildTraverse('DropDown') as any;
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
        const realDropdown = dropdown.FindChildTraverse('DropDown') as any;
        if (realDropdown) {
            const selected = realDropdown.GetSelected();
            if (selected) {
                const val = selected.GetAttributeInt('value', 0);
                $.persistentStorage.setItem('ap_hide_holograms', val);
                
                GameInterfaceAPI.SetSettingInt('ap_hide_holograms', val);
                GameInterfaceAPI.ConsoleCommand('UpdateHologramsVisibility');
                $.Msg(`[AP] Hide Holograms setting saved: ${val}`);
            }
        }
    }
}

function SaveStatusIndicatorModeSetting() {
    const dropdown = $('#StatusIndicatorModeSetting');
    if (dropdown) {
        const realDropdown = dropdown.FindChildTraverse('DropDown') as any;
        if (realDropdown) {
            const val = realDropdown.GetSelected().GetAttributeInt('value', 0);
            $.persistentStorage.setItem('ap_status_indicator_mode', val);
            
            const statusIndicator = (UiToolkitAPI.GetGlobalObject() as any).ArchipelagoStatusIndicator;
            if (statusIndicator) {
                statusIndicator.refreshVisibility();
            }
            $.Msg(`[AP] Status Indicator Mode saved: ${val}`);
        }
    }
}

function UpdateCompletionSymbolStatus() {
    const hideCounts = $.persistentStorage.getItem('ap_hide_location_counts') ?? "0";
    const dropdown = $('#CompletionSymbolSetting');
    if (dropdown) {
        dropdown.enabled = (hideCounts.toString() === "0");
    }
}

function UpdateMapStatusHUDKeyBinder() {
    const showHUD = $.persistentStorage.getItem('ap_show_map_status_hud') ?? "0";
    const keyBinder = $('#MapStatusKeyBinder');
    if (keyBinder) {
        keyBinder.hittest = true;
        keyBinder.hittestchildren = true;

        if (showHUD.toString() === "1") {
            keyBinder.AddClass('disabled');
            keyBinder.SetPanelEvent('onactivate', () => {});
        } else {
            keyBinder.RemoveClass('disabled');
            keyBinder.SetPanelEvent('onactivate', () => {
                $.DispatchEvent('SettingsKeyBinderActivate', keyBinder);
            });
        }
    }
}

function LoadArchipelagoSettings() {
    // 1. Hide Location Counts
    const hideCountsVal = $.persistentStorage.getItem('ap_hide_location_counts') ?? "0";
    const hideCountsPanel = $('#HideCountsSetting');
    if (hideCountsPanel) {
        const children = hideCountsPanel.FindChildTraverse('RadioButtonsContainer')?.Children() || [];
        for (let i = 0; i < children.length; i++) {
            if (children[i].GetAttributeString('value', '0') === hideCountsVal.toString()) {
                children[i].SetSelected(true);
                break;
            }
        }
    }

    // 2. Completion Symbol
    const compVal = $.persistentStorage.getItem('ap_completion_symbol') ?? "0";
    const compDropdown = $('#CompletionSymbolSetting')?.FindChildTraverse('DropDown') as any;
    if (compDropdown) compDropdown.SetSelected('ap_symbol_' + compVal.toString());

    // 3. HUD Visibility
    const hudVal = $.persistentStorage.getItem('ap_show_map_status_hud') ?? "0";
    const hudPanel = $('#MapStatusHUDSetting');
    if (hudPanel) {
        const children = hudPanel.FindChildTraverse('RadioButtonsContainer')?.Children() || [];
        for (let i = 0; i < children.length; i++) {
            if (children[i].GetAttributeString('value', '0') === hudVal.toString()) {
                children[i].SetSelected(true);
                break;
            }
        }
    }
    GameInterfaceAPI.ConsoleCommand(`ap_show_map_status_hud ${hudVal}`);

    // 4. Smart Warp
    const warpVal = $.persistentStorage.getItem('ap_smart_warp') ?? "0";
    const warpDropdown = $('#TransitionTypeSetting')?.FindChildTraverse('DropDown') as any;
    if (warpDropdown) warpDropdown.SetSelected(warpVal.toString() === "1" ? 'ap_transition_smart' : 'ap_transition_menu');
    
    // 6. Hide Holograms
    const hideHoloValRaw = $.persistentStorage.getItem('ap_hide_holograms') ?? "0";
    const hideHoloDropdown = $('#HideHologramsSetting')?.FindChildTraverse('DropDown') as any;
    if (hideHoloDropdown) hideHoloDropdown.SetSelected('ap_hide_holograms_' + hideHoloValRaw.toString());
    
    const hideHoloValNum = parseInt(hideHoloValRaw.toString(), 10) || 0;
    GameInterfaceAPI.SetSettingInt('ap_hide_holograms', hideHoloValNum);

    // 7. Status Indicator Mode
    const statusIndVal = $.persistentStorage.getItem('ap_status_indicator_mode') ?? "0";
    const statusIndDropdown = $('#StatusIndicatorModeSetting')?.FindChildTraverse('DropDown') as any;
    if (statusIndDropdown) statusIndDropdown.SetSelected('ap_status_indicator_mode_' + statusIndVal.toString());

    UpdateCompletionSymbolStatus();
    UpdateMapStatusHUDKeyBinder();

    $.Schedule(0.2, () => {
        GameInterfaceAPI.ConsoleCommand('UpdateHologramsVisibility');
    });
}

// --- EXPOSITION GLOBALE HARMONISÉE ---
(UiToolkitAPI.GetGlobalObject() as any).SaveHideCountsSetting = SaveHideCountsSetting;
(UiToolkitAPI.GetGlobalObject() as any).SaveCompletionSymbolSetting = SaveCompletionSymbolSetting;
(UiToolkitAPI.GetGlobalObject() as any).SaveMapStatusHUDSetting = SaveMapStatusHUDSetting;
(UiToolkitAPI.GetGlobalObject() as any).SaveSmartWarpSetting = SaveSmartWarpSetting;
(UiToolkitAPI.GetGlobalObject() as any).SaveHideHologramsSetting = SaveHideHologramsSetting;
(UiToolkitAPI.GetGlobalObject() as any).SaveStatusIndicatorModeSetting = SaveStatusIndicatorModeSetting;
(UiToolkitAPI.GetGlobalObject() as any).LoadArchipelagoSettings = LoadArchipelagoSettings;
(UiToolkitAPI.GetGlobalObject() as any).UpdateCompletionSymbolStatus = UpdateCompletionSymbolStatus;
(UiToolkitAPI.GetGlobalObject() as any).UpdateMapStatusHUDKeyBinder = UpdateMapStatusHUDKeyBinder;

$.RegisterEventHandler('PropertyTransitionEnd', $.GetContextPanel(), (panel, propertyName) => {
    if (propertyName === 'opacity' && panel.id === $.GetContextPanel().id && !$.GetContextPanel().IsTransparent()) {
        LoadArchipelagoSettings();
    }
});

LoadArchipelagoSettings();