'use strict';

$.Msg("CC: Loading Smart-Filter cc.ts (Pooled Slots & PotatOS Mute)...");

interface CaptionSlot {
    panel: Label;
    dummy: Panel;
    active: boolean;
    token: string;
    text: string;
    lifetime: number;
    fading: boolean;
}

class CloseCaptioning {
    static box: Panel;
    static bg: Panel;
    static CAPTION_WIDTH = 1102;
    static POOL_SIZE = 2;

    static slots: Array<CaptionSlot> = [];
    static settings = { bgOpacity: 0.75, fontSize: 20, fontType: 0, textAlign: 0 };
    static m_Time: number = 0;
    static lastCaptionText: string = "";

    static init() {
        this.box = $<Panel>('#CaptionsBox')!;
        this.bg = $<Panel>('#CaptionsBg')!;

        const _ctx = $.GetContextPanel();
        if (!_ctx || !this.box || !this.bg) return;

        // Initialize static panel pool once
        this.slots = [];
        for (let i = 0; i < this.POOL_SIZE; i++) {
            let style = `font-size: ${this.settings.fontSize}px;`;
            if (this.settings.textAlign === 1) style += ' text-align: center;';
            else if (this.settings.textAlign === 2) style += ' text-align: right;';

            const panel = $.CreatePanel('Label', this.box, `CaptionLabel_${i}`, {
                class: 'closecaptions__text',
                style: style,
                html: true,
                text: ''
            });

            const dummy = $.CreatePanel('Panel', this.bg, `CaptionDummy_${i}`, {
                class: 'closecaptions__dummy'
            });

            panel.style.width = `${this.CAPTION_WIDTH}px`;
            panel.style.opacity = 0;
            panel.style.height = '0px';

            dummy.style.width = `${this.CAPTION_WIDTH}px`;
            dummy.style.height = '0px';
            dummy.style.opacity = 0;

            this.slots.push({
                panel: panel,
                dummy: dummy,
                active: false,
                token: '',
                text: '',
                lifetime: 0,
                fading: false
            });
        }

        // 1. DÉFINITION DE L'ÉVÉNEMENT
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

            // Filtre Back-to-Back
            if (this.lastCaptionText === caption.text) {
                return;
            }
            this.lastCaptionText = caption.text;

            const now = (time !== undefined && time > 0) ? time : this.m_Time;
            const duration = (lifetime < 0.1) ? 0.1 : lifetime;

            // Find an inactive slot, or the oldest slot to replace
            let targetSlot: CaptionSlot = this.slots[0];
            let foundInactive = false;
            for (let i = 0; i < this.slots.length; i++) {
                if (!this.slots[i].active) {
                    targetSlot = this.slots[i];
                    foundInactive = true;
                    break;
                }
            }

            if (!foundInactive) {
                // Pick slot with earliest lifetime
                let oldestIdx = 0;
                let earliestLife = this.slots[0].lifetime;
                for (let i = 1; i < this.slots.length; i++) {
                    if (this.slots[i].lifetime < earliestLife) {
                        earliestLife = this.slots[i].lifetime;
                        oldestIdx = i;
                    }
                }
                targetSlot = this.slots[oldestIdx];
            }

            // Update slot in-place
            targetSlot.active = true;
            targetSlot.fading = false;
            targetSlot.token = token || '';
            targetSlot.text = caption.text;
            targetSlot.lifetime = now + duration;

            targetSlot.panel.text = caption.text;
            const textHeight = targetSlot.panel.GetHeightForText(this.CAPTION_WIDTH, targetSlot.panel.text);
            const h = textHeight > 0 ? textHeight : 24;

            targetSlot.panel.style.height = `${h}px`;
            targetSlot.panel.style.opacity = 1;

            targetSlot.dummy.style.height = `${h + 4}px`;
            targetSlot.dummy.style.opacity = 1;

            if (this.bg && this.bg.IsValid()) {
                this.bg.style.opacity = 1;
            }
        };

        _displayHandle = $.RegisterForUnhandledEvent('DisplayCaptionRequest', onDisplay as any);

        // 4. L'HORLOGE DES SOUS-TITRES
        $.RegisterEventHandler('CaptionTick', $.GetContextPanel(), (time: number) => {
            this.m_Time = time;
            let anyActive = false;

            for (let i = 0; i < this.slots.length; i++) {
                const slot = this.slots[i];
                if (!slot.active) continue;

                if (time >= slot.lifetime) {
                    if (!slot.fading) {
                        slot.fading = true;
                        if (slot.panel && slot.panel.IsValid()) slot.panel.style.opacity = 0;
                        if (slot.dummy && slot.dummy.IsValid()) slot.dummy.style.height = '0px';
                    }

                    if (time >= slot.lifetime + 0.3) {
                        slot.active = false;
                        slot.fading = false;
                        slot.text = '';
                        if (slot.panel && slot.panel.IsValid()) {
                            slot.panel.style.height = '0px';
                            slot.panel.text = '';
                        }
                    } else {
                        anyActive = true;
                    }
                } else {
                    anyActive = true;
                }
            }

            if (!anyActive) {
                this.lastCaptionText = "";
                if (this.bg && this.bg.IsValid()) {
                    this.bg.style.opacity = 0;
                }
            }
        });

        let _mapUnloadHandle: number = -1;
        _mapUnloadHandle = $.RegisterForUnhandledEvent('MapUnloaded', () => {
            if (!_ctx || !_ctx.IsValid()) { $.UnregisterForUnhandledEvent('MapUnloaded', _mapUnloadHandle); return; }
            this.wipeCaptions();
        });
    }

    static wipeCaptions() {
        this.lastCaptionText = "";
        for (let i = 0; i < this.slots.length; i++) {
            const slot = this.slots[i];
            slot.active = false;
            slot.fading = false;
            slot.text = '';
            slot.token = '';
            slot.lifetime = 0;

            if (slot.panel && slot.panel.IsValid()) {
                slot.panel.style.opacity = 0;
                slot.panel.style.height = '0px';
                slot.panel.text = '';
            }
            if (slot.dummy && slot.dummy.IsValid()) {
                slot.dummy.style.opacity = 0;
                slot.dummy.style.height = '0px';
            }
        }

        if (this.bg && this.bg.IsValid()) {
            this.bg.style.opacity = 0;
        }
    }
}

(function () { CloseCaptioning.init(); })();
