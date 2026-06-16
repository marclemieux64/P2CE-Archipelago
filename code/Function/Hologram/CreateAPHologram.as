namespace Archipelago {

CBaseEntity@ CreateAPHologram(Vector position, QAngle angles, float scale, CBaseEntity@ parent = null, string attachment = "", int skin = 0, string name = "", bool animate = true, float playbackRate = 1.0f) {
        CBaseEntity@ h = null;

        if (name != "") {
            @h = EntityList().FindByName(null, name);
        }

    // BLOC DE MISE À JOUR CORRECTIF POUR LE RELOAD
        if (h !is null) {
            if (h.GetModelName().tolower().locate("archipelago_hologram") != uint(-1)) {
                if (Archipelago::cv_ArchipelagoDebug.GetBool()) {
                    Archipelago::ArchipelagoLog("[AP DEBUG] Updating Hologram '" + name + "' to " + angles.x + " " + angles.y + " " + angles.z + " | Skin: " + skin + " | PlaybackRate: " + playbackRate);
                }
            
            // 1. Re-parentage et gestion d'origine stricte à chaque snapshot pour contrer le reload
                if (parent !is null) {
                    h.SetParent(parent);
                    h.SetLocalOrigin(position);
                    h.SetLocalAngles(angles);
                
                    if (attachment != "") {
                        Variant v;
                        v.SetString(attachment);
                        h.FireInput("SetParentAttachment", v, 0.01f, null, null, 0);
                    }
                } else {
                    if (h.GetMoveParent() !is null) {
                        h.SetParent(null); 
                    }
                    h.SetAbsOrigin(position);
                    h.SetAbsAngles(angles);
                }
            
            // 2. Refresh instantané du matériau et de la vitesse d'animation via CBaseAnimating
                CBaseAnimating@ animH = cast<CBaseAnimating>(h);
                if (animH !is null) {
                    animH.SetSkin(skin);
                    animH.SetPlaybackRate(playbackRate); // AJOUT : Mise à jour de la vitesse de lecture
                } else {
                    h.KeyValue("skin", "" + skin); 
                }
            
                h.KeyValue("modelscale", "" + scale);

            // Apply visibility settings
                int hideOption = Archipelago::cv_ArchipelagoHideHolograms.GetInt();
                bool shouldHide = (hideOption == 2) || (hideOption == 1 && (skin == 4 || skin == 2));
                Variant emptyVal;
                h.KeyValue("rendermode", "0");
                if (shouldHide) {
                    h.FireInput("Disable", emptyVal, 0.0f, null, null, 0);
                } else {
                    h.FireInput("Enable", emptyVal, 0.0f, null, null, 0);
                }

                return h;
            }
        }

    // BLOC DE CRÉATION INITIALE 
        @h = util::CreateEntityByName("prop_dynamic");
        if (h !is null) {
            h.KeyValue("model", "models/effects/ap/archipelago_hologram.mdl");
            if (name != "") h.KeyValue("targetname", name);
            h.KeyValue("skin", "" + skin);
            h.KeyValue("modelscale", "" + scale);
            h.KeyValue("DefaultAnim", animate ? "idle" : "");

            if (parent !is null) {
                h.SetAbsOrigin(parent.GetAbsOrigin()); 
                h.SetAbsAngles(parent.GetAbsAngles());
            } else {
                h.SetAbsOrigin(position); 
                h.SetAbsAngles(angles);
            }
        
            h.Spawn(); 

            h.SetSolid(SOLID_NONE);
            h.SetMoveType(MOVETYPE_NONE);

            if (parent !is null) {
                h.SetParent(parent);
                h.SetLocalOrigin(position); 
                h.SetLocalAngles(angles);
            
                if (attachment != "") {
                    Variant v;
                    v.SetString(attachment);
                    h.FireInput("SetParentAttachment", v, 0.01f, null, null, 0);
                }
            }

            // AJOUT : Application de la vitesse de lecture initiale via l'interface d'animation
            CBaseAnimating@ animH = cast<CBaseAnimating>(h);
            if (animH !is null) {
                animH.SetPlaybackRate(playbackRate);
            }

        // Apply visibility settings
            int hideOption = Archipelago::cv_ArchipelagoHideHolograms.GetInt();
            bool shouldHide = (hideOption == 2) || (hideOption == 1 && (skin == 4 || skin == 2));
            Variant emptyVal;
            h.KeyValue("rendermode", "0");
            if (shouldHide) {
                h.FireInput("Disable", emptyVal, 0.0f, null, null, 0);
            } else {
                h.FireInput("Enable", emptyVal, 0.0f, null, null, 0);
            }
        }
        return h;
    }

} // namespace Archipelago