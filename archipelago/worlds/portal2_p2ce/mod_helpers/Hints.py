import logging

logger = logging.getLogger("Portal2Client")

class HintManager:
    def __init__(self, ctx):
        self.ctx = ctx
        self.hint_log: list[dict] = []

    def reset(self):
        """Resets hint history tracking data upon a new session connection."""
        self.hint_log.clear()

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
                    "html": txt_html
                })
            except Exception as e:
                logger.error(f"Error processing hint: {e}")
                self.hint_log.append({
                    "found": h.get("found", False), 
                    "text": f"Hint: Item {h.get('item', '???')} at {h.get('location', '???')}"
                })
