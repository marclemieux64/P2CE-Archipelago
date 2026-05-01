'use strict';

function UpdateCompletionSymbolStatus() {
    const hideCounts = $.persistentStorage.getItem('ap_hide_location_counts') ?? 0;
    const dropdown = $('#CompletionSymbolSetting');
    if (dropdown) {
        // If hideCounts is 1 (True), disable the dropdown
        dropdown.enabled = (hideCounts === 0);
    }
}

function UpdateMapStatusHUDKeyBinder() {
    const showHUD = $.persistentStorage.getItem('ap_show_map_status_hud') ?? 1;
    const keyBinder = $('#MapStatusKeyBinder');
    if (keyBinder) {
        keyBinder.enabled = (showHUD === 1);
    }
}

// Expose to the global object so parent scripts (like settings.ts) can find it
(UiToolkitAPI.GetGlobalObject() as any).UpdateCompletionSymbolStatus = UpdateCompletionSymbolStatus;
(UiToolkitAPI.GetGlobalObject() as any).UpdateMapStatusHUDKeyBinder = UpdateMapStatusHUDKeyBinder;

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
