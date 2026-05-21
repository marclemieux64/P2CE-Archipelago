'use strict';

class ArchipelagoStatusIndicator {
    static lastStatus: any = { connected: false, game_connected: false };

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
        this.refreshVisibility();
    }

    static refreshVisibility() {
        this.updateStatus(this.lastStatus);
    }

    static updateStatus(status: any) {
        if (!status) return;
        this.lastStatus = status;

        const serverDot = $('#ServerDot');
        const gameDot = $('#GameDot');

        const isServerConnected = !!status.connected;
        const isGameConnected = !!status.game_connected;

        // L'astuce du "!!" convertit proprement n'importe quel type en booléen strict,
        // ce qui évite définitivement l'erreur native V8ParamToPanoramaType.
        if (serverDot) {
            serverDot.SetHasClass('ap-status__dot--connected', isServerConnected);
            serverDot.SetHasClass('ap-status__dot--disconnected', !isServerConnected);
        }

        if (gameDot) {
            gameDot.SetHasClass('ap-status__dot--connected', isGameConnected);
            gameDot.SetHasClass('ap-status__dot--disconnected', !isGameConnected);
        }

        // Gestion de la visibilité en fonction du mode de réglage
        const mode = $.persistentStorage.getItem('ap_status_indicator_mode') ?? 0;
        const panel = $.GetContextPanel();
        if (panel) {
            if (mode == 2) {
                // Toujours masquer
                panel.visible = false;
            } else if (mode == 1) {
                // Afficher uniquement si l'un d'eux est rouge (déconnecté)
                const warning = !isServerConnected || !isGameConnected;
                panel.visible = warning;
            } else {
                // Toujours afficher (par défaut)
                panel.visible = true;
            }
        }
    }
}

// Exposition globale pour permettre d'appeler refreshVisibility depuis settings
(UiToolkitAPI.GetGlobalObject() as any).ArchipelagoStatusIndicator = ArchipelagoStatusIndicator;

(function() {
    ArchipelagoStatusIndicator.init();
})();