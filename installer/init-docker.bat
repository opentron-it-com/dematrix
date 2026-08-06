@echo off
REM Initialize Docker Engine for standalone installer

setlocal enabledelayedexpansion

set "APP_DIR=%~dp0"
set "DOCKER_HOME=%APP_DIR%docker-engine"
set "LOG_FILE=%APP_DIR%init-docker.log"

echo. > "%LOG_FILE%"
echo ============================================ >> "%LOG_FILE%"
echo Docker Engine Initialization - %date% %time% >> "%LOG_FILE%"
echo ============================================ >> "%LOG_FILE%"
echo. >> "%LOG_FILE%"

echo.
echo ============================================
echo Docker Engine Setup
echo ============================================
echo.

REM Check if Docker is already installed on system
docker version >nul 2>&1
if errorlevel 0 (
    echo Docker found on system
    echo Using system Docker installation
    goto :DOCKER_READY
)

echo Docker not found in PATH
echo.

REM Check for portable Docker in installation directory
if exist "%DOCKER_HOME%\docker.exe" (
    echo Found portable Docker in: %DOCKER_HOME%
    set "PATH=%DOCKER_HOME%;!PATH!"
    echo Added to PATH: %DOCKER_HOME%
    goto :DOCKER_READY
)

echo.
echo ERROR: Docker not found
echo.
echo Please install Docker from: https://www.docker.com/products/docker-desktop
echo OR ensure portable Docker is in: %DOCKER_HOME%
echo.
pause
exit /b 1

:DOCKER_READY
echo.
echo Verifying Docker daemon...
docker ps >nul 2>&1

if errorlevel 1 (
    echo ERROR: Docker daemon is not responding
    echo.
    echo Trying to start Docker daemon...
    
    REM Try to start Docker
    if exist "%DOCKER_HOME%\dockerd.exe" (
        start "" "%DOCKER_HOME%\dockerd.exe" --log-level=info
        echo Waiting for Docker daemon to start...
        timeout /t 5
    ) else (
        echo ERROR: Docker daemon not found
        echo Please start Docker Desktop manually
        echo.
        pause
        exit /b 1
    )
)

echo Docker daemon is ready.
echo.
echo Docker Initialization Complete!
echo.
