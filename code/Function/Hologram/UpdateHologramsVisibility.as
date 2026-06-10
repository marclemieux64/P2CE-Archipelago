namespace Archipelago {
void UpdateHologramsVisibility() {
        CBaseEntity@ ent = null;
        int hideOption = cv_ArchipelagoHideHolograms.GetInt();
    
        while ((@ent = EntityList().FindByClassname(ent, "prop_dynamic")) !is null) {
            if (ent.GetModelName().tolower().locate("archipelago_hologram") != uint(-1)) {
                int skin = 0;
                CBaseAnimating@ anim = cast<CBaseAnimating>(ent);
                if (anim !is null) {
                    skin = anim.GetSkin();
                }
            
                bool shouldHide = (hideOption == 2) || (hideOption == 1 && (skin == 4 || skin == 2));
                Variant emptyVal;
                ent.KeyValue("rendermode", "0");
                if (shouldHide) {
                    ent.FireInput("Disable", emptyVal, 0.0f, null, null, 0);
                } else {
                    ent.FireInput("Enable", emptyVal, 0.0f, null, null, 0);
                }
            }
        }
    }
}//namepasce Archipelago