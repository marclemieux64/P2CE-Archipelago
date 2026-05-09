'use strict';
declare var $: any;
declare var UiToolkitAPI: any;

class ArchipelagoConsole {
    static m_LastChatCount = 0;
    static g_ConsoleText: string = "";

    // Command History
    static g_CommandHistory: string[] = [];
    static g_HistoryIndex: number = -1;
    static g_CurrentInputBuffer: string = "";

    // Autocomplete Data
    static readonly COMMANDS = [
        "!license", "!options", "!admin", "!help", "!players", "!status", "!release", 
        "!collect", "!countdown seconds=", "!remaning", "!missing", "!checked", 
        "!alias", "!getitem", "!hint", "!hint_location", "!video", 
        "/license", "/exit", "/connect", "/disconnect", "/help", "/received", "/missing", 
        "/items", "/locations", "/item_groups", "/location_groups", "/ready", 
        "/check_connection", "/command", "/deathlink", "/refresh_menu", 
        "/message_in_game", "/needed"
    ];
    static m_FilteredCommands: string[] = [];
    static m_SelectedCmdIndex = 0;

    static COLOR_MAP: Record<string, string> = {
        "red": "#ff5555", "green": "#00ff00", "yellow": "#ffff00",
        "blue": "#77aaff", "magenta": "#ee82ee", "cyan": "#00ffff",
        "white": "#ffffff", "black": "#000000", "gold": "#ffd700",
        "plum": "#dda0dd", "salmon": "#fa8072", "slate": "#708090",
        "brown": "#8b4513", "orange": "#ffa500", "pink": "#ffc0cb",
        "purple": "#800080", "grey": "#808080"
    };

    static init() {
        $.DispatchEvent('MainMenuSetPageLines', 
            $.Localize('#Archipelago_Console_Title'), 
            $.Localize('#Archipelago_Console_Tagline')
        );

        const input = $.GetContextPanel().FindChildTraverse('ArchipelagoInput') as any;
        const wrapper = $.GetContextPanel().FindChildTraverse('ArchipelagoInputWrapper');

        if (input && wrapper) {
            input.SetPanelEvent('onfocus', () => { wrapper.AddClass('focused'); });
            input.SetPanelEvent('onblur', () => { wrapper.RemoveClass('focused'); });

            // Écoute de texte sécurisée
            input.SetPanelEvent('ontextentrychange', () => ArchipelagoConsole.onTextChanged());
            input.SetPanelEvent('oninputsubmit', () => ArchipelagoConsole.onArchipelagoInput());

            // Navigation intelligente Flèches + Tabulation
            $.RegisterKeyBind(input, "key_up", () => {
                if (ArchipelagoConsole.m_FilteredCommands.length > 0) return ArchipelagoConsole.navigateSuggestions(-1);
                return ArchipelagoConsole.handleHistoryNavigation(true);
            });
            $.RegisterKeyBind(input, "key_down", () => {
                if (ArchipelagoConsole.m_FilteredCommands.length > 0) return ArchipelagoConsole.navigateSuggestions(1);
                return ArchipelagoConsole.handleHistoryNavigation(false);
            });
            
            $.RegisterKeyBind(input, "key_tab", () => ArchipelagoConsole.autocompleteSelection());
        }

        const output = $.GetContextPanel().FindChildTraverse('ConsoleOutput') as any;
        if (output) {
            output.SetPanelEvent('onkeydown', () => {
                const key = $.GetContextPanel().GetOwnerWindow()?.GetLastKey();
                if (key === 8 || key === 46 || key > 46) return true;
                return false;
            });
        }

        $.Schedule(0.1, () => {
            if (input) input.SetFocus();
        });

        $.RegisterForUnhandledEvent('ArchipelagoAPI_ChatUpdated', (json: string) => {
            try {
                const chat = JSON.parse(json);
                ArchipelagoConsole.refreshConsoleUI(chat);
            } catch (e) { }
        });

        const api: any = (UiToolkitAPI.GetGlobalObject() as any).ArchipelagoAPI;
        if (api) {
            const currentChat = api.getChat();
            if (currentChat && currentChat.length > 0) {
                ArchipelagoConsole.refreshConsoleUI(currentChat);
            } else {
                api.fetchChat((chat: any[]) => ArchipelagoConsole.refreshConsoleUI(chat));
            }
        }
    }

    static onTextChanged() {
        const input = $.GetContextPanel().FindChildTraverse('ArchipelagoInput') as any;
        const box = $.GetContextPanel().FindChildTraverse('SuggestionBox');
        if (!input || !box) return;

        const val = input.text.toLowerCase().trim();
        if (val.length < 1) {
            box.AddClass('hide');
            ArchipelagoConsole.m_FilteredCommands = [];
            return;
        }

        ArchipelagoConsole.m_FilteredCommands = ArchipelagoConsole.COMMANDS.filter(cmd => cmd.toLowerCase().indexOf(val) !== -1);

        if (ArchipelagoConsole.m_FilteredCommands.length > 0) {
            ArchipelagoConsole.m_SelectedCmdIndex = 0;
            ArchipelagoConsole.updateSuggestionUI();
            box.RemoveClass('hide');
        } else {
            box.AddClass('hide');
        }
    }

    static navigateSuggestions(dir: number): boolean {
        if (ArchipelagoConsole.m_FilteredCommands.length === 0) return false;
        ArchipelagoConsole.m_SelectedCmdIndex = (ArchipelagoConsole.m_SelectedCmdIndex + dir + ArchipelagoConsole.m_FilteredCommands.length) % ArchipelagoConsole.m_FilteredCommands.length;
        ArchipelagoConsole.updateSuggestionUI();
        return true;
    }

    static autocompleteSelection(): boolean {
        if (ArchipelagoConsole.m_FilteredCommands.length === 0) return false;
        
        const input = $.GetContextPanel().FindChildTraverse('ArchipelagoInput') as any;
        const box = $.GetContextPanel().FindChildTraverse('SuggestionBox');
        
        if (input && box) {
            input.text = ArchipelagoConsole.m_FilteredCommands[ArchipelagoConsole.m_SelectedCmdIndex];
            ArchipelagoConsole.m_FilteredCommands = [];
            box.AddClass('hide');
            input.SetFocus(); 
        }
        return true;
    }

    static updateSuggestionUI() {
        const box = $.GetContextPanel().FindChildTraverse('SuggestionBox');
        const input = $.GetContextPanel().FindChildTraverse('ArchipelagoInput') as any;
        if (!box || !input) return;

        box.RemoveAndDeleteChildren();
        const val = input.text.toLowerCase();

        ArchipelagoConsole.m_FilteredCommands.slice(0, 5).forEach((cmd, idx) => {
            const btn = $.CreatePanel('Button', box, '');
            btn.AddClass('suggestion-item');
            if (idx === ArchipelagoConsole.m_SelectedCmdIndex) btn.AddClass('selected');

            btn.SetPanelEvent('onactivate', () => {
                ArchipelagoConsole.m_SelectedCmdIndex = idx;
                ArchipelagoConsole.autocompleteSelection();
            });

            const lbl = $.CreatePanel('Label', btn, '');
            lbl.html = true; 

            const startIdx = cmd.toLowerCase().indexOf(val);
            if (startIdx !== -1) {
                const before = cmd.substring(0, startIdx);
                const match = cmd.substring(startIdx, startIdx + val.length);
                const after = cmd.substring(startIdx + val.length);
                lbl.text = before + "<font color='#ec6726'>" + match + "</font>" + after;
            } else {
                lbl.text = cmd;
            }
        });
    }

    static handleHistoryNavigation(isUp: boolean): boolean {
        const input = $.GetContextPanel().FindChildTraverse('ArchipelagoInput') as any;
        if (!input) return false;

        if (isUp) {
            if (ArchipelagoConsole.g_CommandHistory.length === 0) return true;

            if (ArchipelagoConsole.g_HistoryIndex === -1) {
                ArchipelagoConsole.g_CurrentInputBuffer = input.text;
            }

            if (ArchipelagoConsole.g_HistoryIndex < ArchipelagoConsole.g_CommandHistory.length - 1) {
                ArchipelagoConsole.g_HistoryIndex++;
                input.text = ArchipelagoConsole.g_CommandHistory[ArchipelagoConsole.g_CommandHistory.length - 1 - ArchipelagoConsole.g_HistoryIndex];
                $.Schedule(0.0, () => input.SetCursorOffset(input.text.length));
            }
            return true;
        }
        else {
            if (ArchipelagoConsole.g_HistoryIndex === -1) return true;

            if (ArchipelagoConsole.g_HistoryIndex > 0) {
                ArchipelagoConsole.g_HistoryIndex--;
                input.text = ArchipelagoConsole.g_CommandHistory[ArchipelagoConsole.g_CommandHistory.length - 1 - ArchipelagoConsole.g_HistoryIndex];
                $.Schedule(0.0, () => input.SetCursorOffset(input.text.length));
            } else {
                ArchipelagoConsole.g_HistoryIndex = -1;
                input.text = ArchipelagoConsole.g_CurrentInputBuffer;
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
            text = text.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
            
            let color = "#ffffff";
            if (part.color && ArchipelagoConsole.COLOR_MAP[part.color]) {
                color = ArchipelagoConsole.COLOR_MAP[part.color];
            } else if (part.type === "player_id" || part.type === "player_name") {
                color = "#ff7f50"; 
            } else if (part.type === "item_id" || part.type === "item_name") {
                color = "#00ffff"; 
            } else if (part.type === "location_id" || part.type === "location_name") {
                color = "#00ff00"; 
            } else if (part.type === "entrance_id") {
                color = "#da70d6"; 
            } else {
                result += text;
                continue;
            }
            result += `<font color='${color}'>${text}</font>`;
        }
        return result;
    }

    static refreshConsoleUI(chat: any[]) {
        const output = $.GetContextPanel().FindChildTraverse('ConsoleOutput') as any;
        if (!output) return;

        let fullText = "";
        for (const msg of chat) {
            const d = new Date(msg.time * 1000);
            const timeStr = "[" + d.getHours().toString().padStart(2, '0') + ":" + d.getMinutes().toString().padStart(2, '0') + "]";
            
            let lineText = "";
            if (msg.type === "json" && Array.isArray(msg.data)) {
                lineText = ArchipelagoConsole.formatRichMessage(msg.data);
            } else {
                lineText = msg.text || "";
                lineText = lineText.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
            }
            
            fullText += `<font color='#888888'>${timeStr}</font> ${lineText}<br/>`;
        }

        if (output.text === fullText || ArchipelagoConsole.g_ConsoleText === fullText) return;

        ArchipelagoConsole.g_ConsoleText = fullText;
        output.text = fullText; 

        $.Schedule(0.05, () => {
            const outputArea = $.GetContextPanel().FindChildTraverse('ConsoleOutputArea');
            if (outputArea && typeof (outputArea as any).ScrollToBottom === 'function') {
                (outputArea as any).ScrollToBottom();
            }
        });
    }

    static onArchipelagoInput() {
        if (ArchipelagoConsole.m_FilteredCommands.length > 0) {
            ArchipelagoConsole.autocompleteSelection();
            return;
        }

        const input = $.GetContextPanel().FindChildTraverse('ArchipelagoInput') as any;
        const box = $.GetContextPanel().FindChildTraverse('SuggestionBox');
        if (!input || !input.text) return;

        const text = input.text.trim();
        if (!text) return;

        if (ArchipelagoConsole.g_CommandHistory.length === 0 || ArchipelagoConsole.g_CommandHistory[ArchipelagoConsole.g_CommandHistory.length - 1] !== text) {
            ArchipelagoConsole.g_CommandHistory.push(text);
        }
        ArchipelagoConsole.g_HistoryIndex = -1;

        input.text = "";
        ArchipelagoConsole.m_FilteredCommands = [];
        box?.AddClass('hide');
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