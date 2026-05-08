@echo off
title P2CE Archipelago Launcher

:: 1. On définit les chemins précis (grâce à ton arborescence)
set "MOD_FOLDER=%~dp0"
set "ARCHIPELAGO_LOCAL=%MOD_FOLDER%archipelago"
set "PYTHON_EXE=%ARCHIPELAGO_LOCAL%\libs\python.exe"
set "CLIENT_PY=%ARCHIPELAGO_LOCAL%\worlds\portal2_p2ce\client\Portal2Client.py"

:: 2. Vérification de l'exécutable Python
if not exist "%PYTHON_EXE%" (
    echo [Archipelago] ERROR: Bundled Python not found!
    echo Looked in: "%PYTHON_EXE%"
    pause
    exit /b 1
)

:: 3. Vérification du fichier client (Portal2Client.py)
if not exist "%CLIENT_PY%" (
    echo [Archipelago] ERROR: Client script not found!
    echo Looked in: "%CLIENT_PY%"
    pause
    exit /b 1
)

echo [Archipelago] Starting Autonomous Client...
:: 4. On lance Python en lui donnant le fichier directement
:: On utilise cmd /c pour que la fenêtre se ferme d'elle-même si le processus finit
start "ArchipelagoClient" cmd /c ""%PYTHON_EXE%" "%CLIENT_PY%" --nogui"

echo [Archipelago] Launching Game...
:: 5. Sécurité : On ne lance le jeu que si des arguments ont été passés (ex: via Steam)
if not "%~1"=="" (
    start "" %*
) else (
    echo [Archipelago] No game arguments provided.
    echo [Archipelago] If you are running from Steam, this is normal.
)

:: 6. Attente de la fermeture du jeu pour nettoyer
:WAITLOOP
timeout /t 2 /nobreak >nul
tasklist /FI "IMAGENAME eq p2ce.exe" 2>NUL | find /I /N "p2ce.exe">NUL
if "%ERRORLEVEL%"=="0" goto WAITLOOP

tasklist /FI "IMAGENAME eq portal2.exe" 2>NUL | find /I /N "portal2.exe">NUL
if "%ERRORLEVEL%"=="0" goto WAITLOOP

echo [Archipelago] Game closed. Cleaning up client...
:: On cible spécifiquement la fenêtre qu'on a nommée "ArchipelagoClient"
taskkill /FI "WINDOWTITLE eq ArchipelagoClient*" /T /F >nul 2>&1

exit /b 0