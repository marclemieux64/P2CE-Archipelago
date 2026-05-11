'use strict';

/**
 * ARCHIPELAGO SETTINGS MANAGER
 * Gère la persistance des réglages entre les sessions de jeu.
 */

if (!$.Msg) { $.Msg = (UiToolkitAPI.GetGlobalObject() as any).Msg; }

// --- SAUVEGARDE DES RÉGLAGES ---

function SaveCompletionSymbolSetting() {
    const dropdown = $('#CompletionSymbolSetting');
    if (dropdown) {
        const realDropdown = dropdown.FindChildTraverse('DropDown') as any;
        if (realDropdown) {
            const selected = realDropdown.GetSelected();
            if (selected) {
                const val = selected.GetAttributeInt('value', 0);
                $.persistentStorage.setItem('ap_completion_symbol', val);
                $.Msg(`[AP] Completion Symbol saved: ${val === 1 ? "Star" : "Checkmark"}`);
                
                // On notifie immédiatement le Map Select s'il est ouvert
                const mapSelect = (UiToolkitAPI.GetGlobalObject() as any).ArchipelagoMapSelect;
                if (mapSelect) mapSelect.generateList();
            }
        }
    }
}

function SaveMapStatusHUDSetting() {
    const dropdown = $('#ShowMapStatusHUDSetting');
    if (dropdown) {
        const realDropdown = dropdown.FindChildTraverse('DropDown') as any;
        if (realDropdown) {
            const selected = realDropdown.GetSelected();
            if (selected) {
                const val = selected.GetAttributeInt('value', 0);
                $.persistentStorage.setItem('ap_show_map_status_hud', val);
                $.Msg(`[AP] Show Map Status HUD saved: ${val}`);
                
                // Mettre à jour l'état du binder de touches
                UpdateMapStatusHUDKeyBinder();
            }
        }
    }
}

function SaveSmartWarpSetting() {
    const dropdown = $('#TransitionTypeSetting');
    if (dropdown) {
        const realDropdown = dropdown.FindChildTraverse('DropDown') as any;
        if (realDropdown) {
            const selected = realDropdown.GetSelected();
            if (selected) {
                const val = selected.GetAttributeInt('value', -1);
                $.persistentStorage.setItem('ap_smart_warp', val);
                
                // On définit aussi la convar pour que le moteur de jeu puisse la lire (Smart Warp)
                GameInterfaceAPI.SetSettingInt('ap_smart_warp', val);
                $.Msg(`[AP] Smart Warp setting saved: ${val}`);
            }
        }
    }
}

// --- CHARGEMENT ET MISE À JOUR DE L'UI ---

function LoadArchipelagoSettings() {
    // 1. Completion Symbol
    const compVal = $.persistentStorage.getItem('ap_completion_symbol') ?? 0;
    const compDropdown = $('#CompletionSymbolSetting')?.FindChildTraverse('DropDown') as any;
    if (compDropdown) compDropdown.SetSelected(compVal.toString());

    // 2. HUD Visibility
    const hudVal = $.persistentStorage.getItem('ap_show_map_status_hud') ?? 0;
    const hudDropdown = $('#ShowMapStatusHUDSetting')?.FindChildTraverse('DropDown') as any;
    if (hudDropdown) hudDropdown.SetSelected(hudVal.toString());

    // 3. Smart Warp
    const warpVal = $.persistentStorage.getItem('ap_smart_warp') ?? 0;
    const warpDropdown = $('#TransitionTypeSetting')?.FindChildTraverse('DropDown') as any;
    if (warpDropdown) warpDropdown.SetSelected(warpVal.toString());

    UpdateMapStatusHUDKeyBinder();
}

function UpdateMapStatusHUDKeyBinder() {
    const showHUD = $.persistentStorage.getItem('ap_show_map_status_hud') ?? 0;
    const keyBinder = $('#MapStatusKeyBinder');
    if (keyBinder) {
        // Désactive le raccourci manuel si le HUD est réglé sur "Always Show" (valeur 1)
        keyBinder.enabled = (showHUD == 0);
    }
}

// --- EXPOSITION GLOBALE ---
// Permet aux éléments du fichier XML (onactivate/onchange) d'appeler ces fonctions

(UiToolkitAPI.GetGlobalObject() as any).SaveCompletionSymbolSetting = SaveCompletionSymbolSetting;
(UiToolkitAPI.GetGlobalObject() as any).SaveMapStatusHUDSetting = SaveMapStatusHUDSetting;
(UiToolkitAPI.GetGlobalObject() as any).SaveSmartWarpSetting = SaveSmartWarpSetting;
(UiToolkitAPI.GetGlobalObject() as any).LoadArchipelagoSettings = LoadArchipelagoSettings;

// --- INITIALISATION ---

(function () {
    // Se déclenche quand on entre dans l'onglet des réglages
    $.RegisterEventHandler('PropertyTransitionEnd', $.GetContextPanel(), (panel, propertyName) => {
        if (propertyName === 'opacity' && !$.GetContextPanel().IsTransparent()) {
            LoadArchipelagoSettings();
        }
    });

    LoadArchipelagoSettings();
})();