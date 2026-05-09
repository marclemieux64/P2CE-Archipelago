#!/bin/bash

# P2CE Archipelago Launcher for Linux

# 1. Paths
MOD_FOLDER="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARCHIPELAGO_LOCAL="$MOD_FOLDER/archipelago"
CLIENT_PY="$ARCHIPELAGO_LOCAL/worlds/portal2_p2ce/client/Portal2Client.py"

# Note: On Linux we use the system python3 as the bundled Windows .exe won't work
PYTHON_EXE="python3"

# 2. Check for Python
if ! command -v $PYTHON_EXE &> /dev/null; then
    echo "[Archipelago] ERROR: python3 not found! Please install python3."
    read -p "Press enter to exit..."
    exit 1
fi

# 3. Check for Client Script
if [ ! -f "$CLIENT_PY" ]; then
    echo "[Archipelago] ERROR: Client script not found!"
    echo "Looked in: $CLIENT_PY"
    read -p "Press enter to exit..."
    exit 1
fi

echo "[Archipelago] Starting Autonomous Client..."
# 4. Launch Python in background and save PID
$PYTHON_EXE "$CLIENT_PY" --nogui >> archipelago_debug.log 2>&1 &
CLIENT_PID=$!

echo "[Archipelago] Client started with PID: $CLIENT_PID"

# 5. Launch Game if arguments provided
if [ $# -gt 0 ]; then
    echo "[Archipelago] Launching Game with arguments: $@"
    "$@" -netconport 3000 &
fi

# 6. Wait for Game to close
echo "[Archipelago] Waiting for game to close..."
while true; do
    # Check for common P2CE process names
    if ! pgrep -x "p2ce" > /dev/null && ! pgrep -x "portal2" > /dev/null; then
        break
    fi
    sleep 2
done

echo "[Archipelago] Game closed. Cleaning up client..."
# 7. Cleanup
if ps -p $CLIENT_PID > /dev/null; then
   kill $CLIENT_PID
   echo "[Archipelago] Client process ($CLIENT_PID) terminated."
fi

exit 0
