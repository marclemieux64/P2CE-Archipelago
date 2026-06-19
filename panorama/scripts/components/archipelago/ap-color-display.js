'use strict';

class ApColorDisplay {
    static display = $('#Display');
    static hexEntry = $('#Hex');
    static titleLabel = $('#Title');
    static convar = '';
    static color = '#FFFFFFFF';
    static alpha = 1.0;

    static init() {
        const ctx = $.GetContextPanel();
        if (!ctx) return;

        // Extraction des attributs passés en XML
        ApColorDisplay.convar = ctx.GetAttributeString('convar', '');
        const text = ctx.GetAttributeString('text', '');
        if (text) ApColorDisplay.titleLabel.text = $.Localize(text);

        // Chargement de la couleur sauvegardée ou définition d'une valeur par défaut
        const savedColor = $.persistentStorage.getItem('ap_color_' + ApColorDisplay.convar);
        const defaultColor = '#FFFFFFFF';
        
        ApColorDisplay.saveColor(savedColor || defaultColor);

        // Gestion de la saisie manuelle de l'utilisateur dans le champ de texte
        if (ApColorDisplay.hexEntry) {
            $.RegisterEventHandler('TextEntryChanged', ApColorDisplay.hexEntry, () => {
                let val = ApColorDisplay.hexEntry.text.trim();
                if (!val.startsWith('#')) val = '#' + val;
                if (val.length === 9) {
                    ApColorDisplay.saveColor(val);
                }
            });
        }

        // Configuration du bouton Aléatoire (Dice)
        const randomBtn = $('#RandomColorBtn');
        if (randomBtn) {
            randomBtn.SetPanelEvent('onactivate', () => {
                const randomHex = '#' + Math.floor(Math.random() * 16777215).toString(16).padStart(6, '0') + 'ff';
                ApColorDisplay.saveColor(randomHex);
            });
        }

        // Configuration du bouton Arc-en-ciel (Rainbow)
        const rainbowBtn = $('#RainbowColorBtn');
        if (rainbowBtn) {
            rainbowBtn.SetPanelEvent('onactivate', () => {
                if (ApColorDisplay.hexEntry) {
                    UiToolkitAPI.GetGlobalObject().ToggleRainbowColor(ApColorDisplay.hexEntry);
                }
            });
        }
    }

    static showPopup() {
        // Ouverture du color-picker officiel avec notre variable de couleur isolée
        const popup = UiToolkitAPI.ShowCustomLayoutPopupParameters(
            '',
            'file://{resources}/layout/modals/popups/color-picker.xml',
            'color=' + ApColorDisplay.color
        );
        $.RegisterEventHandler('ColorPickerSave', popup, ApColorDisplay.saveColor.bind(ApColorDisplay));
    }

    static saveColor(color) {
        if (!color) return;
        if (!color.startsWith('#')) color = '#' + color;
        
        ApColorDisplay.color = color.toUpperCase();
        
        // Calcul et extraction logicielle sécurisée de l'alpha (évite le crash NaN)
        if (ApColorDisplay.color.length >= 9) {
            const alphaHex = ApColorDisplay.color.substring(7, 9);
            ApColorDisplay.alpha = parseInt(alphaHex, 16) / 255;
        } else {
            ApColorDisplay.alpha = 1.0;
        }

        // Synchronisation du champ de texte
        if (ApColorDisplay.hexEntry) {
            const cleanHex = ApColorDisplay.color.replace('#', '');
            if (ApColorDisplay.hexEntry.text.toUpperCase() !== cleanHex) {
                ApColorDisplay.hexEntry.text = cleanHex;
            }
        }

        // Sauvegarde persistante locale
        $.persistentStorage.setItem('ap_color_' + ApColorDisplay.convar, ApColorDisplay.color);

        // Transmission de la valeur à la ConVar du moteur de jeu par commande console
        if (ApColorDisplay.convar) {
            const state = GameInterfaceAPI.GetGameUIState();
            // Sécurité : On vérifie si l'objet de type Enum compilé existe, sinon on utilise la valeur 3 par défaut
            const isPauseMenu = (typeof GameUIState !== 'undefined') ? (state === GameUIState.PAUSEMENU) : (state === 3);
            
            if (isPauseMenu) {
                GameInterfaceAPI.ConsoleCommand(ApColorDisplay.convar + ' ' + ApColorDisplay.color);
            }
        }

        ApColorDisplay.updateDisplayOpacity();
    }

    static updateDisplayOpacity() {
        if (!ApColorDisplay.display) return;
        ApColorDisplay.display.style.backgroundColor = ApColorDisplay.color;
        ApColorDisplay.display.style.backgroundImgOpacity = 1 - ApColorDisplay.alpha;
    }
}

(function() {
    ApColorDisplay.init();
})();