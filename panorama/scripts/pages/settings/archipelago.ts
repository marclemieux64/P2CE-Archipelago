'use strict';

function UpdateCompletionSymbolStatus() {
    const hideCounts = $.persistentStorage.getItem('ap_hide_location_counts') ?? 0;
    const dropdown = $('#CompletionSymbolSetting');
    if (dropdown) {
        // If hideCounts is 1 (True), disable the dropdown
        dropdown.enabled = (hideCounts === 0);
    }
}

// Expose to the global object so parent scripts (like settings.ts) can find it
(UiToolkitAPI.GetGlobalObject() as any).UpdateCompletionSymbolStatus = UpdateCompletionSymbolStatus;

(function() {
    $.RegisterEventHandler('PropertyTransitionEnd', $.GetContextPanel(), (panel, propertyName) => {
        if (propertyName === 'opacity' && !$.GetContextPanel().IsTransparent()) {
            UpdateCompletionSymbolStatus();
        }
    });

    UpdateCompletionSymbolStatus();
})();
