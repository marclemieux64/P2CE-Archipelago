// =============================================================
// ARCHIPELAGO MANAGER COORDINATOR (OOP VERSION)
// =============================================================

namespace Archipelago {

class ArchipelagoManager {
    // --- MAIN STATE VARIABLES ---
    private string m_currentMap;
    private int m_transitionScriptCount;
    private bool m_hasPrintedMapComplete;
    private bool m_sentDeathLink;
    private bool m_isProcessingRemoteDeath;
    private bool m_portalgun2Disabled;

    // --- SUBSYSTEM MANAGERS (HANDLES) ---
    private CheckManager@ m_checkManager;
    private TrapManager@ m_trapManager;
    private HologramManager@ m_hologramManager;
    private EntityManager@ m_entityManager;
    private WorkflowManager@ m_workflowManager;

    ArchipelagoManager() {
        m_currentMap = "unknown";
        m_transitionScriptCount = 0;
        m_hasPrintedMapComplete = false;
        m_sentDeathLink = false;
        m_isProcessingRemoteDeath = false;
        m_portalgun2Disabled = false;
    }

    /**
     * Instantiates all managers and boots the integration.
     */
    void Initialize() {
        @m_checkManager = CheckManager();
        @m_trapManager = TrapManager();
        @m_hologramManager = HologramManager();
        @m_entityManager = EntityManager();
        @m_workflowManager = WorkflowManager();

        m_checkManager.Initialize();
        m_trapManager.Initialize();
        m_hologramManager.Initialize();
        m_entityManager.Initialize();
        m_workflowManager.Initialize();
    }

    // --- SUBSYSTEM GETTERS ---
    CheckManager@ GetCheckManager() { return m_checkManager; }
    TrapManager@ GetTrapManager() { return m_trapManager; }
    HologramManager@ GetHologramManager() { return m_hologramManager; }
    EntityManager@ GetEntityManager() { return m_entityManager; }
    WorkflowManager@ GetWorkflowManager() { return m_workflowManager; }

    // --- STATE GETTERS & SETTERS ---
    string GetCurrentMap() const { return m_currentMap; }
    void SetCurrentMap(const string& in mapName) { m_currentMap = mapName; }

    int GetTransitionScriptCount() const { return m_transitionScriptCount; }
    void SetTransitionScriptCount(int val) { m_transitionScriptCount = val; }

    bool HasPrintedMapComplete() const { return m_hasPrintedMapComplete; }
    void SetHasPrintedMapComplete(bool val) { m_hasPrintedMapComplete = val; }

    bool HasSentDeathLink() const { return m_sentDeathLink; }
    void SetSentDeathLink(bool val) { m_sentDeathLink = val; }

    bool IsProcessingRemoteDeath() const { return m_isProcessingRemoteDeath; }
    void SetIsProcessingRemoteDeath(bool val) { m_isProcessingRemoteDeath = val; }

    bool IsPortalGun2Disabled() const { return m_portalgun2Disabled; }
    void SetPortalGun2Disabled(bool val) { m_portalgun2Disabled = val; }

    // --- SHARED COORDINATION PIPELINES ---

    void UpdateInternalMapName() {
        if (host_map.IsValid()) {
            string detected = host_map.GetString();
            if (detected != "" && detected != "nomap" && detected != "unknown") {
                if (m_currentMap != detected) {
                    m_currentMap = detected; 
                    ArchipelagoLog("map_name:" + m_currentMap);
                    CallVScript("SendToPanorama(\"ArchipelagoMapNameUpdated\", \"" + m_currentMap + "|0\")");
                }
            }
        }
    }

    void ResetPersistentSystems() {
        CBaseEntity@ cmd = EntityList().FindByName(null, "InitCmd");
        if (cmd !is null) {
            Variant v;

            // Reset Visuals (Motion Blur Trap)
            v.SetString("sv_friction 4");
            cmd.FireInput("Command", v, 30.0f, null, null, 0);
            
            v.SetString("ent_fire !player AddOutput \"friction 1\"");
            cmd.FireInput("Command", v, 0.1f, null, null, 0);

            // Reset motion blur intensity back to 0.0
            CBaseEntity@ lpp = EntityList().FindByClassname(null, "logic_playerproxy");
            if (lpp is null) {
                @lpp = util::CreateEntityByName("logic_playerproxy");
                if (lpp !is null) lpp.Spawn();
            }
            if (lpp !is null) {
                Variant vBlur;
                vBlur.SetFloat(0.0f);
                lpp.FireInput("SetMotionBlurAmount", vBlur, 0.0f, null, null);
            }

            // Reset Console Log modes
            v.SetString("con_log_channel_mode 0");
            cmd.FireInput("Command", v, 0.1f, null, null, 0);
            
            v.SetString("con_log_severity_mode 0");
            cmd.FireInput("Command", v, 0.1f, null, null, 0);

            // Reset Sound Mixers (PotatOS Silence restoration)
            v.SetString("snd_setmixer potatosVO vol 0.4");
            cmd.FireInput("Command", v, 0.0f, null, null, 0);
            v.SetString("snd_setmixer gladosVO vol 0.7");
            cmd.FireInput("Command", v, 0.0f, null, null, 0);

            CallVScript("MutePotatOSSubtitles(false)");

            // Reset BTS4 Conveyor Holo ConVars (only if we transitioned away from sp_a2_bts4)
            if (m_currentMap != "sp_a2_bts4") {
                v.SetString("ap_bts4_initial_holo_active 0");
                cmd.FireInput("Command", v, 0.0f, null, null, 0);
                v.SetString("ap_bts4_conveyor1_holo_active 0");
                cmd.FireInput("Command", v, 0.0f, null, null, 0);
            }
            
            ArchipelagoLog("Persistent systems have been sanitized for the new session.");
        }
    }

    void CallVScript(string code) {
        Archipelago::CallVScript(code);
    }

    void SafeAddOutput(CBaseEntity@ ent, string output, string target, string input, string param = "", float delay = 0.0f, int maxTimes = -1) {
        Archipelago::SafeAddOutput(ent, output, target, input, param, delay, maxTimes);
    }
}

// Instantiate the global singleton coordinator
ArchipelagoManager g_Archipelago;

} // namespace Archipelago
