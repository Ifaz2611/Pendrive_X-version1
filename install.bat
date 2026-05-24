@echo off
title PENDRIVE_X AI - Multi-Model Setup
color 0B

echo.
echo ========================================================
echo           PENDRIVE_X AI - PORTABLE SETUP
echo ========================================================
echo.
echo    Welcome to PENDRIVE_X AI
echo.
echo    This will download and setup AI models on your USB.
echo.
echo    Features:
echo      * 6 Preset Models (Uncensored + Normal)
echo      * Custom GGUF Model Support
echo      * Fully Portable
echo.
echo    Recommended: 32GB USB Drive
echo    Internet needed for download.
echo.
echo ========================================================
echo.
pause

echo.
echo Starting setup...
timeout /t 2 /nobreak >nul

powershell -ExecutionPolicy Bypass -File "%~dp0install-core.ps1"

echo.
echo ========================================================
echo           SETUP COMPLETED SUCCESSFULLY!
echo ========================================================
echo.
echo Your AI is ready!
echo.
echo Run "start-windows.bat" to start.
echo.
echo ========================================================
pause