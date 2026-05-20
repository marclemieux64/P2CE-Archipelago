namespace Archipelago {

/**
 * TranslateButtonName - Maps user-friendly names to internal IDs for AP buttons.
 */
    string TranslateButtonName(string originalName) {
        string clean = originalName.trim();
        if (clean == "Ratman Den 1") return "rd1";
        if (clean == "Ratman Den 2") return "rd2";
        if (clean == "Ratman Den 3") return "rd3";
        if (clean == "Ratman Den 4") return "rd4";
        if (clean == "Ratman Den 5") return "rd5";
        if (clean == "Ratman Den 6") return "rd6";
        if (clean == "Ratman Den 7") return "rd7";
        return (clean.length() > 0) ? clean : "ap_btn"; 
    }

/**
 * RunButtonScenarioCheck - Formats and prints button verification status for server.
 */
    void RunButtonScenarioCheck(string buttonName) {
        buttonName = buttonName.trim();
        if (buttonName == "rd1") ArchipelagoLog("button_check:Ratman Den 1"); else if (buttonName == "rd2") ArchipelagoLog("button_check:Ratman Den 2"); else if (buttonName == "rd3") ArchipelagoLog("button_check:Ratman Den 3"); else if (buttonName == "rd4") ArchipelagoLog("button_check:Ratman Den 4"); else if (buttonName == "rd5") ArchipelagoLog("button_check:Ratman Den 5"); else if (buttonName == "rd6") ArchipelagoLog("button_check:Ratman Den 6"); else if (buttonName == "rd7") ArchipelagoLog("button_check:Ratman Den 7"); else ArchipelagoLog("button_check:unknown_" + buttonName);
    }

} // namespace Archipelago
