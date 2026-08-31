'use strict';

try { $.DefineEvent("ArchipelagoAPI_StatusUpdated", 1, "json"); } catch (e) {}
try { $.DefineEvent("ArchipelagoAPI_ChatUpdated", 1, "json"); } catch (e) {}
try { $.DefineEvent("ArchipelagoAPI_HintsUpdated", 1, "json"); } catch (e) {}
try { $.DefineEvent("ArchipelagoUpdate", 1, "content"); } catch (e) {}
try { $.DefineEvent("ArchipelagoMapNameUpdated", 1, "payload"); } catch (e) {}

const globalObj = UiToolkitAPI.GetGlobalObject() as any;

if (!globalObj.ArchipelagoAPI) {
    class ArchipelagoAPI {
        static VERSION: string = "4.0.0";
        static API_BASE: string = "http://127.0.0.1:8910";

        static m_Status: any = null;
        static m_Chat: any[] = [];
        static m_Hints: any[] = [];

        static m_AllInFlight: boolean = false;
        static m_AllETag: string = "";
        static m_LastChatId: number = -1;
        static m_ChatInitialized: boolean = false; // true after first chat sync; suppresses notification event on initial history load
        static m_MenuVersion: number = 0;
        static m_CheckedCount: number = 0;
        static m_MissingVersion: number = 0;
        static m_PendingPulse: any = null;
        static m_PulseNeeded: boolean = false;
        static m_PollingPaused: boolean = false;

        static m_HasForeground: boolean = false;
        static m_NeedHints: boolean = false;
        static m_TickerHandle: any = null;
        static m_TICKER_BG: number = 2.0;
        static m_TICKER_FG: number = 0.5;

        static m_StatusListeners: { panel: any, callback: (data: any) => void, foreground: boolean }[] = [];
        static m_ChatListeners: { panel: any, callback: (data: any[]) => void, foreground: boolean }[] = [];
        static m_HintsListeners: { panel: any, callback: (data: any) => void, foreground: boolean }[] = [];

        static init() {
            $.Msg("[AP] Initializing v" + this.VERSION);
            this.pulse();
            this.startTicker();
        }

        static pulse() {
            this.pulseAll();
        }

        static pausePolling() {
            this.m_PollingPaused = true;
            if (this.m_PendingPulse) {
                $.CancelScheduled(this.m_PendingPulse);
                this.m_PendingPulse = null;
            }
            this.m_PulseNeeded = false;
            this.stopTicker();
        }

        static pulseAll() {
            if (this.m_AllInFlight) return;
            this.m_AllInFlight = true;
            const ctx = $.GetContextPanel();

            const url = `${this.API_BASE}/api/all?menu_version=${this.m_MenuVersion}&checked_count=${this.m_CheckedCount}&missing_version=${this.m_MissingVersion}&last_chat=${this.m_LastChatId}&etag=${this.m_AllETag}&need_hints=${this.m_NeedHints ? 1 : 0}`;

            $.AsyncWebRequest(url, {
                type: 'GET',
                complete: (res: any) => {
                    this.m_AllInFlight = false;
                    if (this.m_PollingPaused) {
                        this.m_PulseNeeded = false;
                        return;
                    }
                    if (this.m_PulseNeeded) {
                        this.m_PulseNeeded = false;
                        this.scheduleDebouncedPulse();
                    }
                    if (!ctx || !ctx.IsValid()) return;

                    if (res.status === 304 || res.statusText === 'Not Modified') return;

                    if ((res.status === 200 || res.statusText === 'success') && res.responseText) {
                        const sanitized = res.responseText.replace(/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]/g, "").trim();
                        if (!sanitized) return;

                        try {
                            const data = JSON.parse(sanitized);
                            if (data.e) this.m_AllETag = data.e;
                            if (data.s) this.processStatus(data.s);
                            if (data.c !== undefined && data.c !== null) {
                                const isInitialSync = !this.m_ChatInitialized;
                                this.m_ChatInitialized = true;
                                if (data.c.length > 0) this.processChat(data.c, isInitialSync);
                            }
                            // Anchor m_LastChatId at the server's current head on fresh connect
                            // so history from before this session is never replayed.
                            if (data.ch !== undefined && data.ch !== null && data.ch >= 0) {
                                this.m_LastChatId = data.ch;
                            }
                            if (data.h) this.processHints(data.h);
                        } catch (e) {
                        }
                    } else {
                        // Server offline
                        const offlinePayload = { connected: false, game_connected: false, client_offline: true, menu: null, menu_version: 0 };
                        this.m_Status = offlinePayload;
                        this.m_MenuVersion = 0;
                        this.dispatchStatusUpdate(offlinePayload);
                    }
                }
            });
        }

        static processStatus(data: any) {
            if (!this.m_Status) {
                this.m_Status = data;
            } else {
                for (const key in data) {
                    if (data[key] !== null && data[key] !== undefined) {
                        this.m_Status[key] = data[key];
                    }
                }
            }

            if (data.checked_locations) {
                this.m_Status.checked_locations = data.checked_locations;
                this.m_CheckedCount = data.checked_locations.length;
            } else if (data.checked_locations_count !== undefined) {
                this.m_CheckedCount = data.checked_locations_count;
                if (!this.m_Status.checked_locations || this.m_Status.checked_locations.length !== data.checked_locations_count) {
                    this.m_Status.checked_locations = new Array(data.checked_locations_count);
                }
            }

            if (data.menu_version !== undefined) this.m_MenuVersion = data.menu_version;
            if (data.missing_version !== undefined) this.m_MissingVersion = data.missing_version;

            this.dispatchStatusUpdate(this.m_Status);
        }

        static processChat(delta: any[], isInitialSync: boolean) {
            this.m_Chat = this.m_Chat.concat(delta);
            this.m_LastChatId = delta[delta.length - 1].id;
            ArchipelagoAPI.flushChatChunk(delta, 0, isInitialSync, $.GetContextPanel());
            if (!isInitialSync) {
                try { $.DispatchEvent("ArchipelagoAPI_ChatUpdated", JSON.stringify(delta)); } catch(e) {}
            }
        }

        // Sends delta to listeners in 50-message chunks, one scheduled step at a time.
        static flushChatChunk(delta: any[], offset: number, isInitialSync: boolean, ctx: any) {
            if (!ctx || !ctx.IsValid()) return;
            const end = Math.min(offset + 50, delta.length);
            const chunk = delta.slice(offset, end);
            const isLast = (end >= delta.length);

            ArchipelagoAPI.m_ChatListeners = ArchipelagoAPI.m_ChatListeners.filter((l: any) => l.panel && l.panel.IsValid());
            ArchipelagoAPI.m_ChatListeners.forEach((l: any) => { try { l.callback(chunk, isInitialSync); } catch(e) {} });

            if (!isLast) {
                $.Schedule(0.05, () => {
                    ArchipelagoAPI.flushChatChunk(delta, end, isInitialSync, ctx);
                });
            }
        }

        static processHints(hints: any[]) {
            this.m_Hints = hints;
            this.dispatchHintsUpdate(hints);
        }

        static sendCommand(cmd: string, callback?: () => void) {
            if (!cmd) return;
            this.m_AllETag = "";
            const ctx = $.GetContextPanel();
            $.AsyncWebRequest(this.API_BASE + "/command", {
                type: 'POST',
                data: { command: cmd },
                complete: () => {
                    if (!ctx || !ctx.IsValid()) return;
                    if (callback) callback();
                    this.scheduleDebouncedPulse();
                    // Follow-up polls so the command response is always caught,
                    // even if the _push_update() push notification is missed.
                    $.Schedule(0.75, () => { if (ctx && ctx.IsValid()) ArchipelagoAPI.scheduleDebouncedPulse(); });
                    $.Schedule(2.5, () => { if (ctx && ctx.IsValid()) ArchipelagoAPI.scheduleDebouncedPulse(); });
                }
            });
        }

        static forceRefreshHints() {
            this.m_AllETag = "";
            const ctx = $.GetContextPanel();
            $.AsyncWebRequest(this.API_BASE + "/hints/refresh", {
                type: 'POST',
                complete: () => {
                    if (!ctx || !ctx.IsValid()) return;
                    this.scheduleDebouncedPulse();
                }
            });
        }

        static scheduleDebouncedPulse() {
            if (this.m_PollingPaused) return;
            if (!this.m_TickerHandle) this.startTicker();
            if (this.m_PendingPulse) return;
            const ctx = $.GetContextPanel();
            if (!ctx || !ctx.IsValid()) return;
            if (this.m_AllInFlight) {
                this.m_PulseNeeded = true;
                return;
            }
            this.m_PendingPulse = $.Schedule(0.15, () => {
                this.m_PendingPulse = null;
                if (!ctx.IsValid()) return;
                this.pulse();
            });
        }

        static getStatus() { return this.m_Status; }
        static getChat() { return this.m_Chat; }
        static getHints() { return this.m_Hints; }

        static startTicker() {
            if (this.m_TickerHandle) return;
            const ctx = $.GetContextPanel();
            if (!ctx || !ctx.IsValid()) return;
            const interval = this.m_HasForeground ? this.m_TICKER_FG : this.m_TICKER_BG;
            this.m_TickerHandle = $.Schedule(interval, () => {
                this.m_TickerHandle = null;
                if (!ctx || !ctx.IsValid()) return;
                if (!this.m_PollingPaused) this.scheduleDebouncedPulse();
                this.startTicker();
            });
        }

        static stopTicker() {
            if (this.m_TickerHandle) {
                $.CancelScheduled(this.m_TickerHandle);
                this.m_TickerHandle = null;
            }
        }

        static recomputeNeeds() {
            const prevFg = this.m_HasForeground;
            const prevNeedHints = this.m_NeedHints;
            const all = [...this.m_StatusListeners, ...this.m_ChatListeners, ...this.m_HintsListeners];
            this.m_HasForeground = all.some(l => l.foreground);
            this.m_NeedHints = this.m_HintsListeners.length > 0;
            if (!prevNeedHints && this.m_NeedHints) {
                this.m_AllETag = "";
            }
            if (prevFg !== this.m_HasForeground) {
                this.stopTicker();
                this.startTicker();
            }
        }

        static registerStatusListener(panel: any, callback: (data: any) => void, foreground: boolean = false) {
            if (!panel || !panel.IsValid()) return;
            this.m_StatusListeners = this.m_StatusListeners.filter(l => l.panel && l.panel.IsValid() && l.panel !== panel);
            this.m_StatusListeners.push({ panel, callback, foreground });
            this.recomputeNeeds();
            if (foreground) this.scheduleDebouncedPulse();
            if (this.m_Status) {
                try { callback(this.m_Status); } catch(e) {}
            }
        }

        // On initial registration: callback receives the full accumulated array (for history).
        // On subsequent dispatches: callback receives the delta only.
        static registerChatListener(panel: any, callback: (data: any[]) => void, foreground: boolean = false) {
            if (!panel || !panel.IsValid()) return;
            this.m_ChatListeners = this.m_ChatListeners.filter(l => l.panel && l.panel.IsValid() && l.panel !== panel);
            this.m_ChatListeners.push({ panel, callback, foreground });
            this.recomputeNeeds();
            if (foreground) this.scheduleDebouncedPulse();
            if (this.m_Chat && this.m_Chat.length > 0) {
                try { callback(this.m_Chat, true); } catch(e) {}
            }
        }

        static registerHintsListener(panel: any, callback: (data: any) => void, foreground: boolean = false) {
            if (!panel || !panel.IsValid()) return;
            this.m_HintsListeners = this.m_HintsListeners.filter(l => l.panel && l.panel.IsValid() && l.panel !== panel);
            this.m_HintsListeners.push({ panel, callback, foreground });
            this.recomputeNeeds();
            if (foreground) this.scheduleDebouncedPulse();
            if (this.m_Hints && this.m_Hints.length > 0) {
                try { callback(this.m_Hints); } catch(e) {}
            }
        }

        static dispatchStatusUpdate(data: any) {
            this.m_StatusListeners = this.m_StatusListeners.filter(l => l.panel && l.panel.IsValid());
            this.m_StatusListeners.forEach(l => { try { l.callback(data); } catch(e) {} });
            this.recomputeNeeds();
        }

        // Listeners always receive delta (console needs history on first connect).
        // Event is suppressed on initial sync to avoid replaying history as notifications.
        static dispatchChatUpdate(delta: any[], isInitialSync: boolean = false) {
            this.m_ChatListeners = this.m_ChatListeners.filter(l => l.panel && l.panel.IsValid());
            this.m_ChatListeners.forEach(l => { try { l.callback(delta); } catch(e) {} });
            this.recomputeNeeds();
        }

        static dispatchHintsUpdate(hintsList: any[]) {
            this.m_HintsListeners = this.m_HintsListeners.filter(l => l.panel && l.panel.IsValid());
            this.m_HintsListeners.forEach(l => { try { l.callback(hintsList); } catch(e) {} });
            this.recomputeNeeds();
        }
    }

    globalObj.ArchipelagoAPI = ArchipelagoAPI;
    ArchipelagoAPI.init();
} else {
    // Singleton already exists; reset in-flight state in case the previous panel died mid-request,
    // then do one immediate fetch so this panel gets current state without waiting for a push.
    const _existingApi = globalObj.ArchipelagoAPI;
    _existingApi.m_AllInFlight = false;
    _existingApi.m_AllETag = "";
    _existingApi.m_PendingPulse = null;
    _existingApi.m_PulseNeeded = false;
    _existingApi.m_PollingPaused = false;
    // Restart ticker with fresh context panel (old panel may have died)
    _existingApi.stopTicker();
    _existingApi.pulse();
    _existingApi.startTicker();
}

var ArchipelagoAPI = globalObj.ArchipelagoAPI;

// Register a self-cleaning listener for push notifications from Python via netcon→VScript.
// Runs on every panel load; auto-unregisters when this panel dies so it never accumulates.
{
    const _ctx = $.GetContextPanel();
    let _handle: number = -1;
    const _handler = () => {
        if (!_ctx || !_ctx.IsValid()) {
            $.UnregisterForUnhandledEvent("ArchipelagoUpdate", _handle);
            return;
        }
        if (globalObj.ArchipelagoAPI) globalObj.ArchipelagoAPI.scheduleDebouncedPulse();
    };
    _handle = $.RegisterForUnhandledEvent("ArchipelagoUpdate", _handler);
}

// Resume polling when a new map is ready (fired by AngelScript on map load).
// This unpauses polling that was stopped by requestWarp() to prevent the libpango crash.
{
    const _ctx = $.GetContextPanel();
    let _mapReadyHandle: number = -1;
    const _mapReadyHandler = (_payload: string) => {
        if (!_ctx || !_ctx.IsValid()) {
            $.UnregisterForUnhandledEvent("ArchipelagoMapNameUpdated", _mapReadyHandle);
            return;
        }
        const api = globalObj.ArchipelagoAPI;
        if (api && api.m_PollingPaused) {
            api.m_PollingPaused = false;
            api.m_AllETag = "";
            api.scheduleDebouncedPulse();
        }
    };
    _mapReadyHandle = $.RegisterForUnhandledEvent("ArchipelagoMapNameUpdated", _mapReadyHandler);
}
