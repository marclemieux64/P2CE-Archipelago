import time
import typing
import logging
import re

from game.mod_helpers.ItemHandling import handle_trap

logger = logging.getLogger("Portal2Client")

class ConsoleLogManager:
    # Pre-compiled regex patterns for performance optimization
    _url_pattern = re.compile(r"(?:(?:ws://|wss://|http://|https://)[a-zA-Z0-9.-]+(?::\d+)?)|(?:[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}(?::\d+)?)|(?:\d{1,3}\.){3}\d{1,3}(?::\d+)?|localhost:\d+")
    _shield_regexes = [
        re.compile(r"[a-zA-Z]:\\[a-zA-Z0-9._()\\/-]+"),
        re.compile(r"\b[a-zA-Z0-9._-]+\b/(?:[a-zA-Z0-9._-]+/)*[a-zA-Z0-9._-]+\b"),
        re.compile(r"(?<!\w)/[a-zA-Z0-9_-]+\b"),
        re.compile(r"\b[a-zA-Z0-9_-]+\.(?:py|json|ts|cfg|txt|exe|dll)\b"),
        re.compile(r"\b[a-zA-Z0-9_]+\.[a-zA-Z0-9_]+(?:\.[a-zA-Z0-9_]+)*\b")
    ]
    _team_pattern = re.compile(r"team\s*#\s*\d+", re.IGNORECASE)
    _team_num_pattern = re.compile(r"\d+")
    _quoted_tags_pattern = re.compile(r"'([a-zA-Z0-9_-]+)'|\"([a-zA-Z0-9_-]+)\"")
    _team_mention_pattern = re.compile(r"\b([a-zA-Z0-9_-]+)\s*\(Team\s*#\s*\d+\)")
    
    _locations_cache = None
    _items_cache = None

    def __init__(self, ctx):
        self.ctx = ctx
        self.chat_log: list[dict] = []
        self.msg_id_counter: int = 0
        self._current_ap_msg_type: str = "default"
        self._current_ap_msg_priority: bool = False
        self._in_traceback = False

    def add_in_game_message(self, message: str, color_string: str = None):
        """Handles incoming raw text vectors submitted straight from the game runtime environment."""
        if color_string:
            try:
                rgb = [int(x) for x in color_string.split()]
                if len(rgb) == 3:
                    hex_color = '#%02x%02x%02x' % (rgb[0], rgb[1], rgb[2])
                    self.on_print_silently(message, [{"text": message, "color": hex_color}])
                    return
            except Exception:
                pass
        self.on_print_silently(message)

    def on_print(self, text: str):
        """Redirects default standard terminal prints straight through the silent pipeline."""
        self.on_print_silently(text, mirror_to_hud=False)

    def auto_color_text(self, text: str) -> str:
        # First, escape HTML characters in the plain text
        html_text = text.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
        
        is_server_msg = "[server]" in text.lower() or "[server]:" in text.lower()
        replacements = [] # list of tuple: (term, color)
        
        # 0. Match URLs, hosts with ports, or IP addresses to prevent partial colorization of "Archipelago" inside them
        try:
            urls = self._url_pattern.findall(text)
            for url in urls:
                if url:
                    replacements.append((url, "#77aaff"))
        except Exception:
            pass

        # 0b. Shield paths, filenames, and dotted identifiers to prevent inner words from being colored
        try:
            for pattern in self._shield_regexes:
                matches = pattern.findall(text)
                for match in matches:
                    if match and len(match) > 3:
                        replacements.append((match, "#888888"))
        except Exception:
            pass

        if not is_server_msg:
            # 1. Add Archipelago keywords (only listed once) if present in text
            ap_keywords = [
                ("Archipelago", "#ffd700"),
                ("Portal 2", "#77aaff"),
                ("Error", "#ff5555"),
                ("Warning", "#ffaa00"),
            ]
            for kw, color in ap_keywords:
                if kw in text:
                    replacements.append((kw, color))
                
            # 1b. Add dynamic Team #\d+ colorization based on team number
            try:
                team_colors = {
                    0: "#55ff55", # Lime Green
                    1: "#55aaff", # Sky Blue
                    2: "#ee82ee", # Violet
                    3: "#ffff55", # Yellow
                }
                team_matches = self._team_pattern.findall(text)
                for tm in team_matches:
                    num_match = self._team_num_pattern.search(tm)
                    if num_match:
                        t_num = int(num_match.group())
                        t_color = team_colors.get(t_num, "#ffd700") # Default to Gold
                        replacements.append((tm, t_color))
            except Exception:
                pass

        # 1c. Add dynamic tag colorization for quoted strings like ['AP'], ['DeathLink', 'AP']
        try:
            quoted_tags = self._quoted_tags_pattern.findall(text)
            for tag_tuple in quoted_tags:
                tag_word = tag_tuple[0] or tag_tuple[1]
                if tag_word:
                    replacements.append((f"'{tag_word}'", "#da70d6"))
                    replacements.append((f'"{tag_word}"', "#da70d6"))
        except Exception:
            pass

        if not is_server_msg:
            # 1d. Extract player/slot name from " (Team #" messages
            try:
                # Strategy A: Between "[Archipelago] " and "(Team #"
                idx_ap = text.find("[Archipelago] ")
                idx_team = text.find("(Team #")
                if idx_ap != -1 and idx_team != -1 and idx_team > idx_ap:
                    p_name = text[idx_ap + len("[Archipelago] "):idx_team].strip()
                    if p_name and len(p_name) >= 2:
                        replacements.append((p_name, "#ff7f50"))
                
                # Strategy B: Word before "(Team #"
                team_matches = self._team_mention_pattern.findall(text)
                for p_name in team_matches:
                    if p_name and len(p_name) >= 2:
                        replacements.append((p_name, "#ff7f50"))
            except Exception:
                pass

            # 2. Add slot/player names only if they are actually present in the text
            if hasattr(self.ctx, "player_names") and self.ctx.player_names:
                try:
                    for pid in self.ctx.player_names:
                        name = self.ctx.player_names[pid]
                        if name and name.lower() not in ["ap", "deathlink", "tracker", "bouncer", "webhost", "server", "client"]:
                            if len(name) >= 2 and name in text:
                                replacements.append((name, "#ff7f50"))
                except Exception:
                    pass
                    
            # 3. Add auth (slot name), username, and player's own slot name if present in text
            if hasattr(self.ctx, "auth") and self.ctx.auth:
                auth_name = self.ctx.auth
                if auth_name.lower() not in ["ap", "deathlink", "tracker", "bouncer", "webhost", "server", "client"]:
                    if len(auth_name) >= 2 and auth_name in text:
                        replacements.append((auth_name, "#ff7f50"))
            if hasattr(self.ctx, "username") and self.ctx.username:
                uname = self.ctx.username
                if uname.lower() not in ["ap", "deathlink", "tracker", "bouncer", "webhost", "server", "client"]:
                    if len(uname) >= 2 and uname in text:
                        replacements.append((uname, "#ff7f50"))
            if hasattr(self.ctx, "slot") and self.ctx.slot is not None:
                try:
                    name = self.ctx.player_names[self.ctx.slot]
                    if name and name.lower() not in ["ap", "deathlink", "tracker", "bouncer", "webhost", "server", "client"]:
                        if len(name) >= 2 and name in text:
                            replacements.append((name, "#ff7f50"))
                except Exception:
                    pass
                
            # 5. Add portal 2 map names or locations / items if they are present in text (using lazy class cache)
            if ConsoleLogManager._locations_cache is None:
                try:
                    from game.Locations import all_locations_table
                    ConsoleLogManager._locations_cache = list(all_locations_table.keys())
                except Exception:
                    ConsoleLogManager._locations_cache = []
                    
            for loc in ConsoleLogManager._locations_cache:
                if len(loc) > 3 and loc in text:
                    replacements.append((loc, "#00ff00"))
                
            if ConsoleLogManager._items_cache is None:
                try:
                    from game.mod_helpers.MapMenu import items_shortened
                    ConsoleLogManager._items_cache = list(items_shortened.keys())
                except Exception:
                    ConsoleLogManager._items_cache = []
                    
            for item in ConsoleLogManager._items_cache:
                if len(item) > 3 and item in text:
                    replacements.append((item, "#00ffff"))

        unique_replacements = {}
        for term, color in replacements:
            if term not in unique_replacements or len(term) > len(unique_replacements[term][0]):
                unique_replacements[term] = (term, color)
                
        sorted_replacements = sorted(unique_replacements.values(), key=lambda x: len(x[0]), reverse=True)
        
        placeholders = {}
        placeholder_idx = 0
        for term, color in sorted_replacements:
            # Build smart boundary constraints for word matches
            prefix = r"\b" if term[0].isalnum() else ""
            suffix = r"\b" if term[-1].isalnum() else ""
            
            # Match either an already replaced placeholder (to skip it) or our term case-insensitively with smart boundaries
            pattern = re.compile(r"(__AP_COLOR_PLACEHOLDER_\d+__)|" + prefix + r"(" + re.escape(term) + r")" + suffix, re.IGNORECASE)
            
            def repl(match):
                nonlocal placeholder_idx
                if match.group(1):
                    return match.group(1) # Keep existing placeholder untouched
                matched_text = match.group(2)
                placeholder = f"__AP_COLOR_PLACEHOLDER_{placeholder_idx}__"
                placeholders[placeholder] = f"<font color='{color}'>{matched_text}</font>"
                placeholder_idx += 1
                return placeholder
                
            html_text = pattern.sub(repl, html_text)
                
        for placeholder, replacement in placeholders.items():
            html_text = html_text.replace(placeholder, replacement)
            
        return html_text

    def on_print_silently(self, text: str, rich_data: list = None, html_text: str = None, mirror_to_hud: bool = False, from_logger: bool = False):
        # Traceback and technical dump sanitization for the in-game UI
        lines = text.split("\n")
        cleaned_lines = []
        for line in lines:
            stripped = line.strip()
            if not stripped:
                continue
            
            # Detect starting a traceback block
            if stripped.startswith("Traceback (most recent call last):") or ("[asyncio" in line and "Task exception was never retrieved" in line):
                self._in_traceback = True
                continue
                
            # If we are in a traceback, check if we hit the final exception name
            if self._in_traceback:
                is_exception_end = False
                if re.match(r"^[a-zA-Z0-9._]*(?:Error|Exception)(?::|\b)", stripped) or stripped.startswith("AssertionError"):
                    is_exception_end = True
                    
                if is_exception_end:
                    self._in_traceback = False # Exit traceback filtering state
                    # Translate this final exception line
                    if "ConnectionRefusedError:" in stripped:
                        match = re.search(r"ConnectionRefusedError:\s*(?:\[WinError \d+\]\s*)?(.+)", stripped, re.IGNORECASE)
                        if match:
                            line = f"Error: {match.group(1).strip()}"
                        else:
                            line = "Error: The remote computer refused the network connection."
                    elif "socket.gaierror:" in stripped or "getaddrinfo failed" in stripped:
                        line = "Error: The server address could not be resolved."
                    elif "ConnectionResetError:" in stripped or "forcibly closed" in stripped:
                        line = "Error: The connection was forcibly closed by the remote host."
                    elif "TimeoutError:" in stripped or "connection attempt failed" in stripped:
                        line = "Error: The connection attempt timed out."
                    elif "websockets.exceptions." in stripped:
                        line = "Error: A websocket protocol error occurred."
                    elif stripped.startswith("AssertionError"):
                        # Discard raw AssertionError entirely
                        continue
                else:
                    # Discard all traceback frames, source code lines, carets, etc.
                    continue
            
            # Also catch individual/standalone technical task dumps or file prints outside tracebacks
            if (stripped.startswith("File \"") or (stripped.startswith("File ") and "line " in stripped) or
                "^^^^" in stripped or
                stripped.startswith("future: <Task") or
                "coro=<server_loop()" in stripped or
                stripped.startswith("Task exception was never retrieved") or
                stripped == "AssertionError" or stripped.startswith("AssertionError:")):
                continue
                
            cleaned_lines.append(line)
            
        if not cleaned_lines:
            # Entire block was filtered out, swallow it for the in-game UI
            return
            
        text = "\n".join(cleaned_lines)

        is_processing = getattr(self.ctx, "is_processing_received_cmd", False)
        is_death_event = False
        
        if rich_data:
            for part in rich_data:
                if isinstance(part, dict) and part.get("is_death"):
                    is_death_event = True
                    break

        text_lower = text.lower()
        if "deathlink:" in text_lower and not text.startswith("DEATHLINK:"):
             return 

        noise_filters = ["changed tags from", "now that you are connected", "room information", 
                         "server protocol", "permission", "hint cost", "!hint", "enter slot", "lost connection"]
        if any(noise.lower() in text_lower for noise in noise_filters):
            mirror_to_hud = False

        if not from_logger:
            if mirror_to_hud:
                if is_death_event:
                    logger.info(text, extra={"from_sync": True})
                else:
                    logger.info(f"[HUD] {text}", extra={"from_sync": True})
            else:
                if not any(x in text for x in ["[Archipelago]", "[HUD]", "DEATHLINK:", "Connection to Portal 2", "Disconnected from Portal 2"]):
                    logger.info(f"[Archipelago] {text}", extra={"from_sync": True})
                else:
                    logger.info(text, extra={"from_sync": True})
        
        logger.debug(f"Notification: {text}")

        if rich_data and not html_text:
            has_rich_types = False
            for part in rich_data:
                if isinstance(part, dict) and part.get("type") in ["player_id", "player_name", "item_id", "item_name", "location_id", "location_name", "entrance_id"]:
                    has_rich_types = True
                    break
            
            if has_rich_types:
                color_map = {
                    "player_id": "#ff7f50", "player_name": "#ff7f50", "magenta": "#ee82ee",
                    "item_id": "#00ffff", "item_name": "#00ffff", "cyan": "#00ffff",
                    "location_id": "#00ff00", "location_name": "#00ff00", "green": "#00ff00",
                    "entrance_id": "#da70d6", "gold": "#ffd700", "yellow": "#ffff00", "red": "#ff0000", "blue": "#0000ff"
                }
                html_text = ""
                for part in rich_data:
                    p_text = part.get("text", "") if isinstance(part, dict) else str(part)
                    p_type = part.get("type") if isinstance(part, dict) else None
                    p_color = part.get("color") if isinstance(part, dict) else None
                    color = color_map.get(p_type) or color_map.get(p_color) or p_color
                    html_text += f"<font color='{color}'>{p_text}</font>" if color else p_text
            else:
                html_text = self.auto_color_text(text)
        elif not html_text:
            html_text = self.auto_color_text(text)

        self.msg_id_counter += 1
        self.chat_log.append({
            "id": self.msg_id_counter, 
            "text": text,
            "html": html_text if html_text else text,
            "data": rich_data,
            "type": "text" if rich_data is None else "json",
            "priority": mirror_to_hud,  
            "ap_msg_type": self._current_ap_msg_type if not is_death_event else "deathlink",
            "time": time.time(),
            "muted": is_processing
        })
        
        if len(self.chat_log) > 100:
            self.chat_log.pop(0)

    def print_json(self, data: typing.List[typing.Dict[str, str]], mirror_to_hud: bool = False):
        """Translates multiworld data packages tracking structural components into human-readable strings."""
        resolved_data = []
        is_trap_msg = False 
        
        for part in data:
            if not isinstance(part, dict):
                resolved_data.append(part)
                continue
                
            new_part = part.copy()
            text = part.get("text", "")
            part_type = part.get("type")
            
            try:
                owner_id = part.get("player", self.ctx.slot)

                if part_type == "player_id":
                    new_part["text"] = self.ctx.player_names[int(text)]
                elif part_type == "item_id":
                    item_name = self.ctx.item_names.lookup_in_slot(int(text), owner_id)
                    new_part["text"] = item_name
                    
                    trap_cmd = handle_trap(item_name)
                    if trap_cmd and not getattr(self.ctx, "is_processing_received_cmd", False):
                        new_part["is_trap"] = True
                        is_trap_msg = True
                        
                elif part_type == "location_id":
                    new_part["text"] = self.ctx.location_names.lookup_in_slot(int(text), owner_id)
            except Exception:
                pass 
            
            resolved_data.append(new_part)

        text = "".join(part.get("text", "") if isinstance(part, dict) else str(part) for part in resolved_data)
        
        if getattr(self.ctx, "is_processing_received_cmd", False):
            mirror_to_hud = False
            is_trap_msg = False

        self.on_print_silently(text, resolved_data, mirror_to_hud=(mirror_to_hud or is_trap_msg))

    def on_print_json(self, args: dict):
        """Determines incoming context messaging metadata flags layout categories."""
        ap_msg_type = "default"
        priority = False
        msg_type = args.get("type", "")
        
        if msg_type == "ItemSend":
            receiving = args.get("receiving", 0)
            
            finder = 0
            for part in args.get("data", []):
                if isinstance(part, dict) and part.get("type") == "player_id":
                    try:
                        finder = int(part.get("text", 0))
                    except ValueError:
                        pass
                    break 
            
            if receiving == self.ctx.slot and finder == self.ctx.slot:
                priority = True
                ap_msg_type = "found"
            elif receiving == self.ctx.slot:
                priority = True
                ap_msg_type = "receive"
            elif finder == self.ctx.slot:
                priority = True
                ap_msg_type = "send"
                
        elif msg_type == "Hint":
            for part in args.get("data", []):
                if isinstance(part, dict) and part.get("type") == "player_id":
                    try:
                        if int(part.get("text", 0)) == self.ctx.slot:
                            priority = True
                            ap_msg_type = "hint"
                            break
                    except ValueError:
                        pass
        elif msg_type == "Goal":
            priority = True
            ap_msg_type = "goal"
            
        text_lower = args.get("text", "").lower()
        if "trap" in text_lower:
            priority = True
            ap_msg_type = "trap"

        self._current_ap_msg_type = ap_msg_type
        self._current_ap_msg_priority = priority
        
        if "data" in args:
            self.print_json(args["data"], mirror_to_hud=priority)
        else:
            text = args.get("text", "")
            if text:
                self.on_print_silently(text, mirror_to_hud=priority)
                
        self._current_ap_msg_type = "default"
        self._current_ap_msg_priority = False

    def trigger_go_mode(self):
        """Announces that Go Mode has been reached (all requirements met)."""
        self._current_ap_msg_type = "go_mode"
        self._current_ap_msg_priority = True
        self.on_print_silently("GO MODE: All victory conditions have been met!", mirror_to_hud=True)
        self._current_ap_msg_type = "default"
        self._current_ap_msg_priority = False
