namespace Archipelago {

void OverrideProjector(string mapName, CBaseEntity@ ent, Vector&out targetPos, QAngle&out targetAng, int&out targetSkin, float&out targetScale, bool&out shouldParent, bool&out absoluteAngles) {
        shouldParent = false;   
        absoluteAngles = true;  
        targetScale = 0.66f;
        targetSkin = 4;

        // Fallback defaults to ensure visibility if a map isn't configured yet
        targetAng = ent.GetAbsAngles();
        targetPos = Vector(0.0f, 0.0f, 16.0f);

        // Hardcoded per-map adjustments for precise positioning and angle leveling
        if (mapName == "sp_a2_bridge_intro") {
            targetAng = QAngle(90.0f, 0.0f, 0.0f); 
            targetPos = Vector(16.0f, 0.0f, 8.0f);
        } 
        else if (mapName == "sp_a2_bridge_the_gap") {
            targetAng = QAngle(90.0f, 0.0f, 0.0f); 
            targetPos = Vector(16.0f, 0.0f, 0.0f);
        } 
        else if (mapName == "sp_a2_turret_blocker") {
            targetAng = QAngle(0.0f, 90.0f, 0.0f); 
            targetPos = Vector(16.0f, 0.0f, 0.0f);
        } 
        else if (mapName == "sp_a2_pull_the_rug") {
            targetAng = QAngle(90.0f, 0.0f, 0.0f); 
            targetPos = Vector(16.0f, 0.0f, 0.0f);
        } 
        else if (mapName == "sp_a2_column_blocker") {
            targetAng = QAngle(90.0f, 0.0f, 0.0f); 
            targetPos = Vector(16.0f, 0.0f, 0.0f);
        } 
        else if (mapName == "sp_a2_bts1") {
            targetAng = QAngle(90.0f, 0.0f, 0.0f); 
            targetPos = Vector(16.0f, 0.0f, 0.0f);
        } 
        else if (mapName == "sp_a4_stop_the_box") {
            targetAng = QAngle(0.0f, 90.0f, 0.0f); 
            targetPos = Vector(16.0f, 0.0f, 0.0f);
        }
    }
}