'use strict';

class ArchipelagoHint {
    static readonly ITEMS = [
        "Portal Gun", "Upgraded Portal Gun", "PotatOS", "Weighted Cubes",
        "Redirection Cubes", "Spherical Cubes", "Antique Cubes", "Buttons",
        "Antique Buttons", "Floor Buttons", "Antique Floor Buttons", "Cube Buttons",
        "Ball Buttons", "Frankenturrets", "Three Gels", "Blue Gel", "Orange Gel",
        "White Gel", "Lasers", "Aerial Faith Plates", "Excursion Funnels",
        "Hard Light Bridges", "Laser Relays", "Laser Catchers", "Turrets",
        "Adventure Core", "Space Core", "Fact Core", "Moon Dust", "Lemon",
        "Slice of Cake", "Motion Blur Trap", "Fizzle Portal Trap",
        "Butter Fingers Trap", "Cube Confetti Trap", "Slippery Floor Trap"
    ];

    static m_FilteredItems: string[] = [];
    static m_SelectedIndex = 0;
    static m_SyncCounter = 0;
    static m_SyncInterval = 10;

    static m_WaitingForFeedback = false;
    static m_LastMatchedMsg = ""; 
    static m_FeedbackHideSchedule: any = null;
    static m_RequestChatLength = 0;
    
    // Cache de rendu pour éviter d'effondrer le moteur de rendu Panorama
    static m_LastRawHints: string = "";
    static m_UpdateSchedule: any = null;

    static init() {
        $.DispatchEvent('MainMenuSetPageLines', 
            $.Localize('#Archipelago_Hints_Title'), 
            $.Localize('#Archipelago_Hints_Tooltip')
        );

        const api: any = (UiToolkitAPI.GetGlobalObject() as any).ArchipelagoAPI;
        
        // --- CHARGEMENT INSTANTANÉ DE SÉCURITÉ PAR LE CACHE ---
        const cachedHints = $.persistentStorage.getItem("ArchipelagoLastHintsCacheData");
        if (cachedHints) {
            try { this.render(JSON.parse(cachedHints)); } catch(e) {}
        }

        if (api) {
            $.AsyncWebRequest(api.API_BASE + "/hints/refresh", { type: 'POST' });
            this.updateLoop();
        }

        const doneHeader = $.GetContextPanel().FindChildTraverse('DoneHeader') as any;
        if (doneHeader) {
            doneHeader.SetPanelEvent('onactivate', () => ArchipelagoHint.toggleDoneSection());
        }

        const input = $.GetContextPanel().FindChildTraverse('ArchipelagoInput') as any;
        if (input) {
            input.SetFocus();
            
            input.SetPanelEvent('ontextentrychange', () => ArchipelagoHint.onTextChanged());
            input.SetPanelEvent('oninputsubmit', () => ArchipelagoHint.onHintInputSubmit());

            $.RegisterKeyBind(input, "key_up", () => ArchipelagoHint.navigateSuggestions(-1));
            $.RegisterKeyBind(input, "key_down", () => ArchipelagoHint.navigateSuggestions(1));
            $.RegisterKeyBind(input, "key_tab", () => ArchipelagoHint.autocompleteSelection());
        }

        if (api) {
            api.registerChatListener($.GetContextPanel(), (json: string) => {
                if (!ArchipelagoHint.m_WaitingForFeedback) return;
                try {
                    const chat = typeof json === 'string' ? JSON.parse(json) : json;
                    if (chat && chat.length > ArchipelagoHint.m_RequestChatLength) {
                        for (let i = ArchipelagoHint.m_RequestChatLength; i < chat.length; i++) {
                            const msg = chat[i];
                            const rawStr = JSON.stringify(msg).toLowerCase();
                            
                            if ((rawStr.includes("afford") || rawStr.includes("need at least")) && !rawStr.includes("!hint")) {
                                if (rawStr !== ArchipelagoHint.m_LastMatchedMsg) {
                                    ArchipelagoHint.m_LastMatchedMsg = rawStr;
                                    
                                    let displayMsg = "You don't have enough points for this hint.";
                                    if (typeof msg === 'string') displayMsg = msg;
                                    else if (msg.text) displayMsg = msg.text;
                                    else if (msg.html) displayMsg = msg.html;
                                    else if (msg.message) displayMsg = msg.message;
                                    
                                    ArchipelagoHint.showFeedback(displayMsg);
                                    ArchipelagoHint.m_WaitingForFeedback = false;
                                    return;
                                }
                            }
                        }
                    }
                } catch (e) { }
            });

            const updatePoints = (json: string) => {
                try {
                    let status = typeof json === 'string' ? JSON.parse(json) : json;
                    if (status && status.hint_points !== undefined) {
                        const ptsLabel = $.GetContextPanel().FindChildTraverse('HintPointsLabel') as LabelPanel;
                        if (ptsLabel) {
                            const cost = status.hint_cost !== undefined ? status.hint_cost : 0;
                            
                            let locPoints = $.Localize('#Archipelago_Points');
                            let locCost = $.Localize('#Archipelago_Cost');
                            
                            if (locPoints === '#Archipelago_Points') locPoints = 'Points';
                            if (locCost === '#Archipelago_Cost') locCost = 'Cost';

                            ptsLabel.text = `${locPoints}: ${status.hint_points} | ${locCost}: ${cost}`;
                            ptsLabel.style.color = status.hint_points >= cost ? "#44ff44" : "#ff5555";
                        }
                    }
                } catch (e) { }
            };

            api.registerStatusListener($.GetContextPanel(), (payload: any) => {
                updatePoints(payload);
            });
        }
    }

    static showFeedback(msg: string) {
        const lbl = $.GetContextPanel().FindChildTraverse('HintFeedback') as LabelPanel;
        if (!lbl) return;

        lbl.html = true;
        lbl.text = msg;
        lbl.RemoveClass('hide');

        if (this.m_FeedbackHideSchedule) {
            $.CancelScheduled(this.m_FeedbackHideSchedule);
        }
        
        this.m_FeedbackHideSchedule = $.Schedule(6.0, () => {
            lbl.AddClass('hide');
            this.m_FeedbackHideSchedule = null;
        });
    }

    static onTextChanged() {
        const input = $.GetContextPanel().FindChildTraverse('ArchipelagoInput') as any;
        const box = $.GetContextPanel().FindChildTraverse('SuggestionBox');
        if (!input || !box) return;

        const val = input.text.toLowerCase().trim();
        if (val.length < 1) {
            box.AddClass('hide');
            this.m_FilteredItems = [];
            return;
        }

        this.m_FilteredItems = this.ITEMS.filter(item => item.toLowerCase().indexOf(val) !== -1);

        if (this.m_FilteredItems.length > 0) {
            this.m_SelectedIndex = 0;
            this.updateSuggestionUI();
            box.RemoveClass('hide');
        } else {
            box.AddClass('hide');
        }
    }

    static navigateSuggestions(dir: number): boolean {
        if (this.m_FilteredItems.length === 0) return false;
        this.m_SelectedIndex = (this.m_SelectedIndex + dir + this.m_FilteredItems.length) % this.m_FilteredItems.length;
        this.updateSuggestionUI();
        return true;
    }

    static autocompleteSelection(): boolean {
        if (this.m_FilteredItems.length === 0) return false;
        
        const input = $.GetContextPanel().FindChildTraverse('ArchipelagoInput') as any;
        const box = $.GetContextPanel().FindChildTraverse('SuggestionBox');
        
        if (input && box) {
            input.text = this.m_FilteredItems[this.m_SelectedIndex];
            this.m_FilteredItems = [];
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

        this.m_FilteredItems.slice(0, 5).forEach((item, idx) => {
            const btn = $.CreatePanel('Button', box, '');
            btn.AddClass('suggestion-item');
            if (idx === this.m_SelectedIndex) btn.AddClass('selected');

            btn.SetPanelEvent('onactivate', () => {
                this.m_SelectedIndex = idx;
                this.autocompleteSelection();
            });

            const lbl = $.CreatePanel('Label', btn, '');
            lbl.html = true; 

            const startIdx = item.toLowerCase().indexOf(val);
            if (startIdx !== -1) {
                const before = item.substring(0, startIdx);
                const match = item.substring(startIdx, startIdx + val.length);
                const after = item.substring(startIdx + val.length);
                lbl.text = before + "<font color='#ec6726'>" + match + "</font>" + after;
            } else {
                lbl.text = item;
            }
        });
    }

    static onHintInputSubmit() {
        const panel = $.GetContextPanel();
        const input = panel.FindChildTraverse('ArchipelagoInput') as any;
        const api = (UiToolkitAPI.GetGlobalObject() as any).ArchipelagoAPI;
        const box = panel.FindChildTraverse('SuggestionBox');

        if (!api || !input) return;

        if (this.m_FilteredItems.length > 0) {
            this.autocompleteSelection();
            return; 
        }

        const finalValue = input.text.trim();

        if (finalValue) {
            this.m_WaitingForFeedback = true;
            this.m_LastMatchedMsg = ""; 
            this.m_LastRawHints = ""; 
            
            const currentChat = api.getChat();
            this.m_RequestChatLength = currentChat ? currentChat.length : 0;
            
            $.Schedule(5.0, () => { this.m_WaitingForFeedback = false; });

            // On utilise sendCommand qui nettoie le cache réseau instantanément
            api.sendCommand("!hint " + finalValue, () => {
                api.forceRefreshHints();
            });

            input.text = "";
            this.m_FilteredItems = [];
            box?.AddClass('hide');
        }
    }

    static toggleDoneSection() {
        const section = $.GetContextPanel().FindChildTraverse('SectionDone');
        if (section) section.ToggleClass('collapsed');
    }

    static updateLoop() {
        if (this.m_UpdateSchedule) {
            try { $.CancelScheduled(this.m_UpdateSchedule); } catch(e) {}
            this.m_UpdateSchedule = null;
        }

        if (!$.GetContextPanel().IsValid()) return;
        const api = (UiToolkitAPI.GetGlobalObject() as any).ArchipelagoAPI;
        if (!api) return;

        this.m_SyncCounter++;
        if (this.m_SyncCounter >= this.m_SyncInterval) {
            $.AsyncWebRequest(api.API_BASE + "/hints/refresh", { type: 'POST' });
            this.m_SyncCounter = 0;
        }

        $.AsyncWebRequest(api.API_BASE + "/hints", {
            type: 'GET',
            complete: (res: any) => {
                if (!$.GetContextPanel().IsValid()) return;

                if (res.status === 200 && res.responseText) {
                    const cleanText = res.responseText.trim().replace(/\0/g, '');
                    
                    if (cleanText === ArchipelagoHint.m_LastRawHints) {
                        this.m_UpdateSchedule = $.Schedule(1.0, () => this.updateLoop());
                        return;
                    }
                    ArchipelagoHint.m_LastRawHints = cleanText;
                    $.persistentStorage.setItem("ArchipelagoLastHintsCacheData", cleanText);

                    try {
                        const hints = JSON.parse(cleanText);
                        this.render(hints);
                    } catch (e) { }
                }
                this.m_UpdateSchedule = $.Schedule(1.0, () => this.updateLoop());
            }
        });
    }

    static render(hints: any[]) {
        const pending = $.GetContextPanel().FindChildTraverse('HintListPending');
        const done = $.GetContextPanel().FindChildTraverse('HintListDone');
        if (!pending || !done) return;

        hints.sort((a, b) => a.text.localeCompare(b.text));
        pending.RemoveAndDeleteChildren();
        done.RemoveAndDeleteChildren();

        hints.forEach(hint => {
            const row = $.CreatePanel('Panel', hint.found ? done : pending, '');
            row.AddClass('hint-row');
            if (hint.found) row.AddClass('hint--found');
            const lbl = $.CreatePanel('Label', row, '');
            lbl.html = true;
            lbl.text = hint.text;
        });
    }
}

// Export Global
{
    const cp = $.GetContextPanel() as any;
    const global = UiToolkitAPI.GetGlobalObject() as any;
    if (cp) cp.ArchipelagoHint = ArchipelagoHint;
    if (global) global.ArchipelagoHint = ArchipelagoHint;
}