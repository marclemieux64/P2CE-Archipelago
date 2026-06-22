import typing

from .ConsoleLog import ConsoleLogManager
from .Hints import HintManager

class NotificationManager:
    def __init__(self, ctx):
        self.ctx = ctx
        self.console_manager = ConsoleLogManager(ctx)
        self.hint_manager = HintManager(ctx)

    @property
    def chat_log(self):
        return self.console_manager.chat_log

    @property
    def hint_log(self) -> list[dict]:
        return self.hint_manager.hint_log

    def reset(self):
        """Resets hint history tracking data upon a new session connection."""
        self.hint_manager.reset()

    def add_in_game_message(self, message: str, color_string: str = None):
        """Handles incoming raw text vectors submitted straight from the game runtime environment."""
        self.console_manager.add_in_game_message(message, color_string)

    def on_print(self, text: str):
        """Redirects default standard terminal prints straight through the silent pipeline."""
        self.console_manager.on_print(text)

    def auto_color_text(self, text: str) -> str:
        """Helper to auto colorize keywords and names in text."""
        return self.console_manager.auto_color_text(text)

    def on_print_silently(self, text: str, rich_data: list = None, html_text: str = None, mirror_to_hud: bool = False, from_logger: bool = False):
        """Redirects print straight through the silent logging/HUD pipeline."""
        self.console_manager.on_print_silently(text, rich_data, html_text, mirror_to_hud, from_logger)

    def print_json(self, data: typing.List[typing.Dict[str, str]], mirror_to_hud: bool = False):
        """Translates multiworld data packages tracking structural components into human-readable strings."""
        self.console_manager.print_json(data, mirror_to_hud)

    def on_print_json(self, args: dict):
        """Determines incoming context messaging metadata flags layout categories."""
        self.console_manager.on_print_json(args)

    def process_hints(self, raw_hints: list):
        """Processes the hints list."""
        self.hint_manager.process_hints(raw_hints)

    def trigger_go_mode(self):
        """Triggers go mode announcement."""
        self.console_manager.trigger_go_mode()