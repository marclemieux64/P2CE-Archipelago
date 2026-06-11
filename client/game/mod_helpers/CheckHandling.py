# -*- coding: utf-8 -*-
from game.Locations import (
    all_locations_table, 
    wheatley_monitor_table, 
    wheatley_maps_to_monitor_names, 
    ratman_den_locations_table
)
from game.mod_helpers.ItemHandling import map_specific_commands
from game.Locations import LocationType

def parse_incoming_check(message_type: str, raw_payload: str) -> str:
    """
    Analyse un message Netcon et retourne le nom exact de la location Archipelago correspondante.
    """
    payload = raw_payload.strip()
    
    if message_type == "monitor_break":
        if payload in wheatley_maps_to_monitor_names:
            return wheatley_maps_to_monitor_names[payload]
        return payload

    for loc_name in all_locations_table.keys():
        if loc_name.lower() == payload.lower():
            return loc_name
            
    return payload

def get_map_sync_commands(map_code: str, items_missing: list, checked_locations: set, location_names_helper) -> list:
    """
    Génère l'intégralité des commandes de synchronisation d'état pour la map actuelle.
    """
    commands = []

    # 1. Extraction des moniteurs et des repaires de Ratman déjà validés
    wheatley_monitors_checked = []
    ratman_dens_checked = []
    
    for loc_id in checked_locations:
        loc_name = location_names_helper.lookup_in_game(loc_id)
        if loc_name in wheatley_monitor_table:
            wheatley_monitors_checked.append(loc_name)
        elif loc_name in ratman_den_locations_table:
            ratman_dens_checked.append(loc_name)

    # 2. Application des configurations initiales de la map
    for mc in map_specific_commands:
        if map_code == mc.map_code and (mc.condition_item is None or mc.condition_item in items_missing):
            commands += mc.commands

    # 3. Transmission uniforme de la liste des boutons résolus au mod
    if ratman_dens_checked:
        commands.append(f'SetCheckedButtons {" ".join(ratman_dens_checked)}\n')
    else:
        commands.append('SetCheckedButtons\n')

    # 4. Transmission uniforme de la liste des écrans détruits au mod
    checked_monitor_maps = [wheatley_monitor_table[m].map_name for m in wheatley_monitors_checked if m in wheatley_monitor_table]
    if checked_monitor_maps:
        commands.append(f'SetCheckedScreens {" ".join(checked_monitor_maps)}\n')
    else:
        commands.append('SetCheckedScreens\n')

    commands.append("AddWheatleyMonitorBreakCheck\n")
    return commands