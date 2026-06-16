'use strict';

try {
    $.DefineEvent("ArchipelagoAPI_StatusUpdated", 1, "json");
    $.DefineEvent("ArchipelagoAPI_ChatUpdated", 1, "json");
    $.DefineEvent("ArchipelagoAPI_HintsUpdated", 1, "json");
} catch (e) { }

const globalObj = UiToolkitAPI.GetGlobalObject() as any;

if (!globalObj.ArchipelagoAPI) {
    class ArchipelagoAPI {
        static VERSION: string = "3.1.3"; 
        static API_BASE: string = "http://127.0.0.1:8910";
        
        static m_Status: any = null;
        static m_Chat: any[] = [];
        static m_Hints: any[] = [];
        
        static m_PollSchedule: any = null;
        static m_StatusETag: string = "";
        static m_ChatETag: string = "";
        static m_HintsETag: string = "";
        static m_LastChatId: number = -1;
        static m_MenuVersion: number = 0;

        // Adaptive polling: faster after changes, slower when idle
        static m_PollInterval: number = 1.0;        // current interval in seconds
        static m_PollIntervalFast: number = 0.5;     // after receiving data
        static m_PollIntervalSlow: number = 2.0;     // after 304 / no change
        static m_ConsecutiveIdle: number = 0;         // count of consecutive 304s
        static m_StatusInFlight: boolean = false;
        static m_ChatInFlight: boolean = false;
        static m_HintsInFlight: boolean = false;
        static m_PendingPulse: any = null;            // debounce scheduled pulse

        static m_StatusListeners: { panel: any, callback: (data: any) => void }[] = [];
        static m_ChatListeners: { panel: any, callback: (data: any) => void }[] = [];
        static m_HintsListeners: { panel: any, callback: (data: any) => void }[] = [];

        static init() {
            $.Msg("[AP] Initializing Capped Window Chat & Delta Status Sync Pipeline");
            this.startPolling();
        }

        static startPolling() {
            if (this.m_PollSchedule) {
                try { $.CancelScheduled(this.m_PollSchedule); } catch(e) {}
            }
            this.pulse();
            this.m_PollSchedule = $.Schedule(this.m_PollInterval, () => this.startPolling());
        }

        static pulse() {
            this.pulseStatus();
            this.pulseChat();
            this.pulseHints();
        }

        static pulseStatus() {
            if (this.m_StatusInFlight) return;
            this.m_StatusInFlight = true;

            const headers: Record<string, string> = {};
            if (this.m_StatusETag) {
                headers["If-None-Match"] = this.m_StatusETag;
            }

            const url = `${this.API_BASE}/api/status?menu_version=${this.m_MenuVersion}`;

            $.AsyncWebRequest(url, {
                type: 'GET',
                headers: headers,
                complete: (res: any) => {
                    this.m_StatusInFlight = false;
                    this.handlePollResponse(res, 'status');
                }
            });
        }

        static pulseChat() {
            if (this.m_ChatInFlight) return;
            this.m_ChatInFlight = true;

            const headers: Record<string, string> = {};
            if (this.m_ChatETag) {
                headers["If-None-Match"] = this.m_ChatETag;
            }

            const url = `${this.API_BASE}/api/chat?last_chat=${this.m_LastChatId}`;

            $.AsyncWebRequest(url, {
                type: 'GET',
                headers: headers,
                complete: (res: any) => {
                    this.m_ChatInFlight = false;
                    this.handlePollResponse(res, 'chat');
                }
            });
        }

        static pulseHints() {
            if (this.m_HintsInFlight) return;
            this.m_HintsInFlight = true;

            const headers: Record<string, string> = {};
            if (this.m_HintsETag) {
                headers["If-None-Match"] = this.m_HintsETag;
            }

            const url = `${this.API_BASE}/api/hints`;

            $.AsyncWebRequest(url, {
                type: 'GET',
                headers: headers,
                complete: (res: any) => {
                    this.m_HintsInFlight = false;
                    this.handlePollResponse(res, 'hints');
                }
            });
        }

        static handlePollResponse(res: any, type: string) {
            if (res.status === 304) {
                this.m_ConsecutiveIdle++;
                if (this.m_ConsecutiveIdle >= 5) {
                    this.m_PollInterval = this.m_PollIntervalSlow;
                }
                return;
            }

            if (res.status === 200 && res.responseText) {
                this.m_ConsecutiveIdle = 0;
                this.m_PollInterval = this.m_PollIntervalFast;

                const eTagHeader = res.getheader ? res.getheader("ETag") : "";
                const sanitizedResponse = res.responseText.replace(/[\u0000-\u001F\u007F-\u009F]/g, "").trim();
                if (!sanitizedResponse) return;

                try {
                    const data = JSON.parse(sanitizedResponse);
                    if (type === 'status') {
                        if (eTagHeader) this.m_StatusETag = eTagHeader;
                        
                        if (data.menu_version !== undefined) {
                            if (data.menu) {
                                this.m_Status = data;
                                this.m_MenuVersion = data.menu_version;
                            } else {
                                if (this.m_Status && this.m_Status.menu) {
                                    data.menu = this.m_Status.menu;
                                }
                                this.m_Status = data;
                                this.m_MenuVersion = data.menu_version;
                            }
                        } else {
                            this.m_Status = data;
                        }
                        this.dispatchStatusUpdate(this.m_Status);
                    }
                    else if (type === 'chat') {
                        if (eTagHeader) this.m_ChatETag = eTagHeader;
                        
                        if (data.chat_delta && data.chat_delta.length > 0) {
                            this.m_Chat = this.m_Chat.concat(data.chat_delta);
                            if (this.m_Chat.length > 100) {
                                this.m_Chat = this.m_Chat.slice(this.m_Chat.length - 100);
                            }
                            this.m_LastChatId = data.chat_delta[data.chat_delta.length - 1].id;
                            this.dispatchChatUpdate(this.m_Chat);
                        }
                    }
                    else if (type === 'hints') {
                        if (eTagHeader) this.m_HintsETag = eTagHeader;
                        
                        if (data.hints) {
                            this.m_Hints = data.hints;
                            this.dispatchHintsUpdate(this.m_Hints);
                        }
                    }
                } catch (e) {
                    $.Warning(`[AP] Error parsing ${type} response: ${e}`);
                }
            } else {
                // Connection/server error
                this.m_ConsecutiveIdle++;
                this.m_PollInterval = this.m_PollIntervalSlow;
                if (type === 'status') {
                    const offlinePayload = { connected: false, game_connected: false, client_offline: true, menu: null, menu_version: 0 };
                    this.m_Status = offlinePayload;
                    this.m_MenuVersion = 0;
                    this.dispatchStatusUpdate(offlinePayload);
                }
            }
        }

        static sendCommand(cmd: string, callback?: () => void) {
            if (!cmd) return;
            this.m_StatusETag = ""; 
            this.m_ChatETag = "";

            $.AsyncWebRequest(this.API_BASE + "/command", {
                type: 'POST',
                data: { command: cmd },
                complete: () => { 
                    if (callback) callback();
                    // Debounced pulse: if a pulse is already pending, skip
                    this.scheduleDebouncedPulse();
                }
            });
        }

        static forceRefreshHints() {
            this.m_HintsETag = "";
            $.AsyncWebRequest(this.API_BASE + "/hints/refresh", { 
                type: 'POST',
                complete: () => { this.scheduleDebouncedPulse(); }
            });
        }

        // Debounced pulse: coalesces multiple rapid calls into a single delayed pulse
        static scheduleDebouncedPulse() {
            if (this.m_PendingPulse) return;  // already scheduled
            this.m_PendingPulse = $.Schedule(0.15, () => {
                this.m_PendingPulse = null;
                this.m_PollInterval = this.m_PollIntervalFast;  // speed up next poll cycle
                this.pulse();
            });
        }

        static getStatus() { return this.m_Status; }
        static getChat() { return this.m_Chat; }
        static getHints() { return this.m_Hints; }

        static registerStatusListener(panel: any, callback: (data: any) => void) {
            if (!panel || !panel.IsValid()) return;
            this.m_StatusListeners = this.m_StatusListeners.filter(l => l.panel && l.panel.IsValid() && l.panel !== panel);
            this.m_StatusListeners.push({ panel: panel, callback: callback });
            
            if (this.m_Status) {
                try { callback(this.m_Status); } catch(e) {}
            }
        }

        static registerChatListener(panel: any, callback: (data: any) => void) {
            if (!panel || !panel.IsValid()) return;
            this.m_ChatListeners = this.m_ChatListeners.filter(l => l.panel && l.panel.IsValid() && l.panel !== panel);
            this.m_ChatListeners.push({ panel: panel, callback: callback });
            
            if (this.m_Chat && this.m_Chat.length > 0) {
                try { callback(this.m_Chat); } catch(e) {}
            }
        }

        static registerHintsListener(panel: any, callback: (data: any) => void) {
            if (!panel || !panel.IsValid()) return;
            this.m_HintsListeners = this.m_HintsListeners.filter(l => l.panel && l.panel.IsValid() && l.panel !== panel);
            this.m_HintsListeners.push({ panel: panel, callback: callback });
            
            if (this.m_Hints && this.m_Hints.length > 0) {
                try { callback(this.m_Hints); } catch(e) {}
            }
        }

        static dispatchStatusUpdate(data: any) {
            this.m_StatusListeners.forEach(l => {
                if (l.panel && l.panel.IsValid()) l.callback(data);
            });
            try { $.DispatchEvent("ArchipelagoAPI_StatusUpdated", data); } catch(e) {}
        }

        static dispatchChatUpdate(chatList: any[]) {
            this.m_ChatListeners.forEach(l => {
                if (l.panel && l.panel.IsValid()) l.callback(chatList);
            });
            try { $.DispatchEvent("ArchipelagoAPI_ChatUpdated", chatList); } catch(e) {}
        }

        static dispatchHintsUpdate(hintsList: any[]) {
            this.m_HintsListeners.forEach(l => {
                if (l.panel && l.panel.IsValid()) l.callback(hintsList);
            });
            try { $.DispatchEvent("ArchipelagoAPI_HintsUpdated", hintsList); } catch(e) {}
        }
    }

    globalObj.ArchipelagoAPI = ArchipelagoAPI;
    ArchipelagoAPI.init();
}

var ArchipelagoAPI = globalObj.ArchipelagoAPI;