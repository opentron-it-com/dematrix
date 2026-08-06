@echo off
REM Adesso Document Analyzer - Standalone Installer
REM This script creates a self-contained installer with Docker images pre-loaded

setlocal enabledelayedexpansion

set "INSTALLER_NAME=Adesso Document Analyzer Installer"
set "VERSION=1.0.0"
set "APP_DIR=%ProgramFiles%\Adesso\DocumentAnalyzer"
set "DATA_DIR=%APPDATA%\Adesso\DocumentAnalyzer"

cls
echo.
echo ============================================
echo %INSTALLER_NAME% v%VERSION%
echo ============================================
echo.

REM Check if running as administrator
net session >nul 2>&1
if errorlevel 1 (
    echo ERROR: This installer must run as Administrator
    echo.
    echo Right-click the installer and select "Run as Administrator"
    pause
    exit /b 1
)

REM Check Docker installation
echo [1/5] Checking Docker installation...
docker --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Docker Desktop is not installed or not in PATH
    echo.
    echo Please install Docker Desktop from: https://www.docker.com/products/docker-desktop
    echo.
    echo After installing Docker Desktop, run this installer again.
    pause
    exit /b 1
)

echo Docker found: 
docker --version
echo.

REM Check Docker daemon
echo [2/5] Checking Docker daemon...
docker ps >nul 2>&1
if errorlevel 1 (
    echo ERROR: Docker daemon is not running
    echo.
    echo Please start Docker Desktop and try again.
    pause
    exit /b 1
)

echo Docker daemon is running.
echo.

REM Create installation directories
echo [3/5] Creating installation directories...
if not exist "%APP_DIR%" mkdir "%APP_DIR%"
if not exist "%DATA_DIR%" mkdir "%DATA_DIR%"
if not exist "%DATA_DIR%\postgres" mkdir "%DATA_DIR%\postgres"
if not exist "%DATA_DIR%\chroma" mkdir "%DATA_DIR%\chroma"
if not exist "%DATA_DIR%\ollama" mkdir "%DATA_DIR%\ollama"

echo Installation directories created.
echo App directory: %APP_DIR%
echo Data directory: %DATA_DIR%
echo.

REM Copy compose file
echo [4/5] Installing Docker Compose configuration...
copy /Y "%~dp0docker-compose.yml" "%APP_DIR%\docker-compose.yml" >nul
copy /Y "%~dp0.env" "%APP_DIR%\.env" >nul
copy /Y "%~dp0launch.bat" "%APP_DIR%\launch.bat" >nul
copy /Y "%~dp0stop.bat" "%APP_DIR%\stop.bat" >nul
copy /Y "%~dp0README.txt" "%APP_DIR%\README.txt" >nul

echo Docker Compose configuration installed.
echo.

REM Pre-load Docker images
echo [5/5] Pre-loading Docker images...
echo This may take 10-30 minutes depending on your internet speed.
echo.

set "IMAGES=postgres:16-alpine ghcr.io/chroma-core/chroma:latest ollama/ollama:latest nginx:alpine"

for %%I in (%IMAGES%) do (
    echo Pulling %%I...
    docker pull %%I
    if errorlevel 1 (
        echo WARNING: Failed to pull %%I
        echo The image will be downloaded on first run.
    )
)

echo.
echo Images pre-loaded.
echo.

REM Create shortcuts
echo Creating shortcuts...
powershell -Command "$WshShell = New-Object -ComObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('%USERPROFILE%\Desktop\Adesso Document Analyzer.lnk'); $Shortcut.TargetPath = '%APP_DIR%\launch.bat'; $Shortcut.WorkingDirectory = '%APP_DIR%'; $Shortcut.Save()"

powershell -Command "$WshShell = New-Object -ComObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('%APPDATA%\Microsoft\Windows\Start Menu\Programs\Adesso Document Analyzer.lnk'); $Shortcut.TargetPath = '%APP_DIR%\launch.bat'; $Shortcut.WorkingDirectory = '%APP_DIR%'; $Shortcut.Save()"

echo.
echo ============================================
echo Installation Complete!
echo ============================================
echo.
echo Adesso Document Analyzer has been installed to:
echo %APP_DIR%
echo.
echo Data directory:
echo %DATA_DIR%
echo.
echo Shortcuts created:
echo - Desktop: Adesso Document Analyzer
echo - Start Menu: Adesso Document Analyzer
echo.
echo To launch the application:
echo 1. Click the desktop shortcut, OR
echo 2. Search for "Adesso Document Analyzer" in Start Menu
echo.
echo FIRST RUN:
echo - Docker containers will start automatically
echo - Services may take 30-60 seconds to become ready
echo - Open browser to http://localhost:3000
echo.
echo To stop the application:
echo - Run stop.bat from the installation directory, OR
echo - Use Docker Desktop
echo.
pause
