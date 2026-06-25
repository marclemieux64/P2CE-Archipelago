'use strict';
declare var $: any;
declare var UiToolkitAPI: any;

function isSettingEnabled(key: string, defaultOn: boolean): boolean {
    const val = $.persistentStorage.getItem(key);
    if (val === null || val === undefined) return defaultOn;
    return val === 1 || val === "1";
}

class ArchipelagoPrompt {
    // Smart warp state
    static m_WarpPending: boolean = false;
    static m_SmartWarpSchedule: any = null;
    static m_HadDoableChecksThisMap: boolean = false;
    // Count of "uncheck" symbols when the player entered the current map.
    // Checks that are locked at map entry will never become completable mid-session
    // because their entities get deleted when other checks are completed.
    // -1 = not yet captured for this map.
    static m_EntryUncheckCount: number = -1;

    // Release prompt state
    static m_ReleaseShown: boolean = false;
    static m_ReleasePopupOpen: boolean = false;

    static init() {
        const ctx = $.GetContextPanel();
        if (!ctx || !ctx.IsValid()) return;

        // Register as the current instance. Old HUD reloads' polling loops check this
        // and stop themselves when they see a newer instance has taken over.
        const globalObj = UiToolkitAPI.GetGlobalObject() as any;
        globalObj.ArchipelagoPromptInstance = ArchipelagoPrompt;

        let _mapChangeHandle: number = -1;
        const mapChangeHandler = (payload: string) => {
            if (!ctx || !ctx.IsValid()) {
                $.UnregisterForUnhandledEvent("ArchipelagoMapNameUpdated", _mapChangeHandle);
                return;
            }
            if ((UiToolkitAPI.GetGlobalObject() as any).ArchipelagoPromptInstance !== ArchipelagoPrompt) return;
            ArchipelagoPrompt.onMapChanged(payload.split('|')[0]);
        };
        _mapChangeHandle = $.RegisterForUnhandledEvent("ArchipelagoMapNameUpdated", mapChangeHandler);

        ArchipelagoPrompt.startPolling();
    }

    static startPolling() {
        const ctx = $.GetContextPanel();
        $.Schedule(1.0, () => {
            if (!ctx || !ctx.IsValid()) return;

            // Stop if a newer HUD reload has taken over
            if ((UiToolkitAPI.GetGlobalObject() as any).ArchipelagoPromptInstance !== ArchipelagoPrompt) return;

            if (!ArchipelagoPrompt.m_ReleaseShown && !ArchipelagoPrompt.m_ReleasePopupOpen) {
                if (isSettingEnabled('cv_ReleasePrompt', true)) {
                    const api = (UiToolkitAPI.GetGlobalObject() as any).ArchipelagoAPI;
                    const status = api ? api.getStatus() : null;
                    if (status && status.release_prompt) {
                        ArchipelagoPrompt.m_ReleaseShown = true;
                        ArchipelagoPrompt.showReleasePrompt();
                    }
                }
            }

            if (isSettingEnabled('cv_AutoSmartWarp', true)) {
                ArchipelagoPrompt.evaluateSmartWarp();
            }

            ArchipelagoPrompt.startPolling();
        });
    }

    static onMapChanged(_mapName: string) {
        if (this.m_SmartWarpSchedule) {
            $.CancelScheduled(this.m_SmartWarpSchedule);
            this.m_SmartWarpSchedule = null;
        }
        this.m_WarpPending = false;
        this.m_HadDoableChecksThisMap = false;
        this.m_EntryUncheckCount = -1;
        // Release the global warp lock so the new map can trigger if needed
        (UiToolkitAPI.GetGlobalObject() as any).AP_WarpLock = false;
    }

    static evaluateSmartWarp() {
        if (this.m_WarpPending) return;

        // On first call with valid symbol data, snapshot how many checks were locked
        // at map entry. Checks locked at entry stay inaccessible for the entire session
        // because their entities get deleted when other checks are completed.
        if (this.m_EntryUncheckCount === -1 && this.hasValidSymbolData()) {
            const sync = (UiToolkitAPI.GetGlobalObject() as any).ArchipelagoSync;
            if (sync && sync.m_LastSymbols) {
                const initialList = sync.m_LastSymbols.split(',').filter((s: string) => s !== "");
                this.m_EntryUncheckCount = initialList.filter((s: string) => s === "uncheck").length;
            }
        }

        const conditionMet = this.isSmartWarpConditionMet();

        if (!conditionMet && this.hasValidSymbolData()) {
            this.m_HadDoableChecksThisMap = true;
        }

        if (conditionMet && this.m_HadDoableChecksThisMap && !this.m_SmartWarpSchedule) {
            const ctx = $.GetContextPanel();
            this.m_SmartWarpSchedule = $.Schedule(4.0, () => {
                this.m_SmartWarpSchedule = null;
                if (!ctx || !ctx.IsValid()) return;
                if ((UiToolkitAPI.GetGlobalObject() as any).ArchipelagoPromptInstance !== ArchipelagoPrompt) return;
                if (this.m_WarpPending) return;
                if (!this.m_HadDoableChecksThisMap) return;
                if (!isSettingEnabled('cv_AutoSmartWarp', true)) return;
                if (this.isSmartWarpConditionMet()) {
                    this.triggerSmartWarp();
                }
            });
        } else if (!conditionMet && this.m_SmartWarpSchedule) {
            $.CancelScheduled(this.m_SmartWarpSchedule);
            this.m_SmartWarpSchedule = null;
        }
    }

    // Returns true when no originally-accessible checks remain AND at least one
    // permanently-blocked check exists. Accounts for checks that were "uncheck" at
    // map entry and became accessible mid-session due to item drops: those checks are
    // inaccessible because their entities were already deleted by earlier completions.
    static isSmartWarpConditionMet(): boolean {
        const sync = (UiToolkitAPI.GetGlobalObject() as any).ArchipelagoSync;
        if (!sync) return false;

        const currentMap = sync.m_CurrentMap;
        if (!currentMap || currentMap === "" || currentMap === "main_menu") return false;

        const symbols = sync.m_LastSymbols;
        if (!symbols || symbols === "" || symbols === "INITIAL_SYNC_PENDING" || symbols === "MAP_CHANGE_DETECTED") return false;

        const list = symbols.split(',').filter((s: string) => s !== "");
        if (list.length === 0) return false;

        const currentUncheck = list.filter((s: string) => s === "uncheck").length;
        const currentAccessible = list.filter((s: string) => s !== "uncheck" && s !== "check").length;

        // How many "uncheck" slots converted to accessible mid-session (item received from
        // completing another check). Those are permanently blocked this session.
        const entryUncheck = this.m_EntryUncheckCount >= 0 ? this.m_EntryUncheckCount : currentUncheck;
        const convertedToAccessible = Math.max(0, entryUncheck - currentUncheck);
        const trulyAccessibleRemaining = currentAccessible - convertedToAccessible;

        const hasBlockedChecks = entryUncheck > 0 || currentUncheck > 0;
        return trulyAccessibleRemaining <= 0 && hasBlockedChecks;
    }

    static hasValidSymbolData(): boolean {
        const sync = (UiToolkitAPI.GetGlobalObject() as any).ArchipelagoSync;
        if (!sync) return false;
        const currentMap = sync.m_CurrentMap;
        if (!currentMap || currentMap === "" || currentMap === "main_menu") return false;
        const symbols = sync.m_LastSymbols;
        if (!symbols || symbols === "" || symbols === "INITIAL_SYNC_PENDING" || symbols === "MAP_CHANGE_DETECTED") return false;
        return true;
    }

    static triggerSmartWarp() {
        const globalObj0 = UiToolkitAPI.GetGlobalObject() as any;
        if (globalObj0.AP_WarpLock) return;
        globalObj0.AP_WarpLock = true;
        this.m_WarpPending = true;

        const loc = (key: string, fallback: string) => {
            const v = $.Localize(key);
            return (!v || v === key || v === key.substring(1)) ? fallback : v;
        };

        const title   = loc("#Archipelago_Prompt_SmartWarp_Title", "No Accessible Checks");
        const message = loc("#Archipelago_Prompt_SmartWarp", "No accessible checks remain on this map. Warping to next available map...");
        const notifyFn = (UiToolkitAPI.GetGlobalObject() as any).OnArchipelagoNotify;
        if (notifyFn) notifyFn(JSON.stringify({ title, message, play_sound: true }));

        const ctx = $.GetContextPanel();
        $.Schedule(2.0, () => {
            if (!ctx || !ctx.IsValid()) return;
            const globalObj = UiToolkitAPI.GetGlobalObject() as any;
            const sync = globalObj.ArchipelagoSync;
            const transition = globalObj.ArchipelagoTransition;
            if (sync && transition && sync.m_CurrentMap) {
                transition.requestWarp(sync.m_CurrentMap);
            }
        });
    }

    static showReleasePrompt() {
        if (this.m_ReleasePopupOpen) return;
        this.m_ReleasePopupOpen = true;

        const loc = (key: string, fallback: string) => {
            const v = $.Localize(key);
            return (!v || v === key || v === key.substring(1)) ? fallback : v;
        };

        const title   = loc("#Archipelago_Prompt_Release_Title", "Goal Complete");
        const message = loc("#Archipelago_Prompt_Release", "Goal complete! Release remaining items to other players?");
        const opt1    = loc("#Archipelago_Prompt_Release_Yes", "Release");
        const opt2    = loc("#Archipelago_Prompt_Release_No", "Later");

        UiToolkitAPI.ShowGenericPopupTwoOptionsBgStyle(
            title, message, "",
            opt1, () => {
                ArchipelagoPrompt.m_ReleasePopupOpen = false;
                const api = (UiToolkitAPI.GetGlobalObject() as any).ArchipelagoAPI;
                if (api) api.sendCommand("!release");
            },
            opt2, () => {
                ArchipelagoPrompt.m_ReleasePopupOpen = false;
            },
            "blur"
        );
    }
}

ArchipelagoPrompt.init();
