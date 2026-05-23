import typing
from enum import IntEnum, IntFlag

class LocationProgressType(IntEnum):
    DEFAULT = 1
    PRIORITY = 2
    EXCLUDED = 3

class Location:
    game: str = "Generic"
    player: int
    name: str
    address: typing.Optional[int]
    parent_region: typing.Any
    locked: bool = False
    show_in_spoiler: bool = True
    progress_type: LocationProgressType = LocationProgressType.DEFAULT
    item: typing.Any = None

    def __init__(self, player: int, name: str = '', address: typing.Optional[int] = None, parent: typing.Any = None):
        self.player = player
        self.name = name
        self.address = address
        self.parent_region = parent

    def place_locked_item(self, item: typing.Any):
        if self.item:
            raise Exception(f"Location {self} already filled.")
        self.item = item
        item.location = self
        self.locked = True

    def __repr__(self):
        return f'{self.name} (Player {self.player})'

    def __lt__(self, other: "Location"):
        return (self.player, self.name) < (other.player, other.name)

class ItemClassification(IntFlag):
    filler = 0b00000
    progression = 0b00001
    useful = 0b00010
    trap = 0b00100
    skip_balancing = 0b01000
    deprioritized = 0b10000
    progression_deprioritized_skip_balancing = 0b11001
    progression_skip_balancing = 0b01001
    progression_deprioritized = 0b10001

    def as_flag(self) -> int:
        return int(self & 0b00111)

class Item:
    game: str = "Generic"
    __slots__ = ("name", "classification", "code", "player", "location")
    name: str
    classification: ItemClassification
    code: typing.Optional[int]
    player: int
    location: typing.Optional[Location]

    def __init__(self, name: str, classification: ItemClassification, code: typing.Optional[int], player: int):
        self.name = name
        self.classification = classification
        self.player = player
        self.code = code
        self.location = None

    @property
    def advancement(self) -> bool:
        return ItemClassification.progression in self.classification

    @property
    def useful(self) -> bool:
        return ItemClassification.useful in self.classification

    @property
    def trap(self) -> bool:
        return ItemClassification.trap in self.classification

    @property
    def deprioritized(self) -> bool:
        return ItemClassification.deprioritized in self.classification

    @property
    def filler(self) -> bool:
        return not (self.advancement or self.useful or self.trap)

    @property
    def flags(self) -> int:
        return self.classification.as_flag()

    @property
    def is_event(self) -> bool:
        return self.code is None

    def __eq__(self, other: object) -> bool:
        if not isinstance(other, Item):
            return NotImplemented
        return self.name == other.name and self.player == other.player

    def __lt__(self, other: object) -> bool:
        if not isinstance(other, Item):
            return NotImplemented
        if other.player != self.player:
            return other.player < self.player
        return self.name < other.name

    def __hash__(self) -> int:
        return hash((self.name, self.player))

    def __repr__(self) -> str:
        return f"{self.name} (Player {self.player})"
