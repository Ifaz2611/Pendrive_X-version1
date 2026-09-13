@echo off
title Pendrive_X Doctor
color 0E
echo ===================================================
echo   Pendrive_X Doctor — Diagnostics
echo ===================================================
set "USB_ROOT=%~dp0"
echo USB: %USB_ROOT%
echo.

:: FS check
for /f "usebackq tokens=*" %%a in (`powershell -NoProfile -Command "try{$d='%~d0'; $v=Get-CimInstance -ClassName Win32_LogicalDisk -Filter \"DeviceID='$d'\" -ErrorAction Stop; \"$($v.FileSystem)|$([math]::Round($v.FreeSpace/1GB,1))|$([math]::Round($v.Size/1GB,1))\"} catch {'unknown'}"`) do echo FS ^& Space: %%a

:: RAM
for /f "usebackq tokens=*" %%a in (`powershell -NoProfile -Command "try{[math]::Round((Get-CimInstance Win32_ComputerSystem -ErrorAction Stop).TotalPhysicalMemory/1GB,1)} catch {-1}"`) do echo RAM GB: %%a

:: Installed models
if exist "%USB_ROOT%models\installed-models.txt" (
  echo.
  echo Installed models:
  type "%USB_ROOT%models\installed-models.txt"
) else (
  echo No installed-models.txt
)

:: GGUF size check
echo.
echo GGUF files:
dir "%USB_ROOT%models\*.gguf" 2>nul || echo  (none found)

:: Ollama binary
if exist "%USB_ROOT%ollama\ollama.exe" (echo Ollama: FOUND) else (echo Ollama: MISSING — run install.bat)

:: AnythingLLM
if exist "%USB_ROOT%anythingllm\AnythingLLM.exe" (echo AnythingLLM: FOUND) else (echo AnythingLLM: MISSING)

:: .env
echo.
echo .env:
if exist "%USB_ROOT%anythingllm_data\storage\.env" (type "%USB_ROOT%anythingllm_data\storage\.env") else (echo  (none))

:: Port 11434 busy?
powershell -NoProfile -Command "try{$c=Test-NetConnection 127.0.0.1 -Port 11434 -WarningAction SilentlyContinue; if($c.TcpTestSucceeded){Write-Host 'Port 11434: IN USE (host Ollama may be running)'} else {Write-Host 'Port 11434: free'}} catch {Write-Host 'Port check skipped'}" 2>nul

echo.
echo Logs: %USB_ROOT%installer_data\logs\ , %USB_ROOT%anythingllm_data\logs\
if exist "%USB_ROOT%installer_data\logs" dir "%USB_ROOT%installer_data\logs" /b
if exist "%USB_ROOT%anythingllm_data\logs" dir "%USB_ROOT%anythingllm_data\logs" /b
echo.
pause
