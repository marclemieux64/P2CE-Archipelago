'use strict';

if (!$.Msg) { $.Msg = (UiToolkitAPI.GetGlobalObject() as any).Msg; }

function RunConsoleCommandIfInGame(cmd: string) {
    if (GameInterfaceAPI.GetGameUIState() === GameUIState.PAUSEMENU) {
        GameInterfaceAPI.ConsoleCommand(cmd);
    }
}


// Called by submitoverride on TransitionType dropdown.
function SaveSmartWarpSetting() {
    const panel = $('#TransitionTypeSetting');
    if (!panel) return;
    const dropdown = panel.FindChildTraverse('DropDown');
    if (!dropdown) return;
    const selected = (dropdown as DropDown).GetSelected();
    if (!selected) return;
    const val = selected.GetAttributeInt('value', 0);
    $.persistentStorage.setItem('cv_SmartWarp', val);
}

// Called by activateoverride on MapStatusHUD radio buttons.
function SaveMapStatusHUDSetting() {
    const enumPanel = $('#MapStatusHUDSetting');
    if (!enumPanel) return;
    const children = enumPanel.FindChildTraverse('values')?.Children() || [];
    for (let i = 0; i < children.length; i++) {
        if (children[i].paneltype === 'RadioButton' && (children[i] as RadioButton).IsSelected()) {
            const val = parseInt(children[i].GetAttributeString('value', '0'), 10);
            $.persistentStorage.setItem('cv_ShowMapStatusHUD', val);
            GameInterfaceAPI.ConsoleCommand(`cv_ShowMapStatusHUD ${val}`);
            const mapStatusHUD = (UiToolkitAPI.GetGlobalObject() as any).ArchipelagoMapStatusHUD;
            if (mapStatusHUD && mapStatusHUD.m_CurrentMapName) {
                mapStatusHUD.updateStatus(mapStatusHUD.m_CurrentMapName, false, val === 0);
            }
            break;
        }
    }
}

// Called by submitoverride on HideHolograms dropdown.
function SaveHideHologramsSetting() {
    const panel = $('#HideHologramsSetting');
    if (!panel) return;
    const dropdown = panel.FindChildTraverse('DropDown');
    if (!dropdown) return;
    const selected = (dropdown as DropDown).GetSelected();
    if (!selected) return;
    const val = selected.GetAttributeInt('value', 0);
    $.persistentStorage.setItem('cv_HideHolograms', val);
    GameInterfaceAPI.ConsoleCommand(`cv_HideHolograms ${val}`);
    RunConsoleCommandIfInGame('UpdateHologramsVisibility');
}

// Called by submitoverride on StatusIndicatorMode dropdown.
function SaveStatusIndicatorModeSetting() {
    const panel = $('#StatusIndicatorModeSetting');
    if (!panel) return;
    const dropdown = panel.FindChildTraverse('DropDown');
    if (!dropdown) return;
    const val = (dropdown as DropDown).GetSelected()?.GetAttributeInt('value', 0) ?? 0;
    $.persistentStorage.setItem('cv_StatusIndicatorMode', val);
    const statusIndicator = (UiToolkitAPI.GetGlobalObject() as any).ArchipelagoStatusIndicator;
    if (statusIndicator) statusIndicator.refreshVisibility();
}

// Syncs all skip-related convars from persistentStorage to the game engine.
// Called by every skip RadioButton's activateoverride, and on settings page open.
function SyncSkipSettingsIfInGame() {
    const skipConvars = ['cv_SkipElevatorRide', 'cv_SkipIntroContainerScene', 'cv_SkipBirdScene', 'cv_SkipCeilingScene'];
    for (const convar of skipConvars) {
        const val = $.persistentStorage.getItem(convar) ?? 0;
        GameInterfaceAPI.ConsoleCommand(`${convar} ${val}`);
    }
}

function loadSettingsEnum(panelId: string, psKey: string, defaultVal: number) {
    const stored = $.persistentStorage.getItem(psKey);
    const val = (stored !== null && stored !== undefined) ? parseInt(String(stored), 10) : defaultVal;
    const panel = ($('#' + panelId) as Panel);
    if (!panel) return;
    const children = (panel.FindChildTraverse('values') as Panel)?.Children() || [];
    for (let i = 0; i < children.length; i++) {
        const child = children[i] as RadioButton;
        if (child.paneltype === 'RadioButton') {
            const btnVal = parseInt(child.GetAttributeString('value', '-1'), 10);
            if (btnVal === val) { child.selected = true; break; }
        }
    }
}

// Restore dropdown visual state when the settings page is shown.
// initPersistentStorageEnumDropdown uses SetSelectedIndex which is index-based;
// SetSelected by ID is more reliable when stored values may not align with indices.
function LoadArchipelagoSettings() {
    const warpVal = $.persistentStorage.getItem('cv_SmartWarp') ?? 0;
    const warpDropdown = ($('#TransitionTypeSetting') as Panel)?.FindChildTraverse('DropDown') as DropDown;
    if (warpDropdown) warpDropdown.SetSelected(String(warpVal) === '1' ? 'ap_transition_smart' : 'ap_transition_menu');

    const hideHoloVal = parseInt(String($.persistentStorage.getItem('cv_HideHolograms') ?? '0'), 10);
    const hideHoloDropdown = ($('#HideHologramsSetting') as Panel)?.FindChildTraverse('DropDown') as DropDown;
    if (hideHoloDropdown) hideHoloDropdown.SetSelected('cv_HideHolograms_' + hideHoloVal);
    GameInterfaceAPI.ConsoleCommand(`cv_HideHolograms ${hideHoloVal}`);

    const statusIndVal = parseInt(String($.persistentStorage.getItem('cv_StatusIndicatorMode') ?? '0'), 10);
    const statusIndDropdown = ($('#StatusIndicatorModeSetting') as Panel)?.FindChildTraverse('DropDown') as DropDown;
    if (statusIndDropdown) statusIndDropdown.SetSelected('cv_StatusIndicatorMode_' + statusIndVal);

    loadSettingsEnum('AutoSmartWarpSetting', 'cv_AutoSmartWarp', 1);
    loadSettingsEnum('ReleasePromptSetting', 'cv_ReleasePrompt', 1);

    SyncSkipSettingsIfInGame();
}

(UiToolkitAPI.GetGlobalObject() as any).SaveSmartWarpSetting = SaveSmartWarpSetting;
(UiToolkitAPI.GetGlobalObject() as any).SaveMapStatusHUDSetting = SaveMapStatusHUDSetting;
(UiToolkitAPI.GetGlobalObject() as any).SyncSkipSettingsIfInGame = SyncSkipSettingsIfInGame;
(UiToolkitAPI.GetGlobalObject() as any).SaveHideHologramsSetting = SaveHideHologramsSetting;
(UiToolkitAPI.GetGlobalObject() as any).SaveStatusIndicatorModeSetting = SaveStatusIndicatorModeSetting;

$.GetContextPanel().OnShow = () => { LoadArchipelagoSettings(); };
LoadArchipelagoSettings();
