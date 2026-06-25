'use strict';

$.Msg("CC: Loading Smart-Filter cc.ts (Back-to-back blocking & PotatOS Mute)...");

class CaptionEntry {
    lifetime: number;
    panel: Label;
    dummy: Panel;
    bMarkedForDeletion: boolean = false;
    bReadyToPurge: boolean = false;
    height: number;
    token: string;
    text: string;

    constructor(token: string, caption: any, lifetime: number) {
        this.lifetime = lifetime;
        this.token = token;
        this.text = caption.text || "";

        let style = `font-size: ${CloseCaptioning.settings.fontSize}px; font-family: 'Lexend';`;
        if (CloseCaptioning.settings.textAlign === 1) style += 'text-align: center;';
        else if (CloseCaptioning.settings.textAlign === 2) style += 'text-align: right;';

        this.panel = $.CreatePanel('Label', CloseCaptioning.box, '', {
            class: 'closecaptions__text',
            style: style,
            html: true,
            text: this.text
        });

        this.dummy = $.CreatePanel('Panel', CloseCaptioning.bg, '', {
            class: 'closecaptions__dummy'
        });

        this.panel.style.width = `${CloseCaptioning.CAPTION_WIDTH}px`;
        this.height = this.panel.GetHeightForText(CloseCaptioning.CAPTION_WIDTH, this.panel.text);

        this.panel.style.opacity = 1;
        this.panel.style.height = `${this.height > 0 ? this.height : 24}px`;
        this.dummy.style.height = `${(this.height > 0 ? this.height : 24) + 4}px`;

        $.RegisterEventHandler('PropertyTransitionEnd', this.panel, (s: string, prop: keyof Style) => {
            if (prop === 'opacity' && this.panel && this.panel.IsValid() && this.panel.IsTransparent()) {
                if (this.dummy && this.dummy.IsValid()) {
                    this.dummy.style.height = '0px';
                    $.RegisterEventHandler('PropertyTransitionEnd', this.dummy, (ds: string, dprop: keyof Style) => {
                        if (dprop === 'height') { this.bReadyToPurge = true; }
                    });
                }
            }
        });
    }

    FadeOut() {
        if (!this.panel || !this.panel.IsValid() || this.bMarkedForDeletion) return;
        this.panel.style.opacity = 0;
        this.bMarkedForDeletion = true;
        $.Schedule(0.1, () => { this.bReadyToPurge = true; });
    }
}

class CloseCaptioning {
    static captions: Array<CaptionEntry> = [];
    static box: Panel;
    static bg: Panel;
    static CAPTION_WIDTH = 1102;
    static MAX_VISIBLE = 1;

    static settings = { bgOpacity: 0.75, fontSize: 20, fontType: 0, textAlign: 0 };
    static m_Time: number = 0;

    static init() {
        this.box = $<Panel>('#CaptionsBox')!;
        this.bg = $<Panel>('#CaptionsBg')!;

        const _ctx = $.GetContextPanel();

        // 1. DÉFINITION DE L'ÉVÉNEMENT (Une seule fois au démarrage)
        $.DefineEvent('MutePotatos', 1, 'active', 'Mutes all PotatOS/GLaDOS related captions');

        // 2. RÉCEPTION DU SIGNAL DE SOURDINE
        let _muteHandle: number = -1;
        _muteHandle = $.RegisterForUnhandledEvent('MutePotatos', (active: string) => {
            if (!_ctx || !_ctx.IsValid()) { $.UnregisterForUnhandledEvent('MutePotatos', _muteHandle); return; }
            $.persistentStorage.setItem('MutePotatos', active);

            if (active === '1') {
                CloseCaptioning.wipeCaptions();
                $.Msg("CC: PotatOS/GLaDOS Subtitles are now MUTED (Saved to persistent storage).");
            } else {
                $.Msg("CC: PotatOS/GLaDOS Subtitles are now UNMUTED (Saved to persistent storage).");
            }
        });

        // 3. AFFICHAGE DES SOUS-TITRES
        let _displayHandle: number = -1;
        const onDisplay = (token: string, caption: any, lifetime: number, time: number) => {
            if (!_ctx || !_ctx.IsValid()) { $.UnregisterForUnhandledEvent('DisplayCaptionRequest', _displayHandle); return; }
            if (!caption || !caption.text) return;

            // Filtre Sourdine
            if ($.persistentStorage.getItem('MutePotatos') === '1') {
                if (token && token.toLowerCase().indexOf('potatos') !== -1) {
                    $.Msg("CC: Blocking muted caption: " + token);
                    return;
                }
            }

            // 4. FILTRE "BACK-TO-BACK"
            if (this.captions.length > 0) {
                const lastEntry = this.captions[this.captions.length - 1];
                if (lastEntry.text === caption.text) {
                    return;
                }
            }

            // 5. ÉJECTION SI PLEIN
            if (this.captions.length >= this.MAX_VISIBLE) {
                this.captions[0].FadeOut();
            }

            const now = (time !== undefined && time > 0) ? time : this.m_Time;
            const duration = (lifetime < 0.1) ? 0.1 : lifetime;

            this.captions.push(new CaptionEntry(token, caption, now + duration));
            if (this.bg) this.bg.style.opacity = 1;
        };

        _displayHandle = $.RegisterForUnhandledEvent('DisplayCaptionRequest', onDisplay as any);

        // 6. L'HORLOGE DES SOUS-TITRES
        $.RegisterEventHandler('CaptionTick', $.GetContextPanel(), (time: number) => {
            this.m_Time = time;
            if (this.captions.length === 0) return;

            for (let i = this.captions.length - 1; i >= 0; i--) {
                const c = this.captions[i];
                if (time >= c.lifetime) {
                    c.FadeOut();
                }
                if (c.bReadyToPurge || (time > c.lifetime + 1.5)) {
                    if (c.panel && c.panel.IsValid()) c.panel.DeleteAsync(0);
                    if (c.dummy && c.dummy.IsValid()) c.dummy.DeleteAsync(0);
                    this.captions.splice(i, 1);
                }
            }
            if (this.captions.length === 0 && this.bg) this.bg.style.opacity = 0;
        });

        let _mapUnloadHandle: number = -1;
        _mapUnloadHandle = $.RegisterForUnhandledEvent('MapUnloaded', () => {
            if (!_ctx || !_ctx.IsValid()) { $.UnregisterForUnhandledEvent('MapUnloaded', _mapUnloadHandle); return; }
            this.wipeCaptions();
        });
    }

    static wipeCaptions() {
        // CORRECTION : Supprimer d'abord explicitement les panels via l'API asynchrone sécurisée
        for (let i = 0; i < this.captions.length; i++) {
            const c = this.captions[i];
            if (c.panel && c.panel.IsValid()) {
                c.panel.DeleteAsync(0);
            }
            if (c.dummy && c.dummy.IsValid()) {
                c.dummy.DeleteAsync(0);
            }
        }

        this.captions = [];

        // Nettoyage final des conteneurs sans casser l'arborescence de rendu active
        if (this.box && this.box.IsValid()) this.box.RemoveAndDeleteChildren();
        if (this.bg && this.bg.IsValid()) {
            this.bg.RemoveAndDeleteChildren();
            this.bg.style.opacity = 0;
        }
    }
}

(function () { CloseCaptioning.init(); })();
