'use strict';

class ArchipelagoMapStatusHUD {
    static m_HideSchedule: any = null;
    static m_Debug: boolean = false;
    static m_CurrentMapName: string = "";
    
    // NOUVEAU : Mémoire si le HUD est en attente des données de l'API pour s'afficher
    static m_PendingShow: boolean = false;

    static init() {
        if (this.m_Debug) $.Msg("[AP] MapStatusHUD initialized.");

        $.RegisterForUnhandledEvent("ArchipelagoDebug", (state: string) => {
            this.m_Debug = (state === "1");
        });

        $.RegisterForUnhandledEvent("ArchipelagoMapNameUpdated", (payload: string) => {
            const parts = payload.split('|');
            const mapName = parts[0];
            const isManual = parts[1] === "1";

            this.m_CurrentMapName = mapName;

            if (this.m_HideSchedule) {
                $.CancelScheduled(this.m_HideSchedule);
                this.m_HideSchedule = null;
            }

            if (isManual) {
                this.updateStatus(mapName, true, true);
            } else {
                // Demande d'affichage. Si l'API n'est pas prête, m_PendingShow deviendra true
                $.Schedule(0.5, () => this.updateStatus(this.m_CurrentMapName, false, true));
            }
        });

        $.RegisterForUnhandledEvent("ArchipelagoAPI_StatusUpdated", (json: string) => {
            if (this.m_CurrentMapName) {
                if (this.m_PendingShow) {
                    // L'API vient de répondre et le HUD attendait ça pour apparaître !
                    this.updateStatus(this.m_CurrentMapName, false, true);
                } else {
                    // Mise à jour silencieuse classique
                    this.updateStatus(this.m_CurrentMapName, false, false);
                }
            }
        });
    }

    static updateStatus(currentMapName: string, isManual: boolean, forceShow: boolean) {
        // Lecture sécurisée du paramètre (Vérifie String et Number)
        const psValue = $.persistentStorage.getItem('ap_show_map_status_hud');
        const enabled = (psValue === null || psValue === undefined || psValue == 1 || psValue === "1");

        if (!enabled && !isManual) return;

        const container = $.GetContextPanel();
        if (!container || !currentMapName || currentMapName === "main_menu" || currentMapName === "unknown") return;

        const api = (UiToolkitAPI.GetGlobalObject() as any).ArchipelagoAPI;
        const apiStatus = api ? api.getStatus() : null;
        
        // CORRECTION : Si l'API n'est pas prête, on se met en attente
        if (!apiStatus || !apiStatus.menu) {
            if (forceShow) this.m_PendingShow = true;
            return;
        }

        const syncHelper = (UiToolkitAPI.GetGlobalObject() as any).ArchipelagoSync;
        if (!syncHelper) {
            if (forceShow) this.m_PendingShow = true;
            return;
        }

        const chapters = syncHelper.parseApiStatus(apiStatus);
        let currentMapData: any = null;
        for (const chId in chapters) {
            for (const map of chapters[chId].maps) {
                if (map.command) {
                    const cmdLower = map.command.toLowerCase();
                    const mapLower = currentMapName.toLowerCase();
                    if (cmdLower.indexOf(mapLower) !== -1) {
                        currentMapData = map;
                        break;
                    }
                }
            }
            if (currentMapData) break;
        }

        if (!currentMapData) {
            this.m_PendingShow = false; // Ce n'est pas une map Archipelago, on annule l'attente
            return;
        }

        // On a les données, on décoche l'attente !
        this.m_PendingShow = false;

        // Si on ne force pas l'affichage et que le HUD est caché, on stoppe ici pour sauver les perfs
        if (!forceShow && !container.HasClass('visible')) {
            return;
        }

        const titleLabel = $('#MapTitle') as LabelPanel;
        const iconsContainer = $('#StatusIcons');
        const missingContainer = $('#MissingIcons');
        const missingLabel = $('#MissingLabel');

        const mapToken = `#portal2_MapName_${currentMapName}`;
        const localizedMapName = $.Localize(mapToken);
        titleLabel.text = (localizedMapName !== mapToken) ? localizedMapName : currentMapData.id;

        iconsContainer.RemoveAndDeleteChildren();
        missingContainer.RemoveAndDeleteChildren();

        const rawTitle = currentMapData.title || "";
        let statusIcons = (currentMapData.statusIcons || currentMapData.info || "").replace(/[~\-]/g, "").trim();
        if (!statusIcons && rawTitle.length > 4 && (rawTitle.startsWith("~") || rawTitle.startsWith("-") || rawTitle.startsWith("═"))) {
            statusIcons = rawTitle.substring(0, 4).replace(/[~\-]/g, "").trim();
        }
        
        const mItems = currentMapData.subtitle || "";
        const mapCmdName = currentMapName;
        const logicHelper = (UiToolkitAPI.GetGlobalObject() as any).ArchipelagoLogic;

        const formattedIcons = logicHelper ? logicHelper.getFormattedIcons(statusIcons, mapCmdName, mItems) : [];

        for (const iconData of formattedIcons) {
            const icon = $.CreatePanel('Label', iconsContainer, '');
            icon.text = iconData.char;
            icon.AddClass('status-icon');
            
            icon.style.color = iconData.color;

            if (iconData.isCompleted) {
                icon.AddClass('status-icon--completed');
            }
        }

        let redCount = 0;
        const missingItems = logicHelper ? logicHelper.getMissingItemsList(mItems) : [];

        for (const itemData of missingItems) {
            if (syncHelper.isMissingItem(itemData.char)) {
                const icon = $.CreatePanel('Label', missingContainer, '');
                icon.AddClass('status-icon');
                icon.style.color = itemData.color;
                icon.text = itemData.char;
                redCount++;
            }
        }

        missingLabel.SetHasClass('collapse', redCount === 0);
        missingContainer.SetHasClass('collapse', redCount === 0);

        if (forceShow) {
            container.AddClass('visible');
            container.RemoveClass('collapse');

            if (this.m_HideSchedule) {
                $.CancelScheduled(this.m_HideSchedule);
            }
            this.m_HideSchedule = $.Schedule(5.0, () => {
                container.RemoveClass('visible');
                this.m_HideSchedule = null;
            });
        }
    }
}

ArchipelagoMapStatusHUD.init();