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

echo [Archipelago] Starting Autonomous Client...
pushd "%MOD_FOLDER%"

:: Set PYTHONPATH to our local archipelago folder
:: This allows importing 'worlds', 'CommonClient', etc.
set PYTHONPATH=%ARCHIPELAGO_LOCAL%

:: Start the Portal 2 Client module in the background
start /B "" "%PYTHON_PATH%" -W ignore -m worlds.portal2_p2ce.client.Portal2Client --nogui

popd

echo [Archipelago] Launching Game...
:: Capture arguments and fix common typos
set "GAME_ARGS=%*"

:: Execute the game command
%GAME_ARGS%

echo [Archipelago] Game closed. Cleaning up...
taskkill /F /IM python.exe /T >nul 2>&1

echo [Archipelago] Done.
