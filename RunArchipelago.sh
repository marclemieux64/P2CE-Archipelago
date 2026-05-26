#!/bin/bash

# =============================================================================
# P2CE Archipelago Native Linux & Steam Deck Launcher (Standalone)
# =============================================================================

# 1. Path Definitions
MOD_FOLDER="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLIENT_DIR="$MOD_FOLDER/P2CEClient"
CLIENT_PY="$CLIENT_DIR/run_client.py"
PORTABLE_PY_DIR="$CLIENT_DIR/python_env_linux"
PYTHON_EXE="$PORTABLE_PY_DIR/python/bin/python3"

echo "[Archipelago] Initializing Standalone Linux Launcher..."

# 2. Check and build the standalone Python environment on first run
SETUP_NEEDED=false
if [ ! -f "$PYTHON_EXE" ]; then
    SETUP_NEEDED=true
fi

if [ "$SETUP_NEEDED" = false ]; then
    # Verify all dependencies are installed (specifically pinning websockets < 14)
    if ! "$PYTHON_EXE" -c "import websockets, colorama, yaml, certifi, jellyfish, platformdirs, pathspec, typing_extensions, attrs, schema; assert float(websockets.__version__.split('.')[0]) < 14" &>/dev/null; then
        echo "[Archipelago] Missing, outdated, or incompatible dependencies detected. Installing/updating..."
        "$PYTHON_EXE" -m pip install "websockets>=13.1,<14" colorama==0.4.6 pyyaml==6.0.3 certifi==2026.2.25 jellyfish==1.2.1 platformdirs==4.9.4 pathspec==1.0.4 typing_extensions==4.15.0 attrs==26.1.0 schema==0.7.8
    fi
else
    echo "[Archipelago] Setting up clean, isolated Linux Python environment..."
    mkdir -p "$PORTABLE_PY_DIR"
    
    DOWNLOAD_URL="https://github.com/indygreg/python-build-standalone/releases/download/20240107/cpython-3.11.7+20240107-x86_64-unknown-linux-gnu-install_only.tar.gz"
    
    echo "[Archipelago] Downloading pre-compiled portable Python (3.11)..."
    if command -v wget &> /dev/null; then
        wget -q -O "$CLIENT_DIR/python.tar.gz" "$DOWNLOAD_URL"
    elif command -v curl &> /dev/null; then
        curl -s -L -o "$CLIENT_DIR/python.tar.gz" "$DOWNLOAD_URL"
    else
        echo "[Archipelago] ERROR: Neither wget nor curl found! Cannot download Python."
        exit 1
    fi
    
    if [ ! -f "$CLIENT_DIR/python.tar.gz" ]; then
        echo "[Archipelago] ERROR: Failed to download portable Python!"
        exit 1
    fi
    
    echo "[Archipelago] Extracting Python package..."
    tar -xzf "$CLIENT_DIR/python.tar.gz" -C "$PORTABLE_PY_DIR"
    rm "$CLIENT_DIR/python.tar.gz"
    
    echo "[Archipelago] Installing standalone dependencies into venv..."
    "$PYTHON_EXE" -m ensurepip --upgrade
    "$PYTHON_EXE" -m pip install --upgrade pip
    "$PYTHON_EXE" -m pip install "websockets>=13.1,<14" colorama==0.4.6 pyyaml==6.0.3 certifi==2026.2.25 jellyfish==1.2.1 platformdirs==4.9.4 pathspec==1.0.4 typing_extensions==4.15.0 attrs==26.1.0 schema==0.7.8
    
    echo "[Archipelago] Setup completed successfully!"
fi

# 3. Double-check client entrypoint exists
if [ ! -f "$CLIENT_PY" ]; then
    echo "[Archipelago] ERROR: Standalone client script not found at $CLIENT_PY"
    exit 1
fi

# 4. Launch the Client
echo "[Archipelago] Starting Autonomous Client..."
"$PYTHON_EXE" -u "$CLIENT_PY" --nogui > "$MOD_FOLDER/archipelago_debug.log" 2>&1 &
CLIENT_PID=$!

echo "[Archipelago] Client started natively with PID: $CLIENT_PID"

# 5. Process Synchronization
# This trap ensures that when the game closes, it automatically terminates the background client.
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
    "$@" -netconport 3000 -language english > "$MOD_FOLDER/game_debug.log" 2>&1
else
    echo "[Archipelago] WARNING: No game command provided."
    wait $CLIENT_PID
fi