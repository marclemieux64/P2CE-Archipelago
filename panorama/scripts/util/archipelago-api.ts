'use strict';

try {
    $.DefineEvent("ArchipelagoAPI_StatusUpdated", 1, "json");
    $.DefineEvent("ArchipelagoAPI_ChatUpdated", 1, "json");
    $.DefineEvent("ArchipelagoAPI_HintsUpdated", 1, "json");
} catch (e) { }

class ArchipelagoAPI {
    static VERSION: string = "2.1.1"; 
    static API_BASE: string = "http://127.0.0.1:8910";
    
    static m_Status: any = null;
    static m_Chat: any[] = [];
    static m_Hints: any[] = [];
    
    static m_PollSchedule: any = null;
    static m_StatusETag: string = "";
    static m_ChatETag: string = "";

    static init() {
        $.Msg("[AP] Initializing High-Performance ETag-Cached API with Instant-Invalidation");
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
                    try {
                        const data = JSON.parse(cleanText);
                        this.m_Status = data;
                        if (data.logic_difficulty !== undefined) {
                            $.persistentStorage.setItem("ArchipelagoLogicDifficulty", data.logic_difficulty);
                        }
                        $.DispatchEvent("ArchipelagoAPI_StatusUpdated", cleanText);
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
                    try {
                        const data = JSON.parse(cleanText);
                        this.m_Chat = data;
                        $.DispatchEvent("ArchipelagoAPI_ChatUpdated", cleanText);
                        if (callback) callback(data);
                    } catch (e) { }
                }
            }
        });
    }

    static sendCommand(cmd: string, callback?: () => void) {
        if (!cmd) return;
        // CORRECTIF CACHE : Invalidation agressive immédiate pré-envoi
        this.m_StatusETag = "";
        this.m_ChatETag = "";

        $.AsyncWebRequest(this.API_BASE + "/command", {
            type: 'POST',
            data: { command: cmd },
            complete: () => { 
                if (callback) callback();
                // Double vérification post-exécution pour forcer la vidange du cache Panorama
                this.pulse(); 
            }
        });
    }

    static forceRefreshHints() {
        this.m_StatusETag = "";
        this.m_ChatETag = "";
        $.AsyncWebRequest(this.API_BASE + "/hints/refresh", { 
            type: 'POST',
            complete: () => { this.pulse(); }
        });
    }

    static getStatus() { return this.m_Status; }
    static getChat() { return this.m_Chat; }
    static getHints() { return this.m_Hints; }

    static getLastNotificationId() {
        const globalObj: any = UiToolkitAPI.GetGlobalObject();
        if (globalObj.Archipelago_LastMsgId === undefined) {
            globalObj.Archipelago_LastMsgId = -1;
        }
        return globalObj.Archipelago_LastMsgId;
    }

    static setLastNotificationId(id: number) {
        (UiToolkitAPI.GetGlobalObject() as any).Archipelago_LastMsgId = id;
    }
}

(UiToolkitAPI.GetGlobalObject() as any).ArchipelagoAPI = ArchipelagoAPI;
ArchipelagoAPI.init();