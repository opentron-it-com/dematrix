@echo off
REM Standalone Launcher - Orchestrates entire startup process
REM This runs on first launch to: setup Docker -> load images -> start services

setlocal enabledelayedexpansion

set "APP_DIR=%~dp0"
set "LOG_FILE=%APP_DIR%first-launch.log"

echo. > "%LOG_FILE%"
echo ============================================ >> "%LOG_FILE%"
echo Standalone Launcher - First Run - %date% %time% >> "%LOG_FILE%"
echo ============================================ >> "%LOG_FILE%"
echo. >> "%LOG_FILE%"

echo.
echo ============================================
echo Adesso Document Analyzer - First Launch
echo ============================================
echo.
echo Initializing services (this may take 5-10 minutes on first run)
echo.

REM Step 1: Initialize Docker
echo [1/4] Initializing Docker Engine...
call "%APP_DIR%init-docker.bat" >> "%LOG_FILE%" 2>&1
if errorlevel 1 (
    echo ERROR: Failed to initialize Docker
    echo Check log: %LOG_FILE%
    pause
    exit /b 1
)
echo [1/4] Docker Engine initialized successfully

REM Step 2: Load Docker images
echo.
echo [2/4] Loading Docker images (this may take 3-5 minutes)...
echo Please wait, do not close this window...
echo.

call "%APP_DIR%load-images.bat" >> "%LOG_FILE%" 2>&1
if errorlevel 1 (
    echo ERROR: Failed to load Docker images
    echo Check log: %LOG_FILE%
    pause
    exit /b 1
)
echo [2/4] Docker images loaded successfully

REM Step 3: Create Docker network and volumes
echo.
echo [3/4] Preparing services...

cd /d "%APP_DIR%"
docker network create docnet >nul 2>&1
if errorlevel 0 (
    echo Docker network created
) else (
    echo Docker network already exists
)

echo [3/4] Services prepared successfully

REM Step 4: Start services
echo.
echo [4/4] Starting services...
echo.

docker compose up -d >> "%LOG_FILE%" 2>&1
if errorlevel 1 (
    echo ERROR: Failed to start services
    echo Check log: %LOG_FILE%
    pause
    exit /b 1
)

REM Wait for services to become healthy
echo Waiting for services to become ready (this may take 30-60 seconds)...
echo.

set "WAIT_COUNT=0"
:WAIT_LOOP
docker compose ps 2>nul | find "healthy" >nul
if errorlevel 1 (
    if !WAIT_COUNT! LSS 30 (
        set /a WAIT_COUNT+=1
        timeout /t 2 /nobreak
        goto WAIT_LOOP
    )
)

echo.
echo ============================================
echo Services Started Successfully!
echo ============================================
echo.
echo Opening application in browser...
timeout /t 3

start http://localhost:3000

echo.
echo ============================================
echo Ready to Use!
echo ============================================
echo.
echo Frontend: http://localhost:3000
echo Backend API: http://localhost:8080/api
echo.
echo To view service status:
echo   docker compose ps
echo.
echo To view logs:
echo   docker compose logs -f
echo.
echo To stop services:
echo   docker compose down
echo   OR run stop.bat
echo.
echo.
