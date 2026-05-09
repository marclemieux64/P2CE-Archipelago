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

    static init() {
        $.DispatchEvent('MainMenuSetPageLines', 
            $.Localize('#Archipelago_Hints_Title'), 
            $.Localize('#Archipelago_Hints_Tooltip')
        );

        const api: any = (UiToolkitAPI.GetGlobalObject() as any).ArchipelagoAPI;
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
            
            // NOUVEAU : La touche TAB déclenche l'autocomplétion
            $.RegisterKeyBind(input, "key_tab", () => ArchipelagoHint.autocompleteSelection());
        }
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

    // --- NOUVELLE FONCTION : Remplir le champ texte ---
    static autocompleteSelection(): boolean {
        if (this.m_FilteredItems.length === 0) return false;
        
        const input = $.GetContextPanel().FindChildTraverse('ArchipelagoInput') as any;
        const box = $.GetContextPanel().FindChildTraverse('SuggestionBox');
        
        if (input && box) {
            // Remplace le texte tapé par l'objet complet sélectionné
            input.text = this.m_FilteredItems[this.m_SelectedIndex];
            
            // Vide la liste et cache la boîte
            this.m_FilteredItems = [];
            box.AddClass('hide');
            
            // Force le moteur à garder le curseur dans l'input pour appuyer sur Entrée ensuite
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
            // FIX : Utilisation d'un Button au lieu d'un Label pour capter le clic souris
            const btn = $.CreatePanel('Button', box, '');
            btn.AddClass('suggestion-item');
            if (idx === this.m_SelectedIndex) btn.AddClass('selected');

            // NOUVEAU : Clic souris déclenche l'autocomplétion
            btn.SetPanelEvent('onactivate', () => {
                this.m_SelectedIndex = idx;
                this.autocompleteSelection();
            });

            // Le Label est placé à l'intérieur du bouton
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

        // NOUVEAU : Si la liste est ouverte, appuyer sur Entrée autocomplète au lieu d'envoyer
        if (this.m_FilteredItems.length > 0) {
            this.autocompleteSelection();
            return; // On arrête ici ! La commande n'est pas envoyée.
        }

        // Si la liste est vide (l'autocomplétion est déjà faite), on envoie la commande
        const finalValue = input.text.trim();

        if (finalValue) {
            $.AsyncWebRequest(api.API_BASE + "/command", {
                type: 'POST',
                data: { command: "!hint " + finalValue },
                complete: () => {
                    $.AsyncWebRequest(api.API_BASE + "/hints/refresh", { type: 'POST' });
                }
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
                if (res.status === 200 && res.responseText) {
                    try {
                        const hints = JSON.parse(res.responseText.trim().replace(/\0/g, ''));
                        this.render(hints);
                    } catch (e) { }
                }
                $.Schedule(1.0, () => this.updateLoop());
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
            lbl.text = (hint.found ? "✓ " : "• ") + hint.text;
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