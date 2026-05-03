'use strict';
if (!$.Msg) { $.Msg = (UiToolkitAPI.GetGlobalObject() as any).Msg; }

function SmartWarpNextMap(currentMapName: string) {
    $.Msg("[AP] Smart Warp triggered for map: " + currentMapName + ". Searching for best next map...");
    
    // Ensure we have a string even if something went wrong
    if (!currentMapName) currentMapName = "";

    const extrasKv = $.LoadKeyValuesFile("scripts/extras.txt") || $.LoadKeyValues3File("scripts/extras.txt");
    const data = extrasKv && extrasKv.Extras ? extrasKv.Extras : extrasKv;
    if (!data) {
        $.Msg("[AP] Smart Warp failed: Could not load extras.txt");
        GameInterfaceAPI.ConsoleCommand("disconnect");
        return;
    }

    // 1. Parse data into chapters and maps (similar to map-select.ts)
    const chapters: any = {};
    for (const key in data) {
        const lowerKey = key.toLowerCase();
        if (lowerKey.startsWith('chapter')) {
            const majorId = key.match(/\d+/)?.[0];
            if (majorId) {
                if (!chapters[majorId]) chapters[majorId] = { maps: [] };
                if (key.includes('.')) {
                    chapters[majorId].maps.push({ id: key, ...data[key] });
                } else {
                    Object.assign(chapters[majorId], data[key]);
                }
            }
        }
    }

    const currentMapCmd = "map " + currentMapName;

    const syncHelper = (UiToolkitAPI.GetGlobalObject() as any).ArchipelagoSync;
    const fullyDoableMaps: any[] = [];
    const partiallyDoableMaps: any[] = [];

    for (const chId in chapters) {
        const chapter = chapters[chId];
        if (chapter.maps) {
            for (const map of chapter.maps) {
                if (!map.command) continue;
                
                // CRITICAL: Skip the map we are currently on to avoid infinite loops
                if (map.command.trim() === currentMapCmd.trim()) continue;

                const status = syncHelper ? syncHelper.getMapStatus(map, chapters) : { completed: false, doable: false, fullyDoable: false };
                if (status.completed) continue;

                if (status.fullyDoable) {
                    fullyDoableMaps.push(map);
                } else if (status.doable) {
                    partiallyDoableMaps.push(map);
                }
            }
        }
    }

    $.Msg("[AP] Smart Warp Scan Results: " + fullyDoableMaps.length + " fully doable, " + partiallyDoableMaps.length + " partially doable.");
    if (fullyDoableMaps.length > 0) {
        $.Msg("[AP] Fully doable maps: " + fullyDoableMaps.map(m => m.id).join(", "));
    }
    if (partiallyDoableMaps.length > 0) {
        $.Msg("[AP] Partially doable maps: " + partiallyDoableMaps.map(m => m.id).join(", "));
    }

    let targetMap = null;
    if (fullyDoableMaps.length > 0) {
        const randomIndex = Math.floor(Math.random() * fullyDoableMaps.length);
        $.Msg("[AP] Found " + fullyDoableMaps.length + " fully doable maps. Selecting random candidate at index " + randomIndex);
        targetMap = fullyDoableMaps[randomIndex];
    } else if (partiallyDoableMaps.length > 0) {
        const randomIndex = Math.floor(Math.random() * partiallyDoableMaps.length);
        $.Msg("[AP] No fully doable maps. Found " + partiallyDoableMaps.length + " partially doable maps. Selecting random candidate at index " + randomIndex);
        targetMap = partiallyDoableMaps[randomIndex];
    }

    if (targetMap && targetMap.command) {
        $.Msg("[AP] Smart Warp Success: Sending player to " + targetMap.id + " (" + targetMap.command + ")");
        
        $.Schedule(1.0, () => {
            GameInterfaceAPI.ConsoleCommand(targetMap.command);
        });
    } else {
        $.Msg("[AP] Smart Warp: No doable maps found. Returning to menu.");
        GameInterfaceAPI.ConsoleCommand("disconnect");
    }
}

(UiToolkitAPI.GetGlobalObject() as any).SmartWarpNextMap = SmartWarpNextMap;
