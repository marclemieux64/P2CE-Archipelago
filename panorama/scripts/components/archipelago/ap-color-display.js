'use strict';

class ApColorDisplay {
    static init() {
        const ctx = $.GetContextPanel();
        if (!ctx) return;

        const display = ctx.FindChildTraverse('Display');
        const hexEntry = ctx.FindChildTraverse('Hex');
        const titleLabel = ctx.FindChildTraverse('Title');

        const convar = ctx.GetAttributeString('convar', '');
        const text = ctx.GetAttributeString('text', '');
        if (text && titleLabel) titleLabel.text = $.Localize(text);

        ctx.m_ConVar = convar;
        ctx.m_Display = display;
        ctx.m_HexEntry = hexEntry;

        const savedColor = $.persistentStorage.getItem('ap_color_' + convar);
        const defaultColor = '#FFFFFFFF';
        
        ApColorDisplay.saveColor(savedColor || defaultColor, ctx);

        // Gestion de la saisie manuelle de l'utilisateur dans le champ de texte
        if (hexEntry) {
            $.RegisterEventHandler('TextEntryChanged', hexEntry, () => {
                let val = hexEntry.text.trim();
                if (!val.startsWith('#')) val = '#' + val;
                if (val.length === 9) {
                    ApColorDisplay.saveColor(val, ctx);
                }
            });
        }

        // Configuration du bouton Aléatoire (Dice)
        const randomBtn = ctx.FindChildTraverse('RandomColorBtn');
        if (randomBtn) {
            randomBtn.SetPanelEvent('onactivate', () => {
                const randomHex = '#' + Math.floor(Math.random() * 16777215).toString(16).padStart(6, '0') + 'ff';
                ApColorDisplay.saveColor(randomHex, ctx);
            });
        }

        // Configuration du bouton Arc-en-ciel (Rainbow)
        const rainbowBtn = ctx.FindChildTraverse('RainbowColorBtn');
        if (rainbowBtn) {
            rainbowBtn.SetPanelEvent('onactivate', () => {
                if (hexEntry) {
                    const glob = UiToolkitAPI.GetGlobalObject();
                    if (glob && glob.ToggleRainbowColor) glob.ToggleRainbowColor(hexEntry);
                }
            });
        }
    }

    static showPopup() {
        const ctx = $.GetContextPanel();
        if (!ctx) return;

        const currentColor = ctx.m_Color || '#FFFFFFFF';
        const popup = UiToolkitAPI.ShowCustomLayoutPopupParameters(
            '',
            'file://{resources}/layout/modals/popups/color-picker.xml',
            'color=' + currentColor
        );
        $.RegisterEventHandler('ColorPickerSave', popup, (color) => ApColorDisplay.saveColor(color, ctx));
    }

    static saveColor(color, ctx) {
        if (!ctx) ctx = $.GetContextPanel();
        if (!ctx || !color) return;

        if (!color.startsWith('#')) color = '#' + color;
        const upperColor = color.toUpperCase();
        ctx.m_Color = upperColor;
        
        // Calcul et extraction logicielle sécurisée de l'alpha (évite le crash NaN)
        if (upperColor.length >= 9) {
            const alphaHex = upperColor.substring(7, 9);
            ctx.m_Alpha = parseInt(alphaHex, 16) / 255;
        } else {
            ctx.m_Alpha = 1.0;
        }

        // Synchronisation du champ de texte
        const hexEntry = ctx.m_HexEntry || ctx.FindChildTraverse('Hex');
        if (hexEntry) {
            const cleanHex = upperColor.replace('#', '');
            if (hexEntry.text.toUpperCase() !== cleanHex) {
                hexEntry.text = cleanHex;
            }
        }

        // Sauvegarde persistante locale
        if (ctx.m_ConVar) {
            $.persistentStorage.setItem('ap_color_' + ctx.m_ConVar, upperColor);

            // Transmission de la valeur à la ConVar du moteur de jeu par commande console
            const state = GameInterfaceAPI.GetGameUIState();
            const isPauseMenu = (typeof GameUIState !== 'undefined') ? (state === GameUIState.PAUSEMENU) : (state === 3);
            if (isPauseMenu) {
                GameInterfaceAPI.ConsoleCommand(ctx.m_ConVar + ' ' + upperColor);
            }
        }

        ApColorDisplay.updateDisplayOpacity(ctx);
    }

    static updateDisplayOpacity(ctx) {
        if (!ctx) ctx = $.GetContextPanel();
        if (!ctx) return;
        const display = ctx.m_Display || ctx.FindChildTraverse('Display');
        if (!display) return;
        display.style.backgroundColor = ctx.m_Color || '#FFFFFFFF';
        display.style.backgroundImgOpacity = 1 - (ctx.m_Alpha !== undefined ? ctx.m_Alpha : 1.0);
    }
}
