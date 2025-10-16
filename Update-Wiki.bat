@echo off
REM Batch file wrapper for Update-WikiHome.ps1
REM This allows easy execution by double-clicking on Windows

echo.
echo ========================================
echo Fellows ^& Associates Wiki Updater
echo ========================================
echo.

REM Check if running from correct directory
if not exist "Update-WikiHome.ps1" (
    echo ERROR: Update-WikiHome.ps1 not found!
    echo Please run this script from the repository root directory.
    echo.
    pause
    exit /b 1
)

REM Run the PowerShell script
echo Running wiki home update script...
echo.

pwsh -ExecutionPolicy Bypass -File "Update-WikiHome.ps1"

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================
    echo SUCCESS! Home.md has been updated.
    echo ========================================
) else (
    echo.
    echo ========================================
    echo ERROR: Update failed. See above for details.
    echo ========================================
)

echo.
echo Press any key to exit...
pause >nul
