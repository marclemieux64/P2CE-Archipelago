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

indicator_characters: dict[str, str] = {
    "completed": "check",
    "map": "flag",
    "wheatley": "monitor",
    "ratman": "ratmansdent",
    "vitrified_door": "door",
    portal_gun_1: "portalgun1",
    portal_gun_2: "portalgun2",
    potatos: "potatos",
}

access_icons: dict[str, str] = {
    "playable": "",
    "unplayable": "",
}

def items_to_shortened(items_list: list[str]) -> list[str]:
    return [items_shortened[x] for x in items_list if x in items_shortened]


class MenuElement:
    def __init__(self, parent, name: str, title: str, subtitle: str = "", command: str = "", pic: str = ""):
        self.parent = parent
        self.name = name
        self.title = title
        self.subtitle = subtitle
        self.command = command
        self.pic = pic
        self.info_text: list[str] = []

    def __str__(self):
        return ""
    
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
    next_map: MenuElement = None
    completed: bool = False
    sub_location_completion: dict[str, bool] = {}

    def __init__(self, parent, chapter_number, map_number, title, map_code, location_id, required_items, pic):
        self.location_id = location_id
        self.required_items = required_items
        self.sub_location_completion = get_sub_locations(
            title, parent.parent.has_wheatley_monitors, parent.parent.has_ratman_dens, parent.parent.has_vitrified_doors
        )
        subtitle = "".join(items_to_shortened(self.required_items))
        new_title = title.removesuffix(" Completion")
        super().__init__(parent, f"chapter {chapter_number}.{map_number}", new_title, subtitle, f"map {map_code}", pic)
        self.info_text = [indicator_characters["map"]] + parse_sub_locations(self.sub_location_completion)

    def refresh_title(self, blocked: bool = False):
        self.info_text = [indicator_characters["completed"]] if self.completed else [indicator_characters["map"]]
        self.info_text += parse_sub_locations(self.sub_location_completion)

        if blocked:
            if access_icons["unplayable"] not in self.title:
                self.title = access_icons["unplayable"] + self.title
        elif access_icons["playable"] not in self.title:
            self.title = self.title.strip(access_icons["unplayable"])
            self.title = access_icons["playable"] + self.title

    def get_combined_requirements(self):
        all_reqs = list(self.required_items)
        for sub_loc in self.sub_location_completion:
            if sub_loc in all_locations_table:
                all_reqs.extend(all_locations_table[sub_loc].required_items)
        return list(set(all_reqs))

    def get_string(self, previous_completed: bool):
        return ""

    def to_dict(self, previous_completed: bool):
        all_reqs = self.get_combined_requirements()
        new_required_items = [item for item in all_reqs if item in self.parent.parent.client.item_list]
        self.subtitle = "".join(items_to_shortened(new_required_items))

        is_blocked = not (self.parent.parent.is_open_world or previous_completed)
        self.refresh_title(blocked=is_blocked)

        d = super().to_dict()
        if is_blocked:
            d["command_deactivated"] = d.pop("command")
            d["command"] = None
        else:
            d["command_deactivated"] = None

        raw_status = d.get("statusIcons") or []
        total_count = len(raw_status)
        green_count = sum(1 for c in raw_status if c == indicator_characters["completed"])

        d.update({
            "location_id": self.location_id,
            "required_items": list(self.required_items),
            "completed": self.completed,
            "sub_locations": self.sub_location_completion,
            "is_blocked": is_blocked,
            "progress_text": f"{green_count}/{total_count}" if total_count > 0 else "",
            "status_text_list": raw_status,
            "required_item_icons": items_to_shortened(new_required_items)
        })
        return d

    def complete_map(self, map_id: int) -> bool:
        if self.location_id == map_id:
            if self.completed:
                return True
            self.completed = True
            self.refresh_title()
            if self.next_map:
                self.next_map.command = self.next_map.command.replace("command_deactivated", "command")
            return True
        else:
            if self.next_map:
                return self.next_map.complete_map(map_id)
            else:
                return False

    def complete_sub_location_check(self, sub_location: str):
        if sub_location in self.sub_location_completion:
            self.sub_location_completion[sub_location] = True
            self.refresh_title()
        elif self.next_map:
            self.next_map.complete_sub_location_check(sub_location)

    def complete_check(self, location_id: int):
        if not self.complete_map(location_id):
            location_name = self.parent.parent.client.location_names.lookup_in_game(location_id)
            if "Complete" not in location_name:
                self.complete_sub_location_check(location_name)

blank_map_element = lambda parent, chapter_number: MapMenuElement(parent, chapter_number, 0, "No Maps In This Chapter", "", -1, [], "")

def get_sub_locations(
    location_name: str, has_wheatley_monitors: bool, has_ratman_dens: bool, has_vitrified_doors: bool
) -> dict[str, bool]:
    sub_locations = sub_locations_in_maps.get(location_name, [])
    if not has_wheatley_monitors:
        sub_locations = [sub_location for sub_location in sub_locations if "Wheatley Monitor" not in sub_location]
    if not has_ratman_dens:
        sub_locations = [sub_location for sub_location in sub_locations if "Ratman Den" not in sub_location]
    if not has_vitrified_doors:
        sub_locations = [sub_location for sub_location in sub_locations if "Vitrified Door" not in sub_location]
    return {sub_location: False for sub_location in sub_locations}


def parse_sub_locations(sub_locations: dict[str, bool]) -> list[str]:
    additional_indicators = []
    for sub_location, is_completed in sub_locations.items():
        if not is_completed:
            if "Wheatley Monitor" in sub_location:
                additional_indicators.append(indicator_characters["wheatley"])
            elif "Ratman Den" in sub_location:
                additional_indicators.append(indicator_characters["ratman"])
            elif "Vitrified Door" in sub_location:
                additional_indicators.append(indicator_characters["vitrified_door"])
            elif sub_location in indicator_characters:
                additional_indicators.append(indicator_characters[sub_location])
        else:
            additional_indicators.append(indicator_characters["completed"])
    return additional_indicators


class ChapterMenuElement(MenuElement):
    first_map: MapMenuElement = None

    def __init__(self, parent, chapter_number: int, map_names: list[str]):
        self.chapter_number = chapter_number
        super().__init__(parent, f"chapter{chapter_number}", f"Chapter {chapter_number}", pic=f"vgui/chapters/chapter{chapter_number}")
        if not map_names:
            self.first_map = blank_map_element(self, chapter_number)
            return

        current_map: MapMenuElement = None
        for i, name in enumerate(map_names):
            location = all_locations_table[name]
            next_map = MapMenuElement(
                self, chapter_number, i, name, location.map_name, location.id, location.required_items, self.pic
            )
            if not self.first_map:
                self.first_map = next_map
                current_map = self.first_map
            else:
                current_map.next_map = next_map
                current_map = next_map

    def __str__(self):
        return ""
    
    def to_dict(self):
        d = super().to_dict()
        maps = []
        curr = self.first_map
        prev_completed = True
        
        chapter_total_green = 0
        chapter_total_indicators = 0
        all_maps_complete = True
        has_valid_maps = False

        while curr:
            map_dict = curr.to_dict(prev_completed)
            maps.append(map_dict)
            
            if not map_dict.get("is_blocked") and curr.location_id != -1:
                has_valid_maps = True
                if not map_dict.get("completed"):
                    all_maps_complete = False
                
                raw_status = map_dict.get("status_text_list", [])
                chapter_total_indicators += len(raw_status)
                chapter_total_green += sum(1 for c in raw_status if c == indicator_characters["completed"])

            prev_completed = curr.completed
            curr = curr.next_map
            
        d["maps"] = maps
        d["chapter_number"] = self.chapter_number
        d["all_completed"] = all_maps_complete if has_valid_maps else False
        d["progress_text"] = f"{chapter_total_green}/{chapter_total_indicators}" if chapter_total_indicators > 0 else ""
        return d
    
    def complete_map(self, map_id: int):
        if self.first_map:
            self.first_map.complete_map(map_id)
        
    def complete_sub_location_check(self, sub_location: str):
        if self.first_map:
            self.first_map.complete_sub_location_check(sub_location)
        
    def complete_check(self, location_id: int):
        if self.first_map:
            self.first_map.complete_check(location_id)


class Menu:
    def __init__(
        self,
        chapter_dict: dict[int, list[str]],
        client,
        is_open_world: bool = False,
        logic_difficulty: int = 0,
        wheatley_monitors: bool = False,
        ratman_dens: bool = False,
        vitrified_doors: bool = False,
    ):
        if logic_difficulty == 1:
            for map_location in speedrun_logic_table:
                all_locations_table[map_location].required_items = speedrun_logic_table[map_location]
        self.client = client
        self.is_open_world = is_open_world
        self.has_wheatley_monitors = wheatley_monitors
        self.has_ratman_dens = ratman_dens
        self.has_vitrified_doors = vitrified_doors
        self.chapter_dict = chapter_dict
        self.chapters: list[ChapterMenuElement] = []

    def generate_menu(self):
        for chapter_number, map_names in self.chapter_dict.items():
            self.chapters.append(ChapterMenuElement(self, chapter_number, map_names))

    def to_dict(self):
        return {
            "is_open_world": self.is_open_world,
            "chapters": [chapter.to_dict() for chapter in self.chapters]
        }

    def complete_map(self, map_id: int):
        for chapter in self.chapters:
            chapter.complete_map(map_id)

    def complete_sub_location_check(self, sub_location: str):
        for chapter in self.chapters:
            chapter.complete_sub_location_check(sub_location)

    def complete_check(self, location_id: int):
        for chapter in self.chapters:
            chapter.complete_check(location_id)