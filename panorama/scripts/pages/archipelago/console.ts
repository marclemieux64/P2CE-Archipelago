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

    static COLOR_MAP: Record<string, string> = {
        "red": "#ff5555",
        "green": "#00ff00",
        "yellow": "#ffff00",
        "blue": "#77aaff",
        "magenta": "#ee82ee",
        "cyan": "#00ffff",
        "white": "#ffffff",
        "black": "#000000",
        "gold": "#ffd700",
        "plum": "#dda0dd",
        "salmon": "#fa8072",
        "slate": "#708090",
        "brown": "#8b4513",
        "orange": "#ffa500",
        "pink": "#ffc0cb",
        "purple": "#800080",
        "grey": "#808080"
    };

    static init() {
        this.m_Panel = $.GetContextPanel();
        // --- LA BONNE MÉTHODE ICI ---
        $.DispatchEvent('MainMenuSetPageLines', 
            $.Localize('#Archipelago_Console_Title'), 
            $.Localize('#Archipelago_Console_Tagline')
        );
        
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

    static formatRichMessage(data: any[]): string {
        let result = "";
        for (const part of data) {
            if (!part) continue;
            let text = part.text || "";
            // Escape HTML special characters to prevent rendering issues
            text = text.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
            
            let color = "#ffffff";
            if (part.color && ArchipelagoConsole.COLOR_MAP[part.color]) {
                color = ArchipelagoConsole.COLOR_MAP[part.color];
            } else if (part.type === "player_id" || part.type === "player_name") {
                color = "#ff7f50"; // Standard Archipelago Player Coral
            } else if (part.type === "item_id" || part.type === "item_name") {
                color = "#00ffff"; // Standard Archipelago Item Cyan
            } else if (part.type === "location_id" || part.type === "location_name") {
                color = "#00ff00"; // Standard Archipelago Location Green
            } else if (part.type === "entrance_id") {
                color = "#da70d6"; // Standard Archipelago Entrance Orchid
            } else {
                // No specific color, just add text as-is
                result += text;
                continue;
            }
            result += `<font color='${color}'>${text}</font>`;
        }
        return result;
    }

static refreshConsoleUI(chat: any[]) {
        if (!this.m_Panel || !chat) return;
        const output = this.m_Panel.FindChildTraverse('ConsoleOutput') as any;
        if (!output) return;

        let fullText = "";
        for (const msg of chat) {
            const d = new Date(msg.time * 1000);
            const timeStr = "[" + d.getHours().toString().padStart(2, '0') + ":" + d.getMinutes().toString().padStart(2, '0') + "]";
            
            let lineText = "";
            if (msg.type === "json" && Array.isArray(msg.data)) {
                lineText = this.formatRichMessage(msg.data);
            } else {
                lineText = msg.text || "";
                lineText = lineText.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
            }
            
            fullText += `<font color='#888888'>${timeStr}</font> ${lineText}<br/>`;
        }

        // --- COMPARAISON STRICTE ---
        // Si le texte genere est EXACTEMENT le meme que celui deja affiche,
        // on ne touche ABSOLUMENT PAS a output.text.
        if (output.text === fullText || this.g_ConsoleText === fullText) {
            return;
        }

        this.g_ConsoleText = fullText;
        output.text = fullText; // Le son ne se declenchera QUE si cette ligne s'execute
        // ---------------------------

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
