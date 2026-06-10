@echo off
title P2CE Archipelago Launcher
setlocal enabledelayedexpansion

:: 1. Define paths relative to the mod folder
set "MOD_FOLDER=%~dp0"
set "CLIENT_DIR=%MOD_FOLDER%client"
set "CLIENT_PY=%CLIENT_DIR%\run_client.py"
set "PORTABLE_PY_DIR=%CLIENT_DIR%\python_env"
set "PYTHON_EXE=%PORTABLE_PY_DIR%\python.exe"
set "GAMEINFO_FILE=%MOD_FOLDER%gameinfo.txt"

:: 2. Dynamic Language Catching from Steam Arguments
set "SELECTED_LANGUAGE=english"

:PARSE_ARGS
if "%~1"=="" goto END_PARSE_ARGS
if /i "%~1"=="-language" (
    if not "%~2" == "" (
        set "SELECTED_LANGUAGE=%~2"
        echo [Archipelago] Intercepted explicit language argument from Steam: !SELECTED_LANGUAGE!
    )
)
shift
goto PARSE_ARGS
:END_PARSE_ARGS

:: 3. Dynamically Rewrite gameinfo.txt SearchPaths
if exist "!GAMEINFO_FILE!" (
    echo [Archipelago] Cleaning old localized language mappings from gameinfo.txt...
    
    :: Remove any previously injected or commented lines mapping back to portal2_ language structures
    powershell -Command "$content = Get-Content '!GAMEINFO_FILE!' | Where-Object { $_ -notmatch 'portal2_.*_dir.vpk' -and $_ -notmatch 'portal2_[a-zA-Z]' }; Set-Content '!GAMEINFO_FILE!' $content"

    if /i not "!SELECTED_LANGUAGE!"=="english" if not "!SELECTED_LANGUAGE!"=="" (
        echo [Archipelago] Customizing gameinfo.txt SearchPaths for non-English language: '!SELECTED_LANGUAGE!'...
        
        :: Generate the exact tabs and spacing formatting strings
        set "LANG_VPK=			Game				portal2/portal2_!SELECTED_LANGUAGE!/pak01_dir.vpk"
        set "LANG_DIR=			Game				portal2/portal2_!SELECTED_LANGUAGE!"
        
        :: CRITICAL: Read, look for the core portal2 line, insert custom configurations strictly ABOVE it, and save back down
        powershell -Command "$vpk = '			Game				portal2/portal2/portal2.vpk'; $lines = Get-Content '!GAMEINFO_FILE!'; $newLines = foreach ($line in $lines) { if ($line.Trim() -eq $vpk.Trim()) { '!LANG_VPK!'; '!LANG_DIR!'; $line } else { $line } }; Set-Content '!GAMEINFO_FILE!' $newLines"
        
        echo [Archipelago] gameinfo.txt search paths optimized successfully for custom language.
    ) else (
        echo [Archipelago] Language is English or blank. Keeping gameinfo.txt clean with native base paths.
    )
) else (
    echo [Archipelago] WARNING: gameinfo.txt not found! Skipping localization mount rules.
)

:: 4. Check and build the standalone Python environment on first run
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
:: 5. Double-check client entrypoint exists
if not exist "%CLIENT_PY%" (
    echo [Archipelago] ERROR: Standalone client script not found!
    echo Looked in: "%CLIENT_PY%"
    pause
    exit /b 1
)

echo [Archipelago] Starting Autonomous Client...
:: 6. Launch the client in the background and redirect output to log
start "ArchipelagoClient" cmd /k ""%PYTHON_EXE%" "%CLIENT_PY%" --nogui >> "%MOD_FOLDER%archipelago_debug.log" 2>&1"

echo [Archipelago] Launching Game...
:: 7. Re-parse original command parameters to run the native game binary hook correctly
set "ARGS="
:COLLECT_ARGS
if "%~1"=="" goto RUN_GAME
set "ARGS=!ARGS! %1"
shift
goto COLLECT_ARGS

:RUN_GAME
:: Boot P2CE engine, binding network connection interfaces and matching game language strings
start "" !ARGS! -netconport 3000 -language !SELECTED_LANGUAGE!

:: 8. Wait for game to exit and then clean up the client
:WAITLOOP
timeout /t 2 /nobreak >nul
tasklist /FI "IMAGENAME eq p2ce.exe" 2>NUL | find /I /N "p2ce.exe">NUL
if "%ERRORLEVEL%"=="0" goto WAITLOOP

tasklist /FI "IMAGENAME eq portal2.exe" 2>NUL | find /I /N "portal2.exe">NUL
if "%ERRORLEVEL%"=="0" goto WAITLOOP

echo [Archipelago] Game closed. Cleaning up client...
taskkill /FI "WINDOWTITLE eq ArchipelagoClient*" /T /F >nul 2>&1

exit /b 0