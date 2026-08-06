@echo off
REM Build script for NSIS Installer

setlocal

set "INSTALLER_DIR=%~dp0"
set "NSIS_PATH=C:\Program Files (x86)\NSIS\makensis.exe"

echo.
echo ============================================
echo Adesso Document Analyzer - Installer Builder
echo ============================================
echo.

REM Check if NSIS is installed
if not exist "%NSIS_PATH%" (
    echo ERROR: NSIS is not installed
    echo.
    echo Please install NSIS from: https://nsis.sourceforge.io/
    echo.
    echo After installation, run this script again.
    pause
    exit /b 1
)

echo NSIS found: %NSIS_PATH%
echo.

REM Build installer
echo Building installer...
echo.

cd /d "%INSTALLER_DIR%"
"%NSIS_PATH%" /V4 installer.nsi

if errorlevel 1 (
    echo ERROR: Failed to build installer
    pause
    exit /b 1
)

echo.
echo ============================================
echo Installer created successfully!
echo ============================================
echo.
echo File: Adesso-Document-Analyzer-Setup-1.0.0.exe
echo Location: %INSTALLER_DIR%
echo.
echo You can now:
echo 1. Test the installer on this PC
echo 2. Share the installer with other users
echo 3. Upload to your download server
echo.
pause
