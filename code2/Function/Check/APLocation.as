// =============================================================
// ARCHIPELAGO APLOCATION SUBCLASSES (OOP VERSION)
// =============================================================

namespace Archipelago {

interface APLocation {
    string GetName() const;
    bool IsChecked() const;
    void SetChecked(bool checked);
    void UpdateVisuals();
}

// =============================================================
// MAP COMPLETION LOCATION
// =============================================================

class MapLocation : APLocation {
    private string m_mapName;
    private bool m_isChecked;

    MapLocation(string mapName) {
        m_mapName = mapName.tolower();
        m_isChecked = false;
    }

    string GetName() const override { return m_mapName; }
    bool IsChecked() const override { return m_isChecked; }
    
    void SetChecked(bool checked) override {
        m_isChecked = checked;
        UpdateVisuals();
    }

    void UpdateVisuals() override {
        if (!m_isChecked) return;
        
        string currentMapName = g_Archipelago.GetCurrentMap().tolower();
        if (currentMapName != m_mapName) return;

        CBaseEntity@ holo = null;
        while ((@holo = EntityList().FindByClassname(holo, "prop_dynamic")) !is null) {
            string holoName = holo.GetEntityName();
            bool shouldDisable = false;

            if (holoName.locate("map_check_holo") != uint(-1) || 
                holoName.locate("map_check_trigger_holo") != uint(-1) ||
                holoName.locate("map_check_trigger_elevator_holo") != uint(-1)) {
                shouldDisable = true;
            }
            else if (currentMapName == "sp_a4_finale4" && holoName == "moon_holo") {
                shouldDisable = true;
            }

            if (shouldDisable) {
                CBaseAnimating@ animHolo = cast<CBaseAnimating>(holo);
                if (animHolo !is null) {
                    animHolo.SetSkin(4);
                    ArchipelagoLog("Map check hologram '" + holoName + "' set to Skin 4 (Disabled).");
                }
            }
        }
    }
}

// =============================================================
// SECURITY CAMERA LOCATION
// =============================================================

class CameraLocation : APLocation {
    private string m_name; // Format: "sp_a1_intro3_1" or similar
    private bool m_isChecked;
    private Vector m_position;
    private QAngle m_angles;
    private float m_scale;

    CameraLocation(string name, Vector position, QAngle angles, float scale) {
        m_name = name.tolower();
        m_position = position;
        m_angles = angles;
        m_scale = scale;
        m_isChecked = false;
    }

    string GetName() const override { return m_name; }
    bool IsChecked() const override { return m_isChecked; }
    
    void SetChecked(bool checked) override {
        m_isChecked = checked;
        UpdateVisuals();
    }

    void UpdateVisuals() override {
        string holoName = "camera_check_holo_" + m_name;
        int skin = m_isChecked ? 4 : 0;
        CreateAPHologram(m_position, m_angles, m_scale, null, "", skin, holoName);
    }
}

// =============================================================
// CUSTOM RATMAN DEN BUTTON LOCATION
// =============================================================

class ButtonLocation : APLocation {
    private string m_name; // Scenario name, e.g. "rd1"
    private bool m_isChecked;
    private Vector m_position;
    private QAngle m_angles;
    private float m_holoScale;
    private int m_skin;

    ButtonLocation(string name, Vector position, QAngle angles, float scale, int skin) {
        m_name = name.tolower();
        m_position = position;
        m_angles = angles;
        m_holoScale = scale;
        m_skin = skin;
        m_isChecked = false;
    }

    string GetName() const override { return m_name; }
    bool IsChecked() const override { return m_isChecked; }
    
    void SetChecked(bool checked) override {
        m_isChecked = checked;
        UpdateVisuals();
    }

    void UpdateVisuals() override {
        int finalSkin = m_isChecked ? 4 : m_skin;
        string holoName = m_name + "_holo";
        
        CBaseEntity@ modelEnt = EntityList().FindByName(null, m_name + "_model");
        if (modelEnt !is null) {
            if (m_isChecked) {
                CBaseAnimating@ animBody = cast<CBaseAnimating>(modelEnt);
                if (animBody !is null) {
                    animBody.SetSequence(animBody.LookupSequence("down"));
                }
                CBaseEntity@ brainEnt = EntityList().FindByName(null, m_name);
                if (brainEnt !is null) {
                    brainEnt.KeyValue("m_bLocked", 1);
                    brainEnt.KeyValue("spawnflags", "3073");
                }
            }
            
            CBaseEntity@ holo = null;
            while ((@holo = EntityList().FindByClassname(holo, "prop_dynamic")) !is null) {
                if (holo.GetMoveParent() is modelEnt && holo.GetEntityName() == holoName) {
                    CBaseAnimating@ animHolo = cast<CBaseAnimating>(holo);
                    if (animHolo !is null) {
                        animHolo.SetSkin(finalSkin);
                    }
                    break;
                }
            }
        }
    }
}

// =============================================================
// VITRIFIED DOOR BUTTON LOCATION
// =============================================================

class VitrifiedDoorLocation : APLocation {
    private string m_name; // e.g. "Vitrified Door 1"
    private string m_entName; // e.g. "dummy_chamber_button"
    private bool m_isChecked;

    VitrifiedDoorLocation(string name, string entName) {
        m_name = name;
        m_entName = entName.tolower();
        m_isChecked = false;
    }

    string GetName() const override { return m_name; }
    bool IsChecked() const override { return m_isChecked; }
    
    void SetChecked(bool checked) override {
        m_isChecked = checked;
        UpdateVisuals();
    }

    void UpdateVisuals() override {
        if (!m_isChecked) return;

        CBaseEntity@ holo = null;
        while ((@holo = EntityList().FindByClassname(holo, "prop_dynamic")) !is null) {
            string holoName = holo.GetEntityName().tolower();
            string targetHoloName = m_entName + "_holo";
            uint locIdx = holoName.locate(targetHoloName);
            if (holoName == targetHoloName || (locIdx != uint(-1) && (locIdx + targetHoloName.length() == holoName.length()))) {
                CBaseAnimating@ animHolo = cast<CBaseAnimating>(holo);
                if (animHolo !is null) {
                    animHolo.SetSkin(4);
                }
            }
        }
    }
}

// =============================================================
// WHEATLEY MONITOR LOCATION
// =============================================================

class MonitorLocation : APLocation {
    private string m_name; // e.g. "sp_a4_tb_catch 1"
    private string m_relayName; // e.g. "monitor1-relay_break"
    private bool m_isChecked;

    MonitorLocation(string name, string relayName) {
        m_name = name;
        m_relayName = relayName.tolower();
        m_isChecked = false;
    }

    string GetName() const override { return m_name; }
    bool IsChecked() const override { return m_isChecked; }
    
    void SetChecked(bool checked) override {
        m_isChecked = checked;
        UpdateVisuals();
    }

    void UpdateVisuals() override {
        if (!m_isChecked) return;

        CBaseEntity@ holo = null;
        while ((@holo = EntityList().FindByClassname(holo, "prop_dynamic")) !is null) {
            string holoName = holo.GetEntityName().tolower();
            string targetHoloName = m_relayName + "_holo";
            if (holoName == targetHoloName) {
                CBaseAnimating@ animHolo = cast<CBaseAnimating>(holo);
                if (animHolo !is null) {
                    animHolo.SetSkin(4);
                }
            }
        }
    }
}

} // namespace Archipelago
