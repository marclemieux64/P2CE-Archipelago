'use strict';
if (!$.Msg) { $.Msg = (UiToolkitAPI.GetGlobalObject() as any).Msg; }

function UpdateCompletionSymbolStatus() {
    const dropdown = $('#CompletionSymbolSetting');
    if (dropdown) {
        dropdown.enabled = true;
    }
}

function UpdateMapStatusHUDKeyBinder() {
    const showHUD = $.persistentStorage.getItem('ap_show_map_status_hud') ?? 0;
    const keyBinder = $('#MapStatusKeyBinder');
    if (keyBinder) {
        // Disable manual invocation when "Hide" is ON, as it's intended for map entry only
        keyBinder.enabled = (showHUD == 0);
    }
}

function SaveSmartWarpSetting() {
    const dropdown = $('#TransitionTypeSetting');
    if (dropdown) {
        // Find the internal dropdown child
        const realDropdown = dropdown.FindChildTraverse('DropDown');
        if (realDropdown) {
            const selected = realDropdown.GetSelected();
            if (selected) {
                const val = selected.GetAttributeInt('value', -1);
                $.persistentStorage.setItem('ap_smart_warp', val);
                // Also set convar for the engine/AngelScript to read
                GameInterfaceAPI.SetSettingInt('ap_smart_warp', val);
                $.Msg(`[AP] Smart Warp setting saved: ${val}`);
            }
        }
    }
}

// Expose to the global object so parent scripts (like settings.ts) can find it
(UiToolkitAPI.GetGlobalObject() as any).UpdateCompletionSymbolStatus = UpdateCompletionSymbolStatus;
(UiToolkitAPI.GetGlobalObject() as any).UpdateMapStatusHUDKeyBinder = UpdateMapStatusHUDKeyBinder;
(UiToolkitAPI.GetGlobalObject() as any).SaveSmartWarpSetting = SaveSmartWarpSetting;

(function () {
    $.RegisterEventHandler('PropertyTransitionEnd', $.GetContextPanel(), (panel, propertyName) => {
        if (propertyName === 'opacity' && !$.GetContextPanel().IsTransparent()) {
            UpdateCompletionSymbolStatus();
            UpdateMapStatusHUDKeyBinder();
        }
    });

    UpdateCompletionSymbolStatus();
    UpdateMapStatusHUDKeyBinder();
})();
