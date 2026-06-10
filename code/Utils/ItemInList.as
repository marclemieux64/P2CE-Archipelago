namespace Archipelago {

bool ItemInList(string item, array<string> list) {
        for (uint i = 0; i < list.length(); i++) {
            if (list[i] == item) return true;
        }
        return false;
    }

} // namespace Archipelago
