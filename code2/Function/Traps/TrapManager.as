// =============================================================
// ARCHIPELAGO TRAP MANAGER
// =============================================================

namespace Archipelago {

class TrapManager {
    private array<ITrap@> m_registeredTraps;

    TrapManager() {
        // Constructor
    }

    void Initialize() {
        // Register all available traps
        m_registeredTraps.insertLast(ButterFingerTrap());
        m_registeredTraps.insertLast(CubeConfettiTrap());
        m_registeredTraps.insertLast(DialogTrap());
        m_registeredTraps.insertLast(FizzlePortalTrap());
        m_registeredTraps.insertLast(MotionBlurTrap());
        m_registeredTraps.insertLast(SlipperyFloorTrap());
    }

    /**
     * Finds and triggers a registered trap by name.
     */
    void TriggerTrap(const string& in trapName, const CommandArgs@ args) {
        for (uint i = 0; i < m_registeredTraps.length(); i++) {
            if (m_registeredTraps[i].GetName() == trapName) {
                m_registeredTraps[i].Trigger(args);
                return;
            }
        }
        ArchipelagoLog("Warning: Trap '" + trapName + "' is not registered in TrapManager.");
    }
}

} // namespace Archipelago
