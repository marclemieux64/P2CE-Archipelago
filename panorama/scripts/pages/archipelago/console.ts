'use strict';
declare var $: any;
declare var UiToolkitAPI: any;

class ArchipelagoConsole {
    // Command History
    static g_CommandHistory: string[] = [];
    static g_HistoryIndex: number = -1;
    static g_CurrentInputBuffer: string = "";

    // Autocomplete Data
    static readonly COMMANDS = [
        "!license", "!options", "!admin", "!help", "!players", "!status", "!release",
        "!collect", "!countdown seconds=", "!remaning", "!missing", "!checked",
        "!alias", "!getitem", "!hint", "!hint_location", "!video",
        "/license", "/exit","/connect archipelago.gg:", "/connect", "/disconnect", "/help", "/received", "/missing",
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
        "brown": "#8b4313", "orange": "#ffa500", "pink": "#ffc0cb",
        "purple": "#800080", "grey": "#808080"
    };

    // Debounce storage writes — flush at most once per 3s
    static m_StoragePendingChat: any[] | null = null;
    static m_StorageFlushSchedule: any = null;

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

            input.SetPanelEvent('ontextentrychange', () => ArchipelagoConsole.onTextChanged());
            input.SetPanelEvent('oninputsubmit', () => ArchipelagoConsole.onArchipelagoInput());

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

        $.Schedule(0.1, () => {
            if (input) input.SetFocus();
        });

        const api: any = (UiToolkitAPI.GetGlobalObject() as any).ArchipelagoAPI;
        if (api) {
            // On initial registration: receives full accumulated array (history).
            // On subsequent dispatches: receives delta only.
            api.registerChatListener($.GetContextPanel(), (data: any[]) => {
                if (!Array.isArray(data) || data.length === 0) return;
                const output = $.GetContextPanel().FindChildTraverse('ConsoleOutput') as any;
                if (!output) return;
                const isHistory = output.GetChildCount() === 0;
                if (isHistory) {
                    ArchipelagoConsole.buildAllPanels(data);
                } else {
                    ArchipelagoConsole.appendPanels(data);
                }
            });
        }
    }

    static formatMessage(msg: any): string {
        let timeStr = "";
        if (msg.time_str) {
            timeStr = "[" + msg.time_str + "]";
        } else {
            const d = new Date(msg.time * 1000);
            timeStr = "[" + d.getHours().toString().padStart(2, '0') + ":" + d.getMinutes().toString().padStart(2, '0') + "]";
        }

        let lineText = "";
        if (msg.html) {
            lineText = msg.html;
        } else if (msg.type === "json" && Array.isArray(msg.data)) {
            lineText = ArchipelagoConsole.formatRichMessage(msg.data);
        } else {
            lineText = (msg.text || "").replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
        }

        return `<font color='#888888'>${timeStr}</font> ${lineText}`;
    }

    // Full rebuild from an array — used on init and cache load.
    static buildAllPanels(chat: any[]) {
        const output = $.GetContextPanel().FindChildTraverse('ConsoleOutput') as any;
        if (!output) return;
        output.RemoveAndDeleteChildren();
        for (const msg of chat) {
            if (!msg) continue;
            ArchipelagoConsole.createLinePanel(output, msg);
        }
        ArchipelagoConsole.scheduleStorageFlush(chat);
        ArchipelagoConsole.scrollToBottom();
    }

    // Incremental append — used on each delta from the API.
    static appendPanels(delta: any[]) {
        const output = $.GetContextPanel().FindChildTraverse('ConsoleOutput') as any;
        if (!output) return;
        for (const msg of delta) {
            if (!msg) continue;
            ArchipelagoConsole.createLinePanel(output, msg);
        }
        // Trim to max 100 panels (evict oldest)
        while (output.GetChildCount() > 100) {
            const oldest = output.GetChild(0);
            if (oldest) oldest.DeleteAsync(0);
        }
        // Accumulate for deferred storage write
        const api: any = (UiToolkitAPI.GetGlobalObject() as any).ArchipelagoAPI;
        if (api) ArchipelagoConsole.scheduleStorageFlush(api.getChat());
        ArchipelagoConsole.scrollToBottom();
    }

    static createLinePanel(output: any, msg: any) {
        const line = $.CreatePanel('Label', output, '') as any;
        line.AddClass('console-line');
        line.html = true;
        line.text = ArchipelagoConsole.formatMessage(msg);
    }

    static scrollToBottom() {
        $.Schedule(0.05, () => {
            const outputArea = $.GetContextPanel().FindChildTraverse('ConsoleOutputArea');
            if (outputArea && typeof (outputArea as any).ScrollToBottom === 'function') {
                (outputArea as any).ScrollToBottom();
            }
        });
    }

    static scheduleStorageFlush(chat: any[]) {
        ArchipelagoConsole.m_StoragePendingChat = chat;
        if (!ArchipelagoConsole.m_StorageFlushSchedule) {
            ArchipelagoConsole.m_StorageFlushSchedule = $.Schedule(3.0, () => {
                ArchipelagoConsole.m_StorageFlushSchedule = null;
                if (ArchipelagoConsole.m_StoragePendingChat) {
                    $.persistentStorage.setItem("ArchipelagoLastChatCacheData", JSON.stringify(ArchipelagoConsole.m_StoragePendingChat));
                    ArchipelagoConsole.m_StoragePendingChat = null;
                }
            });
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
        } else {
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
                    if (api.pulse) api.pulse();
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
