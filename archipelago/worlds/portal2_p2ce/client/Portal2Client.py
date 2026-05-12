import copy
import os
import sys
import argparse
import asyncio
import logging
import time
import typing
import json

# --- STANDALONE FIX ---
archipelago_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', '..'))
if archipelago_root not in sys.path:
    sys.path.insert(0, archipelago_root)

os.environ['SKIP_REQUIREMENTS_UPDATE'] = '1'

from CommonClient import CommonContext, server_loop, ClientCommandProcessor, logger, gui_enabled
from NetUtils import ClientStatus, NetworkItem
from Utils import async_start, init_logging

import worlds
from worlds.portal2_p2ce import Portal2World
from worlds.portal2_p2ce.mod_helpers.ItemHandling import add_ratman_commands, handle_item, handle_map_start, handle_trap, portal_gun_upgrade_not_inplace, potatos_not_inplace
from worlds.portal2_p2ce.mod_helpers.MapMenu import Menu
from worlds.portal2_p2ce.client.DeathMessages import get_death_message
from worlds.portal2_p2ce.Locations import location_names_to_map_codes, map_codes_to_location_names, wheatley_maps_to_monitor_names, all_locations_table, wheatley_monitor_table, ratman_den_locations_table
from worlds.portal2_p2ce.Options import GameModeOption

worlds.network_data_package["games"]["Portal 2"] = Portal2World.get_data_package_data()

logger = logging.getLogger("Portal2Client")

class Portal2CommandProcessor(ClientCommandProcessor):
    def __init__(self, ctx: CommonContext):
        super().__init__(ctx)

    def _cmd_help(self, *args):
        self.output("Portal 2 Archipelago Client Commands:")
        super()._cmd_help()

    def _cmd_check_connection(self):
        self.ctx.alert_game_connection()

    def _cmd_command(self, *command):
        self.ctx.command_queue.append(' '.join(command) + "\n")

    def _cmd_deathlink(self):
        self.ctx.death_link_active = not self.ctx.death_link_active
        async_start(self.ctx.update_death_link(self.ctx.death_link_active), "set_deathlink")
        self.output(f"Death link has been {'enabled' if self.ctx.death_link_active else 'disabled'}")

    def _cmd_refresh_menu(self):
        self.ctx.refresh_menu()

    def _cmd_received(self):
        self.ctx.is_processing_received_cmd = True
        try:
            super()._cmd_received()
        finally:
            self.ctx.is_processing_received_cmd = False

    def _cmd_message_in_game(self, message: str, *color_string):
        if len(color_string) == 3:
            self.ctx.add_to_in_game_message_queue(message, ' '.join(color_string))
        else:
            self.ctx.add_to_in_game_message_queue(message)

    def _cmd_needed(self, *location_name):
        message = "Location not found, use /locations to get a list of locations"
        location_name_str = ' '.join(location_name)
        for location in location_names_to_map_codes.keys():
            if location_name_str in location:
                requirements = all_locations_table[location].required_items
                requirements_not_collected = list(set(self.ctx.item_list) & set(requirements))
                requirements.sort()
                requirements_not_collected.sort()

                message = ("Required Items: \n"
                           f"{', '.join(requirements)}\n"
                           f"{'All items acquired' if not requirements_not_collected else 'Still needed: \n' + ', '.join(requirements_not_collected)}")
                break
        self.output(message)

    def output(self, text: str):
        self.ctx.on_print(text)

class Portal2Context(CommonContext):
    command_processor = Portal2CommandProcessor
    game_connection_task: typing.Optional["asyncio.Task[None]"] = None
    
    def __init__(self, server_address: str = None, password: str = None):
        class QueuingLogHandler(logging.Handler):
            def __init__(self):
                super().__init__()
                self.queue = []
            def emit(self, record):
                self.queue.append(self.format(record))
        
        self.temp_handler = QueuingLogHandler()
        self.temp_handler.setFormatter(logging.Formatter('%(message)s'))
        logging.getLogger().addHandler(self.temp_handler)

        class PanoramaLogHandler(logging.Handler):
            def __init__(self, ctx):
                super().__init__()
                self.ctx = ctx

            def emit(self, record):
                if "[Archipelago]" in record.msg or "[HUD]" in record.msg:
                    return
                try:
                    msg = self.format(record)
                    if getattr(self.ctx, 'loop', None):
                        msg_lower = msg.lower()
                        noise_keywords = ["serving on", "connected to", "logged in", "connecting to", "connection closed", 
                                          "room information", "server protocol", "permission", "hint cost", "!hint", "enter slot", "lost connection"]
                        
                        if any(noise.lower() in msg_lower for noise in noise_keywords):
                            self.ctx.loop.call_soon_threadsafe(self.ctx.on_print_silently, msg, None, None, False)
                            return

                        self.ctx.loop.call_soon_threadsafe(self.ctx.on_print_silently, msg, None, None, False)
                except Exception:
                    pass

        self.panorama_handler = PanoramaLogHandler(self)
        self.panorama_handler.setFormatter(logging.Formatter('%(message)s'))
        logging.getLogger().addHandler(self.panorama_handler)

        super().__init__(server_address, password)

    def flush_init_logs(self):
        if hasattr(self, 'temp_handler') and self.temp_handler:
            for msg in self.temp_handler.queue:
                self.on_print_silently(msg)
            logging.getLogger().removeHandler(self.temp_handler)
            self.temp_handler = None

    game = "Portal 2"
    items_handling = 0b111 

    HOST = "127.0.0.1"
    PORT = 3000

    death_link_active = False
    goal_map_code = ""

    item_list: list[str] = []
    item_remove_commands: list[str] = []
    command_queue: list[str] = []
    game_message_queue: list[str] = []
    is_processing_received_cmd: bool = False

    sender_active : bool = False
    listener_active : bool = False
    completed_maps: set[str] = set()

    location_name_to_id: dict[str, int] = None
    menu: Menu = None
    
    chat_log: list[dict] = []
    hint_log: list[dict] = []
    last_api_update: float = 0
    has_ever_connected: bool = False
    _msg_id_counter: int = 0

    def on_input(self, command: str):
        command = command.strip()
        try:
            if getattr(self, "input_requests", 0) > 0:
                self.input_requests -= 1
                self.input_queue.put_nowait(command)
                return

            if command.startswith("/"):
                logger.debug(f"Executing client command: {command}")
                proc = self.command_processor(self)
                proc(command)
            
            elif command.startswith("!"):
                logger.info(f"Sending server command: {command}")
                async_start(self.send_msgs([{"cmd": "Say", "text": command}]))
            
            else:
                self.command_queue.append(command + "\n")
                
        except Exception as e:
            logger.error(f"Command Error ({command}): {e}")
            self.on_print(f"Error: {e}")

    def request_hints_sync(self):
        if self.team is not None and self.slot:
            key = f"_read_hints_{self.team}_{self.slot}"
            async_start(self.send_msgs([{"cmd": "Get", "keys": [key]}]))

    def alert_game_connection(self):
        if self.check_game_connection():
            self.on_print_silently("Connection to Portal 2 is up and running", mirror_to_hud=False)
        else:
            self.on_print_silently("Disconnected from Portal 2. Make sure the mod is open and the `-netconport 3000` launch option is set", mirror_to_hud=False)

    def on_print(self, text: str):
        self.on_print_silently(text, mirror_to_hud=False)

    def output(self, text: str):
        self.on_print(text)

    def on_print_silently(self, text: str, rich_data: list = None, html_text: str = None, mirror_to_hud: bool = False):
        print(f"[DEBUG] {text}")

        text_lower = text.lower()
        noise_filters = ["changed tags from", "now that you are connected", "room information", 
                         "server protocol", "permission", "hint cost", "!hint", "enter slot", "lost connection"]
        if any(noise.lower() in text_lower for noise in noise_filters):
            mirror_to_hud = False

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

        # --- NOUVELLE GESTION DU TAG AP ---
        ap_msg_type = getattr(self, "_current_ap_msg_type", "default")
        if getattr(self, "_current_ap_msg_priority", False):
            mirror_to_hud = True

        if "DeathLink" in text or "mort" in text_lower:
            mirror_to_hud = True
            ap_msg_type = "deathlink"
        elif "Trap" in text:
            mirror_to_hud = True
            ap_msg_type = "trap"

        if mirror_to_hud:
            logger.info(f"[HUD] {text}")

        self._msg_id_counter += 1
        no_notification = getattr(self, 'is_processing_received_cmd', False)
        
        self.chat_log.append({
            "id": self._msg_id_counter, 
            "text": text,
            "html": html_text if html_text else text,
            "data": rich_data,
            "type": "text" if rich_data is None else "json",
            "priority": mirror_to_hud,  
            "no_notification": no_notification,
            "ap_msg_type": ap_msg_type,
            "time": time.time()
        })
        if len(self.chat_log) > 100:
            self.chat_log.pop(0)

    def print_json(self, data: typing.List[typing.Dict[str, str]], mirror_to_hud: bool = False):
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
                owner_id = part.get("player", self.slot)

                if part_type == "player_id":
                    new_part["text"] = self.player_names[int(text)]
                elif part_type == "item_id":
                    item_name = self.item_names.lookup_in_slot(int(text), owner_id)
                    new_part["text"] = item_name
                    
                    trap_cmd = handle_trap(item_name)
                    if trap_cmd:
                        new_part["is_trap"] = True
                        is_trap_msg = True
                        if mirror_to_hud:
                            self.command_queue.append(trap_cmd)
                        
                elif part_type == "location_id":
                    new_part["text"] = self.location_names.lookup_in_slot(int(text), owner_id)
            except Exception:
                pass 
            
            resolved_data.append(new_part)

        text = "".join(part.get("text", "") if isinstance(part, dict) else str(part) for part in resolved_data)
        self.on_print_silently(text, resolved_data, mirror_to_hud=(mirror_to_hud or is_trap_msg))

    def on_print_json(self, args: dict):
        ap_msg_type = "default"
        priority = False
        msg_type = args.get("type", "")
        
        if msg_type == "ItemSend":
            receiving = args.get("receiving", 0)
            
            # On cherche qui a trouvé l'objet de manière sécurisée
            finder = 0
            for part in args.get("data", []):
                if isinstance(part, dict) and part.get("type") == "player_id":
                    try:
                        finder = int(part.get("text", 0))
                    except ValueError:
                        pass
                    break 
            
            if receiving == self.slot and finder == self.slot:
                priority = True
                ap_msg_type = "found"
            elif receiving == self.slot:
                priority = True
                ap_msg_type = "receive"
            elif finder == self.slot:
                priority = True
                ap_msg_type = "send"
                
        elif msg_type == "Hint":
            # Si notre ID de joueur est mentionné n'importe où dans l'indice, ça nous concerne !
            for part in args.get("data", []):
                if isinstance(part, dict) and part.get("type") == "player_id":
                    try:
                        if int(part.get("text", 0)) == self.slot:
                            priority = True
                            ap_msg_type = "hint"
                            break
                    except ValueError:
                        pass

        # Traps et Deathlink
        text_lower = args.get("text", "").lower()
        if "deathlink" in text_lower or "mort" in text_lower:
            priority = True
            ap_msg_type = "deathlink"
        elif "trap" in text_lower:
            priority = True
            ap_msg_type = "trap"

        # On applique le tag temporaire pour que la fonction d'enregistrement le capte
        self._current_ap_msg_type = ap_msg_type
        self._current_ap_msg_priority = priority
        
        # On demande à Archipelago de construire le texte final avec toutes les couleurs
        if "data" in args:
            self.print_json(args["data"], mirror_to_hud=priority)
        else:
            text = args.get("text", "")
            if text:
                self.on_print_silently(text, mirror_to_hud=priority)
                
        # On nettoie le tag une fois terminé
        self._current_ap_msg_type = "default"
        self._current_ap_msg_priority = False
    
    def update_menu(self, location_id: int = None):
        if self.menu and location_id is not None:
            self.menu.complete_check(location_id)

    def refresh_menu(self):
        if not self.menu:
            return
        for location_id in self.checked_locations:
            self.menu.complete_check(location_id)
        self.update_menu()

    def add_to_in_game_message_queue(self, message: str, color_string: str = None) -> None:
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

    async def p2_connection_loop(self):
        await asyncio.sleep(1)
        attempt_count = 0
        while not self.exit_event.is_set():
            try:
                attempt_count += 1
                reader, writer = await asyncio.open_connection(self.HOST, self.PORT)
                self.sender_active = True
                self.listener_active = True
                self.has_ever_connected = True
                attempt_count = 0 
                logger.info(f"Connected to Portal 2 netcon on {self.HOST}:{self.PORT}")
                self.alert_game_connection()

                while not self.exit_event.is_set():
                    while self.command_queue:
                        cmd = self.command_queue.pop(0)
                        if cmd:
                            logger.debug(f"Sending command to game: {cmd.strip()}")
                            writer.write(cmd.encode())
                            await writer.drain()

                    try:
                        data = await asyncio.wait_for(reader.read(4096), timeout=0.1)
                        if not data:
                            logger.warning("Portal 2 connection closed by peer")
                            break
                        
                        messages = data.decode(errors="ignore").replace("\'", "").split('\n')
                        for message in messages:
                            message = message.strip()
                            if message:
                                await self.handle_message(message)
                    except asyncio.TimeoutError:
                        pass
                    except Exception as e:
                        logger.error(f"Error reading from Portal 2: {e}")
                        self.add_to_in_game_message_queue(f"Error reading from Portal 2: {e}", "error")
                        break

            except ConnectionRefusedError:
                if self.has_ever_connected:
                    if attempt_count > 10:
                        logger.info("Game connection lost for 10s. Shutting down client...")
                        self.exit_event.set()
                        break
                
                if attempt_count <= 5:
                    logger.info(f"Waiting for Portal 2 to start on {self.HOST}:{self.PORT}... (Attempt {attempt_count})")
                else:
                    logger.warning(f"Connection refused on {self.HOST}:{self.PORT}. Is the game running with -netconport {self.PORT}?")
                self.sender_active = False
                self.listener_active = False
                await asyncio.sleep(1)
            except Exception as e:
                logger.error(f"Netcon Loop Error ({type(e).__name__}): {e}")
                self.sender_active = False
                self.listener_active = False
                await asyncio.sleep(1)
            finally:
                self.sender_active = False
                self.listener_active = False

    def start_api_server(self):
        import threading
        from http.server import BaseHTTPRequestHandler, HTTPServer
        from urllib.parse import parse_qs
        from worlds.portal2_p2ce.mod_helpers.MapMenu import items_shortened 
        client_self = self

        class APIHandler(BaseHTTPRequestHandler):
            def log_message(self, format, *args): pass 
            def do_OPTIONS(self):
                self.send_response(200); self.send_header('Access-Control-Allow-Origin', '*'); self.end_headers()

            def do_GET(self):
                # --- NOUVELLE ROUTE OPTIMISÉE ---
                if self.path == '/status_full':
                    is_conn = bool(client_self.server and client_self.server.socket and not client_self.server.socket.closed)
                    
                    missing_str = ""
                    if hasattr(client_self, "item_list"):
                        missing_str = "".join([items_shortened.get(i, "") for i in client_self.item_list])

                    full_data = {
                        "status": {
                            "connected": is_conn, 
                            "game_connected": client_self.check_game_connection(), 
                            "slot": client_self.slot, 
                            "checked_locations": list(client_self.checked_locations), 
                            "missing_items": missing_str, 
                            "hint_points": getattr(client_self, "hint_points", 0), 
                            "hint_cost": getattr(client_self, "hint_cost", 0), 
                            "logic_difficulty": getattr(client_self, "logic_difficulty", 0), # <--- AJOUT ICI
                            "menu": client_self.menu.to_dict() if client_self.menu else None
                        },
                        "chat": client_self.chat_log,
                        "hints": client_self.hint_log
                    }
                    
                    # On convertit en texte et on génère une empreinte unique (Hash)
                    json_body = json.dumps(full_data)
                    current_hash = str(hash(json_body))

                    # On envoie la réponse avec le Hash dans le header
                    self.send_response(200)
                    self.send_header('Content-Type', 'application/json')
                    self.send_header('Access-Control-Allow-Origin', '*')
                    self.send_header('X-Data-Hash', current_hash)
                    self.end_headers()
                    self.wfile.write(json_body.encode('utf-8'))
                    return

                # --- ANCIENNES ROUTES (Conservées pour éviter de casser le reste) ---
                if self.path == '/status':
                    is_conn = bool(client_self.server and client_self.server.socket and not client_self.server.socket.closed)
                    
                    missing_str = ""
                    if hasattr(client_self, "item_list"):
                        missing_str = "".join([items_shortened.get(i, "") for i in client_self.item_list])

                    self._send_json({
                        "connected": is_conn, 
                        "game_connected": client_self.check_game_connection(), 
                        "slot": client_self.slot, 
                        "checked_locations": list(client_self.checked_locations), 
                        "missing_items": missing_str, 
                        "hint_points": getattr(client_self, "hint_points", 0), 
                        "hint_cost": getattr(client_self, "hint_cost", 0), 
                        "menu": client_self.menu.to_dict() if client_self.menu else None
                    })
                elif self.path == '/chat':
                    self._send_json(client_self.chat_log)
                elif self.path == '/hints':
                    self._send_json(client_self.hint_log)
                else:
                    self.send_error(404)
            def do_POST(self):
                try:
                    content_length = int(self.headers.get('Content-Length', 0))
                    body = self.rfile.read(content_length).decode('utf-8')
                    
                    command = None
                    try:
                        data = json.loads(body)
                        command = data.get("command")
                    except json.JSONDecodeError:
                        data = parse_qs(body)
                        if "command" in data: command = data["command"][0]

                    if self.path == '/command' and command:
                        print(f"[UI] Commande reçue : {command}")
                        client_self.loop.call_soon_threadsafe(client_self.on_input, command)
                        self._send_json({"status": "ok"})
                    elif self.path == '/hints/refresh':
                        client_self.loop.call_soon_threadsafe(client_self.request_hints_sync)
                        self._send_json({"status": "ok"})
                    else: self.send_error(404)
                except Exception as e: self.send_error(500, str(e))

            def _send_json(self, d):
                body = json.dumps(d).encode('utf-8')
                self.send_response(200); self.send_header('Content-Type', 'application/json'); self.send_header('Access-Control-Allow-Origin', '*'); self.end_headers(); self.wfile.write(body)

        def run_server():
            try:
                server = HTTPServer(('0.0.0.0', 8910), APIHandler)
                server.serve_forever()
            except Exception as e: 
                print(f"API Server Error: {e}")

        threading.Thread(target=run_server, daemon=True).start()

    def send_level_begin_commands(self):
        for cmd in self.item_remove_commands:
            if cmd:
                self.command_queue.append(cmd + "\n")

    async def handle_message(self, message: str):
        if message.startswith("map_name:"):
            map_name = message.split(':', 1)[1]
            self.send_level_begin_commands()
            self.command_queue += handle_map_start(map_name, self.item_list, self.get_wheatley_monitor_names(self.checked_locations), self.get_ratman_den_names(self.checked_locations))

        elif message.startswith("map_complete:"):
            done_map = message.split(':', 1)[1]
            if done_map in self.completed_maps:
                return
            self.completed_maps.add(done_map)

            if done_map == self.goal_map_code:
                await self.handle_goal_completion()
            
            map_id = self.map_code_to_location_id(done_map)
            if map_id:
                await self.check_locations([map_id])
                self.update_menu(map_id)
        
        elif message.startswith("item_collected:"):
            item_collected = message.split(":", 1)[1]
            if item_collected in all_locations_table:
                check_id = all_locations_table[item_collected].id
                await self.check_locations([check_id])
                self.update_menu(check_id)
        
        elif message.startswith("monitor_break:"):
            map_name = message.split(":", 1)[1]
            if map_name in wheatley_maps_to_monitor_names:
                check_name = wheatley_maps_to_monitor_names[map_name]
                if check_name in all_locations_table:
                    check_id = all_locations_table[check_name].id
                    await self.check_locations([check_id])
                    self.update_menu(check_id)
        elif message.startswith("button_check:"):
            check_name = message.split(":", 1)[1]
            if check_name in all_locations_table:
                check_id = all_locations_table[check_name].id
                await self.check_locations([check_id])
                self.update_menu(check_id)
        
        elif message.startswith("send_deathlink"):
            if self.death_link_active and time.time() - getattr(self, 'last_death_link', 0) > 10:
                map_name = message.strip().split()[1]
                death_message = get_death_message(map_name, self.player_names[self.slot])
                
                await self.send_death(death_text=death_message)
                
                fake_data = [{"text": death_message, "is_death": True}]
                self.on_print_silently(death_message, fake_data, mirror_to_hud=True)

    async def handle_goal_completion(self):
        if getattr(self, 'finished_game', False):
            return
        self.finished_game = True
        await self.send_msgs([{"cmd": "StatusUpdate", "status": ClientStatus.CLIENT_GOAL}])

    def on_deathlink(self, data: typing.Dict[str, typing.Any]):
        self.command_queue.append("kill\n")
        
        cause = data.get("cause", "Un joueur est mort.")
        
        fake_data = [{"text": cause, "is_death": True}]
        self.on_print_silently(cause, fake_data, mirror_to_hud=True)
        
        return super().on_deathlink(data)

    def check_game_connection(self) -> bool:
        return self.sender_active and self.listener_active
    
    def location_id_to_map_code(self, location_id: str) -> str:
        location_name = self.location_names.lookup_in_game(location_id)
        if location_name in location_names_to_map_codes:
            return location_names_to_map_codes[location_name]
        return None
    
    def map_code_to_location_id(self, map_code: str):
        if map_code not in map_codes_to_location_names:
            return None
        location_name = map_codes_to_location_names[map_code]
        if not hasattr(self, 'location_name_to_id') or not self.location_name_to_id:
            return None
        if location_name not in self.location_name_to_id:
            return None
        return self.location_name_to_id[location_name]
    
    def get_wheatley_monitor_names(self, location_ids: list[int]) -> list[str]:
        monitors_checked = []
        for loc in location_ids:
            location_name = self.location_names.lookup_in_game(loc)
            if location_name in wheatley_monitor_table:
                monitors_checked.append(location_name)
        return monitors_checked
    
    def get_ratman_den_names(self, location_ids: list[int]) -> list[str]:
        dens_checked = []
        for loc in location_ids:
            location_name = self.location_names.lookup_in_game(loc)
            if location_name in ratman_den_locations_table:
                dens_checked.append(location_name)
        return dens_checked

    def handle_slot_data(self, slot_data: dict):
        if "death_link" in slot_data:
            self.death_link_active = slot_data["death_link"]
            async_start(self.update_death_link(self.death_link_active), "set_deathlink")

        if "goal_map_code" in slot_data:
            self.goal_map_code = slot_data["goal_map_code"]

        if "location_name_to_id" in slot_data:
            self.location_name_to_id = slot_data["location_name_to_id"]

        # --- NOUVEAU : Récupération de la difficulté logique ---
        if "logic_difficulty" in slot_data:
            self.logic_difficulty = slot_data["logic_difficulty"]
        else:
            self.logic_difficulty = 0

        if "chapter_dict" in slot_data:
            if "logic_difficulty" in slot_data:
                self.menu = Menu(slot_data["chapter_dict"], self, logic_difficulty=slot_data["logic_difficulty"])
            else:
                self.menu = Menu(slot_data["chapter_dict"], self)
        else:
            raise Exception("chapter_dict not found in slot data")
        
        if "game_mode" in slot_data:
            self.menu.is_open_world = slot_data["game_mode"] == GameModeOption.OPEN_WORLD
            
        if "wheatley_monitors" in slot_data:
            if slot_data["wheatley_monitors"]:
                self.menu.has_wheatley_monitors = True
            
        if "ratman_dens" in slot_data:
            if slot_data["ratman_dens"]:
                add_ratman_commands()
                self.menu.has_ratman_dens = True
                
        if "vitrified_doors" in slot_data:
            if slot_data["vitrified_doors"]:
                self.menu.has_vitrified_doors = True
        
        if "portal_gun_upgrade_inplace" not in slot_data:
            portal_gun_upgrade_not_inplace()
            
        if "potatos_inplace" not in slot_data:
            potatos_not_inplace()
        
        self.menu.generate_menu()
        self.refresh_menu()

    def on_package(self, cmd, args):
        if cmd in ("RoomInfo", "RoomUpdate"):
            if "hint_points" in args:
                self.hint_points = args["hint_points"]
            if "hint_cost" in args:
                self.hint_cost = args["hint_cost"]

        def update_item_list():
            if not getattr(self, "full_item_list_loaded", False):
                from worlds.portal2_p2ce.mod_helpers.MapMenu import items_shortened
                self.item_list = list(items_shortened.keys())
                self.full_item_list_loaded = True
                
            recv_names = [self.item_names.lookup_in_game(i.item, self.game) for i in self.items_received]
            self.item_list = list(set(self.item_list) - set(recv_names))
            self.refresh_menu()

        if cmd == "Retrieved":
            update_item_list()
            self.update_item_remove_commands()
            
            hkey = f"_read_hints_{self.team}_{self.slot}"
            if hkey in args["keys"]:
                raw_hints = args["keys"][hkey]
                self.hint_log = []
                for h in raw_hints:
                    try:
                        rec_id = h.get("receiving_player")
                        find_id = h.get("finding_player")
                        item_id = h.get("item")
                        loc_id = h.get("location")
                        
                        rec = self.player_names[rec_id]
                        find = self.player_names[find_id]
                        item_name = self.item_names.lookup_in_slot(item_id, rec_id)
                        loc_name = self.location_names.lookup_in_slot(loc_id, find_id)
                        
                        txt = f"<font color='#ff7f50'>{rec}</font>'s <font color='#00ffff'>{item_name}</font> is at <font color='#00ff00'>{loc_name}</font> in <font color='#ff7f50'>{find}</font>'s World"
                    except Exception: 
                        txt = f"Hint: Item {h.get('item', '???')} at {h.get('location', '???')}"
                    
                    self.hint_log.append({
                        "found": h.get("found", False), 
                        "text": txt
                    })
                print(f"[AP] {len(self.hint_log)} indices mis à jour.")

        if cmd == "ReceivedItems":
            index = args["index"]
            for item in args["items"]:
                if index >= len(self.items_received) and (item.flags & 0b100):
                    self.command_queue.append(handle_trap(self.item_names.lookup_in_game(item.item, self.game)) + "\n")
                index += 1
            super().on_package(cmd, args)
            update_item_list()
            self.update_item_remove_commands()
            return
        
        super().on_package(cmd, args)
        if cmd == "Connected":
            self.handle_slot_data(args["slot_data"])
            self.alert_game_connection()

    def parse_message(self, data: list[dict], sending: int | None = None) -> str:
        message = ""
        for part in data:
            text = part["text"]
            if "type" in part:
                if part["type"] == "item_id":
                    text = self.item_names.lookup_in_slot(int(text), self.slot)
                elif part["type"] == "location_id":
                    text = self.location_names.lookup_in_slot(int(text), sending)
                elif part["type"] == "player_id":
                    text = self.player_names[int(text)]
            message += text
        return message

    def update_item_remove_commands(self):
        temp_commands = []
        for item_name in self.item_list:
            item_commands = handle_item(item_name)
            if item_commands:
                temp_commands += item_commands
        self.item_remove_commands = temp_commands
        
    def make_gui(self):
        from kvui import GameManager

        class Portal2TextManager(GameManager):
            base_title = "Portal 2 Text Client"
            def __init__(self, ctx):
                super().__init__(ctx)
                self.icon = r"worlds/portal2/data/Portalpelago.png"

        return Portal2TextManager
    
    async def shutdown(self):
        self.server_address = ""
        self.username = None
        self.password = None
        self.cancel_autoreconnect()
        if self.server and self.server.socket and not self.server.socket.closed:
            await self.server.socket.close()
        if self.server_task:
            await self.server_task
        if self.game_connection_task:
            self.game_connection_task.cancel()

        while self.input_requests > 0:
            self.input_queue.put_nowait(None)
            self.input_requests -= 1
        self.keep_alive_task.cancel()
        if self.ui_task:
            await self.ui_task
        if getattr(self, 'input_task', None):
            self.input_task.cancel()

    async def server_auth(self, password_requested: bool = False) -> None:
        if password_requested and not self.password:
            await super().server_auth(password_requested)
        await self.get_username()
        await self.send_connect(game="Portal 2")

async def main(args: argparse.Namespace):
    ctx = Portal2Context(args.connect, args.password)
    ctx.loop = asyncio.get_running_loop()
    ctx.server_task = asyncio.create_task(server_loop(ctx), name="server loop")
    ctx.game_connection_task = asyncio.create_task(ctx.p2_connection_loop(), name="netcon loop")
    
    ctx.start_api_server()
    ctx.flush_init_logs()

    if gui_enabled and not args.nogui:
        ctx.run_gui()
    ctx.run_cli()
    
    await ctx.exit_event.wait()
    await ctx.shutdown()

def get_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Portal 2 Archipelago Standalone Client")
    parser.add_argument("connect", nargs="?", help="Address of the Archipelago server", default="")
    parser.add_argument("--password", help="Password for the Archipelago server", default=None)
    parser.add_argument("--nogui", help="Disable the GUI", action="store_true")
    return parser.parse_args()

if __name__ == "__main__":
    init_logging("Portal2Client", exception_logger="Portal2Client")
    args = get_args()
    try:
        asyncio.run(main(args))
    except KeyboardInterrupt:
        logger.info("Client closed by user.")