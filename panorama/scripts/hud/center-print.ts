'use strict';

class CenterPrint {
	static readonly HOLD_TIME = 5;
	static readonly FADE_TIME = 1.5;

	static hideSchedule: uuid | null = null;
	static panel: Panel;
	static label: Label;

	static onShowCenterPrintText(message: string, _priority: unknown) {
		try {
			CenterPrint.cancelPending();

			const token = '#' + message;
			const localized = $.Localize(token);
			CenterPrint.label.text = localized && localized !== token ? localized : message;
			CenterPrint.panel.RemoveClass('center-print--hidden');
			CenterPrint.panel.AddClass('center-print--visible');

			CenterPrint.hideSchedule = $.Schedule(CenterPrint.HOLD_TIME, CenterPrint.hide);
		} catch (e) {
			$.Warning('CenterPrint error: ' + e);
		}
	}

	static hide() {
		CenterPrint.hideSchedule = null;
		CenterPrint.panel.RemoveClass('center-print--visible');
		CenterPrint.panel.AddClass('center-print--hidden');
	}

	static cancelPending() {
		if (CenterPrint.hideSchedule !== null) {
			try {
				$.CancelScheduled(CenterPrint.hideSchedule);
			} catch (e) {
				// Ignore
			}
			CenterPrint.hideSchedule = null;
		}
	}

	static {
		CenterPrint.panel = $('#CenterPrint') as Panel;
		CenterPrint.label = $('#CenterPrintLabel') as Label;

		const ctx = $.GetContextPanel();
		let _handle: number = -1;
		const wrapper = (message: string, _priority: unknown) => {
			if (!ctx || !ctx.IsValid()) {
				$.UnregisterForUnhandledEvent('ShowCenterPrintText', _handle);
				return;
			}
			CenterPrint.onShowCenterPrintText(message, _priority);
		};
		_handle = $.RegisterForUnhandledEvent('ShowCenterPrintText', wrapper);
	}
}
