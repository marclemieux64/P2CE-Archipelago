'use strict';

// --- DÉCLARATION DES ÉVÉNEMENTS PANORAMA ---
// Obligatoire pour éviter l'erreur "Invalid event name to DispatchEvent"
try {
    $.DefineEvent("ArchipelagoAPI_StatusUpdated", 1, "json");
    $.DefineEvent("ArchipelagoAPI_ChatUpdated", 1, "json");
    $.DefineEvent("ArchipelagoAPI_HintsUpdated", 1, "json");
} catch (e) { }

/**
 * Archipelago Web API Bridge
 * Handles asynchronous communication with the local Python client.
 * OPTIMIZED: Uses Single-Pulse architecture with Raw String validation.
 */
class ArchipelagoAPI {
    static VERSION: string = "2.0.2";
    static API_BASE: string = "http://127.0.0.1:8910";
    
    static m_Status: any = null;
    static m_Chat: any[] = [];
    static m_Hints: any[] = [];
    
    static m_LastRawJson: string = ""; 
    static m_PollSchedule: any = null;

    static init() {
        $.Msg("[AP] Initializing Optimized Single-Pulse API v" + this.VERSION);
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
        $.AsyncWebRequest(this.API_BASE + "/status_full", {
            type: 'GET',
            complete: (res: any) => {
                if (res.status === 200 && res.responseText) {
                    
                    if (res.responseText === this.m_LastRawJson) {
                        return; 
                    }
                    
                    this.m_LastRawJson = res.responseText;

                    try {
                        const cleanJson = res.responseText.trim().replace(/\0/g, '');
                        const data = JSON.parse(cleanJson);

                        if (data.status) {
                            this.m_Status = data.status;
                            
                            // --- NOUVEAU : Sauvegarde de la difficulté logique en mémoire ---
                            if (data.status.logic_difficulty !== undefined) {
                                $.persistentStorage.setItem("ArchipelagoLogicDifficulty", data.status.logic_difficulty);
                            }

                            $.DispatchEvent("ArchipelagoAPI_StatusUpdated", JSON.stringify(this.m_Status));
                        }
                        if (data.chat) {
                            this.m_Chat = data.chat;
                            $.DispatchEvent("ArchipelagoAPI_ChatUpdated", JSON.stringify(this.m_Chat));
                        }
                        if (data.hints) {
                            this.m_Hints = data.hints;
                            $.DispatchEvent("ArchipelagoAPI_HintsUpdated", JSON.stringify(this.m_Hints));
                        }
                        
                    } catch (e) {
                        $.Warning("[AP API] Parse Error: " + e);
                    }
                }
            },
            error: () => {
                if (!this.m_Status || !this.m_Status.client_offline) {
                    this.m_Status = { client_offline: true };
                    $.DispatchEvent("ArchipelagoAPI_StatusUpdated", JSON.stringify(this.m_Status));
                }
            }
        });
    }

    static sendCommand(cmd: string) {
        if (!cmd) return;
        $.Msg("[AP API] Sending command: " + cmd);
        
        $.AsyncWebRequest(this.API_BASE + "/command", {
            type: 'POST',
            data: { command: cmd },
            complete: () => { 
                this.pulse(); 
            }
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

    static ENABLE_DEBUG: boolean = false;
}

(UiToolkitAPI.GetGlobalObject() as any).ArchipelagoAPI = ArchipelagoAPI;
ArchipelagoAPI.init();