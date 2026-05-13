'use strict';

// --- DÉCLARATION DES ÉVÉNEMENTS PANORAMA ---
try {
    $.DefineEvent("ArchipelagoAPI_StatusUpdated", 1, "json");
    $.DefineEvent("ArchipelagoAPI_ChatUpdated", 1, "json");
    $.DefineEvent("ArchipelagoAPI_HintsUpdated", 1, "json");
} catch (e) { }

class ArchipelagoAPI {
    static VERSION: string = "2.0.4"; 
    static API_BASE: string = "http://127.0.0.1:8910";
    
    static m_Status: any = null;
    static m_Chat: any[] = [];
    static m_Hints: any[] = [];
    
    static m_PollSchedule: any = null;

    static init() {
        $.Msg("[AP] Initializing Compatible API");
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
        // 1. Requête pour le statut
        $.AsyncWebRequest(this.API_BASE + "/status", {
            type: 'GET',
            complete: (res: any) => {
                if (res.status === 200 && res.responseText) {
                    try {
                        const data = JSON.parse(res.responseText.trim().replace(/\0/g, ''));
                        this.m_Status = data;
                        
                        if (data.logic_difficulty !== undefined) {
                            $.persistentStorage.setItem("ArchipelagoLogicDifficulty", data.logic_difficulty);
                        }

                        $.DispatchEvent("ArchipelagoAPI_StatusUpdated", JSON.stringify(this.m_Status));
                    } catch (e) { }
                }
            },
            error: () => {
                if (!this.m_Status || !this.m_Status.client_offline) {
                    this.m_Status = { client_offline: true };
                    $.DispatchEvent("ArchipelagoAPI_StatusUpdated", JSON.stringify(this.m_Status));
                }
            }
        });

        // 2. Requête pour le chat
        this.fetchChat();
    }

    // Remis en place car votre fichier console.ts en a besoin !
    static fetchChat(callback?: (chat: any) => void) {
        $.AsyncWebRequest(this.API_BASE + "/chat", {
            type: 'GET',
            complete: (res: any) => {
                if (res.status === 200 && res.responseText) {
                    try {
                        const data = JSON.parse(res.responseText.trim().replace(/\0/g, ''));
                        this.m_Chat = data;
                        $.DispatchEvent("ArchipelagoAPI_ChatUpdated", JSON.stringify(this.m_Chat));
                        if (callback) callback(data);
                    } catch (e) { }
                }
            }
        });
    }

    static sendCommand(cmd: string) {
        if (!cmd) return;
        $.AsyncWebRequest(this.API_BASE + "/command", {
            type: 'POST',
            data: { command: cmd },
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