'use strict';

try {
    $.DefineEvent("ArchipelagoAPI_StatusUpdated", 1, "json");
    $.DefineEvent("ArchipelagoAPI_ChatUpdated", 1, "json");
    $.DefineEvent("ArchipelagoAPI_HintsUpdated", 1, "json");
} catch (e) { }

const globalObj = UiToolkitAPI.GetGlobalObject() as any;

if (!globalObj.ArchipelagoAPI) {
    class ArchipelagoAPI {
        static VERSION: string = "3.1.1"; 
        static API_BASE: string = "http://127.0.0.1:8910";
        
        static m_Status: any = null;
        static m_Chat: any[] = [];
        static m_Hints: any[] = [];
        
        static m_PollSchedule: any = null;
        static m_SyncETag: string = "";
        static m_LastChatId: number = -1;

        static m_StatusListeners: { panel: any, callback: (data: any) => void }[] = [];
        static m_ChatListeners: { panel: any, callback: (data: any) => void }[] = [];

        static init() {
            $.Msg("[AP] Initializing Safe Single-Pulse Delta Sync Pipeline");
            this.startPolling();
        }

        static startPolling() {
            if (this.m_PollSchedule) {
                try { $.CancelScheduled(this.m_PollSchedule); } catch(e) {}
            }
            this.pulse();
            this.m_PollSchedule = $.Schedule(0.4, () => this.startPolling());
        }

        static pulse() {
            const headers: Record<string, string> = {};
            if (this.m_SyncETag) {
                headers["If-None-Match"] = this.m_SyncETag;
            }

            const url = `${this.API_BASE}/api/sync?last_chat=${this.m_LastChatId}`;

            $.AsyncWebRequest(url, {
                type: 'GET',
                headers: headers,
                complete: (res: any) => {
                    if (res.status === 304) {
                        return;
                    }

                    if (res.status === 200 && res.responseText) {
                        const eTagHeader = res.getheader ? res.getheader("ETag") : "";
                        if (eTagHeader) this.m_SyncETag = eTagHeader;

                        const sanitizedResponse = res.responseText.replace(/[\u0000-\u001F\u007F-\u009F]/g, "").trim();
                        if (!sanitizedResponse) return;

                        try {
                            const data = JSON.parse(sanitizedResponse);
                            
                            this.m_Status = data;
                            this.m_Hints = data.hints || [];
                            this.dispatchStatusUpdate(data);

                            if (data.chat_delta && data.chat_delta.length > 0) {
                                this.m_Chat = this.m_Chat.concat(data.chat_delta);
                                this.m_LastChatId = data.chat_delta[data.chat_delta.length - 1].id;
                                this.dispatchChatUpdate(data.chat_delta);
                            }
                        } catch (e) {
                            $.Warning("[AP] SyntaxError prevention triggered during single-pulse resolution: " + e);
                        }
                    } else {
                        // FIX COMPORTEMENT : Si le serveur est éteint (status 0), on propage activement l'état offline
                        const offlinePayload = { connected: false, game_connected: false, client_offline: true, menu: null };
                        this.m_Status = offlinePayload;
                        this.dispatchStatusUpdate(offlinePayload);
                    }
                }
            });
        }

        static sendCommand(cmd: string, callback?: () => void) {
            if (!cmd) return;
            this.m_SyncETag = ""; 

            $.AsyncWebRequest(this.API_BASE + "/command", {
                type: 'POST',
                data: { command: cmd },
                complete: () => { 
                    if (callback) callback();
                    this.pulse(); 
                }
            });
        }

        static forceRefreshHints() {
            this.m_SyncETag = "";
            $.AsyncWebRequest(this.API_BASE + "/hints/refresh", { 
                type: 'POST',
                complete: () => { this.pulse(); }
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

        static dispatchStatusUpdate(data: any) {
            this.m_StatusListeners.forEach(l => {
                if (l.panel && l.panel.IsValid()) l.callback(data);
            });
            try { $.DispatchEvent("ArchipelagoAPI_StatusUpdated", data); } catch(e) {}
        }

        static dispatchChatUpdate(chatDelta: any[]) {
            this.m_ChatListeners.forEach(l => {
                if (l.panel && l.panel.IsValid()) l.callback(chatDelta);
            });
            try { $.DispatchEvent("ArchipelagoAPI_ChatUpdated", chatDelta); } catch(e) {}
        }
    }

    globalObj.ArchipelagoAPI = ArchipelagoAPI;
    ArchipelagoAPI.init();
}

var ArchipelagoAPI = globalObj.ArchipelagoAPI;