from ..Locations import all_locations_table, speedrun_logic_table, sub_locations_in_maps
from ..ItemNames import *

# Correspondance exacte avec les noms de vos fichiers SVG physiques
items_shortened = {
    portal_gun_1: "portalgun1",
    portal_gun_2: "portalgun2",
    potatos: "potatos",
    weighted_cube: "weightedcube",
    reflection_cube: "lasercube",
    spherical_cube: "ballcube",
    antique_cube: "antiqueweightedcube",
    button: "button",
    old_button: "antiquebutton",
    floor_button: "weightedfloorbutton",
    old_floor_button: "antiquefloorbutton",
    frankenturret: "frankencube",
    paint: "paint",
    blue_gel: "jumpgel",
    orange_gel: "speedgel",
    white_gel: "portalgel",
    laser: "laser",
    faith_plate: "faithplate",
    funnel: "funnel",
    bridge: "lightbridge",
    laser_relays: "laserrelay",
    laser_catcher: "lasercatcher",
    turrets: "turret",
    adventure_core: "advcore",
    space_core: "spacecore",
    fact_core: "factcore",
    moon_dust: "moondust",
    lemon: "lemon",
    slice_of_cake: "cake",
    motion_blur_trap: "trap",
    fizzle_portal_trap: "trap",
    butter_fingers_trap: "trap",
    cube_confetti_trap: "trap",
    slippery_floor_trap: "trap",
}

indicator_characters = {
    "completed": "check",
    "map": "flag",
    "wheatley": "monitor",
    "ratman": "ratmansdent", 
    "vitrified_door": "door",
    portal_gun_1: "portalgun1",
    portal_gun_2: "portalgun2",
    potatos: "potatos",
}

def items_to_shortened(items_list):
    return [items_shortened[x] for x in items_list if x in items_shortened]

def get_sub_locations(location_name, has_wheatley, has_ratman, has_vitrified):
    subs = sub_locations_in_maps.get(location_name, [])
    if not has_wheatley: subs = [s for s in subs if "Wheatley Monitor" not in s]
    if not has_ratman: subs = [s for s in subs if "Ratman Den" not in s]
    if not has_vitrified: subs = [s for s in subs if "Vitrified Door" not in s]
    return {s: False for s in subs}

class MenuElement:
    def __init__(self, parent, name, title, subtitle="", command="", pic=""):
        self.parent = parent
        self.name = name
        self.title = title
        self.subtitle = subtitle
        self.command = command
        self.pic = pic
        self.info_text = []

    def to_dict(self):
        return {
            "name": self.name,
            "title": self.title,
            "subtitle": self.subtitle,
            "command": self.command,
            "pic": self.pic,
            "statusIcons": self.info_text,
            "info": self.info_text
        }

class MapMenuElement(MenuElement):
    next_map = None
    completed = False
    sub_location_completion = {}

    def __init__(self, parent, chapter_number, map_number, title, map_code, location_id, required_items, pic):
        self.location_id = location_id
        self.required_items = required_items
        self.sub_location_completion = get_sub_locations(title, parent.parent.has_wheatley_monitors, parent.parent.has_ratman_dens, parent.parent.has_vitrified_doors)
        subtitle = "".join(items_to_shortened(self.required_items))
        super().__init__(parent, f"vgui/chapters/chapter{chapter_number}", map_code, subtitle, f"map {map_code}", pic)
        self.refresh_title()

    def check_logic(self, required_items):
        # FIX: Validate logic checks against the active item_list directly.
        # Since item_list tracks missing items, if an item is NOT in item_list, it has been received.
        client = self.parent.parent.client
        if not client or not hasattr(client, "item_list"):
            return False
        
        return all(item not in client.item_list for item in required_items)

    def refresh_title(self):
        client = self.parent.parent.client
        if client and hasattr(client, "checked_locations"):
            if self.location_id in client.checked_locations:
                self.completed = True
            for sub in self.sub_location_completion:
                if sub in all_locations_table and all_locations_table[sub].id in client.checked_locations:
                    self.sub_location_completion[sub] = True

        self.info_text = [indicator_characters["completed"] if self.completed else (indicator_characters["map"] if self.check_logic(self.required_items) else "uncheck")]
        
        for sub_location, is_completed in self.sub_location_completion.items():
            if is_completed:
                self.info_text.append(indicator_characters["completed"])
            else:
                reqs = all_locations_table[sub_location].required_items if sub_location in all_locations_table else []
                if self.check_logic(reqs):
                    if sub_location in indicator_characters:
                        self.info_text.append(indicator_characters[sub_location])
                    elif "Wheatley Monitor" in sub_location:
                        self.info_text.append(indicator_characters["wheatley"])
                    elif "Ratman Den" in sub_location:
                        self.info_text.append(indicator_characters["ratman"])
                    elif "Vitrified Door" in sub_location:
                        self.info_text.append(indicator_characters["vitrified_door"])
                    elif len(reqs) == 1:
                        shortened = items_to_shortened(reqs)
                        self.info_text.append(shortened[0] if shortened else indicator_characters["map"])
                    else:
                        self.info_text.append(indicator_characters["map"])
                else:
                    self.info_text.append("uncheck")

    def get_combined_requirements(self):
        all_reqs = list(self.required_items)
        for sub_loc in self.sub_location_completion:
            if sub_loc in all_locations_table:
                all_reqs.extend(all_locations_table[sub_loc].required_items)
        return list(set(all_reqs))

    def to_dict(self, previous_completed):
        is_blocked = not (self.parent.parent.is_open_world or previous_completed)
        self.refresh_title()
        
        all_reqs = self.get_combined_requirements()
        icons = items_to_shortened(all_reqs)
        
        valid_count = 0
        total_count = 0
        for icon in self.info_text:
            if icon == "check":
                continue
            elif icon == "uncheck":
                total_count += 1
            else:
                valid_count += 1
                total_count += 1

        active_sub_keys = []
        for k in self.sub_location_completion.keys():
            k_lower = k.lower()
            if "wheatley monitor" in k_lower: active_sub_keys.append("monitor")
            elif "ratman den" in k_lower: active_sub_keys.append("ratmansdent")
            elif "vitrified door" in k_lower: active_sub_keys.append("door")
            elif "potatos" in k_lower: active_sub_keys.append("potatos") 
            elif portal_gun_1 in k or "portal gun 1" in k_lower: active_sub_keys.append("portalgun1")
            elif portal_gun_2 in k or "portal gun 2" in k_lower: active_sub_keys.append("portalgun2")

        d = super().to_dict()
        d.update({
            "command": None if is_blocked else self.command,
            "command_deactivated": self.command if is_blocked else None,
            "location_id": self.location_id, 
            "completed": self.completed,
            "valid_count": valid_count,
            "total_count": total_count,
            "progress_text": f"{valid_count}/{total_count}",
            "status_text_list": self.info_text, 
            "required_item_icons": icons, 
            "active_sub_keys": active_sub_keys,
            "is_chapter": False
        })
        return d

    def complete_map(self, map_id):
        if self.location_id == map_id:
            self.completed = True
            self.refresh_title()
            return True
        return self.next_map.complete_map(map_id) if self.next_map else False

    def complete_sub_location_check(self, sub):
        if sub in self.sub_location_completion:
            self.sub_location_completion[sub] = True
            self.refresh_title()
        elif self.next_map: self.next_map.complete_sub_location_check(sub)

    def complete_check(self, loc_id):
        if not self.complete_map(loc_id):
            name = self.parent.parent.client.location_names.lookup_in_game(loc_id)
            if name and "Complete" not in name: self.complete_sub_location_check(name)

class ChapterMenuElement(MenuElement):
    first_map = None
    def __init__(self, parent, chapter_number, map_names):
        self.chapter_number = "".join(c for c in str(chapter_number) if c.isdigit())
        super().__init__(parent, f"chapter{self.chapter_number}", f"Chapter {self.chapter_number}", pic=f"vgui/chapters/chapter{self.chapter_number}")
        curr = None
        for i, name in enumerate(map_names):
            loc = all_locations_table[name]
            nxt = MapMenuElement(self, self.chapter_number, i, name, loc.map_name, loc.id, loc.required_items, self.pic)
            if not self.first_map: self.first_map = nxt
            else: curr.next_map = nxt
            curr = nxt

    def complete_check(self, loc_id):
        if self.first_map:
            self.first_map.complete_check(loc_id)

    def to_dict(self, previous_completed=True):
        maps_list, curr = [], self.first_map
        prev_comp = previous_completed
        chapter_valid = 0
        chapter_total = 0
        all_maps_complete = True
        has_valid_maps = False

        while curr:
            m = curr.to_dict(prev_comp)
            maps_list.append(m)
            if curr.location_id != -1:
                has_valid_maps = True
                if not m.get("completed"):
                    all_maps_complete = False
                
                chapter_valid += m.get("valid_count", 0)
                chapter_total += m.get("total_count", 0)
            prev_comp = curr.completed
            curr = curr.next_map

        return {
            "name": self.name, 
            "title": self.title, 
            "chapter_number": self.chapter_number,
            "maps": maps_list, 
            "valid_count": chapter_valid,
            "total_count": chapter_total,
            "progress_text": f"{chapter_valid}/{chapter_total}" if chapter_total > 0 else "0/0", 
            "is_chapter": True,
            "all_completed": all_maps_complete if has_valid_maps else False
        }

class Menu:
    def __init__(self, chapter_dict, client, is_open_world=False, logic_difficulty=0, **kwargs):
        if logic_difficulty == 1:
            for map_location in speedrun_logic_table:
                all_locations_table[map_location].required_items = speedrun_logic_table[map_location]
        self.client = client
        self.is_open_world = is_open_world
        self.has_wheatley_monitors = kwargs.get("wheatley_monitors", False)
        self.has_ratman_dens = kwargs.get("ratman_dens", False)
        self.has_vitrified_doors = kwargs.get("vitrified_doors", False)
        self.chapter_dict = chapter_dict
        self.chapters = []

    def generate_menu(self):
        for chapter_number, map_names in self.chapter_dict.items():
            self.chapters.append(ChapterMenuElement(self, chapter_number, map_names))

    def to_dict(self):
        data = []
        for ch in self.chapters:
            ch_dict = ch.to_dict(previous_completed=True)
            data.append(ch_dict)
        return {"is_open_world": self.is_open_world, "chapters": data}

    def complete_map(self, map_id):
        for ch in self.chapters: ch.complete_map(map_id)
        
    def complete_sub_location_check(self, sub):
        for ch in self.chapters: ch.complete_sub_location_check(sub)
        
    def complete_check(self, loc_id):
        for ch in self.chapters: ch.complete_check(loc_id)