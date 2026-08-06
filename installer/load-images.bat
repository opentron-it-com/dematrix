@echo off
REM Load Docker images from standalone installer package

setlocal enabledelayedexpansion

set "APP_DIR=%~dp0"
set "IMAGES_DIR=%APP_DIR%docker-images"
set "LOG_FILE=%APP_DIR%load-images.log"

if exist "%APP_DIR%docker-env.cmd" call "%APP_DIR%docker-env.cmd"
if not defined DOCKER_CLI (
    if exist "%APP_DIR%docker-engine\docker.exe" (
        set "DOCKER_CLI=%APP_DIR%docker-engine\docker.exe"
    ) else (
        set "DOCKER_CLI=docker"
    )
)
if defined DOCKER_HOST (
    set "DOCKER_ARGS=--host %DOCKER_HOST%"
) else (
    set "DOCKER_ARGS="
)

echo. > "%LOG_FILE%"
echo ============================================ >> "%LOG_FILE%"
echo Docker Image Loader - %date% %time% >> "%LOG_FILE%"
echo ============================================ >> "%LOG_FILE%"
echo. >> "%LOG_FILE%"

echo.
echo ============================================
echo Loading Docker Images
echo ============================================
echo.

REM Check if images directory exists
if not exist "%IMAGES_DIR%" (
    echo ERROR: Docker images directory not found
    echo Expected: %IMAGES_DIR%
    pause
    exit /b 1
)

echo Found images directory: %IMAGES_DIR%
echo.

REM Check Docker daemon
echo Checking Docker daemon...
if defined DOCKER_CLI (
    "%DOCKER_CLI%" %DOCKER_ARGS% ps >nul 2>&1
) else (
    docker %DOCKER_ARGS% ps >nul 2>&1
)
if errorlevel 1 (
    echo ERROR: Docker is not running
    echo Please start Docker Desktop or Docker Engine
    pause
    exit /b 1
)
echo Docker daemon is running.
echo.

REM Count and load images
set "LOADED=0"
set "FAILED=0"

echo Loading images...
echo.

for %%F in ("%IMAGES_DIR%\*.tar") do (
    set "FILENAME=%%~nxF"
    echo Loading: !FILENAME!
    
    echo Starting image load (this may take several minutes): !FILENAME!
    powershell -NoProfile -Command "& { & '%DOCKER_CLI%' %DOCKER_ARGS% load -i '%%~fF' 2>&1 | Tee-Object -FilePath '%LOG_FILE%' -Append }"
    
    if errorlevel 1 (
        echo ERROR: Failed to load !FILENAME!
        echo ERROR: Failed to load !FILENAME! >> "%LOG_FILE%"
        set /a FAILED+=1
    ) else (
        echo Successfully loaded: !FILENAME!
        echo Successfully loaded: !FILENAME! >> "%LOG_FILE%"
        set /a LOADED+=1
    )
    echo.
)

echo ============================================
echo Image Loading Complete
echo ============================================
echo.
echo Successfully loaded: %LOADED% image(s)
if %FAILED% GTR 0 (
    echo Failed: %FAILED% image(s)
)
echo.
echo Log saved to: %LOG_FILE%
echo.

if %FAILED% GTR 0 (
    pause
    exit /b 1
)

pause
