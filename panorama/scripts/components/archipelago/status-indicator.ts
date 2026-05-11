'use strict';

class ArchipelagoStatusIndicator {
    static init() {
        $.RegisterForUnhandledEvent("ArchipelagoAPI_StatusUpdated", (payload: string) => {
            try {
                this.updateStatus(JSON.parse(payload));
            } catch (e) { }
        });

        // Vérification initiale si l'API est déjà peuplée
        const api = (UiToolkitAPI.GetGlobalObject() as any).ArchipelagoAPI;
        if (api && api.getStatus()) {
            this.updateStatus(api.getStatus());
        }
    }

    static updateStatus(status: any) {
        if (!status) return;

        const serverDot = $('#ServerDot');
        const gameDot = $('#GameDot');

        // L'astuce est le "!!" : cela transforme undefined ou null en false, 
        // et une valeur existante en true. Cela règle l'erreur V8ParamToPanoramaType.
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