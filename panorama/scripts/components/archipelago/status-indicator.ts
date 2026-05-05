'use strict';

class ArchipelagoStatusIndicator {
    static init() {
        $.RegisterForUnhandledEvent("ArchipelagoAPI_StatusUpdated", (payload: string) => {
            this.updateStatus(JSON.parse(payload));
        });

        // Initial check if API is already populated
        const api = (UiToolkitAPI.GetGlobalObject() as any).ArchipelagoAPI;
        if (api && api.getStatus()) {
            this.updateStatus(api.getStatus());
        }
    }

    static updateStatus(status: any) {
        const serverDot = $('#ServerDot');
        const gameDot = $('#GameDot');

        if (serverDot) {
            serverDot.SetHasClass('ap-status__dot--connected', status.connected);
            serverDot.SetHasClass('ap-status__dot--disconnected', !status.connected);
        }

        if (gameDot) {
            gameDot.SetHasClass('ap-status__dot--connected', status.game_connected);
            gameDot.SetHasClass('ap-status__dot--disconnected', !status.game_connected);
        }
    }
}

(function() {
    ArchipelagoStatusIndicator.init();
})();
