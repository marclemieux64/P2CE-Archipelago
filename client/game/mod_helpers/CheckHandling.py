# -*- coding: utf-8 -*-
from game.Locations import (
    all_locations_table, 
    wheatley_monitor_table, 
    wheatley_maps_to_monitor_names, 
    ratman_den_locations_table,
    item_location_table,
    map_complete_table,          # Importation de la table de complétion des chambres
    cutscene_completion_table,   # Importation de la table de complétion des cinématiques
    security_camera_table,
    camera_maps_to_camera_names,
    camera_names_to_camera_ids
)
from game.mod_helpers.ItemHandling import map_specific_commands
from game.Locations import LocationType

def parse_incoming_check(message_type: str, raw_payload: str) -> str:
    """
    Analyse un message Netcon et retourne le nom exact de la location Archipelago correspondante.
    """
    payload = raw_payload.strip()
    
    # 1. Gestion des moniteurs de Wheatley
    if message_type == "monitor_break":
        if payload in wheatley_maps_to_monitor_names:
            return wheatley_maps_to_monitor_names[payload]
        return payload

    # 2. Gestion des objets physiques ramassés (Portal Gun / PotatOS)
    if message_type == "item_collected":
        # Correspondance explicite basée sur la carte associée à l'item
        for loc_name, loc_data in item_location_table.items():
            if payload.lower() == "portal_gun_1" and loc_data.map_name == "sp_a1_intro3":
                return loc_name
            if payload.lower() == "portal_gun_2" and loc_data.map_name == "sp_a2_intro":
                return loc_name
            if payload.lower() == "potatos" and loc_data.map_name == "sp_a3_transition01":
                return loc_name
            
            # Fallback en cas d'envoi du nom d'affichage brut
            if loc_name.lower() == payload.lower() or payload.lower().replace("_", " ") in loc_name.lower():
                return loc_name

    # 2b. Gestion des caméras de sécurité
    if message_type == "camera_knocked":
        if payload in camera_maps_to_camera_names:
            return camera_maps_to_camera_names[payload]
        return payload

    # 3. Fallback général sur la table globale de locations
    for loc_name in all_locations_table.keys():
        if loc_name.lower() == payload.lower():
            return loc_name
            
    return payload

def get_map_sync_commands(map_code: str, items_missing: list, checked_locations: set, location_names_helper) -> list:
    """
    Génère l'intégralité des commandes de synchronisation d'état pour la map actuelle.
    """
    commands = []

    # Extraction des éléments validés depuis l'état Archipelago
    wheatley_monitors_checked = []
    ratman_dens_checked = []
    items_picked_up_checked = []
    maps_completed_checked = [] # Liste pour stocker les codes des cartes résolues
    security_cameras_checked = []
    
    for loc_id in checked_locations:
        loc_name = location_names_helper.lookup_in_game(loc_id)
        if loc_name in wheatley_monitor_table:
            wheatley_monitors_checked.append(loc_name)
        elif loc_name in ratman_den_locations_table:
            ratman_dens_checked.append(loc_name)
        elif loc_name in item_location_table:
            items_picked_up_checked.append(loc_name)
        elif loc_name in map_complete_table:
            maps_completed_checked.append(map_complete_table[loc_name].map_name)
        elif loc_name in cutscene_completion_table:
            maps_completed_checked.append(cutscene_completion_table[loc_name].map_name)
        elif loc_name in security_camera_table:
            security_cameras_checked.append(loc_name)

    # 1. Application des configurations de structures initiales de la map
    for mc in map_specific_commands:
        if map_code == mc.map_code and (mc.condition_item is None or mc.condition_item in items_missing):
            commands += mc.commands

    # 2. Transmission de la liste des boutons Ratman résolus
    if ratman_dens_checked:
        commands.append(f'SetCheckedButtons {" ".join(ratman_dens_checked)}\n')
    else:
        commands.append('SetCheckedButtons\n')

    # Transmission du statut des portes vitrifiées (Vitrified Doors)
    vitrified_doors_checked = [0] * 6
    for loc_id in checked_locations:
        loc_name = location_names_helper.lookup_in_game(loc_id)
        if loc_name and loc_name.startswith("Vitrified Door "):
            try:
                door_num = int(loc_name.split(" ")[-1])
                if 1 <= door_num <= 6:
                    vitrified_doors_checked[door_num - 1] = 1
            except ValueError:
                pass
    vitrified_bitmask = "".join(str(bit) for bit in vitrified_doors_checked)
    commands.append(f'SetVitrifiedStatus {vitrified_bitmask}\n')

    # 3. Transmission de la liste des écrans détruits
    checked_monitor_maps = [wheatley_monitor_table[m].map_name for m in wheatley_monitors_checked if m in wheatley_monitor_table]
    if checked_monitor_maps:
        commands.append(f'SetCheckedScreens {" ".join(checked_monitor_maps)}\n')
    else:
        commands.append('SetCheckedScreens\n')

    # 3b. Transmission de la liste des caméras détruites
    checked_camera_ids = [camera_names_to_camera_ids[c] for c in security_cameras_checked if c in camera_names_to_camera_ids]
    if checked_camera_ids:
        commands.append(f'SetCheckedCameras {" ".join(checked_camera_ids)}\n')
    else:
        commands.append('SetCheckedCameras\n')

    # 4. Transmission de l'état de ramassage du Portal Gun / PotatOS pour la carte en cours
    for item_name in items_picked_up_checked:
        loc_data = item_location_table[item_name]
        if loc_data.map_name == map_code:
            if map_code == "sp_a1_intro3":
                commands.append('SetCheckedPickup portal_gun_1\n')
            elif map_code == "sp_a2_intro":
                commands.append('SetCheckedPickup portal_gun_2\n')
            elif map_code == "sp_a3_transition01":
                commands.append('SetCheckedPickup potatos\n')

    # 5. Transmission unifiée de l'état de complétion pour la carte actuelle
    # (Pour éviter le débordement de tampon console Cbuf_AddText de 512 caractères)
    current_map_lower = map_code.lower() if map_code else ""
    if current_map_lower and any(m.lower() == current_map_lower for m in maps_completed_checked):
        commands.append(f'SetCheckedMaps {current_map_lower}\n')
    else:
        commands.append('SetCheckedMaps\n')

    commands.append("AddWheatleyMonitorBreakCheck\n")
    commands.append("AddCameraCheck\n")
    return commands