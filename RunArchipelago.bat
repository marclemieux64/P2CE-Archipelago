@echo off
:: Archipelago Autonomous Launch Script for P2CE
:: This script runs the local bundled Archipelago client.

set MOD_FOLDER=%~dp0
set ARCHIPELAGO_LOCAL=%MOD_FOLDER%archipelago

:: Use system python (required by user)
set PYTHON_PATH=python

where %PYTHON_PATH% >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo [Archipelago] ERROR: Python was not found in your system PATH.
    echo Please ensure Python is installed and added to your environment variables.
    pause
    exit /b 1
)

echo [Archipelago] Launching Game...
set "GAME_ARGS=%*"

:: Start the game in a new process so we can continue the script
start "" %GAME_ARGS%

echo [Archipelago] Waiting for game to initialize...
:: Delay the client launch as requested by the user
timeout /t 3 /nobreak >nul

echo [Archipelago] Starting Autonomous Client...
pushd "%MOD_FOLDER%"
set PYTHONPATH=%ARCHIPELAGO_LOCAL%
:: Start the Portal 2 Client module in the background and hide its output
start /B "" "%PYTHON_PATH%" -W ignore -m worlds.portal2_p2ce.client.Portal2Client --nogui >archipelago_client.log 2>&1
popd

echo [Archipelago] Client is running. The game is active.

:: Wait for the game process to finish. 
:: We check for both p2ce.exe and portal2.exe just in case.
:WAITLOOP
tasklist /FI "IMAGENAME eq p2ce.exe" 2>NUL | find /I /N "p2ce.exe">NUL
if "%ERRORLEVEL%"=="0" (
    goto WAITLOOP
)

echo [Archipelago] Game closed. Cleaning up...
taskkill /F /IM python.exe /T >nul 2>&1

echo [Archipelago] Done.
