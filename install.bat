@echo off
:: Disable command echoing to keep the console output clean and professional

title PENDRIVE_X AI - Multi-Model Setup
:: Set the title of the console window

color 0B
:: Set the console color scheme: 0 = Black background, B = Light Aqua text

echo.
:: Print a blank line for spacing

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
:: Display the welcome banner, feature list, and requirements to the user

pause
:: Halt execution and wait for the user to press any key to continue

echo.
echo Starting setup...
:: Inform the user that the automated setup process is beginning

timeout /t 2 /nobreak >nul
:: Pause execution for 2 seconds to let the user read the message. 
:: /nobreak prevents the user from skipping the wait, and >nul hides the countdown timer.

powershell -ExecutionPolicy Bypass -File "%~dp0install-core.ps1"
:: Execute the core PowerShell installation script.
:: -ExecutionPolicy Bypass allows the script to run without changing system-wide security settings.
:: "%~dp0" dynamically resolves to the drive letter and folder path where this batch file is located.

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
:: Display the final success banner and provide instructions on how to launch the AI

pause
:: Halt execution one last time so the user can read the completion message before the window closes

@REM Signing OFF IMF [Ethen Hunt] Code name ["Bravo Echo 11"]
:: Original author signature/comment