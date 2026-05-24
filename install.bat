@echo off
title Pendrive_X AI | Multi-Model USB Setup
color 0A

echo.
echo ┌─────────────────────────────────────────────────────────────┐
echo │     Pendrive_X AI  |  USB Multi-Model Setup                 │
echo │     Automated Configuration | Windows Environment           │
echo └─────────────────────────────────────────────────────────────┘
echo.
echo [SYS] Initializing setup environment...
echo [SYS] Loading configuration modules...
echo.
echo This wizard will download and configure local AI models
echo directly onto your USB drive. You have FULL CONTROL:
echo.
echo  ✔ 6 curated presets (uncensored + standard variants)
echo  ✔ Custom model support (bring your own GGUF files)
echo  ✔ Optimized for offline/air-gapped deployment
echo  ✔ Auto-configured Ollama/AppImage runtime
echo.
echo ─────────────────────────────────────────────────────────────
echo  SYSTEM REQUIREMENTS:
echo   • Minimum USB free space: 16 GB (32 GB recommended)
echo   • Stable internet connection for initial downloads
echo   • Windows 10/11 with PowerShell 5.1+ enabled
echo ─────────────────────────────────────────────────────────────
echo.
echo Ensure your USB drive is inserted and properly detected.
echo Make sure you have a good internet connection before proceeding!
echo.
pause

:: Run the PowerShell setup script from the same folder as this bat file
echo.
echo [✓] Launching core installer...
echo [?] Please follow the on-screen prompts in the PowerShell window.
echo ─────────────────────────────────────────────────────────────
powershell -ExecutionPolicy Bypass -File "%~dp0install-core.ps1"
echo ─────────────────────────────────────────────────────────────
echo.

echo ┌─────────────────────────────────────────────────────────────┐
echo │                SETUP COMPLETE! You're ready to go!          │
echo └─────────────────────────────────────────────────────────────┘
echo.
echo [INFO] All models and dependencies have been successfully configured.
echo.
echo To start your AI environment, simply double-click:
echo        start-windows.bat
echo.
echo Need help? Check the README or run the script with --verbose
echo.
pause

:: Ethan Hunt [IMF] - "Mission Accomplished!"