// =============================================================
// ARCHIPELAGO ITRAP INTERFACE
// =============================================================

namespace Archipelago {

interface ITrap {
    /**
     * Returns the unique identifying name of the trap.
     */
    string GetName() const;

    /**
     * Executes the trap behavior with the given command arguments.
     */
    void Trigger(const CommandArgs@ args);
}

} // namespace Archipelago
