#!/bin/bash

# =============================================================================
# P2CE Archipelago Flatpak / Proton Native Container Layer Sandbox Fix
# =============================================================================

# 1. Path Definitions
MOD_FOLDER="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLIENT_DIR="$MOD_FOLDER/P2CEClient"
CLIENT_PY="$CLIENT_DIR/run_client.py"
PORTABLE_PY_DIR="$CLIENT_DIR/python_env_linux"
PYTHON_EXE="$PORTABLE_PY_DIR/python/bin/python3"
GAMEINFO_FILE="$MOD_FOLDER/gameinfo.txt"

# 2. Dynamic Language Catching from Steam Arguments
SELECTED_LANGUAGE="english"

ARG_LIST=("$@")
for ((i=0; i<${#ARG_LIST[@]}; i++)); do
    if [ "${ARG_LIST[i]}" == "-language" ] && [ $((i+1)) -lt ${#ARG_LIST[@]} ]; then
        SELECTED_LANGUAGE="${ARG_LIST[i+1]}"
        echo "[Archipelago] Intercepted explicit language argument from Steam: $SELECTED_LANGUAGE"
    fi
done

# 3. Dynamically Rewrite gameinfo.txt SearchPaths to Mount the Selected Language Pack
if [ -f "$GAMEINFO_FILE" ]; then
    sed -i '/portal2_.*_dir.vpk/d' "$GAMEINFO_FILE"
    sed -i '/portal2_[a-zA-Z]*/d' "$GAMEINFO_FILE"
    
    if [ "$SELECTED_LANGUAGE" != "english" ] && [ -n "$SELECTED_LANGUAGE" ]; then
        echo "[Archipelago] Customizing gameinfo.txt SearchPaths for non-English language: '$SELECTED_LANGUAGE'..."
        LANG_VPK="Game\t\t\t\tportal2/portal2_${SELECTED_LANGUAGE}/pak01_dir.vpk"
        LANG_DIR="Game\t\t\t\tportal2/portal2_${SELECTED_LANGUAGE}"
        
        sed -i '/portal2\/portal2\/portal2.vpk/i \ \ \ \ \ \ \ \ \ \ \ '"$LANG_VPK"'' "$GAMEINFO_FILE"
        sed -i '/portal2\/portal2\/portal2.vpk/i \ \ \ \ \ \ \ \ \ \ \ '"$LANG_DIR"'' "$GAMEINFO_FILE"
        echo "[Archipelago] gameinfo.txt search paths optimized successfully for custom language."
    else
        echo "[Archipelago] Language is English or blank. Keeping gameinfo.txt clean with native base paths."
    fi
else
    echo "[Archipelago] WARNING: gameinfo.txt not found at $GAMEINFO_FILE. Skipping localization mount rules."
fi

# 4. Standalone Runtime Environment Setup (First-Run check)
SETUP_NEEDED=false
if [ ! -f "$PYTHON_EXE" ]; then
    SETUP_NEEDED=true
fi

if [ "$SETUP_NEEDED" = false ]; then
    if ! "$PYTHON_EXE" -c "import websockets, colorama, yaml, certifi, jellyfish, platformdirs, pathspec, typing_extensions, attrs, schema; assert float(websockets.__version__.split('.')[0]) < 14" &>/dev/null; then
        echo "[Archipelago] Dependency drift detected. Updating runtime workspace..."
        "$PYTHON_EXE" -m pip install "websockets>=13.1,<14" colorama==0.4.6 pyyaml==6.0.3 certifi==2026.2.25 jellyfish==1.2.1 platformdirs==4.9.4 pathspec==1.0.4 typing_extensions==4.15.0 attrs==26.1.0 schema==0.7.8
    fi
else
    echo "[Archipelago] Bootstrapping fresh, isolated Linux Python runtime..."
    mkdir -p "$PORTABLE_PY_DIR"
    DOWNLOAD_URL="https://github.com/indygreg/python-build-standalone/releases/download/20240107/cpython-3.11.7+20240107-x86_64-unknown-linux-gnu-install_only.tar.gz"
    
    if command -v wget &> /dev/null; then
        wget -q -O "$CLIENT_DIR/python.tar.gz" "$DOWNLOAD_URL"
    elif command -v curl &> /dev/null; then
        curl -s -L -o "$CLIENT_DIR/python.tar.gz" "$DOWNLOAD_URL"
    else
        echo "[Archipelago] ERROR: Neither wget nor curl found on system. Aborting build."
        exit 1
    fi
    
    tar -xzf "$CLIENT_DIR/python.tar.gz" -C "$PORTABLE_PY_DIR"
    rm "$CLIENT_DIR/python.tar.gz"
    
    "$PYTHON_EXE" -m ensurepip --upgrade
    "$PYTHON_EXE" -m pip install "websockets>=13.1,<14" colorama==0.4.6 pyyaml==6.0.3 certifi==2026.2.25 jellyfish==1.2.1 platformdirs==4.9.4 pathspec==1.0.4 typing_extensions==4.15.0 attrs==26.1.0 schema==0.7.8
fi

# 5. Launch Autonomous Headless Client Bridge
export SKIP_REQUIREMENTS_UPDATE=1
if [ -f "$CLIENT_PY" ]; then
    "$PYTHON_EXE" -u "$CLIENT_PY" --nogui > "$MOD_FOLDER/archipelago_debug.log" 2>&1 &
    CLIENT_PID=$!
    echo "[Archipelago] Autonomous background bridge started with PID: $CLIENT_PID"
    
    cleanup() {
        echo "[Archipelago] Game session terminated. Cleaning up background processes..."
        if kill -0 $CLIENT_PID 2>/dev/null; then
            kill -TERM $CLIENT_PID
        fi
    }
    trap cleanup EXIT INT TERM
else
    echo "[Archipelago] WARNING: client entrypoint script missing. Interface running solo."
fi

# 6. Execute Game Process via Transparent Handoff
if [ $# -gt 0 ]; then
    echo "[Archipelago] Handing control smoothly over to Flatpak Proton layer..."
    
    # Extract the container runner executable dynamically from Steam's launch pipeline
    GAME_COMMAND="$1"
    shift
    
    # Append netcon parameters directly into the plain array stack rather than 
    # forcing variable strings that trigger nested sandbox evaluations
    exec "$GAME_COMMAND" "$@" -netconport 3000 -language "$SELECTED_LANGUAGE" > "$MOD_FOLDER/game_debug.log" 2>&1
else
    echo "[Archipelago] ERROR: No game execution parameters provided by Steam launch pipeline."
    exit 1
fi