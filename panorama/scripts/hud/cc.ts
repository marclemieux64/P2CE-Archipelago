'use strict';

$.Msg("CC: Loading Smart-Filter cc.ts (Back-to-back blocking only)...");

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
            if (prop === 'opacity' && this.panel.IsTransparent()) {
                this.dummy.style.height = '0px';
                $.RegisterEventHandler('PropertyTransitionEnd', this.dummy, (ds: string, dprop: keyof Style) => {
                    if (dprop === 'height') { this.bReadyToPurge = true; }
                });
            }
        });
    }

    FadeOut() {
        if (!this.panel || !this.panel.IsValid() || this.bMarkedForDeletion) return;
        this.panel.style.opacity = 0;
        this.bMarkedForDeletion = true;
        $.Schedule(1.2, () => { this.bReadyToPurge = true; });
    }
}

class CloseCaptioning {
    static captions: Array<CaptionEntry> = [];
    static box: Panel;
    static bg: Panel;
    static CAPTION_WIDTH = 1102;
    static MAX_VISIBLE = 2; 
    
    static settings = { bgOpacity: 0.75, fontSize: 20, fontType: 0, textAlign: 0 };
    static m_Time: number = 0;

    static init() {
        this.box = $<Panel>('#CaptionsBox')!;
        this.bg = $<Panel>('#CaptionsBg')!;

        const onDisplay = (token: string, caption: any, lifetime: number, time: number) => {
            if (!caption || !caption.text) return;

            // 1. FILTRE "BACK-TO-BACK"
            if (this.captions.length > 0) {
                const lastEntry = this.captions[this.captions.length - 1];
                if (lastEntry.text === caption.text) {
                    return; 
                }
            }

            // 2. ÉJECTION SI PLEIN
            if (this.captions.length >= this.MAX_VISIBLE) {
                this.captions[0].FadeOut();
            }

            const now = (time !== undefined && time > 0) ? time : this.m_Time;
            const duration = (lifetime < 0.5) ? 1.0 : lifetime;

            this.captions.push(new CaptionEntry(token, caption, now + duration));
            if (this.bg) this.bg.style.opacity = 1;
        };

        // CORRECTION : On ne garde que DisplayCaptionRequest car DisplayCaption n'est pas un Event Panorama valide
        $.RegisterForUnhandledEvent('DisplayCaptionRequest', onDisplay as any);

        $.RegisterEventHandler('CaptionTick', $.GetContextPanel(), (time: number) => {
            this.m_Time = time;
            if (this.captions.length === 0) return;

            for (let i = this.captions.length - 1; i >= 0; i--) {
                const c = this.captions[i];
                if (time >= c.lifetime) {
                    c.FadeOut();
                }
                if (c.bReadyToPurge || (time > c.lifetime + 1.5)) { // Sécurité supplémentaire sur le cleanup
                    if (c.panel && c.panel.IsValid()) c.panel.DeleteAsync(0);
                    if (c.dummy && c.dummy.IsValid()) c.dummy.DeleteAsync(0);
                    this.captions.splice(i, 1);
                }
            }
            if (this.captions.length === 0 && this.bg) this.bg.style.opacity = 0;
        });

        $.RegisterForUnhandledEvent('MapUnloaded', () => this.wipeCaptions());
    }

    static wipeCaptions() {
        this.captions = [];
        if (this.box) this.box.RemoveAndDeleteChildren();
        if (this.bg) {
            this.bg.RemoveAndDeleteChildren();
            this.bg.style.opacity = 0;
        }
    }
}

(function () { CloseCaptioning.init(); })();