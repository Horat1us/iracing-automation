@echo off
setlocal EnableDelayedExpansion
title iRacing Automation - Setup

echo ========================================
echo  iRacing Automation Setup
echo ========================================
echo.

REM Function to check PowerShell versions
:CheckPowerShell
echo [1/3] Checking PowerShell availability...

REM Check for PowerShell 7+
pwsh -Version >nul 2>&1
if %errorlevel% equ 0 (
    echo ✅ PowerShell 7+ detected - Using modern PowerShell
    set "POWERSHELL_CMD=pwsh"
    goto :RunInstall
)

REM Check for PowerShell 5.1
powershell -Command "exit" >nul 2>&1
if %errorlevel% equ 0 (
    REM Check version to ensure it's 5.1+
    for /f "tokens=*" %%i in ('powershell -Command "$PSVersionTable.PSVersion.Major"') do set PS_MAJOR=%%i
    if !PS_MAJOR! geq 5 (
        echo ✅ PowerShell 5.1+ detected - Using Windows PowerShell
        set "POWERSHELL_CMD=powershell"
        goto :RunInstall
    )
)

echo ❌ PowerShell not found or version too old
echo.
goto :OfferInstallation

:OfferInstallation
echo [2/3] PowerShell Installation Required
echo.
echo iRacing Automation requires PowerShell to function.
echo We can automatically install PowerShell 7 for you.
echo.
set /p choice="Install PowerShell automatically? (Y/N): "
if /i "%choice%"=="Y" goto :InstallPowerShell
if /i "%choice%"=="yes" goto :InstallPowerShell

echo.
echo Manual Installation:
echo 1. Install via Microsoft Store: "PowerShell"
echo 2. Or download from: https://github.com/PowerShell/PowerShell/releases
echo.
echo Re-run this installer after PowerShell is installed.
pause
exit /b 1

:InstallPowerShell
echo.
echo Installing PowerShell via WinGet...

REM Check if WinGet is available
winget --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ WinGet not available on this system
    echo.
    echo Please install PowerShell manually:
    echo 1. Microsoft Store: Search for "PowerShell"
    echo 2. Direct download: https://github.com/PowerShell/PowerShell/releases
    echo.
    pause
    exit /b 1
)

echo Installing Microsoft PowerShell...
winget install Microsoft.PowerShell --accept-source-agreements --accept-package-agreements

if %errorlevel% equ 0 (
    echo ✅ PowerShell installed successfully!
    echo.
    echo Please restart this installer to continue.
    pause
    exit /b 0
) else (
    echo ❌ PowerShell installation failed
    echo.
    echo Please try manual installation:
    echo 1. Microsoft Store: Search for "PowerShell" 
    echo 2. Direct download: https://github.com/PowerShell/PowerShell/releases
    pause
    exit /b 1
)

:RunInstall
echo.
echo [3/3] Starting iRacing Automation installation...
echo This may take a few moments...
echo.

%POWERSHELL_CMD% -ExecutionPolicy Bypass -NoProfile -File "%~dp0scripts\Install.ps1"

if %errorlevel% equ 0 (
    echo.
    echo ✅ Installation completed successfully!
) else (
    echo.
    echo ❌ Installation encountered issues. Check the output above.
)

echo.
echo Press any key to exit...
pause >nul