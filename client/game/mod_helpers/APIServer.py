import json
import hashlib
import threading
from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import urlparse, parse_qs


class APIServer:
    def __init__(self, ctx):
        self.ctx = ctx
        self.server = None
        self.thread = None

        self._cache = {}

        self._menu_version = 0
        self._last_menu_key = None
        self._cached_menu_dict = None

        self._missing_items_key = None
        self._cached_missing_str = ""
        self._missing_version = 0

    def start(self):
        client_self = self.ctx
        server_self = self

        class APIHandler(BaseHTTPRequestHandler):
            def log_message(self, format, *args):
                pass

            def do_OPTIONS(self):
                self.send_response(200)
                self.send_header('Access-Control-Allow-Origin', '*')
                self.send_header('Access-Control-Allow-Headers', 'Content-Type, If-None-Match')
                self.end_headers()

            def _get_missing_str(self):
                """Cached missing_str — only recomputed when item counts change."""
                from game.mod_helpers.MapMenu import items_shortened
                items_received_len = len(client_self.items_received) if hasattr(client_self, "items_received") else 0
                item_list_len = len(client_self.item_list) if hasattr(client_self, "item_list") else 0
                missing_key = (items_received_len, item_list_len)

                if missing_key != server_self._missing_items_key:
                    server_self._missing_items_key = missing_key
                    server_self._missing_version += 1
                    if hasattr(client_self, "items_received") and hasattr(client_self, "item_names"):
                        received_names = {client_self.item_names.lookup_in_game(i.item, client_self.game) for i in client_self.items_received}
                        server_self._cached_missing_str = ",".join([items_shortened[item] for item in items_shortened if item not in received_names])
                    else:
                        server_self._cached_missing_str = ",".join([items_shortened.get(i, "") for i in client_self.item_list]) if hasattr(client_self, "item_list") else ""

                return server_self._cached_missing_str

            def do_GET(self):
                is_conn = bool(client_self.server and client_self.server.socket and not client_self.server.socket.closed)
                game_conn = client_self.check_game_connection()

                if self.path.startswith('/api/all'):
                    query = parse_qs(urlparse(self.path).query)
                    try: client_menu_version = int(query.get('menu_version', [-1])[0])
                    except: client_menu_version = -1
                    try: client_checked_count = int(query.get('checked_count', [-1])[0])
                    except: client_checked_count = -1
                    try: client_missing_version = int(query.get('missing_version', [-1])[0])
                    except: client_missing_version = -1
                    try: last_chat_id = int(query.get('last_chat', [-1])[0])
                    except: last_chat_id = -1

                    # --- Status section ---
                    self._get_missing_str()

                    items_received_len = len(client_self.items_received) if hasattr(client_self, "items_received") else 0
                    item_list_len = len(client_self.item_list) if hasattr(client_self, "item_list") else 0
                    current_checked_locations_len = len(client_self.checked_locations)

                    current_menu_key = (current_checked_locations_len, items_received_len, item_list_len, client_self.slot)
                    if current_menu_key != server_self._last_menu_key:
                        server_self._last_menu_key = current_menu_key
                        server_self._menu_version += 1
                        server_self._cached_menu_dict = client_self.menu.to_dict() if client_self.menu else None

                    status_key = (
                        is_conn, game_conn, client_self.slot,
                        current_checked_locations_len, items_received_len, item_list_len,
                        getattr(client_self, "hint_points", 0),
                        getattr(client_self, "hint_cost", 0),
                        getattr(client_self, "logic_difficulty", 0),
                        client_menu_version, server_self._menu_version,
                        client_checked_count, client_missing_version, server_self._missing_version,
                        getattr(client_self.deathlink_handler, 'last_death_link_executed', 0.0)
                    )

                    status_changed = status_key != server_self._cache.get("all_status_key")
                    if status_changed:
                        server_self._cache["all_status_key"] = status_key
                        should_send_menu = (client_menu_version != server_self._menu_version)
                        should_send_checked = (client_checked_count != current_checked_locations_len)
                        should_send_missing = (client_missing_version != server_self._missing_version)
                        server_self._cache["all_status_payload"] = {
                            "connected": is_conn,
                            "game_connected": game_conn,
                            "slot": client_self.slot,
                            "checked_locations_count": current_checked_locations_len,
                            "checked_locations": list(client_self.checked_locations) if should_send_checked else None,
                            "missing_version": server_self._missing_version,
                            "missing_items": server_self._cached_missing_str if should_send_missing else None,
                            "hint_points": getattr(client_self, "hint_points", 0),
                            "hint_cost": getattr(client_self, "hint_cost", 0),
                            "logic_difficulty": getattr(client_self, "logic_difficulty", 0),
                            "menu_version": server_self._menu_version,
                            "menu": server_self._cached_menu_dict if should_send_menu else None,
                            "persistent_death_time": getattr(client_self.deathlink_handler, 'last_death_link_executed', 0.0)
                        }

                    # --- Chat section ---
                    chat_log = client_self.notifier.chat_log
                    chat_head_id = chat_log[-1]["id"] if chat_log else -1
                    chat_key = (chat_head_id, last_chat_id)
                    chat_delta = list([msg for msg in chat_log if msg["id"] > last_chat_id])

                    # --- Hints section ---
                    hint_log = client_self.notifier.hint_log
                    hints_key = (len(hint_log), tuple(h.get("found", False) for h in hint_log))
                    hints_changed = hints_key != server_self._cache.get("all_hints_key")
                    if hints_changed:
                        server_self._cache["all_hints_key"] = hints_key
                        server_self._cache["all_hints_payload"] = list(hint_log)

                    # --- Combined ETag ---
                    combined_key = (status_key, chat_key, hints_key)

                    if combined_key == server_self._cache.get("all_key"):
                        if self.headers.get('If-None-Match') == server_self._cache.get("all_etag", ""):
                            self.send_response(304)
                            self.send_header('Access-Control-Allow-Origin', '*')
                            self.send_header('Content-Length', '0')
                            self.end_headers()
                            return

                    server_self._cache["all_key"] = combined_key

                    payload = {
                        "s": server_self._cache.get("all_status_payload") if status_changed else None,
                        "c": chat_delta,
                        "h": server_self._cache.get("all_hints_payload") if hints_changed else None
                    }

                    body = json.dumps(payload).encode('utf-8')
                    etag = hashlib.md5(body).hexdigest()
                    server_self._cache["all_etag"] = etag

                    self.send_response(200)
                    self.send_header('Content-Type', 'application/json')
                    self.send_header('Content-Length', str(len(body)))
                    self.send_header('Access-Control-Allow-Origin', '*')
                    self.send_header('ETag', etag)
                    self.end_headers()
                    self.wfile.write(body)
                    return

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
                        client_self.loop.call_soon_threadsafe(client_self.on_input, command)
                        self._send_json({"status": "ok"})
                    elif self.path == '/hints/refresh':
                        client_self.loop.call_soon_threadsafe(client_self.request_hints_sync)
                        self._send_json({"status": "ok"})
                    else:
                        self.send_error(404)
                except Exception as e:
                    self.send_error(500, str(e))

            def _send_json(self, d):
                body = json.dumps(d).encode('utf-8')
                self.send_response(200)
                self.send_header('Content-Type', 'application/json')
                self.send_header('Content-Length', str(len(body)))
                self.send_header('Access-Control-Allow-Origin', '*')
                self.end_headers()
                self.wfile.write(body)

        def run_server():
            try:
                self.server = HTTPServer(('0.0.0.0', 8910), APIHandler)
                self.server.serve_forever()
            except Exception:
                pass

        self.thread = threading.Thread(target=run_server, daemon=True)
        self.thread.start()
