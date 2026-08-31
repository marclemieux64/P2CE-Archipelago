'use strict';
declare var $: any;
declare var UiToolkitAPI: any;
declare var SteamOverlayAPI: any;

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

    static m_Ctx: any = null;
    static m_DisplayLines: any[] = [];
    static m_LabelPanels: any[] = [];

    static readonly MAX_LABELS = 300;
    static m_LastDisplayedId: number = -1;
    static m_IsAutoScrolling = true;

    static init() {
        ArchipelagoConsole.m_Ctx = $.GetContextPanel();

        $.DispatchEvent('MainMenuSetPageLines',
            $.Localize('#Archipelago_Console_Title'),
            $.Localize('#Archipelago_Console_Tagline')
        );

        const outputArea = ArchipelagoConsole.m_Ctx.FindChildTraverse('ConsoleOutputArea');
        const poolContainer = ArchipelagoConsole.m_Ctx.FindChildTraverse('ConsolePoolContainer');
        const input = $.GetContextPanel().FindChildTraverse('ArchipelagoInput') as any;
        const wrapper = $.GetContextPanel().FindChildTraverse('ArchipelagoInputWrapper');

        if (poolContainer) {
            poolContainer.RemoveAndDeleteChildren();
            ArchipelagoConsole.m_LabelPanels = [];
            ArchipelagoConsole.m_DisplayLines = [];
        }

        if (outputArea) {
            outputArea.SetPanelEvent('onscroll', () => {
                ArchipelagoConsole.onConsoleScroll();
            });
        }

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
            if (input && input.IsValid()) input.SetFocus();
        });

        ArchipelagoConsole.startPolling();

        const api: any = (UiToolkitAPI.GetGlobalObject() as any).ArchipelagoAPI;
        if (api) {
            api.registerChatListener($.GetContextPanel(), (data: any[], isInitialSync: boolean) => {
                if (!Array.isArray(data) || data.length === 0) return;
                const isHistory = ArchipelagoConsole.m_DisplayLines.length === 0 || isInitialSync;
                if (isHistory) {
                    ArchipelagoConsole.buildAllPanels(data);
                } else {
                    ArchipelagoConsole.appendPanels(data);
                }
            }, true);
        }
    }

    static formatMessage(msg: any): string {
        let timeStr = "";
        if (msg.time_str) {
            timeStr = "[" + msg.time_str + "]";
        } else if (msg.time) {
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

    static onConsoleScroll() {
        const ctx = ArchipelagoConsole.m_Ctx;
        if (!ctx || !ctx.IsValid()) return;
        const outputArea = ctx.FindChildTraverse('ConsoleOutputArea');
        if (!outputArea) return;

        const maxScroll = outputArea.contentheight - outputArea.actuallayoutheight;
        if (maxScroll <= 0) return;

        const deltaFromBottom = maxScroll - outputArea.scrolloffset_y;
        ArchipelagoConsole.m_IsAutoScrolling = (deltaFromBottom < 35);
    }

    static buildAllPanels(chat: any[]) {
        const poolContainer = ArchipelagoConsole.m_Ctx?.FindChildTraverse('ConsolePoolContainer');
        if (!poolContainer || !poolContainer.IsValid()) return;

        poolContainer.RemoveAndDeleteChildren();
        ArchipelagoConsole.m_LabelPanels = [];
        ArchipelagoConsole.m_DisplayLines = [];
        ArchipelagoConsole.m_LastDisplayedId = -1;

        const startFrom = Math.max(0, chat.length - ArchipelagoConsole.MAX_LABELS);
        const slice = chat.slice(startFrom);

        // Batched insertion: Render latest 50 messages immediately, load older ones across frames
        const CHUNK_SIZE = 50;
        const total = slice.length;

        const renderChunk = (startIdx: number) => {
            const container = ArchipelagoConsole.m_Ctx?.FindChildTraverse('ConsolePoolContainer');
            if (!container || !container.IsValid()) return;

            const endIdx = Math.min(startIdx + CHUNK_SIZE, total);
            for (let i = startIdx; i < endIdx; i++) {
                const msg = slice[i];
                if (!msg) continue;
                msg.cachedMarkup = ArchipelagoConsole.formatMessage(msg);
                ArchipelagoConsole.m_DisplayLines.push(msg);
                if (msg.id !== undefined && msg.id > ArchipelagoConsole.m_LastDisplayedId)
                    ArchipelagoConsole.m_LastDisplayedId = msg.id;

                const lbl = $.CreatePanel('Label', container, '');
                lbl.html = true;
                lbl.AddClass('console_line_item');
                lbl.text = msg.cachedMarkup;
                ArchipelagoConsole.m_LabelPanels.push(lbl);
            }

            if (startIdx === 0) {
                ArchipelagoConsole.scrollToBottom();
            }

            if (endIdx < total) {
                $.Schedule(0.01, () => renderChunk(endIdx));
            }
        };

        renderChunk(0);
    }

    static appendPanels(delta: any[]) {
        const poolContainer = ArchipelagoConsole.m_Ctx?.FindChildTraverse('ConsolePoolContainer');
        if (!poolContainer || !poolContainer.IsValid()) return;

        let added = false;
        for (const msg of delta) {
            if (!msg || (msg.id !== undefined && msg.id <= ArchipelagoConsole.m_LastDisplayedId)) continue;

            msg.cachedMarkup = ArchipelagoConsole.formatMessage(msg);
            ArchipelagoConsole.m_DisplayLines.push(msg);
            if (msg.id !== undefined) ArchipelagoConsole.m_LastDisplayedId = msg.id;

            const lbl = $.CreatePanel('Label', poolContainer, '');
            lbl.html = true;
            lbl.AddClass('console_line_item');
            lbl.text = msg.cachedMarkup;
            ArchipelagoConsole.m_LabelPanels.push(lbl);
            added = true;
        }

        if (!added) return;

        while (ArchipelagoConsole.m_LabelPanels.length > ArchipelagoConsole.MAX_LABELS) {
            const old = ArchipelagoConsole.m_LabelPanels.shift();
            if (old && old.IsValid()) old.DeleteAsync(0);
            ArchipelagoConsole.m_DisplayLines.shift();
        }

        if (ArchipelagoConsole.m_IsAutoScrolling) {
            ArchipelagoConsole.scrollToBottom();
        }
    }

    static scrollToBottom() {
        const ctx = ArchipelagoConsole.m_Ctx;
        if (!ctx || !ctx.IsValid()) return;
        const outputArea = ctx.FindChildTraverse('ConsoleOutputArea');
        if (!outputArea || !outputArea.IsValid()) return;

        $.Schedule(0.05, () => {
            if (!outputArea.IsValid()) return;
            if (typeof (outputArea as any).ScrollToBottom === 'function') {
                ArchipelagoConsole.m_IsAutoScrolling = true;
                (outputArea as any).ScrollToBottom();
            }
        });
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

    static m_PollSchedule: any = null;

    static startPolling() {
        const ctx = $.GetContextPanel();
        if (!ctx || !ctx.IsValid()) {
            ArchipelagoConsole.m_PollSchedule = null;
            return;
        }
        ArchipelagoConsole.m_PollSchedule = $.Schedule(2.0, () => {
            const c = $.GetContextPanel();
            if (!c || !c.IsValid()) {
                ArchipelagoConsole.m_PollSchedule = null;
                return;
            }
            const api: any = (UiToolkitAPI.GetGlobalObject() as any).ArchipelagoAPI;
            if (api && api.scheduleDebouncedPulse) api.scheduleDebouncedPulse();
            ArchipelagoConsole.startPolling();
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
            api.m_AllETag = "";
            $.AsyncWebRequest(api.API_BASE + "/command", {
                type: 'POST',
                data: { command: text },
                complete: () => {
                    if (api.scheduleDebouncedPulse) api.scheduleDebouncedPulse();
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