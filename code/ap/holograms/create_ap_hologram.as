void CreateAPHologram(Vector position, QAngle angles, float scale, string new_parent = "", string attachment = "", int skin = 0, string name = "") {
    CBaseEntity@ holo = util::CreateEntityByName("prop_dynamic_override");
    if (@holo == null) return;
    
    holo.PrecacheModel("models/effects/ap/archipelago_hologram.mdl");
    holo.KeyValue("model", "models/effects/ap/archipelago_hologram.mdl");
    
    Vector fixedPos(position.x, position.y, position.z + 32.0f); 
    
    holo.KeyValue("origin", fixedPos);
    holo.KeyValue("angles", "" + angles.x + " " + angles.y + " " + angles.z);
    
    holo.KeyValue("solid", 0);
    holo.KeyValue("skin", skin);
    holo.KeyValue("modelscale", scale);
    
    if (name != "" && name != "null") {
        holo.KeyValue("targetname", name);
    }
    
    holo.Spawn();
    
    Variant animVar;
    animVar.SetString("idle");
    holo.FireInput("SetAnimation", animVar, 0.0f, null, null, 0);
    
    if (new_parent != "" && new_parent != "null") {
        CBaseEntity@ nullEnt = null;
        CBaseEntity@ parentEnt = EntityList().FindByName(nullEnt, new_parent);
        if (@parentEnt != null) {
            holo.SetParent(parentEnt, -1);
            if (attachment != "" && attachment != "null") {
                holo.SetParentAttachmentMaintainOffset(attachment);
            }
        }
    }
    
    holo.SetAbsOrigin(fixedPos);
    holo.SetAbsAngles(angles);
    holo.SetSolid(SOLID_NONE);
}
