'use strict';

try {
    $.DefineEvent("ArchipelagoAPI_StatusUpdated", 1, "json");
    $.DefineEvent("ArchipelagoAPI_ChatUpdated", 1, "json");
    $.DefineEvent("ArchipelagoAPI_HintsUpdated", 1, "json");
} catch (e) { }

const globalObj = UiToolkitAPI.GetGlobalObject() as any;

if (!globalObj.ArchipelagoAPI) {
    class ArchipelagoAPI {
        static VERSION: string = "2.1.2"; 
        static API_BASE: string = "http://127.0.0.1:8910";
        
        static m_Status: any = null;
        static m_Chat: any[] = [];
        static m_Hints: any[] = [];
        
        static m_PollSchedule: any = null;
        static m_StatusETag: string = "";
        static m_ChatETag: string = "";

        static m_LastRawStatus: string = "";
        static m_LastRawChat: string = "";

        static m_StatusListeners: { panel: any, callback: (data: any) => void }[] = [];
        static m_ChatListeners: { panel: any, callback: (data: any) => void }[] = [];

        static init() {
            $.Msg("[AP] Initializing High-Performance ETag-Cached Singleton API with Instant-Invalidation");
            this.startPolling();
        }

        static startPolling() {
            if (this.m_PollSchedule) {
                try { $.CancelScheduled(this.m_PollSchedule); } catch(e) {}
            }
            
            this.pulse();
            this.m_PollSchedule = $.Schedule(0.5, () => this.startPolling());
        }

        static pulse() {
            const headers: Record<string, string> = {};
            if (this.m_StatusETag) {
                headers["If-None-Match"] = this.m_StatusETag;
            }

            $.AsyncWebRequest(this.API_BASE + "/status", {
                type: 'GET',
                headers: headers,
                complete: (res: any) => {
                    if (res.status === 304) {
                        this.fetchChat();
                        return;
                    }

                    if (res.status === 200 && res.responseText) {
                        const eTagHeader = res.getheader ? res.getheader("ETag") : "";
                        if (eTagHeader) this.m_StatusETag = eTagHeader;

                        const cleanText = res.responseText.replace(/[\u0000-\u001F\u007F-\u009F]/g, "").trim();
                        
                        if (cleanText === this.m_LastRawStatus) {
                            this.fetchChat();
                            return;
                        }
                        this.m_LastRawStatus = cleanText;

                        try {
                            const data = JSON.parse(cleanText);
                            this.m_Status = data;
                            if (data.logic_difficulty !== undefined) {
                                $.persistentStorage.setItem("ArchipelagoLogicDifficulty", data.logic_difficulty);
                            }
                            this.dispatchStatusUpdate(cleanText);
                        } catch (e) { }
                    }
                    this.fetchChat();
                }
            });
        }

        static fetchChat(callback?: (chat: any) => void) {
            const headers: Record<string, string> = {};
            if (this.m_ChatETag) {
                headers["If-None-Match"] = this.m_ChatETag;
            }

            $.AsyncWebRequest(this.API_BASE + "/chat", {
                type: 'GET',
                headers: headers,
                complete: (res: any) => {
                    if (res.status === 304) {
                        if (callback) callback(this.m_Chat);
                        return;
                    }

                    if (res.status === 200 && res.responseText) {
                        const eTagHeader = res.getheader ? res.getheader("ETag") : "";
                        if (eTagHeader) this.m_ChatETag = eTagHeader;

                        const cleanText = res.responseText.trim().replace(/\0/g, '');
                        
                        if (cleanText === this.m_LastRawChat) {
                            if (callback) callback(this.m_Chat);
                            return;
                        }
                        this.m_LastRawChat = cleanText;

                        try {
                            const data = JSON.parse(cleanText);
                            this.m_Chat = data;
                            this.dispatchChatUpdate(cleanText);
                            if (callback) callback(data);
                        } catch (e) { }
                    }
                }
            });
        }

        static sendCommand(cmd: string, callback?: () => void) {
            if (!cmd) return;
            this.m_StatusETag = "";
            this.m_ChatETag = "";
            this.m_LastRawStatus = "";
            this.m_LastRawChat = "";

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
            this.m_StatusETag = "";
            this.m_ChatETag = "";
            this.m_LastRawStatus = "";
            this.m_LastRawChat = "";
            $.AsyncWebRequest(this.API_BASE + "/hints/refresh", { 
                type: 'POST',
                complete: () => { this.pulse(); }
            });
        }

        static getStatus() { return this.m_Status; }
        static getChat() { return this.m_Chat; }
        static getHints() { return this.m_Hints; }

        static getLastNotificationId() {
            if (globalObj.Archipelago_LastMsgId === undefined) {
                globalObj.Archipelago_LastMsgId = -1;
            }
            return globalObj.Archipelago_LastMsgId;
        }

        static setLastNotificationId(id: number) {
            globalObj.Archipelago_LastMsgId = id;
        }

        static registerStatusListener(panel: any, callback: (data: any) => void) {
            if (!panel || !panel.IsValid()) return;
            this.m_StatusListeners = this.m_StatusListeners.filter(l => l.panel && l.panel.IsValid());
            this.m_StatusListeners = this.m_StatusListeners.filter(l => l.panel !== panel);
            this.m_StatusListeners.push({ panel: panel, callback: callback });
            
            if (this.m_Status) {
                try {
                    callback(this.m_Status);
                } catch(e) {}
            }
        }

        static registerChatListener(panel: any, callback: (data: any) => void) {
            if (!panel || !panel.IsValid()) return;
            this.m_ChatListeners = this.m_ChatListeners.filter(l => l.panel && l.panel.IsValid());
            this.m_ChatListeners = this.m_ChatListeners.filter(l => l.panel !== panel);
            this.m_ChatListeners.push({ panel: panel, callback: callback });

            if (this.m_Chat && this.m_Chat.length > 0) {
                try {
                    callback(this.m_Chat);
                } catch(e) {}
            }
        }

        static dispatchStatusUpdate(data: any) {
            this.m_StatusListeners = this.m_StatusListeners.filter(l => {
                if (l.panel && l.panel.IsValid()) {
                    try {
                        l.callback(data);
                    } catch(e) {
                        $.Warning("[AP] Error in status listener callback: " + e);
                    }
                    return true;
                }
                return false;
            });
            try {
                $.DispatchEvent("ArchipelagoAPI_StatusUpdated", data);
            } catch(e) {}
        }

        static dispatchChatUpdate(data: any) {
            this.m_ChatListeners = this.m_ChatListeners.filter(l => {
                if (l.panel && l.panel.IsValid()) {
                    try {
                        l.callback(data);
                    } catch(e) {
                        $.Warning("[AP] Error in chat listener callback: " + e);
                    }
                    return true;
                }
                return false;
            });
            try {
                $.DispatchEvent("ArchipelagoAPI_ChatUpdated", data);
            } catch(e) {}
        }
    }

    globalObj.ArchipelagoAPI = ArchipelagoAPI;
    ArchipelagoAPI.init();
}

var ArchipelagoAPI = globalObj.ArchipelagoAPI;