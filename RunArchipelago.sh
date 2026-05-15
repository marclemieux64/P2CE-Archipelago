#!/bin/bash

# =============================================================================
# P2CE Archipelago Native Linux Launcher
# =============================================================================

# 1. Path Definitions
MOD_FOLDER="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARCHIPELAGO_LOCAL="$MOD_FOLDER/archipelago"
CLIENT_PY="$ARCHIPELAGO_LOCAL/worlds/portal2_p2ce/client/Portal2Client.py"
VENV_DIR="$MOD_FOLDER/ap_venv"

echo "[Archipelago] Initializing Linux Native Launcher..."

# 2. Find a Compatible System Python (3.11, 3.12, or 3.13)
echo "[Archipelago] Hunting for compatible Python version..."
PYTHON_BASE=""
for py in python3.13 python3.12 python3.11; do
    if command -v "$py" &> /dev/null; then
        PYTHON_BASE="$py"
        echo "[Archipelago] Success! Found compatible Python: $PYTHON_BASE"
        break
    fi
done

if [ -z "$PYTHON_BASE" ]; then
    echo "[Archipelago] ERROR: Compatible Python (3.11, 3.12, or 3.13) is NOT installed."
    echo "Your default Python 3.14 is too new for Archipelago."
    exit 1
fi

# 3. Virtual Environment & Dependency Management
if [ ! -d "$VENV_DIR" ]; then
    echo "[Archipelago] Creating isolated Python virtual environment..."
    # Force the venv to be created with the compatible version we found
    "$PYTHON_BASE" -m venv "$VENV_DIR"
    
    if [ -f "$ARCHIPELAGO_LOCAL/requirements.txt" ]; then
        echo "[Archipelago] Installing dependencies into venv..."
        "$VENV_DIR/bin/pip" install --upgrade pip
        "$VENV_DIR/bin/pip" install -r "$ARCHIPELAGO_LOCAL/requirements.txt"
    fi
fi

# Point our execution to the isolated Python binary
PYTHON_EXE="$VENV_DIR/bin/python"

if [ ! -f "$CLIENT_PY" ]; then
    echo "[Archipelago] ERROR: Client script not found at $CLIENT_PY"
    exit 1
fi

# 4. Launch the Client
echo "[Archipelago] Starting Autonomous Client..."
"$PYTHON_EXE" "$CLIENT_PY" --nogui > "$MOD_FOLDER/archipelago_debug.log" 2>&1 &
CLIENT_PID=$!

echo "[Archipelago] Client started natively with PID: $CLIENT_PID"

# 5. Process Synchronization (The Clean Way)
# This trap ensures that no matter how this bash script exits (game crash, 
# normal exit, or forced kill), it will always take the Python client down with it.
cleanup() {
    echo "[Archipelago] Game closed. Cleaning up client process..."
    if kill -0 $CLIENT_PID 2>/dev/null; then
        kill -TERM $CLIENT_PID
    fi
}
trap cleanup EXIT INT TERM

# 6. Launch the Game
if [ $# -gt 0 ]; then
    echo "[Archipelago] Launching Game with Steam arguments..."
    # We are adding a redirect to save the game's output to game_debug.log
    "$@" -netconport 3000 -language english > "$MOD_FOLDER/game_debug.log" 2>&1
else
    echo "[Archipelago] WARNING: No game command provided."
    wait $CLIENT_PID
fi