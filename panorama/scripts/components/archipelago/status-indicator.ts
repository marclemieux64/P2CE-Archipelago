'use strict';

class ArchipelagoStatusIndicator {
    static init() {
        // --- CORRECTIF SÉCURISÉ POUR L'ÉVÉNEMENT API ---
        $.RegisterForUnhandledEvent("ArchipelagoAPI_StatusUpdated", (payload: any) => {
            try {
                // On s'adapte de manière transparente si le payload est une string brute ou un objet
                let status = payload;
                if (typeof payload === 'string') {
                    status = JSON.parse(payload);
                }
                this.updateStatus(status);
            } catch (e) { }
        });

        // Vérification initiale si l'API est déjà peuplée
        const api = (UiToolkitAPI.GetGlobalObject() as any).ArchipelagoAPI;
        if (api && api.getStatus()) {
            let initialStatus = api.getStatus();
            // Double sécurité au cas où le cache de démarrage synchrone retournerait une string
            if (typeof initialStatus === 'string') {
                try { initialStatus = JSON.parse(initialStatus); } catch(e) {}
            }
            this.updateStatus(initialStatus);
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