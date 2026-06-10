namespace Archipelago { 

    void LockButtonByName(string entity_name) 
    {
        // Initialisation du pointeur de recherche au début de la liste des entités
        CBaseEntity@ pEntity = null;
        
        // On parcourt toutes les entités de la carte portant ce nom spécifique
        while ((@pEntity = EntityList().FindByName(pEntity, entity_name)) != null)
        {
            // 1. Envoi de l'input de verrouillage standard du moteur Source
            Variant emptyValue;
            pEntity.FireInput("Lock", emptyValue, 0.0f, null, null, 0);
            
            // 2. Correction manuelle préventive de la propriété m_bLocked via KeyValue
            // Cela force le flag à true dans VScript pour contourner le bug natif du moteur
            pEntity.KeyValue("m_bLocked", 1);
            
            // Journalisation de débogage dans la console du développeur
            ArchipelagoLog("[Archipelago] Entite bouton verrouillee avec succes : " + entity_name + "\n");

            // --------------------------------------------------------------------
            // AJOUT DE L'HOLOGRAMME (SKIN 4) AVEC AJUSTEMENT DE LA HAUTEUR
            // --------------------------------------------------------------------
            string holoName = entity_name + "_holo";
            
            // AJUSTEMENT DE HAUTEUR : On décale de 25 unités sur l'axe Z local.
            Vector localPos(0, 0, 25); 
            QAngle localAng(0, 0, 0); // Alignement local relatif au bouton
            float holoScale = 0.66f;

            // Appel de la fonction de création/mise à jour de l'hologramme parenté au bouton
            CreateAPHologram(localPos, localAng, holoScale, pEntity, "", 4, holoName, true);

            // --------------------------------------------------------------------
            // AJOUT ET CONFIGURATION DYNAMIQUE DE L'ENV_INSTRUCTOR_HINT
            // --------------------------------------------------------------------
            string hintCaption = "";
            
            // Détermination stricte de la chaîne de localisation basée sur le nom de la pompe
            if (entity_name == "pump_machine_white_button") {
                hintCaption = "#Archipelago_Hint_NoWhiteGel";
            } else if (entity_name == "pump_machine_blue_button") {
                hintCaption = "#Archipelago_Hint_NoBlueGel";
            } else if (entity_name == "pump_machine_orange_button") {
                hintCaption = "#Archipelago_Hint_NoOrangeGel";
            }

            // Génération d'un nom unique pour la cible de l'indicateur
            string hintTargetName = entity_name + "_hint_target";
            pEntity.KeyValue("targetname", hintTargetName);
            
            string hintName = "hudhint_" + entity_name;

            // Création de l'entité d'affichage du message à l'écran
            CBaseEntity@ hint = util::CreateEntityByName("env_instructor_hint");
            if (hint !is null) {
                hint.KeyValue("targetname", hintName);
                hint.KeyValue("hint_target", hintTargetName);
                hint.KeyValue("hint_static", "0"); // Suit l'entité cible dynamiquement dans l'espace 3D
                hint.KeyValue("hint_caption", hintCaption); // Utilise le token localisé adapté
                hint.KeyValue("hint_icon_onscreen", "icon_alert");
                hint.KeyValue("hint_color", "255 50 50"); // Rouge d'alerte Archipelago
                hint.KeyValue("hint_forcecaption", "1"); // S'assure que le texte s'affiche toujours
            }

            // --------------------------------------------------------------------
            // CONNEXION DU RECIPIENT D'OUTPUTS : LE BOUTON DÉCLENCHE LE HINT
            // --------------------------------------------------------------------
            // "Quand le bouton est utilisé alors qu'il est verrouillé (OnUseLocked), 
            // envoyer l'input 'ShowHint' à notre entité 'env_instructor_hint' immédiatement."
            SafeAddOutput(pEntity, "OnUseLocked", hintName, "ShowHint", "", 0.0f, -1);
        }
    }

} // namespace Archipelago