'use strict';

declare var $: any;
declare var UiToolkitAPI: any;

class ArchipelagoConsole {
    static m_Panel: Panel | null = null;
    static m_LastChatCount = 0;
    static g_ConsoleText: string = "";

    // Command History
    static g_CommandHistory: string[] = [];
    static g_HistoryIndex: number = -1;
    static g_CurrentInputBuffer: string = "";

    static init() {
        this.m_Panel = $.GetContextPanel();
        $.Msg("[AP] Console initialized");

        const input = this.m_Panel?.FindChildTraverse('ArchipelagoInput') as any;
        const wrapper = this.m_Panel?.FindChildTraverse('ArchipelagoInputWrapper');

        if (input && wrapper) {
            input.SetPanelEvent('onfocus', () => {
                wrapper.AddClass('focused');
            });
            input.SetPanelEvent('onblur', () => {
                wrapper.RemoveClass('focused');
            });

            $.RegisterKeyBind(input, "key_up", () => {
                return this.handleHistoryNavigation(true);
            });
            $.RegisterKeyBind(input, "key_down", () => {
                return this.handleHistoryNavigation(false);
            });
        }

        const output = this.m_Panel?.FindChildTraverse('ConsoleOutput') as any;
        if (output) {
            output.SetPanelEvent('onkeydown', () => {
                const key = $.GetContextPanel().GetOwnerWindow()?.GetLastKey();
                // Block Backspace (8), Delete (46), and all standard character keys (> 32)
                // but allow Ctrl (17) + C (67) if possible, and Arrows (37-40)
                if (key === 8 || key === 46 || key > 46) {
                    // Allow C (67) only if we're not sure about Ctrl, 
                    // but usually blocking everything > 46 is safest to prevent typing.
                    // We'll block everything that could modify text.
                    return true;
                }
                return false;
            });
        }

        $.Schedule(0.1, () => {
            if (input) input.SetFocus();
        });

        // Listen for chat updates from the global API bridge
        $.RegisterForUnhandledEvent('ArchipelagoAPI_ChatUpdated', (json: string) => {
            try {
                const chat = JSON.parse(json);
                this.refreshConsoleUI(chat);
            } catch (e) { }
        });

        // Initial fetch from API
        const api: any = (UiToolkitAPI.GetGlobalObject() as any).ArchipelagoAPI;
        if (api) {
            const currentChat = api.getChat();
            if (currentChat && currentChat.length > 0) {
                this.refreshConsoleUI(currentChat);
            } else {
                api.fetchChat((chat: any[]) => this.refreshConsoleUI(chat));
            }
        }
    }

    static handleHistoryNavigation(isUp: boolean): boolean {
        const input = this.m_Panel?.FindChildTraverse('ArchipelagoInput') as any;
        if (!input) return false;

        if (isUp) {
            if (this.g_CommandHistory.length === 0) return true;

            if (this.g_HistoryIndex === -1) {
                this.g_CurrentInputBuffer = input.text;
            }

            if (this.g_HistoryIndex < this.g_CommandHistory.length - 1) {
                this.g_HistoryIndex++;
                input.text = this.g_CommandHistory[this.g_CommandHistory.length - 1 - this.g_HistoryIndex];
                $.Schedule(0.0, () => input.SetCursorOffset(input.text.length));
            }
            return true;
        }
        else {
            if (this.g_HistoryIndex === -1) return true;

            if (this.g_HistoryIndex > 0) {
                this.g_HistoryIndex--;
                input.text = this.g_CommandHistory[this.g_CommandHistory.length - 1 - this.g_HistoryIndex];
                $.Schedule(0.0, () => input.SetCursorOffset(input.text.length));
            } else {
                this.g_HistoryIndex = -1;
                input.text = this.g_CurrentInputBuffer;
                $.Schedule(0.0, () => input.SetCursorOffset(input.text.length));
            }
            return true;
        }
    }

    static refreshConsoleUI(chat: any[]) {
        if (!this.m_Panel || !chat) return;
        const output = this.m_Panel.FindChildTraverse('ConsoleOutput') as any;
        if (!output) return;

        let fullText = "";
        for (const msg of chat) {
            const d = new Date(msg.time * 1000);
            const timeStr = "[" + d.getHours().toString().padStart(2, '0') + ":" + d.getMinutes().toString().padStart(2, '0') + "]";
            fullText += timeStr + " " + msg.text + "\n";
        }

        if (this.g_ConsoleText === fullText) return;

        this.g_ConsoleText = fullText;
        output.text = fullText;

        $.Schedule(0.05, () => {
            if (!this.m_Panel) return;
            const outputArea = this.m_Panel.FindChildTraverse('ConsoleOutputArea');
            if (outputArea && typeof (outputArea as any).ScrollToBottom === 'function') {
                (outputArea as any).ScrollToBottom();
            }
        });
    }

    static onArchipelagoInput() {
        if (!this.m_Panel) return;
        const input = this.m_Panel.FindChildTraverse('ArchipelagoInput') as any;
        if (!input || !input.text) return;

        const text = input.text;

        if (this.g_CommandHistory.length === 0 || this.g_CommandHistory[this.g_CommandHistory.length - 1] !== text) {
            this.g_CommandHistory.push(text);
        }
        this.g_HistoryIndex = -1;

        input.text = "";
        input.SetFocus();

        const api: any = (UiToolkitAPI.GetGlobalObject() as any).ArchipelagoAPI;
        if (api) {
            $.AsyncWebRequest(api.API_BASE + "/command", {
                type: 'POST',
                data: { command: text },
                complete: () => {
                    if (api.fetchChat) api.fetchChat();
                }
            });
        }
    }
}

{
    const cp = $.GetContextPanel() as any;
    const global = UiToolkitAPI.GetGlobalObject() as any;
    if (cp) cp.ArchipelagoConsole = ArchipelagoConsole;
    global.ArchipelagoConsole = ArchipelagoConsole;
}
