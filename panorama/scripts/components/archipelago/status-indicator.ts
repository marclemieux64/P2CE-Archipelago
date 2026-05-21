'use strict';

class ArchipelagoStatusIndicator {
    static init() {
        const api = (UiToolkitAPI.GetGlobalObject() as any).ArchipelagoAPI;
        if (api) {
            api.registerStatusListener($.GetContextPanel(), (payload: any) => {
                try {
                    let status = payload;
                    if (typeof payload === 'string') {
                        status = JSON.parse(payload);
                    }
                    this.updateStatus(status);
                } catch (e) { }
            });
        }
    }

    static updateStatus(status: any) {
        if (!status) return;

        const serverDot = $('#ServerDot');
        const gameDot = $('#GameDot');

        // L'astuce du "!!" convertit proprement n'importe quel type en booléen strict,
        // ce qui évite définitivement l'erreur native V8ParamToPanoramaType.
        if (serverDot) {
            const isServerConnected = !!status.connected;
            serverDot.SetHasClass('ap-status__dot--connected', isServerConnected);
            serverDot.SetHasClass('ap-status__dot--disconnected', !isServerConnected);
        }

        if (gameDot) {
            const isGameConnected = !!status.game_connected;
            gameDot.SetHasClass('ap-status__dot--connected', isGameConnected);
            gameDot.SetHasClass('ap-status__dot--disconnected', !isGameConnected);
        }
    }
}

(function() {
    ArchipelagoStatusIndicator.init();
})();