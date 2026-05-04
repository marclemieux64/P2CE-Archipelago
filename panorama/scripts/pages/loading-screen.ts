'use strict';
if (!$.Msg) { $.Msg = (UiToolkitAPI.GetGlobalObject() as any).Msg; }

class LoadingScreenController {
	static lastLoadedMapName = '';
	static logoEvent: number | undefined = undefined;
	static bgEvent: number | undefined = undefined;
	static bgEvent2: number | undefined = undefined;

	static progressBar = $('#ProgressBar') as ProgressBar;
	static bgImage1 = $('#BackgroundMapImage1') as Image;
	static bgImage2 = $('#BackgroundMapImage2') as Image;
	static bgImage3 = $('#BackgroundMapImage3') as Image;
	static bgImage4 = $('#BackgroundMapImage4') as Image;
	static logo = $<Image>('#Logo');
	static beBlankIfInvalid = false;

	static init() {
		this.progressBar.value = 0;

		this.bgImage2.RemoveClass('loadingscreen__backgroundshowanim');
		this.bgImage3.RemoveClass('loadingscreen__backgroundshowanim');
		this.bgImage4.RemoveClass('loadingscreen__backgroundshowanim');

		if (!this.bgEvent) {
			this.bgEvent = $.RegisterEventHandler('ImageFailedLoad', this.bgImage1, () => {
				if (this.beBlankIfInvalid) {
					this.bgImage1.visible = false;
				} else {
					this.bgImage1.SetImage('file://{images}/archipelago/chapter1.png');
				}
			});
			this.bgEvent2 = $.RegisterEventHandler('ImageFailedLoad', this.bgImage1, () => {
				this.bgImage2.visible = false;
			});
		}

		if (this.logo) {
			if (!this.logoEvent) {
				this.logoEvent = $.RegisterEventHandler('ImageFailedLoad', this.logo, () => {
					$.Warning('LOADING SCREEN: Square logo was specified, but could not be loaded.');
					this.logo!.SetImage('file://{images}/menu/p2ce/logo.png');
				});
			}

			if (CampaignAPI.IsCampaignActive()) {
				const img = CampaignAPI.GetCampaignMeta(null).get(CampaignMeta.SQUARE_LOGO);
				if (img) {
					this.logo.SetImage(`${getCampaignAssetPath(CampaignAPI.GetActiveCampaign()!)}${img}`);
				} else {
					this.logo.SetImage('file://{images}/archipelago/portalpelago_v2.png');
				}
			} else {
				this.logo.SetImage('file://{images}/archipelago/portalpelago_v2.png');
			}
		}
	}

	static updateLoadingScreenInfoRepeater() {
		// Progress bar will be 1.0 when loading finishes and is then reset to 0.0
		if (this.progressBar.value >= 0.20) {
			this.bgImage2.AddClass('loadingscreen__backgroundshowanim');
		}
		if (this.progressBar.value >= 0.45) {
			this.bgImage3.AddClass('loadingscreen__backgroundshowanim');
		}
		if (this.progressBar.value >= 0.70) {
			this.bgImage4.AddClass('loadingscreen__backgroundshowanim');
			return; // stop repeating once we hit the final layer
		}

		// Rechecking every 8th of a second is OK, it doesn't need to be anything crazy
		$.Schedule(0.125, this.updateLoadingScreenInfoRepeater.bind(this));
	}

	static updateLoadingScreenInfo(mapName: string) {
		const useTransitScreen = this.lastLoadedMapName.length > 0;

		if (mapName.length > 0) {
			this.lastLoadedMapName = mapName;
			$.persistentStorage.setItem('ArchipelagoLastMap', mapName);
		}

		if (CampaignAPI.IsCampaignActive()) {
			// get relevant information
			const c = CampaignAPI.GetActiveCampaign()!;
			const meta = CampaignAPI.GetCampaignMeta(null);

			if (this.logo) {
				const pad = Number(meta.get(CampaignMeta.LOADING_LOGO_PAD));
				if (!isNaN(pad)) {
					this.logo.style.padding = `${pad}px`;
				}
			}

			// applies image and sets panel if it's valid
			// otherwise, make it invisible
			const setImg = (panel: Image, path: string) => {
				if (path && path.length > 0) {
					panel.visible = true;
					panel.SetImage(`${getCampaignAssetPath(c)}${path}`);
				} else {
					panel.visible = false;
				}
			};

			let path: string;
			this.beBlankIfInvalid = isSingleWsCampaign(c);
			if (this.beBlankIfInvalid) {
				path = useTransitScreen ? 'transition_screen.png' : 'loading_screen.png';
			} else {
				path = meta.get(useTransitScreen ? CampaignMeta.TRANSITION_SCREEN : CampaignMeta.LOADING_SCREEN) ?? '';
			}

			$.Msg(`Image asset path: ${path}`);
			if (path && path.length > 0 && !path.endsWith('.xml')) {
				const split = (path as string).split('.');
				let join = '';
				for (let i = 0; i < split.length - 1; ++i) {
					join += split[i];
				}
				setImg(this.bgImage1, join + '_1.' + split[split.length - 1]);
				setImg(this.bgImage2, join + '_2.' + split[split.length - 1]);

				$.Schedule(0.125, this.updateLoadingScreenInfoRepeater.bind(this));
			} else {
				this.bgImage1.visible = true;
				this.bgImage2.visible = true;
				this.bgImage3.visible = true;
				this.bgImage4.visible = true;
				const pics = this.getPictureForMap(mapName, useTransitScreen);
				this.bgImage1.SetImage(pics.img1);
				this.bgImage2.SetImage(pics.img2);
				this.bgImage3.SetImage(pics.img3);
				this.bgImage4.SetImage(pics.img4);

				$.Schedule(0.125, this.updateLoadingScreenInfoRepeater.bind(this));
			}
		} else {
			this.bgImage1.visible = true;
			this.bgImage2.visible = true;
			this.bgImage3.visible = true;
			this.bgImage4.visible = true;
			const pics = this.getPictureForMap(mapName, useTransitScreen);
			this.bgImage1.SetImage(pics.img1);
			this.bgImage2.SetImage(pics.img2);
			this.bgImage3.SetImage(pics.img3);
			this.bgImage4.SetImage(pics.img4);

			$.Schedule(0.125, this.updateLoadingScreenInfoRepeater.bind(this));
		}
	}

	static getPictureForMap(mapName: string, isTransit: boolean): { img1: string, img2: string, img3: string, img4: string } {
		const map = mapName.toLowerCase();
		let prefix = 'a1';
		let transit = 'a';
		
		// Official Chapter 1
		if (map.includes('sp_a1') || map === 'sp_a2_intro') { 
			prefix = 'a1'; transit = 'a'; 
		}
		// Official Chapter 2-5
		else if (map.includes('sp_a2')) { 
			prefix = 'a2'; transit = 'b'; 
		}
		// Official Chapter 6-7
		else if (map.includes('sp_a3')) { 
			prefix = 'a3'; transit = 'c'; 
		}
		// Official Chapter 8
		else if (map.includes('sp_a4_intro') || map.includes('sp_a4_tb_') || map.includes('sp_a4_stop') || map.includes('sp_a4_laser') || map.includes('sp_a4_speed') || map.includes('sp_a4_jump')) { 
			prefix = 'a4'; transit = 'd'; 
		}
		// Official Chapter 9-10
		else if (map.includes('sp_a4_finale') || map.includes('sp_a5')) { 
			prefix = map.includes('sp_a5') ? 'a5' : 'a4';
			transit = 'e'; 
		}
		else if (map.includes('mp_coop')) { 
			prefix = 'default_a'; transit = 'a'; 
		}

		const isWidescreen = ($.GetContextPanel().actuallayoutwidth / $.GetContextPanel().actuallayoutheight) > 1.5;
		const suffix = isWidescreen ? '_widescreen' : '';
		const finalPrefix = isTransit ? `default_${transit}` : prefix;

		// a5 only has layer 1
		if (finalPrefix === 'a5') {
			return {
				img1: `file://{images}/loading_screens/loadingscreen_${finalPrefix}_1${suffix}.png`,
				img2: `file://{images}/loading_screens/loadingscreen_${finalPrefix}_1${suffix}.png`,
				img3: `file://{images}/loading_screens/loadingscreen_${finalPrefix}_1${suffix}.png`,
				img4: `file://{images}/loading_screens/loadingscreen_${finalPrefix}_1${suffix}.png`
			};
		}

		return {
			img1: `file://{images}/loading_screens/loadingscreen_${finalPrefix}_1${suffix}.png`,
			img2: `file://{images}/loading_screens/loadingscreen_${finalPrefix}_2${suffix}.png`,
			img3: `file://{images}/loading_screens/loadingscreen_${finalPrefix}_3${suffix}.png`,
			img4: `file://{images}/loading_screens/loadingscreen_${finalPrefix}_4${suffix}.png`
		};
	}

	static {
		$.RegisterForUnhandledEvent('UnloadLoadingScreenAndReinit', this.init.bind(this));
		$.RegisterForUnhandledEvent('PopulateLoadingScreen', this.updateLoadingScreenInfo.bind(this));
		$.RegisterForUnhandledEvent('LoadingScreenClearLastMap', () => {
			this.lastLoadedMapName = '';
		});
	}
}
