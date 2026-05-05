'use strict';

/**
 * Archipelago Web API Bridge
 * Handles asynchronous communication with the local Python client.
 */
class ArchipelagoAPI {
    static VERSION: string = "1.0.0";
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
        this.m_PollSchedule = $.Schedule(2.0, () => this.startPolling());
    }

    static refreshStatus() {
        if (this.ENABLE_DEBUG) $.Msg("[AP API] Refreshing status...");
        $.AsyncWebRequest(this.API_BASE + "/status", {
            type: 'GET',
            complete: (data: any) => {
                if (data && data.responseText) {
                    try {
                        const cleanJson = data.responseText.trim().replace(/\0/g, '');
                        const status = JSON.parse(cleanJson);
                        this.m_Status = status;
                        
                        // Seed Validation / Auto-Reset Logic
                        if (status.seed && status.seed !== "unknown") {
                            // We can use this to auto-wipe bitmasks if the seed changed
                            // For now, just log it
                            if (ArchipelagoAPI.ENABLE_DEBUG) $.Msg("[AP API] Seed: " + status.seed);
                        }

                        // Dispatch update event
                        $.DispatchEvent("ArchipelagoAPI_StatusUpdated", JSON.stringify(status));
                    } catch (e) {
                        $.Warning("[AP API] Error parsing status: " + e);
                    }
                }
            },
            error: () => {
                // Silently fail if client isn't running
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

    static ENABLE_DEBUG: boolean = true;
}

// Global exposure
(UiToolkitAPI.GetGlobalObject() as any).ArchipelagoAPI = ArchipelagoAPI;
ArchipelagoAPI.init();
