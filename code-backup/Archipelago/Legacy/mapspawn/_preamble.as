// =============================================================
// ARCHIPELAGO LEGACY MAPSPAWN (Converted from Squirrel)
// =============================================================

namespace Legacy {

// Helper: Check if item is in array
    bool ItemInList(string item, array<string> list) {
        for (uint i = 0; i < list.length(); i++) {
            if (list[i] == item) return true;
        }
        return false;
    }

    float DegToRad(float degrees) {
        return degrees * (3.14159f / 180.0f);
    }

    Vector AnglesToForward(QAngle angles) {
        Vector forward;
        AngleVectors(angles, forward);
        return forward;
    }

    Vector AnglesToRight(QAngle angles) {
        Vector forward, right, up;
        AngleVectors(angles, forward, right, up);
        return right;
    }

    Vector AnglesToUp(QAngle angles) {
        Vector forward, right, up;
        AngleVectors(angles, forward, right, up);
        return up;
    }

    array<string> scripted_fling_levels = {"sp_a3_03", "sp_a3_bomb_flings", "sp_a3_transition01", "sp_a3_speed_flings", "sp_a3_end", "sp_a4_jump_polarity" };


/**
 * ResetPersistentSystems - Forces global engine and player states back to defaults.
 * Called during map init to prevent trap effects from surviving reloads/save-loads.
 */
