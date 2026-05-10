'use strict';

/**
 * Archipelago Web API Bridge
 * Handles asynchronous communication with the local Python client.
 */
class ArchipelagoAPI {
    static VERSION: string = "1.0.1";
    static API_BASE: string = "http://127.0.0.1:8910";
    static m_Status: any = null;
    static m_Chat: any[] = [];
    static m_PollSchedule: any = null;

    static init() {
        $.Msg("[AP] Initializing Archipelago Web API Bridge v" + this.VERSION);
        this.startPolling();
    }

    static startPolling() {
        if (this.m_PollSchedule) {
            try { $.CancelScheduled(this.m_PollSchedule); } catch(e) {}
        }
        
        this.refreshStatus();
        this.fetchChat();
        this.m_PollSchedule = $.Schedule(1.0, () => this.startPolling());
    }

    static sendCommand(cmd: string) {
        if (!cmd) return;
        $.Msg("[AP API] Sending command: " + cmd);
        
        $.AsyncWebRequest(this.API_BASE + "/command", {
            type: 'POST',
            data: { command: cmd },
            complete: (data: any) => {
                this.fetchChat();
            }
        });
    }

    static refreshStatus() {
        $.AsyncWebRequest(this.API_BASE + "/status", {
            type: 'GET',
            complete: (data: any) => {
                if (data && data.responseText) {
                    try {
                        const cleanJson = data.responseText.trim().replace(/\0/g, '');
                        const status = JSON.parse(cleanJson);
                        this.m_Status = status;
                        $.DispatchEvent("ArchipelagoAPI_StatusUpdated", JSON.stringify(status));
                    } catch (e) {
                        $.Warning("[AP API] Error parsing status: " + e);
                    }
                }
            },
            error: () => {
                // NOUVEAU: Si le client Python est fermé ou injoignable, on le signale proprement.
                if (!this.m_Status || !this.m_Status.client_offline) {
                    this.m_Status = { client_offline: true };
                    $.DispatchEvent("ArchipelagoAPI_StatusUpdated", JSON.stringify(this.m_Status));
                }
            }
        });
    }

    static fetchChat(callback?: (chat: any[]) => void) {
        $.AsyncWebRequest(this.API_BASE + "/chat", {
            type: 'GET',
            complete: (data: any) => {
                if (data && data.responseText) {
                    try {
                        const cleanJson = data.responseText.trim().replace(/\0/g, '');
                        const chat = JSON.parse(cleanJson);
                        this.m_Chat = chat;
                        if (callback) callback(chat);
                        $.DispatchEvent("ArchipelagoAPI_ChatUpdated", JSON.stringify(chat));
                    } catch (e) {
                        $.Warning("[AP API] Error parsing chat: " + e);
                    }
                }
            }
        });
    }

    static getStatus() {
        return this.m_Status;
    }
    
    static getChat() {
        return this.m_Chat;
    }
    
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

    static ENABLE_DEBUG: boolean = false;
}

(UiToolkitAPI.GetGlobalObject() as any).ArchipelagoAPI = ArchipelagoAPI;
ArchipelagoAPI.init();