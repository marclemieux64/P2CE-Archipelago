namespace Archipelago {

void PrintMapComplete() {
        if (g_has_printed_map_complete) return;
        if (transition_script_count > 0) {
            transition_script_count--;
            return;
        }
        PrintMapCompleteNoExit();
        WaitExecute("WarpToMenu", 2.0f, "return_to_menu");
    }

} // namespace Archipelago
