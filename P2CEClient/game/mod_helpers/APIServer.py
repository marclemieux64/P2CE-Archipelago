import copy
import os
import sys
import argparse
import asyncio
import logging
import time
import typing
import json
from urllib.parse import parse_qs
import hashlib
import worlds

# --- STANDALONE FIX ---
archipelago_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', '..'))
if archipelago_root not in sys.path:
    sys.path.insert(0, archipelago_root)

os.environ['SKIP_REQUIREMENTS_UPDATE'] = '1'

from CommonClient import CommonContext, server_loop, ClientCommandProcessor, logger, gui_enabled
from NetUtils import ClientStatus, NetworkItem
from Utils import async_start, init_logging

import worlds
from game.mod_helpers.ItemHandling import add_ratman_commands, handle_item, handle_map_start, handle_trap, portal_gun_upgrade_not_inplace, potatos_not_inplace
from game.mod_helpers.MapMenu import Menu
from game.mod_helpers.Notifications import NotificationManager
from game.mod_helpers.DeathLinkHandler import DeathLinkHandler
from game.client.DeathMessages import get_death_message
from game.Locations import location_names_to_map_codes, map_codes_to_location_names, wheatley_maps_to_monitor_names, all_locations_table, wheatley_monitor_table, ratman_den_locations_table
from game.Options import GameModeOption

# Helper to construct network data package statically for client/API validation without importing Portal2World generator
def get_portal2_data_package():
    from game.Items import item_table
    from game.Locations import all_locations_table, location_groups
    
    item_name_to_id = {name: data.id for name, data in item_table.items() if data.id}
    location_name_to_id = {name: data.id for name, data in all_locations_table.items() if data.id}
    
    sorted_item_name_groups = {"Everything": sorted(item_name_to_id.keys())}
    sorted_location_name_groups = {
        name: sorted(location_groups[name]) for name in sorted(location_groups.keys())
    }
    sorted_location_name_groups["Everywhere"] = sorted(location_name_to_id.keys())
    
    res = {
        "item_name_groups": sorted_item_name_groups,
        "item_name_to_id": item_name_to_id,
        "location_name_groups": sorted_location_name_groups,
        "location_name_to_id": location_name_to_id,
    }
    
    import hashlib
    from NetUtils import encode
    res["checksum"] = hashlib.sha1(encode(res).encode()).hexdigest()
    return res

worlds.network_data_package["games"]["Portal 2"] = get_portal2_data_package()

logger = logging.getLogger("Portal2Client")

class Portal2CommandProcessor(ClientCommandProcessor):
    def __init__(self, ctx: CommonContext):
        super().__init__(ctx)

    def _cmd_help(self, *args):
        self.output("Portal 2 Archipelago Client Commands:")
        super()._cmd_help()

    def _cmd_check_connection(self):
        """Responds with the status of the client's connection to the Portal 2 mod"""
        self.ctx.alert_game_connection()

    def _cmd_command(self, *command):
        """Sends a command to the game. Should not be used unless you get softlocked"""
        self.ctx.command_queue.append(' '.join(command) + "\n")

    def _cmd_deathlink(self):
        """Toggles death link for this client"""
        self.ctx.death_link_active = not self.ctx.death_link_active
        async_start(self.ctx.update_death_link(self.ctx.death_link_active), "set_deathlink")
        self.output(f"Death link has been {'enabled' if self.ctx.death_link_active else 'disabled'}")

    def _cmd_refresh_menu(self):
        """Refreshed the in game menu in case of maps being inaccessible when they should be"""
        self.ctx.refresh_menu()

    def _cmd_received(self):
        """Lists all items received"""
        self.ctx.is_processing_received_cmd = True
        try:
            super()._cmd_received()
        finally:
            self.ctx.is_processing_received_cmd = False

    def _cmd_message_in_game(self, message: str, *color_string):
        """Send a message to be displayed in game (only works while in a map)."""
        if len(color_string) == 3:
            self.ctx.notifier.add_in_game_message(message, ' '.join(color_string))
        else:
            self.ctx.notifier.add_in_game_message(message)

    def _cmd_needed(self, *location_name):
        """Get the requirements for the map separated by all requirements and ones not yet acquired"""
        message = "Location not found, use /locations to get a list of locations"
        location_name_str = ' '.join(location_name)
        for location in location_names_to_map_codes.keys():
            if location_name_str in location:
                requirements = all_locations_table[location].required_items
                requirements_not_collected = list(set(self.ctx.item_list) & set(requirements))
                requirements.sort()
                requirements_not_collected.sort()

                still_needed = "All items acquired" if not requirements_not_collected else f"Still needed: \n{', '.join(requirements_not_collected)}"
                message = (f"Required Items: \n{', '.join(requirements)}\n"
                           f"{still_needed}")
                break
        self.output(message)

    def output(self, text: str):
        self.ctx.on_print(text)

class Portal2Context(CommonContext):
    command_processor = Portal2CommandProcessor
    game_connection_task: typing.Optional["asyncio.Task[None]"] = None
    
    def __init__(self, server_address: str = None, password: str = None):
        self.notifier = NotificationManager(self)
        self.deathlink_handler = DeathLinkHandler(self)
        self.api_server = APIServer(self)
        
        self.is_processing_received_cmd = False
        self.item_list = []
        self.item_remove_commands = []
        self.command_queue = []
        self.game_message_queue = []
        self.completed_maps = set()
        
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
                # Prevent duplicate logging in game console for messages already logged/handled
                if getattr(record, "from_sync", False) or any(x in record.msg for x in ["[HUD]", "DEATHLINK:", "Connection to Portal 2", "Disconnected from Portal 2"]):
                    return
                try:
                    msg = self.format(record)
                    if "Connecting to Archipelago server at" in msg:
                        current_time = time.time()
                        last_time = getattr(self.ctx, "last_connect_log_time", 0.0)
                        if current_time - last_time < 3.0:
                            return
                        self.ctx.last_connect_log_time = current_time
                    if getattr(self.ctx, 'loop', None):
                        msg_lower = msg.lower()
                        noise_keywords = ["serving on", "connected to", "logged in", "connecting to", "connection closed", 
                                          "room information", "server protocol", "permission", "hint cost", "!hint", "enter slot", "lost connection"]
                        
                        if any(noise.lower() in msg_lower for noise in noise_keywords):
                            self.ctx.loop.call_soon_threadsafe(self.ctx.notifier.on_print_silently, msg, None, None, False, True)
                            return

                        self.ctx.loop.call_soon_threadsafe(self.ctx.notifier.on_print_silently, msg, None, None, False, True)
                except Exception:
                    pass

        self.panorama_handler = PanoramaLogHandler(self)
        self.panorama_handler.setFormatter(logging.Formatter('%(message)s'))
        logging.getLogger().addHandler(self.panorama_handler)

        super().__init__(server_address, password)

    def flush_init_logs(self):
        if hasattr(self, 'temp_handler') and self.temp_handler:
            for msg in self.temp_handler.queue:
                self.notifier.on_print_silently(msg, from_logger=True)
            logging.getLogger().removeHandler(self.temp_handler)
            self.temp_handler = None

    game = "Portal 2"
    items_handling = 0b111 

    HOST = "127.0.0.1"
    PORT = 3000

    death_link_active = False
    goal_map_code = ""
    sender_active : bool = False
    listener_active : bool = False
    location_name_to_id: dict[str, int] = None
    menu: Menu = None
    last_api_update: float = 0
    has_ever_connected: bool = False
    deferred_events: list[dict] = []
    pending_validation_events: list[dict] = []
    ping_sent_time: float = 0

    def execute_in_game_event(self, event_data: dict):
        self.pending_validation_events.append(event_data)
        if self.ping_sent_time == 0:
            self.command_queue.append("ping\n")
            self.ping_sent_time = time.time()

    def process_event(self, ev: dict):
        if ev.get("text"):
            self.notifier.on_print_silently(ev["text"], ev.get("data"), mirror_to_hud=ev.get("mirror_to_hud", False))
            
        if ev.get("command"):
            async def delayed_action():
                await asyncio.sleep(4.0) 
                self.command_queue.append(ev["command"])
            
            if self.loop:
                self.loop.create_task(delayed_action())
            else:
                self.command_queue.append(ev["command"])

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
            self.notifier.on_print(f"Error: {e}")

    def request_hints_sync(self):
        if self.team is not None and self.slot:
            key = f"_read_hints_{self.team}_{self.slot}"
            async_start(self.send_msgs([{"cmd": "Get", "keys": [key]}]))

    def alert_game_connection(self):
        if self.check_game_connection():
            self.notifier.on_print_silently("Connection to Portal 2 is up and running", mirror_to_hud=False)
            logger.info("Connection to Portal 2 is up and running")
        else:
            msg = f"Disconnected from Portal 2. Make sure the mod is open and the `-netconport {self.PORT}` launch option is set"
            self.notifier.on_print_silently(msg, mirror_to_hud=False)
            logger.info(msg)

    def update_menu(self, location_id: int = None):
        if self.menu and location_id is not None:
            self.menu.complete_check(location_id)

    def refresh_menu(self):
        if not self.menu:
            return
        for location_id in self.checked_locations:
            self.menu.complete_check(location_id)
        self.update_menu()

    def on_print(self, text: str):
        self.notifier.on_print(text)

    def output(self, text: str):
        self.notifier.on_print(text)
        
    def on_print_json(self, args: dict):
        self.notifier.on_print_json(args)

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
                    if self.ping_sent_time > 0 and (time.time() - self.ping_sent_time) > 1.5:
                        if self.pending_validation_events:
                            self.deferred_events.extend(self.pending_validation_events)
                            self.pending_validation_events.clear()
                        self.ping_sent_time = 0
                    
                    while self.command_queue:
                        cmd = self.command_queue.pop(0)
                        if cmd:
                            writer.write(cmd.encode())
                            await writer.drain()

                    try:
                        data = await asyncio.wait_for(reader.read(4096), timeout=0.1)
                        if not data:
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
                        self.notifier.add_in_game_message(f"Error reading from Portal 2: {e}", "error")
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

    def send_level_begin_commands(self):
        if self.item_remove_commands:
            self.command_queue.append(f"{';'.join(self.item_remove_commands)}\n")

    async def handle_message(self, message: str):
        msg_lower = message.lower()
        
        if message.startswith("deathlink_pong_ready"):
            self.deathlink_handler.process_pong()
            return

        if "client ping times" in msg_lower or "ms :" in msg_lower or "ping:" in msg_lower:
            if self.ping_sent_time > 0:
                if self.pending_validation_events:
                    for ev in self.pending_validation_events:
                        self.process_event(ev)
                    self.pending_validation_events.clear()
                self.ping_sent_time = 0
            return

        if message.startswith("map_name:"):
            map_name = message.split(':', 1)[1]
            self.send_level_begin_commands()
            self.command_queue += handle_map_start(map_name, self.item_list, self.get_wheatley_monitor_names(self.checked_locations), self.get_ratman_den_names(self.checked_locations))
            
            if self.deferred_events:
                for ev in self.deferred_events:
                    self.process_event(ev)
                self.deferred_events.clear()
            
            if self.pending_validation_events:
                for ev in self.pending_validation_events:
                    self.process_event(ev)
                self.pending_validation_events.clear()
                self.ping_sent_time = 0

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
                self.notifier.on_print_silently(death_message, fake_data, mirror_to_hud=True)

    async def handle_goal_completion(self):
        if getattr(self, 'finished_game', False):
            return
        self.finished_game = True
        await self.send_msgs([{"cmd": "StatusUpdate", "status": ClientStatus.CLIENT_GOAL}])

    def on_deathlink(self, data: typing.Dict[str, typing.Any]):
        cause = data.get("cause", "A player died.")
        self.deathlink_handler.enqueue_death(cause)
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
        if cmd in ("RoomInfo", "RoomUpdate", "Connected"):
            if "location_check_points" in args:
                self.check_points = args["location_check_points"]

            def get_abs_cost(pct):
                total_locs = self.total_locations
                return max(1, int(pct * 0.01 * total_locs)) if pct and total_locs else 0

            if "hint_points" in args:
                self.hint_points = args["hint_points"]
                pct = getattr(self, "hint_cost", 0)
                cost = get_abs_cost(pct)
                check_pts = getattr(self, "check_points", 1)
                if cost > 0:
                    self.hints_used = max(0, (check_pts * len(self.checked_locations) - self.hint_points) // cost)
                else:
                    hkey = f"_read_hints_{self.team}_{self.slot}"
                    self.hints_used = len(self.stored_data.get(hkey, []))

            if "hint_cost" in args:
                new_pct = args["hint_cost"]
                old_pct = getattr(self, "hint_cost", 0)
                if new_pct != old_pct and "hint_points" not in args:
                    check_pts = getattr(self, "check_points", 1)
                    hints_used = getattr(self, "hints_used", 0)
                    new_cost = get_abs_cost(new_pct)
                    self.hint_points = check_pts * len(self.checked_locations) - new_cost * hints_used
                self.hint_cost = new_pct

        def update_item_list():
            from game.mod_helpers.MapMenu import items_shortened
            
            full_list = list(items_shortened.keys())
            recv_names = [self.item_names.lookup_in_game(i.item, self.game) for i in self.items_received]
            self.item_list = list(set(full_list) - set(recv_names))
            self.refresh_menu()
            
            finale_loc_name = map_codes_to_location_names.get("sp_a4_finale4")
            if finale_loc_name and finale_loc_name in all_locations_table:
                requirements = all_locations_table[finale_loc_name].required_items
                missing = [item for item in requirements if item in self.item_list]
                
                if not missing and not getattr(self, "go_mode_announced", False):
                    self.go_mode_announced = True
                    self.notifier.trigger_go_mode()

        if cmd == "Retrieved":
            if f"_read_item_name_groups_{self.game}" in args["keys"]:
                self.item_list = args["keys"][f"_read_item_name_groups_{self.game}"]["Everything"]
            update_item_list()
            self.update_item_remove_commands()
            
            hkey = f"_read_hints_{self.team}_{self.slot}"
            if hkey in args["keys"]:
                self.notifier.process_hints(args["keys"][hkey])

        if cmd == "ReceivedItems":
            index = args["index"]
            for item in args["items"]:
                if (item.flags & 0b100):
                    if not self.is_processing_received_cmd:
                        trap_cmd = handle_trap(self.item_names.lookup_in_game(item.item, self.game))
                        if trap_cmd:
                            self.execute_in_game_event({"command": trap_cmd + "\n"})
                index += 1
            
            super().on_package(cmd, args)
            update_item_list()
            self.update_item_remove_commands()
            return
            
        if cmd == "PrintJSON":
            if "type" in args:
                if args["type"] == "ItemSend" and args["receiving"] == self.slot:
                    item: NetworkItem = args["item"]
                    text = self.parse_message(args["data"], sending = item.player)
                elif args["type"] == "Goal":
                    text = self.parse_message(args["data"])
                else:
                    if args["type"] == "Collect":
                        self.update_menu()
                    return 
                self.notifier.add_in_game_message(text)
        
        super().on_package(cmd, args)
        
        if cmd == "Connected":
            self.completed_maps.clear() 
            self.go_mode_announced = False
            self.notifier.reset()
            
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
            base_title = "Portal 2 Archipelago Client"
            def __init__(self, ctx):
                super().__init__(ctx)
                self.icon = r"worlds/portal2/data/Portalpelago.png"

        return Portal2TextManager
    
    async def shutdown(self):
        self.server_address = ""
        self.username = None
        self.password = None
        self.cancel_autoreconnect()
        if self.server and getattr(self.server, "socket", None) and not self.server.socket.closed:
            await self.server.socket.close()
        if getattr(self, "server_task", None):
            await self.server_task
        if getattr(self, "game_connection_task", None):
            self.game_connection_task.cancel()
        if self.deathlink_handler:
            self.deathlink_handler.stop()

        while self.input_requests > 0:
            self.input_queue.put_nowait(None)
            self.input_requests -= 1
        self.keep_alive_task.cancel()
        if getattr(self, "ui_task", None):
            await self.ui_task
        if getattr(self, 'input_task', None):
            self.input_task.cancel()

    async def get_username(self):
        if not self.auth:
            self.auth = self.username
            if not self.auth:
                logger.info('Enter slot name:')
                self.auth = await self.console_input()
                
                # Update the log message in self.notifier.chat_log
                for entry in reversed(self.notifier.chat_log):
                    if "Enter slot name:" in entry["text"]:
                        new_text = f"Enter slot name: {self.auth}"
                        entry["text"] = new_text
                        entry["html"] = self.notifier.auto_color_text(new_text)
                        break

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
    
    ctx.deathlink_handler.start()
    ctx.api_server.start()
    ctx.flush_init_logs()

    if gui_enabled and not args.nogui:
        ctx.run_gui()
    ctx.run_cli()
    
    await ctx.exit_event.wait()
    await ctx.shutdown()

def launch(*args: str) -> None:
    from .Launch import launch_portal_2_client
    launch_portal_2_client(*args)

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