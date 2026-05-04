'use strict';

$.Msg("CC: Loading cc.ts...");

const CCSetting = {
	BG_OPACITY: 'cc.bg_opacity',
	FONT_SIZE: 'cc.font_size',
	FONT_TYPE: 'cc.font',
	TEXT_ALIGN: 'cc.text_align',
	BOX_WIDTH: 'cc.box_width'
};

interface Caption {
	bLowPriority: boolean;
	bSFX: boolean;
	nNoRepeat: number;
	nDelay: number;
	flLifetimeOverride: number;
	text: string;
	options: Map<string, string>;
}

class CaptionEntry {
	lifetime: number;
	panel: Label;
	dummy: Panel;
	bMarkedForDeletion: boolean = false;
	bReadyToPurge: boolean = false;
	height: number;
	token: string;

	constructor(token: string, caption: any, lifetime: number) {
		this.lifetime = lifetime;
		this.token = token;

		let style = `font-size: ${CloseCaptioning.settings.fontSize}px;`;
		switch (CloseCaptioning.settings.textAlign) {
			default:
			case 0: style += 'text-align: left;'; break;
			case 1: style += 'text-align: center;'; break;
			case 2: style += 'text-align: right;'; break;
		}

		switch (CloseCaptioning.settings.fontType) {
			case 0: style += "font-family: 'Lexend';transform: translateY(-1px);"; break;
			case 1: style += "font-family: 'Univers LT Std 47 Cn Lt';"; break;
			case 2: style += "font-family: 'GorDIN';"; break;
			case 3: style += "font-family: 'Verdana';"; break;
			case 4: style += "font-family: 'Noto Sans';"; break;
			case 5: style += "font-family: 'Stratum2';"; break;
			default: style += "font-family: 'Lexend';"; break;
		}

		if (CloseCaptioning.settings.bgOpacity === 0.0) {
			style += 'text-shadow: 2px 2px 1px 2 rgb(0,0,0);';
		}

		const parent = CloseCaptioning.box || $<Panel>('#CaptionsBox');
		const bgParent = CloseCaptioning.bg || $<Panel>('#CaptionsBg');

		if (!parent || !bgParent) {
			$.Msg("CC: ERROR: Panels not found during CaptionEntry creation!");
			return;
		}

		this.panel = $.CreatePanel('Label', parent, '', {
			class: 'closecaptions__text',
			style: style,
			html: true,
			text: caption.text
		});

		this.dummy = $.CreatePanel('Panel', bgParent, '', {
			class: 'closecaptions__dummy'
		});

		this.panel.style.width = `${CloseCaptioning.CAPTION_WIDTH}px`;
		this.dummy.style.width = `${CloseCaptioning.CAPTION_WIDTH}px`;

		const rawText = (caption && caption.text) ? caption.text : '';
		const localizedText = (rawText.indexOf('cheaptitles') !== -1 && rawText.indexOf('#') === -1) ? $.Localize('#' + rawText) : $.Localize(rawText);
		const textToMeasure = this.panel.text || localizedText.replace(/<[^>]*>?/gm, '');
		this.height = this.panel.GetHeightForText(CloseCaptioning.CAPTION_WIDTH, textToMeasure);
		if (this.height <= 0) this.height = 24;

		this.panel.style.opacity = 1;
		this.panel.style.height = `${this.height}px`;
		this.dummy.style.height = `${this.height + 4}px`;

		$.RegisterEventHandler('PropertyTransitionEnd', this.panel, (s: string, prop: keyof Style) => {
			if (prop === 'opacity' && this.panel.IsTransparent()) {
				this.dummy.style.height = '0px';
				$.RegisterEventHandler('PropertyTransitionEnd', this.dummy, (s: string, prop: keyof Style) => {
					if (prop === 'height') { this.bReadyToPurge = true; }
				});
			}
		});
	}

	FadeOut() {
		if (!this.panel || !this.panel.IsValid() || this.bMarkedForDeletion) return;
		this.panel.style.opacity = 0;
		this.bMarkedForDeletion = true;
	}
}

class CloseCaptioning {
	static captions: Array<CaptionEntry> = [];
	static box: Panel;
	static bg: Panel;
	static CAPTION_WIDTH = 1102;
	static settings = {
		bgOpacity: 0.75,
		fontSize: 20,
		fontType: 0,
		textAlign: 0,
		boxWidth: 1102
	};

	static bPotatosMuted: boolean = false;
	static captionRecord: Map<string, number> = new Map();
	static textCooldowns: Map<string, number> = new Map();

	static getVars() {
		const fontType = $.persistentStorage.getItem(CCSetting.FONT_TYPE);
		if (fontType !== null) this.settings.fontType = Number(fontType);
		const textAlign = $.persistentStorage.getItem(CCSetting.TEXT_ALIGN);
		if (textAlign !== null) this.settings.textAlign = Number(textAlign);
	}

	static init() {
		$.Msg("CC: Initializing CloseCaptioning system...");
		this.box = $<Panel>('#CaptionsBox')!;
		this.bg = $<Panel>('#CaptionsBg')!;
		this.getVars();

		// Helper for absolute time conversion
		const getAbsoluteTime = (lifetime: number, eventTime?: number) => {
			const engineTime = ($.GetContextPanel() as any).GetEngineTime ? ($.GetContextPanel() as any).GetEngineTime() : 0;
			const current = (eventTime !== undefined) ? eventTime : engineTime;
			if (lifetime > 0 && lifetime < 10000) return current + lifetime;
			return (lifetime <= 0) ? current + 5.0 : lifetime;
		};

		const onDisplay = (token: string, caption: any, lifetime: number, time: number) => {
			try {
				if (!caption) return;
				if (this.bPotatosMuted && (token.toLowerCase().includes('glados.') || token.toLowerCase().includes('potatos.'))) return;
				if (this.captionRecord.has(token)) return;

				const rawText = caption.text || '';
				const locText = (rawText.indexOf('cheaptitles') !== -1 && rawText.indexOf('#') === -1) ? $.Localize('#' + rawText) : $.Localize(rawText);
				if (this.textCooldowns.has(locText) && (time - this.textCooldowns.get(locText)!) < 0.1) return;

				this.textCooldowns.set(locText, time);
				this.captionRecord.set(token, time + Math.max(0.5, caption.nNoRepeat || 0));

				let absLife = getAbsoluteTime(lifetime, time);
				if (token.toLowerCase().includes('cheaptitles')) {
					absLife = Math.min(absLife, time + 7.0);
				}

				this.captions.push(new CaptionEntry(token, caption, absLife));
				this.showBox();
			} catch (e) { $.Msg("CC: Error in DisplayCaption (" + token + "): " + e); }
		};

		const onBad = (token: string, lifetime: number, time?: number) => {
			try {
				const absLife = getAbsoluteTime(lifetime, time);
				this.captions.push(new CaptionEntry(token, { text: `[MISSING] ${token}` }, absLife));
				this.showBox();
			} catch (e) { $.Msg("CC: Error in BadCaption: " + e); }
		};

		// Registry with fallbacks
		try { $.RegisterForUnhandledEvent('DisplayCaption', onDisplay); } catch (e) { }
		try { $.RegisterForUnhandledEvent('DisplayCaptionRequest', onDisplay); } catch (e) { }
		try { $.RegisterForUnhandledEvent('BadCaption', onBad); } catch (e) { }
		try { $.RegisterForUnhandledEvent('BadCaptionRequest', onBad); } catch (e) { }
		try {
			$.RegisterForUnhandledEvent('EndCaption', (token: string) => {
				for (const c of this.captions) if (c.token === token) c.FadeOut();
			});
		} catch (e) { }

		$.RegisterEventHandler('CaptionTick', $.GetContextPanel(), (time: number) => {
			if (this.captions.length === 0) return;
			for (let i = this.captions.length - 1; i >= 0; i--) {
				const c = this.captions[i];
				if (time >= c.lifetime) {
					if (c.bReadyToPurge) {
						if (c.panel.IsValid()) c.panel.DeleteAsync(0);
						if (c.dummy.IsValid()) c.dummy.DeleteAsync(0);
						if (!c.panel.IsValid() && !c.dummy.IsValid()) this.captions.splice(i, 1);
					} else { c.FadeOut(); }
				}
			}
			if (this.captions.length === 0) this.hideBox();
			for (const [tok, life] of this.captionRecord) if (time >= life) this.captionRecord.delete(tok);
			for (const [txt, life] of this.textCooldowns) if (time >= life) this.textCooldowns.delete(txt);
		});

		$.RegisterForUnhandledEvent('ArchipelagoMutePotatos', (active: string) => {
			this.bPotatosMuted = (active === '1');
			if (this.bPotatosMuted) this.wipeCaptions();
		});

		$.RegisterForUnhandledEvent('MapUnloaded', () => this.wipeCaptions());
		$.RegisterForUnhandledEvent('MapLoaded', () => this.wipeCaptions());
		$.RegisterForUnhandledEvent('GameUIStateChanged', () => this.updateStyle());

		this.updateStyle();
	}

	static updateStyle() {
		$.GetContextPanel().SetHasClass('MainMenu', GameInterfaceAPI.GetGameUIState() === 1); // 1 is MAINMENU
	}

	static showBox() { if (this.bg) this.bg.style.opacity = 1; }
	static hideBox() { if (this.bg) this.bg.style.opacity = 0; }
	static wipeCaptions() {
		this.captions = [];
		if (this.box) this.box.RemoveAndDeleteChildren();
		if (this.bg) this.bg.RemoveAndDeleteChildren();
		this.hideBox();
	}
}

// Global scope initialization
(function () {
	CloseCaptioning.init();
})();
