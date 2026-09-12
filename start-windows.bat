@echo off
title PENDRIVE_X AI - Launcher
color 0A

echo ===================================================
echo     Launching PENDRIVE_X Engine from USB...       
echo ===================================================

:: -------------------------------------------------------
:: IMPORTANT: All paths must point to USB, not the PC!
:: -------------------------------------------------------

:: Set Ollama model data path to the USB drive
set "OLLAMA_MODELS=%~dp0ollama\data"

:: Tell AnythingLLM to store ALL its data on the USB
:: STORAGE_DIR is the official AnythingLLM portable env var
set "STORAGE_DIR=%~dp0anythingllm_data"
set "ANYTHINGLLM_PROFILE=%STORAGE_DIR%\anythingllm-desktop"
set "ROAMING_PROFILE=%USERPROFILE%\AppData\Roaming\anythingllm-desktop"
set "PROFILE_BACKUP=%USERPROFILE%\AppData\Roaming\anythingllm-desktop.host-backup"

:: Also override APPDATA AND XDG paths for Electron safety net
set "APPDATA=%~dp0anythingllm_data"
set "LOCALAPPDATA=%~dp0anythingllm_data"

:: Create the data folder on USB if it doesn't exist
if not exist "%~dp0anythingllm_data" mkdir "%~dp0anythingllm_data"
if not exist "%ANYTHINGLLM_PROFILE%" mkdir "%ANYTHINGLLM_PROFILE%"

:: -------------------------------------------------------
:: ENSURE ANYTHINGLLM USES EXTERNAL OLLAMA (not built-in)
:: -------------------------------------------------------
set "ENV_FILE=%~dp0anythingllm_data\storage\.env"
if not exist "%~dp0anythingllm_data\storage" mkdir "%~dp0anythingllm_data\storage"

:: Read the first model from installed-models.txt if it exists
set "DEFAULT_MODEL=nemomix-local"
if exist "%~dp0models\installed-models.txt" (
    for /f "usebackq tokens=1 delims=|" %%a in ("%~dp0models\installed-models.txt") do (
        set "DEFAULT_MODEL=%%a"
        goto :GotModel
    )
)
:GotModel

:: Check if .env needs fixing (missing or using built-in ollama)
set "NEEDS_FIX=0"
if not exist "%ENV_FILE%" set "NEEDS_FIX=1"
if exist "%ENV_FILE%" (
    findstr /C:"LLM_PROVIDER=ollama" "%ENV_FILE%" >nul 2>&1
    if errorlevel 1 set "NEEDS_FIX=1"
    findstr /C:"LLM_PROVIDER=anythingllm_ollama" "%ENV_FILE%" >nul 2>&1
    if not errorlevel 1 set "NEEDS_FIX=1"
)

if "%NEEDS_FIX%"=="1" (
    echo Configuring AnythingLLM to use external Ollama engine...
    (
        echo LLM_PROVIDER=ollama
        echo OLLAMA_BASE_PATH=http://127.0.0.1:11434
        echo OLLAMA_MODEL_PREF=%DEFAULT_MODEL%
        echo OLLAMA_MODEL_TOKEN_LIMIT=4096
        echo EMBEDDING_ENGINE=native
        echo VECTOR_DB=lancedb
    ) > "%ENV_FILE%"
    echo Done. Default model: %DEFAULT_MODEL%
)

:: -------------------------------------------------------
:: PROFILE REDIRECT PREVENTED
:: -------------------------------------------------------
:: Electron '--user-data-dir' completely overrides profile creation,
:: ensuring Everything is purely portable on the USB drive.


:: -------------------------------------------------------
:: SHOW INSTALLED MODELS
:: -------------------------------------------------------
if exist "%~dp0models\installed-models.txt" (
    echo.
    echo Installed models:
    for /f "usebackq tokens=1,2,3 delims=|" %%a in ("%~dp0models\installed-models.txt") do (
        echo   - %%b [%%c]
    )
    echo.
)

:: Start Ollama Engine silently in the background with PID capture
echo Starting Ollama Engine...
set "OLLAMA_PID="
for /f "usebackq tokens=*" %%p in (`powershell -NoProfile -Command "$p=Start-Process -FilePath '%~dp0ollama\ollama.exe' -ArgumentList 'serve' -WindowStyle Hidden -PassThru; $p.Id"`) do set "OLLAMA_PID=%%p"
if not defined OLLAMA_PID (
    echo [WARN] Could not capture Ollama PID - fallback to background start
    start "" /B "%~dp0ollama\ollama.exe" serve
) else (
    echo Ollama PID: %OLLAMA_PID%
)
set "PID_FILE=%~dp0anythingllm_data\.session_pids"
if defined OLLAMA_PID echo %OLLAMA_PID% > "%PID_FILE%"

:: Health check: wait for Ollama API instead of blind 3s sleep
echo Waiting for Ollama to be ready...
set "OLLAMA_READY=0"
for /L %%i in (1,1,30) do (
    powershell -NoProfile -Command "try { Invoke-RestMethod -Uri 'http://127.0.0.1:11434/api/tags' -TimeoutSec 2 | Out-Null; exit 0 } catch { exit 1 }" >nul 2>&1
    if not errorlevel 1 (
        set "OLLAMA_READY=1"
        goto :OllamaReady
    )
    timeout /t 1 /nobreak >nul
)
:OllamaReady
if "%OLLAMA_READY%"=="0" (
    echo [WARN] Ollama did not become ready in 30s - continuing anyway...
) else (
    echo Ollama is ready.
)

:: Find and launch AnythingLLM
echo Starting AnythingLLM Interface...

if exist "%~dp0anythingllm\AnythingLLM.exe" (
    set "APP_PATH=%~dp0anythingllm\AnythingLLM.exe"
    goto LaunchApp
)

echo.
echo ERROR: AnythingLLM was not found in 'anythingllm' folder!
echo.
echo Directory Listing for Diagnostic:
dir "%~dp0anythingllm"
echo.
echo Please run install.bat first to download and extract everything.
echo.
:: Clean up orphan Ollama if we started one
if defined OLLAMA_PID taskkill /PID %OLLAMA_PID% /T /F >nul 2>&1
if exist "%PID_FILE%" del "%PID_FILE%" 2>nul
pause
exit /b 1

:LaunchApp
:: CRITICAL: We MUST wipe ONLY hardware-dependent Electron caches for portability.
:: Do NOT delete config.json — it holds user settings. Only wipe GPU/Shader caches.
:: This fixes the "JavaScript error (ENOENT)" when moving USBs between PCs.
set "ELECTRON_CACHE=%~dp0anythingllm_data\anythingllm-desktop"
if exist "%ELECTRON_CACHE%\GPUCache" rmdir /s /q "%ELECTRON_CACHE%\GPUCache"
if exist "%ELECTRON_CACHE%\Cache" rmdir /s /q "%ELECTRON_CACHE%\Cache"
if exist "%ELECTRON_CACHE%\Code Cache" rmdir /s /q "%ELECTRON_CACHE%\Code Cache"
if exist "%ELECTRON_CACHE%\ShaderCache" rmdir /s /q "%ELECTRON_CACHE%\ShaderCache"
:: Legacy fallback — older versions stored cache at root
if exist "%~dp0anythingllm_data\Cache" rmdir /s /q "%~dp0anythingllm_data\Cache"
if exist "%~dp0anythingllm_data\GPUCache" rmdir /s /q "%~dp0anythingllm_data\GPUCache"

:: CRITICAL: We MUST pushd into the app directory for the portable app to find its own resources!
pushd "%~dp0anythingllm"
:: Pass --user-data-dir 
start "" "AnythingLLM.exe" --user-data-dir="%~dp0anythingllm_data"
popd

:Running
echo.
echo ===================================================
echo   SYSTEM ONLINE: Your AI is running from the USB!  
echo ===================================================
echo.
echo You can now use the AnythingLLM window to chat.
echo Keep this black window open to keep the AI engine running!
echo.
echo TIP: Go to Settings ^> LLM to switch between models.
echo.
echo Press any key to SHUT DOWN the AI safely...
echo.
pause

:: Clean shutdown — kill only OUR PIDs, never a host Ollama blindly
if defined OLLAMA_PID (
    taskkill /PID %OLLAMA_PID% /T /F >nul 2>&1
) else if exist "%PID_FILE%" (
    for /f "tokens=1" %%a in (%PID_FILE%) do taskkill /PID %%a /T /F >nul 2>&1
    del "%PID_FILE%" 2>nul
) else (
    :: Last resort: only kill ollama.exe that lives on THIS USB path
    for /f "usebackq tokens=*" %%p in (`powershell -NoProfile -Command "Get-Process ollama -ErrorAction SilentlyContinue | Where-Object {$_.Path -eq '%~dp0ollama\ollama.exe'} | Select-Object -ExpandProperty Id -First 1"`) do taskkill /PID %%p /T /F >nul 2>&1
)
taskkill /F /IM "AnythingLLM.exe" >nul 2>&1
if exist "%PID_FILE%" del "%PID_FILE%" 2>nul
echo.
echo AI Engine shut down. You may safely eject the USB.
timeout /t 3 >nul
