import os
import sys
import json
import hashlib
import threading
from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import urlparse, parse_qs

# --- STANDALONE FIX ---
archipelago_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', '..'))
if archipelago_root not in sys.path:
    sys.path.insert(0, archipelago_root)

os.environ['SKIP_REQUIREMENTS_UPDATE'] = '1'

class APIServer:
    def __init__(self, ctx):
        self.ctx = ctx
        self.server = None
        self.thread = None
        
        # Cache serveur pour éviter json.dumps() et calculs MD5 redondants
        self._cache = {
            "sync_key": None, "sync_json": b"", "sync_etag": "",
            "status_key": None, "status_json": b"", "status_etag": "",
            "chat_key": None, "chat_json": b"", "chat_etag": "",
            "hints_key": None, "hints_json": b"", "hints_etag": ""
        }

    def start(self):
        client_self = self.ctx
        server_self = self

        class APIHandler(BaseHTTPRequestHandler):
            def log_message(self, format, *args):
                pass  # Supprime les logs console pour éliminer l'overhead d'I/O disque

            def do_OPTIONS(self):
                self.send_response(200)
                self.send_header('Access-Control-Allow-Origin', '*')
                self.send_header('Access-Control-Allow-Headers', 'Content-Type, If-None-Match')
                self.end_headers()

            def do_GET(self):
                from game.mod_helpers.MapMenu import items_shortened

                is_conn = bool(client_self.server and client_self.server.socket and not client_self.server.socket.closed)
                missing_str = "".join([items_shortened.get(i, "") for i in client_self.item_list]) if hasattr(client_self, "item_list") else ""

                # =============================================================
                # 1. CANAL UNIFIÉ DELTA SYNC (Haute performance pour le V8)
                # =============================================================
                if self.path.startswith('/api/sync'):
                    query = parse_qs(urlparse(self.path).query)
                    try:
                        last_chat_id = int(query.get('last_chat', [-1])[0])
                    except (ValueError, IndexError):
                        last_chat_id = -1

                    chat_log = client_self.notifier.chat_log
                    chat_delta = [msg for msg in chat_log if msg["id"] > last_chat_id]

                    # Clé de cache composite incluant le delta de chat pour invalider au bon moment
                    current_key = (
                        is_conn,
                        client_self.check_game_connection(),
                        client_self.slot,
                        len(client_self.checked_locations),
                        getattr(client_self, "hint_points", 0),
                        getattr(client_self, "hint_cost", 0),
                        getattr(client_self, "logic_difficulty", 0),
                        len(chat_delta)
                    )

                    if current_key != server_self._cache["sync_key"]:
                        server_self._cache["sync_key"] = current_key
                        
                        payload = {
                            "connected": is_conn,
                            "game_connected": client_self.check_game_connection(),
                            "slot": client_self.slot,
                            "checked_locations": list(client_self.checked_locations),
                            "missing_items": missing_str,
                            "hint_points": getattr(client_self, "hint_points", 0),
                            "hint_cost": getattr(client_self, "hint_cost", 0),
                            "logic_difficulty": getattr(client_self, "logic_difficulty", 0),
                            "menu": client_self.menu.to_dict() if client_self.menu else None,
                            "chat_delta": chat_delta,
                            "hints": client_self.notifier.hint_log,
                            "persistent_death_time": getattr(client_self.deathlink_handler, 'last_death_link_executed', 0.0)
                        }
                        server_self._cache["sync_json"] = json.dumps(payload).encode('utf-8')
                        server_self._cache["sync_etag"] = hashlib.md5(server_self._cache["sync_json"]).hexdigest()

                    if self.headers.get('If-None-Match') == server_self._cache["sync_etag"]:
                        self.send_response(304)
                        self.send_header('Access-Control-Allow-Origin', '*')
                        self.send_header('Content-Length', '0')
                        self.end_headers()
                        return

                    self.send_response(200)
                    self.send_header('Content-Type', 'application/json')
                    self.send_header('Content-Length', str(len(server_self._cache["sync_json"]))) # FIX: Longueur explicite
                    self.send_header('Access-Control-Allow-Origin', '*')
                    self.send_header('ETag', server_self._cache["sync_etag"])
                    self.end_headers()
                    self.wfile.write(server_self._cache["sync_json"])
                    return

                # =============================================================
                # 2. ROUTES HISTORIQUES PRÉSERVÉES POUR SÉCURISER L'INTERFACE
                # =============================================================
                elif self.path in ('/status', '/status_full'):
                    current_key = (
                        is_conn,
                        client_self.check_game_connection(),
                        client_self.slot,
                        len(client_self.checked_locations),
                        getattr(client_self, "hint_points", 0),
                        getattr(client_self, "hint_cost", 0),
                        getattr(client_self, "logic_difficulty", 0)
                    )
                    
                    if current_key != server_self._cache["status_key"]:
                        server_self._cache["status_key"] = current_key
                        
                        data_to_serialize = {
                            "connected": is_conn, 
                            "game_connected": client_self.check_game_connection(), 
                            "slot": client_self.slot, 
                            "checked_locations": list(client_self.checked_locations), 
                            "missing_items": missing_str, 
                            "hint_points": getattr(client_self, "hint_points", 0), 
                            "hint_cost": getattr(client_self, "hint_cost", 0), 
                            "logic_difficulty": getattr(client_self, "logic_difficulty", 0),
                            "menu": client_self.menu.to_dict() if client_self.menu else None
                        }
                        if self.path == '/status_full':
                            data_to_serialize["chat"] = client_self.notifier.chat_log
                            data_to_serialize["hints"] = client_self.notifier.hint_log
                            
                        server_self._cache["status_json"] = json.dumps(data_to_serialize).encode('utf-8')
                        server_self._cache["status_etag"] = hashlib.md5(server_self._cache["status_json"]).hexdigest()
                        
                    if self.headers.get('If-None-Match') == server_self._cache["status_etag"]:
                        self.send_response(304)
                        self.send_header('Access-Control-Allow-Origin', '*')
                        self.send_header('Content-Length', '0')
                        self.end_headers()
                        return
                        
                    self.send_response(200)
                    self.send_header('Content-Type', 'application/json')
                    self.send_header('Content-Length', str(len(server_self._cache["status_json"]))) # FIX: Longueur explicite
                    self.send_header('Access-Control-Allow-Origin', '*')
                    self.send_header('ETag', server_self._cache["status_etag"])
                    self.end_headers()
                    self.wfile.write(server_self._cache["status_json"])
                    return

                elif self.path == '/chat':
                    chat_log = client_self.notifier.chat_log
                    current_key = (len(chat_log), chat_log[-1]["id"] if chat_log else 0)
                    
                    if current_key != server_self._cache["chat_key"]:
                        server_self._cache["chat_key"] = current_key
                        server_self._cache["chat_json"] = json.dumps(chat_log).encode('utf-8')
                        server_self._cache["chat_etag"] = hashlib.md5(server_self._cache["chat_json"]).hexdigest()
                        
                    if self.headers.get('If-None-Match') == server_self._cache["chat_etag"]:
                        self.send_response(304)
                        self.send_header('Access-Control-Allow-Origin', '*')
                        self.send_header('Content-Length', '0')
                        self.end_headers()
                        return
                        
                    self.send_response(200)
                    self.send_header('Content-Type', 'application/json')
                    self.send_header('Content-Length', str(len(server_self._cache["chat_json"]))) # FIX: Longueur explicite
                    self.send_header('Access-Control-Allow-Origin', '*')
                    self.send_header('ETag', server_self._cache["chat_etag"])
                    self.end_headers()
                    self.wfile.write(server_self._cache["chat_json"])
                    return

                elif self.path == '/hints':
                    hint_log = client_self.notifier.hint_log
                    current_key = len(hint_log)
                    
                    if current_key != server_self._cache["hints_key"]:
                        server_self._cache["hints_key"] = current_key
                        server_self._cache["hints_json"] = json.dumps(hint_log).encode('utf-8')
                        server_self._cache["hints_etag"] = hashlib.md5(server_self._cache["hints_json"]).hexdigest()
                        
                    if self.headers.get('If-None-Match') == server_self._cache["hints_etag"]:
                        self.send_response(304)
                        self.send_header('Access-Control-Allow-Origin', '*')
                        self.send_header('Content-Length', '0')
                        self.end_headers()
                        return
                        
                    self.send_response(200)
                    self.send_header('Content-Type', 'application/json')
                    self.send_header('Content-Length', str(len(server_self._cache["hints_json"]))) # FIX: Longueur explicite
                    self.send_header('Access-Control-Allow-Origin', '*')
                    self.send_header('ETag', server_self._cache["hints_etag"])
                    self.end_headers()
                    self.wfile.write(server_self._cache["hints_json"])
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