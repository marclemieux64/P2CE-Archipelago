@echo off
title P2CE Archipelago Launcher
setlocal enabledelayedexpansion

:: 1. Define paths relative to the mod folder
set "MOD_FOLDER=%~dp0"
set "CLIENT_DIR=%MOD_FOLDER%P2CEClient"
set "CLIENT_PY=%CLIENT_DIR%\run_client.py"
set "PORTABLE_PY_DIR=%CLIENT_DIR%\python_env"
set "PYTHON_EXE=%PORTABLE_PY_DIR%\python.exe"

echo [Archipelago] Initializing Autonomous Launcher...

:: 2. Check and build the standalone Python environment on first run
if not exist "%PYTHON_EXE%" goto DOWNLOAD_PY

:: Verify if all required dependencies are installed (specifically pinning websockets < 14)
"%PYTHON_EXE%" -c "import websockets, colorama, yaml, certifi, jellyfish, platformdirs, pathspec, typing_extensions, attrs, schema; assert float(websockets.__version__.split('.')[0]) < 14" >nul 2>&1
if "%ERRORLEVEL%"=="0" goto RUN_CLIENT

echo [Archipelago] Missing, outdated, or incompatible dependencies detected. Installing/updating...
goto INSTALL_DEPS

:DOWNLOAD_PY
echo [Archipelago] Setting up clean, isolated Python environment. Please wait...
echo [Archipelago] Downloading lightweight portable Python (3.11)...

mkdir "%PORTABLE_PY_DIR%" >nul 2>&1

:: Download portable Python zip silently using PowerShell Tls12 protocol
powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; (New-Object System.Net.WebClient).DownloadFile('https://www.python.org/ftp/python/3.11.9/python-3.11.9-embed-amd64.zip', '%CLIENT_DIR%\python.zip')"

if not exist "%CLIENT_DIR%\python.zip" (
    echo [Archipelago] ERROR: Failed to download portable Python!
    pause
    exit /b 1
)

echo [Archipelago] Extracting Python package...
powershell -Command "Expand-Archive -Path '%CLIENT_DIR%\python.zip' -DestinationPath '%PORTABLE_PY_DIR%' -Force"
del "%CLIENT_DIR%\python.zip" >nul 2>&1

:: Enable site-packages in the embedded Python environment by adding import site
set "PTH_FILE=%PORTABLE_PY_DIR%\python311._pth"
if exist "%PTH_FILE%" (
    echo import site >> "%PTH_FILE%"
)

echo [Archipelago] Installing standalone package manager (pip)...
powershell -Command "(New-Object System.Net.WebClient).DownloadFile('https://bootstrap.pypa.io/get-pip.py', '%PORTABLE_PY_DIR%\get-pip.py')"
"%PYTHON_EXE%" "%PORTABLE_PY_DIR%\get-pip.py" --no-warn-script-location >nul 2>&1
del "%PORTABLE_PY_DIR%\get-pip.py" >nul 2>&1

:INSTALL_DEPS
echo [Archipelago] Installing required dependencies (websockets 13.1, colorama, pyyaml, certifi, jellyfish, platformdirs, pathspec, typing_extensions, attrs, schema)...
"%PYTHON_EXE%" -m pip install "websockets>=13.1,<14" colorama==0.4.6 pyyaml==6.0.3 certifi==2026.2.25 jellyfish==1.2.1 platformdirs==4.9.4 pathspec==1.0.4 typing_extensions==4.15.0 attrs==26.1.0 schema==0.7.8 --no-warn-script-location >nul 2>&1

echo [Archipelago] Environment setup completed successfully!

:RUN_CLIENT
:: 3. Double-check client entrypoint exists
if not exist "%CLIENT_PY%" (
    echo [Archipelago] ERROR: Standalone client script not found!
    echo Looked in: "%CLIENT_PY%"
    pause
    exit /b 1
)

echo [Archipelago] Starting Autonomous Client...
:: 4. Launch the client in the background and redirect output to log
start "ArchipelagoClient" cmd /k ""%PYTHON_EXE%" "%CLIENT_PY%" --nogui >> "%MOD_FOLDER%archipelago_debug.log" 2>&1"

echo [Archipelago] Launching Game...
:: 5. Launch the game if arguments are passed (standard Steam launch)
if not "%~1"=="" (
    start "" %* -netconport 3000
) else (
    echo [Archipelago] No game arguments provided.
    echo [Archipelago] If you are running from Steam, this is normal.
)

:: 6. Wait for game to exit and then clean up the client
:WAITLOOP
timeout /t 2 /nobreak >nul
tasklist /FI "IMAGENAME eq p2ce.exe" 2>NUL | find /I /N "p2ce.exe">NUL
if "%ERRORLEVEL%"=="0" goto WAITLOOP

tasklist /FI "IMAGENAME eq portal2.exe" 2>NUL | find /I /N "portal2.exe">NUL
if "%ERRORLEVEL%"=="0" goto WAITLOOP

echo [Archipelago] Game closed. Cleaning up client...
taskkill /FI "WINDOWTITLE eq ArchipelagoClient*" /T /F >nul 2>&1

exit /b 0