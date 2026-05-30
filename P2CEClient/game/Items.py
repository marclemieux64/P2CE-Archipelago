from enum import Flag, auto
from BaseClasses import Item, ItemClassification
from .ItemNames import *

class ItemTag(Flag):
    # Item type
    ENTITY = auto()
    WEAPON = auto()
    CUBE = auto()
    GEL = auto()

    BLUE_GEL = auto()
    ORANGE_GEL = auto()
    WHITE_GEL = auto()
    
    CORE = auto()

    # Affect applied
    DELETE = auto()
    DISABLE = auto()
    ALTER = auto()

p2ce_base_id = 98285000
offset_index = 0
    
class P2CEItemData:
    def __init__(self, in_game_name: str = "", variant: str = None, tags: ItemTag = None, classification: ItemClassification = ItemClassification.progression):
        self.in_game_name = in_game_name
        self.variant = variant
        self.tags = tags
        self.classification = classification
        
        global p2ce_base_id, offset_index
        self.id = p2ce_base_id + offset_index
        offset_index += 1

class P2CEItem(Item):
    game: str = "P2CE"

game_item_table: dict[str, P2CEItemData] = {
    # Guns
    portal_gun_2: P2CEItemData("weapon_portalgun", "CanFirePortal2", ItemTag.WEAPON | ItemTag.DISABLE, ItemClassification.progression | ItemClassification.useful),
    potatos: P2CEItemData("weapon_portalgun", "potato", ItemTag.WEAPON | ItemTag.DISABLE, ItemClassification.progression),
    
    # Cubes (GetModelName())
    weighted_cube: P2CEItemData("prop_weighted_cube", "models/props/metal_box.mdl", ItemTag.DELETE | ItemTag.CUBE, ItemClassification.progression),
    reflection_cube: P2CEItemData("prop_weighted_cube", "models/props/reflection_cube.mdl", ItemTag.DELETE | ItemTag.CUBE, ItemClassification.progression),
    spherical_cube: P2CEItemData("prop_weighted_cube", "models/props_gameplay/mp_ball.mdl", ItemTag.DELETE | ItemTag.CUBE, ItemClassification.filler),
    antique_cube: P2CEItemData("prop_weighted_cube", "models/props_underground/underground_weighted_cube.mdl", ItemTag.DELETE | ItemTag.CUBE, ItemClassification.progression),

    # Buttons
    button: P2CEItemData("prop_button", None, ItemTag.ENTITY | ItemTag.DELETE, ItemClassification.progression),
    old_button: P2CEItemData("prop_under_button", None, ItemTag.ENTITY | ItemTag.DELETE, ItemClassification.progression),
    floor_button: P2CEItemData("prop_floor_button", None, ItemTag.ENTITY | ItemTag.DELETE, ItemClassification.progression),
    old_floor_button: P2CEItemData("prop_under_floor_button", None, ItemTag.ENTITY | ItemTag.DELETE, ItemClassification.progression),

    # Puzzle Elements
    frankenturret: P2CEItemData("prop_monster_box", None, ItemTag.ENTITY | ItemTag.DELETE, ItemClassification.progression),
    blue_gel: P2CEItemData("various", "blue", ItemTag.ENTITY | ItemTag.GEL | ItemTag.BLUE_GEL, ItemClassification.progression),
    orange_gel: P2CEItemData("various", "orange", ItemTag.ENTITY | ItemTag.GEL | ItemTag.ORANGE_GEL, ItemClassification.progression),
    white_gel: P2CEItemData("various", "white", ItemTag.ENTITY | ItemTag.GEL | ItemTag.WHITE_GEL, ItemClassification.progression),
    laser: P2CEItemData("env_portal_laser", None, ItemTag.ENTITY | ItemTag.DELETE, ItemClassification.progression),
    faith_plate: P2CEItemData("trigger_catapult", None, ItemTag.ENTITY | ItemTag.DELETE, ItemClassification.progression),
    funnel: P2CEItemData("prop_tractor_beam", None, ItemTag.ENTITY | ItemTag.DELETE, ItemClassification.progression),
    bridge: P2CEItemData("prop_wall_projector", None, ItemTag.ENTITY | ItemTag.DELETE, ItemClassification.progression),
    laser_relays: P2CEItemData("prop_laser_relay", None, ItemTag.ENTITY | ItemTag.DELETE, ItemClassification.progression),
    laser_catcher: P2CEItemData("prop_laser_catcher", None, ItemTag.ENTITY | ItemTag.DELETE, ItemClassification.progression),
    
    # Hazards
    turrets: P2CEItemData("npc_portal_turret_floor", None, ItemTag.ENTITY | ItemTag.DISABLE, ItemClassification.progression),

    # Goal Items
    adventure_core: P2CEItemData("npc_personality_core", "@core02", ItemTag.CORE | ItemTag.DELETE, ItemClassification.progression_skip_balancing),
    space_core: P2CEItemData("npc_personality_core", "@core01", ItemTag.CORE | ItemTag.DELETE, ItemClassification.progression_skip_balancing),
    fact_core: P2CEItemData("npc_personality_core", "@core03", ItemTag.CORE | ItemTag.DELETE, ItemClassification.progression_skip_balancing)
}

# Junk items
junk_items = [moon_dust, lemon, slice_of_cake]

junk_items_table: dict[str, P2CEItemData] = {
    moon_dust: P2CEItemData(classification = ItemClassification.filler),
    lemon: P2CEItemData(classification = ItemClassification.filler),
    slice_of_cake: P2CEItemData(classification = ItemClassification.filler)
}

trap_items_table: dict[str, P2CEItemData] = {
    motion_blur_trap: P2CEItemData(classification = ItemClassification.trap),
    fizzle_portal_trap: P2CEItemData(classification = ItemClassification.trap),
    butter_fingers_trap: P2CEItemData(classification = ItemClassification.trap),
    cube_confetti_trap: P2CEItemData(classification = ItemClassification.trap),
    slippery_floor_trap: P2CEItemData(classification = ItemClassification.trap),
}

trap_items = [trap for trap in trap_items_table.keys()]

item_table: dict[str, P2CEItemData] = game_item_table.copy()
item_table.update(junk_items_table)
item_table.update(trap_items_table)