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
            if not isinstance(h, dict):
                continue
            try:
                rec_id = h.get("receiving_player")
                find_id = h.get("finding_player")
                item_id = h.get("item")
                loc_id = h.get("location")
                
                # Coercition de type sécurisée et double vérification d'index (int vs string)
                rec = self.ctx.player_names.get(int(rec_id)) or self.ctx.player_names.get(str(rec_id)) or f"Player {rec_id}"
                find = self.ctx.player_names.get(int(find_id)) or self.ctx.player_names.get(str(find_id)) or f"Player {find_id}"
                
                # Résilience multi-jeux complète pour parer aux ID inconnus des autres mondes
                try:
                    item_name = self.ctx.item_names.lookup_in_slot(int(item_id), int(rec_id))
                except Exception:
                    item_name = f"Item {item_id}"

                try:
                    loc_name = self.ctx.location_names.lookup_in_slot(int(loc_id), int(find_id))
                except Exception:
                    loc_name = f"Location {loc_id}"
                
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