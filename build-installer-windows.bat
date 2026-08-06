@echo off
REM Adesso Document Analyzer - Local Desktop Installer
REM This script sets up all dependencies and creates the installer

echo.
echo ============================================
echo Adesso Document Analyzer - Desktop Setup
echo ============================================
echo.

REM Check if Node.js is installed
node --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Node.js is not installed or not in PATH
    echo Please install Node.js from https://nodejs.org/
    pause
    exit /b 1
)

echo [1/5] Installing dependencies...
call npm install
if errorlevel 1 (
    echo ERROR: Failed to install dependencies
    pause
    exit /b 1
)

echo [2/5] Checking Docker installation...
docker --version >nul 2>&1
if errorlevel 1 (
    echo WARNING: Docker is not installed or not in PATH
    echo The application requires Docker to run
    echo Please install Docker Desktop from https://www.docker.com/products/docker-desktop
    pause
    exit /b 1
)

echo [3/5] Starting services...
cd docker
docker compose up -d
cd ..
echo Services started in background
timeout /t 5

echo [4/5] Building React application...
call npm run react-build
if errorlevel 1 (
    echo ERROR: Failed to build React application
    pause
    exit /b 1
)

echo [5/5] Creating desktop installer...
call npm run build-win
if errorlevel 1 (
    echo ERROR: Failed to create installer
    pause
    exit /b 1
)

echo.
echo ============================================
echo Installation Complete!
echo ============================================
echo.
echo Installer created in: dist/
echo.
echo System Requirements:
echo  - Windows 10 or later
echo  - 8GB RAM (minimum)
echo  - 10GB free disk space
echo  - Docker Desktop installed and running
echo.
echo To install the application:
echo  1. Run the installer from the dist/ folder
echo  2. Follow the installation wizard
echo  3. Launch from Start Menu or Desktop shortcut
echo.
pause
