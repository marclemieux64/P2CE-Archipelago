// =============================================================
// ARCHIPELAGO NOTIFICATION BRIDGE (P2CE Direct Panorama)
// =============================================================
// Purpose: Send notification data directly to the Panorama HUD
// using the native Strata VScript API.
// =============================================================

/**
 * AddToTextQueue - Entry point for Python/Console calls.
 * Example: script AddToTextQueue("Found a Portal Gun!", "success")
 * * @param {string} text  - The message body to display.
 * @param {string} color - The CSS class to apply (success, error, etc.)
 */
function AddToTextQueue(text, color = "success") {
    // Standardizing the JSON payload for the bridge
    local payload = "{\"title\":\"ARCHIPELAGO\", \"message\":\"" + text + "\", \"type\":\"" + color + "\"}";
    SendToPanorama("ArchipelagoNotify", payload);
    printl("[AP] Direct Panorama notification dispatched: " + text);
}
