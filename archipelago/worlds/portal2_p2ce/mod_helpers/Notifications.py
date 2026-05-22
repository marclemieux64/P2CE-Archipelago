import time
import typing
import logging

from worlds.portal2_p2ce.mod_helpers.ItemHandling import handle_trap

logger = logging.getLogger("Portal2Client")

class NotificationManager:
    def __init__(self, ctx):
        self.ctx = ctx
        self.chat_log: list[dict] = []
        self.hint_log: list[dict] = []
        self.msg_id_counter: int = 0
        self._current_ap_msg_type: str = "default"
        self._current_ap_msg_priority: bool = False

    def reset(self):
        """Resets hint history tracking data upon a new session connection."""
        self.hint_log.clear()

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

    def on_print_silently(self, text: str, rich_data: list = None, html_text: str = None, mirror_to_hud: bool = False):
        # 1. Define mandatory variables at the very top
        is_processing = getattr(self.ctx, "is_processing_received_cmd", False)
        is_death_event = False
        
        # 2. Check for Death event early
        if rich_data:
            for part in rich_data:
                if isinstance(part, dict) and part.get("is_death"):
                    is_death_event = True
                    break

        # 3. Filter noise (Suppress standard client announcements for DeathLink)
        text_lower = text.lower()
        if "deathlink:" in text_lower and not text.startswith("DEATHLINK:"):
             return 

        noise_filters = ["changed tags from", "now that you are connected", "room information", 
                         "server protocol", "permission", "hint cost", "!hint", "enter slot", "lost connection"]
        if any(noise.lower() in text_lower for noise in noise_filters):
            mirror_to_hud = False

        # 4. Handle Logging and HUD Printing (Single source of truth)
        if mirror_to_hud:
            if is_death_event:
                # DeathLink print: Clean, no prefix, only once
                logger.info(text)
            else:
                # Normal HUD print: with prefix
                logger.info(f"[HUD] {text}")
        
        # Internal debug logging
        logger.debug(f"Notification: {text}")

        # 5. Process HTML/Rich Text for API
        if rich_data and not html_text:
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

        # 6. Update internal logs for API/UI
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
        
    def process_hints(self, raw_hints: list):
        self.hint_log.clear()
        for h in raw_hints:
            try:
                rec_id = h.get("receiving_player")
                find_id = h.get("finding_player")
                item_id = h.get("item")
                loc_id = h.get("location")
                
                # Fetching names safely from context
                rec = self.ctx.player_names.get(rec_id, str(rec_id))
                find = self.ctx.player_names.get(find_id, str(find_id))
                item_name = self.ctx.item_names.lookup_in_slot(item_id, rec_id)
                loc_name = self.ctx.location_names.lookup_in_slot(loc_id, find_id)
                
                # Create the HTML string with colors
                txt_html = (f"<font color='#ff7f50'>{rec}</font>'s "
                            f"<font color='#00ffff'>{item_name}</font> is at "
                            f"<font color='#00ff00'>{loc_name}</font> in "
                            f"<font color='#ff7f50'>{find}</font>'s World")
                
                # Plain text fallback
                txt_plain = f"{rec}'s {item_name} is at {loc_name} in {find}'s World"
                
                self.hint_log.append({
                    "found": h.get("found", False), 
                    "text": txt_plain,
                    "html": txt_html # This is what your TS code looks for
                })
            except Exception as e:
                logger.error(f"Error processing hint: {e}")
                self.hint_log.append({
                    "found": h.get("found", False), 
                    "text": f"Hint: Item {h.get('item', '???')} at {h.get('location', '???')}"
                })