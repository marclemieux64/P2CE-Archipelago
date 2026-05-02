'use strict';
if (!$.Msg) { $.Msg = (UiToolkitAPI.GetGlobalObject() as any).Msg; }

function UpdateCompletionSymbolStatus() {
    const hideCounts = $.persistentStorage.getItem('ap_hide_location_counts') ?? 0;
    const dropdown = $('#CompletionSymbolSetting');
    if (dropdown) {
        // Use loose equality to handle string/number mismatch from PS
        dropdown.enabled = (hideCounts == 0);
    }
}

function UpdateMapStatusHUDKeyBinder() {
    const showHUD = $.persistentStorage.getItem('ap_show_map_status_hud') ?? 1;
    const keyBinder = $('#MapStatusKeyBinder');
    if (keyBinder) {
        // Use loose equality to handle string/number mismatch from PS
        keyBinder.enabled = (showHUD == 1);
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
