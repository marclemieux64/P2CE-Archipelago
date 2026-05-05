from .. import Portal2World
import worlds
# Manually overwrite the "Portal 2" data package with our mod's data
# This allows us to use our mod's logic while still connecting to the server as "Portal 2"
worlds.network_data_package["games"]["Portal 2"] = Portal2World.get_data_package_data()

from argparse import Namespace
import os
import asyncio
import logging
import sys
import time
import typing

os.environ['SKIP_REQUIREMENTS_UPDATE'] = '1'

from CommonClient import CommonContext, server_loop, ClientCommandProcessor, logger, gui_enabled
from NetUtils import ClientStatus, NetworkItem
from Utils import async_start, init_logging

from ..mod_helpers.ItemHandling import add_ratman_commands, handle_item, handle_map_start, handle_trap, portal_gun_upgrade_not_inplace, potatos_not_inplace
from ..mod_helpers.MapMenu import Menu
from .DeathMessages import get_death_message
from ..Locations import location_names_to_map_codes, map_codes_to_location_names, wheatley_maps_to_monitor_names, all_locations_table, wheatley_monitor_table, ratman_den_locations_table
from ..Options import GameModeOption

import json

if __name__ == "__main__":
    init_logging("Portal2Client", exception_logger="Portal2Client")
    
logger = logging.getLogger("Portal2Client")

class Portal2CommandProcessor(ClientCommandProcessor):
    def __init__(self, ctx: CommonContext):
        super().__init__(ctx)

    def _cmd_help(self, *args):
        """Display this help message"""
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
        self.output(f"Death link has been {"enabled" if self.ctx.death_link_active else "disabled"}")

    def _cmd_refresh_menu(self):
        """Refreshed the in game menu in case of maps being inaccessible when they should be"""
        self.ctx.refresh_menu()

    def _cmd_message_in_game(self, message: str, *color_string):
        """Send a message to be displayed in game (only works while in a map). 
        message can be any text 
        color_string is an optional RGB string e.g. 255 100 0"""
        if len(color_string) == 3:
            self.ctx.add_to_in_game_message_queue(message, ' '.join(color_string))
        else:
            self.ctx.add_to_in_game_message_queue(message)

    def _cmd_needed(self, *location_name):
        """Get the requirements for the map separated by all requirements and ones not yet acquired"""
        # Check if map name is in the list of map names
        message = "Location not found, use /locations to get a list of locations"
        location_name = ' '.join(location_name)
        for location in location_names_to_map_codes.keys():
            if location_name in location:
                requirements = all_locations_table[location].required_items
                requirements_not_collected = list(set(self.ctx.item_list) & set(requirements))
                requirements.sort()
                requirements_not_collected.sort()

                message = ("Required Items: \n"
                           f"{", ".join(requirements)}\n"
                           f"{"All items acquired" if not requirements_not_collected else "Still needed: \n" + ", ".join(requirements_not_collected)}")
                break
        self.output(message)

    def output(self, text: str):
        self.ctx.on_print(text)

class Portal2Context(CommonContext):
    command_processor = Portal2CommandProcessor
    game_connection_task: typing.Optional["asyncio.Task[None]"] = None
    
    def __init__(self, server_address: str = None, password: str = None):
        # 1. Setup a temporary handler to catch logs during initialization (before loop is ready)
        class QueuingLogHandler(logging.Handler):
            def __init__(self):
                super().__init__()
                self.queue = []
            def emit(self, record):
                self.queue.append(self.format(record))
        
        temp_handler = QueuingLogHandler()
        temp_handler.setFormatter(logging.Formatter('%(message)s'))
        logging.getLogger().addHandler(temp_handler)

        super().__init__(server_address, password)
        
        # 2. Setup the real handler that sends to the Panorama UI
        class PanoramaLogHandler(logging.Handler):
            def __init__(self, ctx):
                super().__init__()
                self.ctx = ctx
            def emit(self, record):
                try:
                    msg = self.format(record)
                    # Use call_soon_threadsafe because logging can happen from any thread
                    self.ctx.loop.call_soon_threadsafe(self.ctx.on_print_silently, msg)
                except Exception:
                    pass

        handler = PanoramaLogHandler(self)
        handler.setFormatter(logging.Formatter('%(message)s'))
        
        # Add to root logger to catch everything
        logging.getLogger().addHandler(handler)
        
        # 3. Flush the temporary queue and remove it
        for msg in temp_handler.queue:
            self.loop.call_soon_threadsafe(self.on_print_silently, msg)
        logging.getLogger().removeHandler(temp_handler)

    game = "Portal 2"
    items_handling = 0b111  # receive all items for /received

    HOST = "127.0.0.1"
    PORT = 3000  # Default Portal 2 netcon port

    death_link_active = False
    goal_map_code = ""

    item_list: list[str] = []
    item_remove_commands: list[str] = []
    command_queue: list[str] = []
    game_message_queue: list[str] = []

    sender_active : bool = False
    listener_active : bool = False

    location_name_to_id: dict[str, int] = None
    menu: Menu = None
    
    # Live API State
    chat_log: list[dict] = []
    last_api_update: float = 0

    def on_input(self, command: str):
        command = command.strip()
        try:
            # Check if the client is waiting for a direct answer (like a password or slot name)
            if getattr(self, "input_requests", 0) > 0:
                self.input_requests -= 1
                self.input_queue.put_nowait(command)
                return

            if command.startswith("/"):
                logger.debug(f"Executing command: {command}")
                # Pass the whole command (including the /) to the processor
                proc = self.command_processor(self)
                proc(command)
            else:
                self.command_queue.append(command + "\n")
        except Exception as e:
            logger.error(f"Command Error ({command}): {e}")
            self.on_print(f"Error: {e}")

    def alert_game_connection(self):
        if self.check_game_connection():
            self.output("Connection to Portal 2 is up and running")
        else:
            self.output("Disconnected from Portal 2. Make sure the mod is open and the `-netconport 3000` launch option is set")

    def on_print(self, text: str):
        """Hook for client output to capture it for the Panorama API"""
        # We don't log to info here to avoid recursion with the log handler
        self.on_print_silently(text)

    def on_print_silently(self, text: str):
        """Internal method to update chat log without triggering the logger"""
        self.chat_log.append({
            "text": text,
            "type": "text",
            "time": time.time()
        })
        if len(self.chat_log) > 50:
            self.chat_log.pop(0)

    def on_print_json(self, data: typing.Union[dict, list]):
        """Hook for Archipelago formatted messages (Legacy/Alternative)"""
        if isinstance(data, dict) and "data" in data:
            self.print_json(data["data"])
        elif isinstance(data, list):
            self.print_json(data)

    def print_json(self, data: typing.List[typing.Dict[str, str]]):
        """Hook for Archipelago formatted messages"""
        # Convert formatted message parts to plain text for the simple console
        text = "".join(part.get("text", "") if isinstance(part, dict) else str(part) for part in data)
        self.on_print(text)

    def output(self, text: str):
        """Legacy output hook"""
        self.on_print(text)

    def create_level_begin_command(self):
        '''Generates a command that deletes all entities not collected yet'''
        return f"{';'.join(self.item_remove_commands)}\n"
    
    def update_menu(self, location_id: int = None):
        if location_id is not None:
            self.menu.complete_check(location_id)

        # We no longer write to a file, Panorama will get this via the API
        pass

    def refresh_menu(self):
        for location_id in self.checked_locations:
            self.menu.complete_check(location_id)
        self.update_menu()

    def add_to_in_game_message_queue(self, message: str, color_string: str = None) -> None:
        self.command_queue.append(f'script AddToTextQueue("{message}"{f',"{color_string}"' if color_string else ""})\n')

    async def p2_connection_loop(self):
        '''Single loop to handle both reading and writing to Portal 2 via netcon'''
        # Give the game a few seconds to open the netcon port if starting together
        await asyncio.sleep(5)
        while not self.exit_event.is_set():
            try:
                reader, writer = await asyncio.open_connection(self.HOST, self.PORT)
                self.sender_active = True
                self.listener_active = True
                logger.info(f"Connected to Portal 2 netcon on {self.HOST}:{self.PORT}")
                self.alert_game_connection()

                while not self.exit_event.is_set():
                    # 1. Handle Outgoing Commands
                    while self.command_queue:
                        cmd = self.command_queue.pop(0)
                        if cmd:
                            logger.debug(f"Sending command to game: {cmd.strip()}")
                            writer.write(cmd.encode())
                            await writer.drain()

                    # 2. Handle Incoming Messages (Non-blocking read)
                    try:
                        # We use a small timeout to keep the loop responsive to outgoing commands
                        data = await asyncio.wait_for(reader.read(4096), timeout=0.1)
                        if not data:
                            logger.warning("Portal 2 connection closed by peer")
                            break
                        
                        messages = data.decode(errors="ignore").replace("\'", "").split('\r\n')
                        for message in messages:
                            if message:
                                await self.handle_message(message)
                    except asyncio.TimeoutError:
                        # No data to read right now, just continue the loop
                        pass
                    except Exception as e:
                        logger.error(f"Error reading from Portal 2: {e}")
                        break

            except ConnectionRefusedError:
                logger.warning(f"Connection refused on {self.HOST}:{self.PORT}. Is the game running with -netconport {self.PORT}?")
                self.sender_active = False
                self.listener_active = False
                await asyncio.sleep(5)
            except Exception as e:
                logger.error(f"Netcon Loop Error ({type(e).__name__}): {e}")
                self.sender_active = False
                self.listener_active = False
                await asyncio.sleep(5)
            finally:
                self.sender_active = False
                self.listener_active = False

    def start_api_server(self):
        """Starts a simple synchronous HTTP server in a separate thread"""
        import threading
        from http.server import BaseHTTPRequestHandler, HTTPServer
        
        # Capture 'self' for the handler
        client_self = self

        class APIHandler(BaseHTTPRequestHandler):
            def log_message(self, format, *args):
                pass # Silence console logs

            def do_OPTIONS(self):
                self.send_response(200)
                self.send_header('Access-Control-Allow-Origin', '*')
                self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
                self.send_header('Access-Control-Allow-Headers', 'Content-Type')
                self.end_headers()

            def do_GET(self):
                if self.path == '/status':
                    try:
                        self._send_json({
                            "connected": client_self.server is not None and client_self.server.socket is not None and not client_self.server.socket.closed,
                            "game_connected": client_self.check_game_connection(),
                            "seed": client_self.seed_name if hasattr(client_self, 'seed_name') else "unknown",
                            "slot": client_self.slot,
                            "items": [client_self.item_names.lookup_in_game(i.item, client_self.game) for i in client_self.items_received] if client_self.item_names else [],
                            "checked_locations": list(client_self.checked_locations),
                            "missing_locations": list(client_self.missing_locations) if hasattr(client_self, 'missing_locations') else [],
                            "deathlink": client_self.death_link_active,
                            "menu": client_self.menu.to_dict() if client_self.menu else None
                        })
                    except Exception as e:
                        logger.error(f"API Status Error: {e}")
                        self.send_error(500, str(e))
                elif self.path == '/chat':
                    try:
                        self._send_json(list(client_self.chat_log))
                    except Exception as e:
                        logger.error(f"API Chat Error: {e}")
                        self.send_error(500, str(e))
                else:
                    self.send_error(404)

            def do_POST(self):
                try:
                    # logger.info(f"API POST Request: {self.path}")
                    if self.path == '/command':
                        content_length = int(self.headers.get('Content-Length', 0))
                        if content_length == 0:
                            self.send_error(400, "Empty body")
                            return
                            
                        post_data = self.rfile.read(content_length)
                        decoded_data = post_data.decode('utf-8')
                        
                        command = None
                        try:
                            data = json.loads(decoded_data)
                            command = data.get("command")
                        except json.JSONDecodeError:
                            # Fallback for form-encoded data from Panorama
                            from urllib.parse import parse_qs
                            data = parse_qs(decoded_data)
                            if "command" in data:
                                command = data["command"][0]
                        
                        if command:
                            # logger.info(f"API Command received: {command}")
                            # Use call_soon_threadsafe because we're in the HTTP server thread, not the main loop thread
                            client_self.loop.call_soon_threadsafe(client_self.on_input, command)
                            self._send_json({"status": "ok"})
                        else:
                            self.send_error(400, "No command in JSON")
                    else:
                        self.send_error(404)
                except Exception as e:
                    logger.error(f"API POST Error: {e}")
                    self.send_error(500, str(e))

            def _send_json(self, data):
                body = json.dumps(data).encode('utf-8')
                self.send_response(200)
                self.send_header('Content-Type', 'application/json')
                self.send_header('Content-Length', str(len(body)))
                self.send_header('Access-Control-Allow-Origin', '*')
                self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
                self.send_header('Access-Control-Allow-Headers', 'Content-Type')
                self.end_headers()
                self.wfile.write(body)

        def run_server():
            try:
                server = HTTPServer(('0.0.0.0', 8910), APIHandler)
                logger.info('Panorama API Server serving on http://localhost:8910 (Sync Thread)')
                server.serve_forever()
            except Exception as e:
                logger.error(f"Failed to start Panorama API Server: {e}")

        thread = threading.Thread(target=run_server, daemon=True)
        thread.start()

    async def handle_api_status(self, request):
        from aiohttp import web
        status = {
            "connected": self.server is not None and self.server.socket is not None and not self.server.socket.closed,
            "seed": self.seed_name if hasattr(self, 'seed_name') else "unknown",
            "slot": self.slot,
            "items": [self.item_names.lookup_in_game(i.item, self.game) for i in self.items_received],
            "checked_locations": list(self.checked_locations),
            "missing_locations": list(self.missing_locations) if hasattr(self, 'missing_locations') else [],
            "deathlink": self.death_link_active
        }
        return web.json_response(status)

    async def handle_api_chat(self, request):
        from aiohttp import web
        return web.json_response(self.chat_log)

    async def handle_api_command(self, request):
        from aiohttp import web
        try:
            data = await request.json()
            command = data.get("command")
            if command:
                self.run_gui_command(command)
                return web.json_response({"status": "ok"})
            return web.json_response({"error": "No command"}, status=400)
        except Exception as e:
            return web.json_response({"error": str(e)}, status=400)

    async def handle_message(self, message: str):
        if message.startswith("map_name:"):
            map_name = message.split(':', 1)[1]
            # append the whole command string
            command_string = self.create_level_begin_command()
            self.command_queue.append(command_string)
            self.command_queue += handle_map_start(map_name, self.item_list, self.get_wheatley_monitor_names(self.checked_locations), self.get_ratman_den_names(self.checked_locations))

        # For map complete checks
        elif message.startswith("map_complete:"):
            done_map = message.split(':', 1)[1]
            if done_map == self.goal_map_code:
                await self.handle_goal_completion()
            
            map_id = self.map_code_to_location_id(done_map)
            if map_id:
                await self.check_locations([map_id])
                self.update_menu(map_id)
        
        # All other checks
        # Item checks e.g. portal gun upgrade, potatos
        elif message.startswith("item_collected:"):
            item_collected = message.split(":", 1)[1]
            check_id = all_locations_table[item_collected].id
            await self.check_locations([check_id])
            self.update_menu(check_id)
        
        # Wheatley monitor checks
        elif message.startswith("monitor_break:"):
            map_name = message.split(":", 1)[1]
            check_name = wheatley_maps_to_monitor_names[map_name]
            check_id = all_locations_table[check_name].id
            await self.check_locations([check_id])
            self.update_menu(check_id)
        
        # Custom buttons e.g. ratman dens, vitrified doors
        elif message.startswith("button_check:"):
            check_name = message.split(":", 1)[1]
            check_id = all_locations_table[check_name].id
            await self.check_locations([check_id])
            self.update_menu(check_id)
        
        # Deathlink
        elif message.startswith("send_deathlink"):
            if self.death_link_active and time.time() - self.last_death_link > 10:
                map_name = message.split(" ")[1]
                death_message = get_death_message(map_name, self.player_names[self.slot])
                await self.send_death(death_text=death_message)

    async def handle_goal_completion(self):
        if self.finished_game:
            return
        
        self.finished_game = True
        await self.send_msgs([{"cmd": "StatusUpdate", "status": ClientStatus.CLIENT_GOAL}])

    def on_deathlink(self, data):
        self.command_queue.append("restart\n")
        return super().on_deathlink(data)

    def check_game_connection(self) -> bool:
        return self.sender_active and self.listener_active
    
    # Used for nothing?
    def location_id_to_map_code(self, location_id: str) -> str:
        '''Converts a location ID to a map code (if that id relates to a map location)'''
        # Convert id to name
        location_name = self.location_names.lookup_in_game(location_id)
        # Get info for location name
        if location_name in location_names_to_map_codes:
            return location_names_to_map_codes[location_name]
        
        return None
    
    def map_code_to_location_id(self, map_code: str):
        '''Convert in game map name to location id for location checks'''
        if map_code not in map_codes_to_location_names:
            return None
        
        location_name = map_codes_to_location_names[map_code]
        if not self.location_name_to_id:
            raise Exception("location_name_to_id dict has not been created yet")
        if location_name not in self.location_name_to_id:
            return None
        return self.location_name_to_id[location_name]
    
    def get_wheatley_monitor_names(self, location_ids: list[int]) -> list[str]:
        '''Convert location ids to the names of the wheatley monitor checks if they are ones'''
        monitors_checked = []
        for loc in location_ids:
            location_name = self.location_names.lookup_in_game(loc)
            if location_name in wheatley_monitor_table:
                monitors_checked.append(location_name)
        return monitors_checked
    
    def get_ratman_den_names(self, location_ids: list[int]) -> list[str]:
        '''Convert location ids to the names of the ratman den checks if they are ones'''
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
        
        # Don't remove the portal gun upgrade after pickup
        if "portal_gun_upgrade_inplace" not in slot_data:
            portal_gun_upgrade_not_inplace()
            
        # Don't disable potatos in PotatOS level
        if "potatos_inplace" not in slot_data:
            potatos_not_inplace()
        
        self.menu.generate_menu()
        self.refresh_menu()

    def on_package(self, cmd, args):
        def update_item_list():
            # Update item list to only include items not collected
            items_received_names = [self.item_names.lookup_in_game(i.item, self.game) for i in self.items_received]
            self.item_list = list(set(self.item_list) - set(items_received_names))
            self.refresh_menu()

        # Add item names to list
        if cmd == "Retrieved":
            if f"_read_item_name_groups_{self.game}" in args["keys"]:
                self.item_list = args["keys"][f"_read_item_name_groups_{self.game}"]["Everything"]
                update_item_list()
                self.update_item_remove_commands()

        if cmd == "ReceivedItems":
            index = args["index"]
            for item in args["items"]:
                # Only handle traps if they are new (index >= current count)
                if index >= len(self.items_received):
                    if item.flags & 0b100: # Trap flag
                        trap_name = self.item_names.lookup_in_game(item.item, self.game)
                        self.command_queue.append(handle_trap(trap_name))
                index += 1
            
            # Now let the base class update self.items_received
            super().on_package(cmd, args)
            update_item_list()
            self.update_item_remove_commands()
            return # Already called super
        
        super().on_package(cmd, args)

        if cmd == "Connected":
            self.handle_slot_data(args["slot_data"])
            self.alert_game_connection()

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
                    return # Don't send text to game
                self.add_to_in_game_message_queue(text)
                
            # chat_log.append is handled by the logging handler for all messages, including PrintJSON

    def parse_message(self, data: list[dict], sending: int | None = None) -> str: # data pats not cast to JSONMessagePart as expected, dict instead
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
        if self.input_task:
            self.input_task.cancel()

    async def server_auth(self, password_requested: bool = False) -> None:
        if password_requested and not self.password:
            await super().server_auth(password_requested)
        await self.get_username()
        await self.send_connect(game="Portal 2")

async def main(args: Namespace):
    ctx = Portal2Context(args.connect, args.password)
    ctx.loop = asyncio.get_running_loop()
    ctx.server_task = asyncio.create_task(server_loop(ctx), name="server loop")
    ctx.game_connection_task = asyncio.create_task(ctx.p2_connection_loop(), name="netcon loop")
    ctx.start_api_server()

    if gui_enabled:
        ctx.run_gui()
    ctx.run_cli()
    
    await ctx.exit_event.wait()
    await ctx.shutdown()

def launch(*args: str) -> None:
    from .Launch import launch_portal_2_client

    launch_portal_2_client(*args)


if __name__ == "__main__":
    launch(*sys.argv[1:])
