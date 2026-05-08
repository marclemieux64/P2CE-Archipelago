/**
 * @packageDocumentation
 * Captioning Interface
 */

interface Caption {
	bLowPriority: boolean;
	bSFX: boolean;
	nNoRepeat: number;
	nDelay: number;
	flLifetimeOverride: number;
	text: string;
	options: Map<string, string>;
}

interface GlobalEventNameMap {
	DisplayCaption: (token: string, caption: Caption, lifetime: number, emitTime: number) => void;
	BadCaption: (token: string, lifetime: number, emitTime: number) => void;
	EndCaption: (token: string) => void;
}

declare namespace ClosedCaptionsAPI {
	function RemoveCaption(token: string): void;
}