'use strict';

function registerSelfCleaningEvent(eventName: string, callback: (...args: any[]) => void) {
    const contextPanel = $.GetContextPanel();
    let _handle: number = -1;
    const wrapper = (...args: any[]) => {
        if (!contextPanel || !contextPanel.IsValid()) {
            $.UnregisterForUnhandledEvent(eventName, _handle);
            return;
        }
        callback(...args);
    };
    _handle = $.RegisterForUnhandledEvent(eventName, wrapper);
}

/**
 * Archipelago Trap Manager
 * Handles persistence of active traps across map transitions.
 */
class ArchipelagoTrapManager {
    static m_Debug: boolean = false;
    static m_StorageKey: string = "ArchipelagoActiveTraps";

    static init() {
        if (this.m_Debug) $.Msg("[AP] TrapManager: Initializing...");

        // Register for trap trigger events from AngelScript
        registerSelfCleaningEvent("ArchipelagoTrapTriggered", (trapName: string, duration: number) => {
            if (typeof trapName === 'string' && trapName.indexOf('|') !== -1) {
                const parts = trapName.split('|');
                trapName = parts[0];
                duration = parseFloat(parts[1]);
            }
            this.saveTrap(trapName, duration);
        });

        // Run persistence check on map load
        this.checkPendingTraps();
    }

    /**
     * Saves a trap to persistent storage with an expiration timestamp.
     */
    static saveTrap(trapName: string, duration: number) {
        if (this.m_Debug) $.Msg(`[AP] TrapManager: Saving trap ${trapName} for ${duration}s`);
        
        let traps = this.getSavedTraps();
        const expiration = Date.now() + (duration * 1000);
        
        // Add or update trap
        traps[trapName] = {
            expiration: expiration,
            originalDuration: duration
        };

        $.persistentStorage.setItem(this.m_StorageKey, JSON.stringify(traps));
    }

    /**
     * Checks for active traps in storage and re-triggers them if still valid.
     */
    static checkPendingTraps() {
        const traps = this.getSavedTraps();
        const now = Date.now();
        let changed = false;

        for (const trapName in traps) {
            const data = traps[trapName];
            const remaining = (data.expiration - now) / 1000;

            if (remaining > 0.5) { // Small buffer
                if (this.m_Debug) $.Msg(`[AP] TrapManager: Re-triggering active trap ${trapName} with ${remaining.toFixed(1)}s remaining.`);
                
                // Trigger the trap command with remaining time
                const cmd = `${trapName}Trap ${remaining.toFixed(1)}`;
                GameInterfaceAPI.ConsoleCommand(cmd);
            } else {
                if (this.m_Debug) $.Msg(`[AP] TrapManager: Trap ${trapName} has expired.`);
                delete traps[trapName];
                changed = true;
            }
        }

        if (changed) {
            $.persistentStorage.setItem(this.m_StorageKey, JSON.stringify(traps));
        }

        // Schedule a cleanup sweep in 5 seconds to remove expired traps from storage
        const ctx = $.GetContextPanel();
        $.Schedule(5.0, () => {
            if (!ctx || !ctx.IsValid()) return;
            this.cleanupExpired();
        });
    }

    /**
     * Removes expired traps from persistent storage.
     */
    static cleanupExpired() {
        const traps = this.getSavedTraps();
        const now = Date.now();
        let changed = false;

        for (const trapName in traps) {
            if (traps[trapName].expiration < now) {
                delete traps[trapName];
                changed = true;
            }
        }

        if (changed) {
            $.persistentStorage.setItem(this.m_StorageKey, JSON.stringify(traps));
        }
    }

    static getSavedTraps(): { [key: string]: any } {
        const raw = $.persistentStorage.getItem(this.m_StorageKey);
        if (!raw) return {};
        try {
            return JSON.parse(raw as string);
        } catch (e) {
            return {};
        }
    }

    static getSkippedTrapIds(): number[] {
        const val = $.persistentStorage.getItem("AP_SkippedTrapIds");
        if (!val) return [];
        try {
            const arr = JSON.parse(val as string);
            return Array.isArray(arr) ? arr : [];
        } catch (e) {
            return [];
        }
    }

    static addSkippedTrapId(id: number) {
        const arr = this.getSkippedTrapIds();
        if (arr.indexOf(id) === -1) {
            arr.push(id);
            $.persistentStorage.setItem("AP_SkippedTrapIds", JSON.stringify(arr));
        }
    }

    static removeSkippedTrapId(id: number) {
        const arr = this.getSkippedTrapIds();
        const idx = arr.indexOf(id);
        if (idx !== -1) {
            arr.splice(idx, 1);
            $.persistentStorage.setItem("AP_SkippedTrapIds", JSON.stringify(arr));
        }
    }

    static isSkippedTrap(id: number): boolean {
        return this.getSkippedTrapIds().indexOf(id) !== -1;
    }
}

// Global exposure
(UiToolkitAPI.GetGlobalObject() as any).ArchipelagoTrapManager = ArchipelagoTrapManager;
ArchipelagoTrapManager.init();
