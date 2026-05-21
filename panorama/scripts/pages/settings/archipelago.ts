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

function SavePortalGunSkinSetting() {
    const dropdown = $('#PortalGunSkinSetting');
    if (dropdown) {
        const realDropdown = dropdown.FindChildTraverse('DropDown') as any;
        if (realDropdown) {
            const selected = realDropdown.GetSelected();
            if (selected) {
                const val = selected.GetAttributeInt('value', 0);
                $.persistentStorage.setItem('ap_portalgun_skin', val);
                
                // Appel de la commande AngelScript pour mettre à jour le skin de l'arme
                GameInterfaceAPI.ConsoleCommand('AP_UpdateGunSkin ' + val);
                $.Msg(`[AP] Portal Gun Skin saved and applied: ${val}`);
            }
        }
    }
}

function SaveHideHologramsSetting() {
    const dropdown = $('#HideHologramsSetting');
    if (dropdown) {
        const realDropdown = dropdown.FindChildTraverse('DropDown') as any;
        if (realDropdown) {
            const selected = realDropdown.GetSelected();
            if (selected) {
                const val = selected.GetAttributeInt('value', 0);
                $.persistentStorage.setItem('ap_hide_holograms', val);
                
                // Mettre à jour la convar pour le moteur
                GameInterfaceAPI.SetSettingInt('ap_hide_holograms', val);
                
                // Déclencher la mise à jour visuelle immédiate en jeu
                GameInterfaceAPI.ConsoleCommand('AP_UpdateHologramsVisibility');
                $.Msg(`[AP] Hide Holograms setting saved: ${val}`);
            }
        }
    }
}

function SaveStatusIndicatorModeSetting() {
    const dropdown = $('#StatusIndicatorModeSetting');
    if (dropdown) {
        const realDropdown = dropdown.FindChildTraverse('DropDown') as any;
        if (realDropdown) {
            const selected = realDropdown.GetSelected();
            if (selected) {
                const val = selected.GetAttributeInt('value', 0);
                $.persistentStorage.setItem('ap_status_indicator_mode', val);
                
                // Rafraîchir immédiatement l'indicateur sur le HUD
                const statusIndicator = (UiToolkitAPI.GetGlobalObject() as any).ArchipelagoStatusIndicator;
                if (statusIndicator) {
                    statusIndicator.refreshVisibility();
                }
                $.Msg(`[AP] Status Indicator Mode saved: ${val}`);
            }
        }
    }
}

function LoadArchipelagoSettings() {
    // 1. Completion Symbol
    const compVal = $.persistentStorage.getItem('ap_completion_symbol') ?? 0;
    const compDropdown = $('#CompletionSymbolSetting')?.FindChildTraverse('DropDown') as any;
    if (compDropdown) compDropdown.SetSelected('ap_symbol_' + compVal);

    // 2. HUD Visibility
    const hudVal = $.persistentStorage.getItem('ap_show_map_status_hud') ?? 0;

    // 3. Smart Warp
    const warpVal = $.persistentStorage.getItem('ap_smart_warp') ?? 0;
    const warpDropdown = $('#TransitionTypeSetting')?.FindChildTraverse('DropDown') as any;
    if (warpDropdown) warpDropdown.SetSelected(warpVal === 1 ? 'ap_transition_smart' : 'ap_transition_menu');

    // 4. Portal Gun Skin
    const skinVal = $.persistentStorage.getItem('ap_portalgun_skin') ?? 0;
    const skinDropdown = $('#PortalGunSkinSetting')?.FindChildTraverse('DropDown') as any;
    if (skinDropdown) skinDropdown.SetSelected('ap_skin_' + skinVal);
    
    // Applique le skin au moteur de jeu immédiatement au chargement
    GameInterfaceAPI.ConsoleCommand('AP_UpdateGunSkin ' + skinVal)

    // 5. Hide Holograms
    const hideHoloVal = $.persistentStorage.getItem('ap_hide_holograms') ?? 0;
    const hideHoloDropdown = $('#HideHologramsSetting')?.FindChildTraverse('DropDown') as any;
    if (hideHoloDropdown) hideHoloDropdown.SetSelected('ap_hide_holograms_' + hideHoloVal);
    
    // Synchroniser la convar et rafraîchir la visibilité au chargement
    GameInterfaceAPI.SetSettingInt('ap_hide_holograms', hideHoloVal);
    GameInterfaceAPI.ConsoleCommand('AP_UpdateHologramsVisibility');

    // 6. Status Indicator Mode
    const statusIndVal = $.persistentStorage.getItem('ap_status_indicator_mode') ?? 0;
    const statusIndDropdown = $('#StatusIndicatorModeSetting')?.FindChildTraverse('DropDown') as any;
    if (statusIndDropdown) statusIndDropdown.SetSelected('ap_status_indicator_mode_' + statusIndVal);

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

// --- EXPOSITION GLOBALE HARMONISÉE ---
// Permet aux éléments externes et aux enums de settings.ts d'appeler ces fonctions sans planter
(UiToolkitAPI.GetGlobalObject() as any).SaveCompletionSymbolSetting = SaveCompletionSymbolSetting;
(UiToolkitAPI.GetGlobalObject() as any).SaveMapStatusHUDSetting = SaveMapStatusHUDSetting;
(UiToolkitAPI.GetGlobalObject() as any).SaveSmartWarpSetting = SaveSmartWarpSetting;
(UiToolkitAPI.GetGlobalObject() as any).SavePortalGunSkinSetting = SavePortalGunSkinSetting;
(UiToolkitAPI.GetGlobalObject() as any).SaveHideHologramsSetting = SaveHideHologramsSetting;
(UiToolkitAPI.GetGlobalObject() as any).SaveStatusIndicatorModeSetting = SaveStatusIndicatorModeSetting;
(UiToolkitAPI.GetGlobalObject() as any).LoadArchipelagoSettings = LoadArchipelagoSettings;
(UiToolkitAPI.GetGlobalObject() as any).UpdateMapStatusHUDKeyBinder = UpdateMapStatusHUDKeyBinder; // <-- CORRECTIF ICI

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