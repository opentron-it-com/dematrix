@echo off
SETLOCAL EnableDelayedExpansion
TITLE Adesso Document Analyzer Setup ^& Launcher

SET "APP_DIR=%~dp0"
CD /D "%APP_DIR%"

:: 1. Fast-Path Check: Is the application container stack actively running?
docker ps --format "{{.Names}}" 2>nul | findstr /R /C:"^doc-analyzer-nginx$" >nul 2>&1
if %errorLevel% equ 0 (
    echo Application is already running. Opening browser...
    start http://localhost:3000
    exit /b 0
)

:: 2. Quick-Start Check: Are containers installed but stopped?
docker ps -a --format "{{.Names}}" 2>nul | findstr /R /C:"^doc-analyzer-nginx$" >nul 2>&1
if %errorLevel% equ 0 (
    echo Starting existing container stack...
    docker compose start >nul 2>&1
    timeout /t 2 /nobreak >nul
    start http://localhost:3000
    exit /b 0
)

:: 3. Full Initialization Route (First Launch or Broken Daemon)
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Requesting Administrative Privileges...
    powershell -Command "Start-Process '%~f0' -Verb RunAs -WorkingDirectory '%APP_DIR%'"
    exit /b
)

echo ===================================================
echo 1. Checking Docker Desktop Installation
echo ===================================================
where docker >nul 2>&1
if %errorLevel% equ 0 (
    echo Docker CLI detected on system.
    goto :CHECK_DOCKER_RUNNING
)

if exist "%ProgramFiles%\Docker\Docker\Docker Desktop.exe" (
    echo Docker Desktop installation detected.
    goto :START_DOCKER_DESKTOP
)

echo.
echo WARNING: Docker Desktop is not installed on this system.
echo Downloading and installing Docker Desktop automatically...
echo.

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "Invoke-WebRequest -Uri 'https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe' -OutFile '$env:TEMP\DockerDesktopInstaller.exe'"

if not exist "%TEMP%\DockerDesktopInstaller.exe" (
    echo ERROR: Failed to download Docker Desktop Installer.
    pause
    exit /b 1
)

echo Installing Docker Desktop... Please wait...
start /wait "" "%TEMP%\DockerDesktopInstaller.exe" install --quiet --accept-license
del /f /q "%TEMP%\DockerDesktopInstaller.exe" >nul 2>&1

:START_DOCKER_DESKTOP
echo Starting Docker Desktop service...
start "" "%ProgramFiles%\Docker\Docker\Docker Desktop.exe"

:CHECK_DOCKER_RUNNING
echo Waiting for Docker Daemon to respond...
SET /A WAIT_COUNT=0
:WAIT_LOOP
docker info >nul 2>&1
if %errorLevel% equ 0 (
    echo Docker Engine is running and ready.
    goto :CHECK_EXISTING_AFTER_DAEMON
)
SET /A WAIT_COUNT+=1
if %WAIT_COUNT% GEQ 60 (
    echo ERROR: Docker Engine did not start in time. Please start Docker Desktop manually.
    pause
    exit /b 1
)
timeout /t 3 /nobreak >nul
goto :WAIT_LOOP

:CHECK_EXISTING_AFTER_DAEMON
:: Retry quick start now that daemon is running
docker ps -a --format "{{.Names}}" 2>nul | findstr /R /C:"^doc-analyzer-nginx$" >nul 2>&1
if %errorLevel% equ 0 (
    echo Application stack found. Starting containers...
    docker compose up -d
    timeout /t 3 /nobreak >nul
    start http://localhost:3000
    exit /b 0
)

:CLEANUP_OLD_CONTAINERS
echo.
echo ===================================================
echo 2. Purging Stale Container Conflicts ^& References
echo ===================================================
docker compose down --remove-orphans >nul 2>&1
docker container prune -f >nul 2>&1
docker rm -f doc-analyzer-ollama doc-analyzer-backend doc-analyzer-frontend doc-analyzer-db doc-analyzer-vector-db doc-analyzer-ollama-init >nul 2>&1

:DOWNLOAD_AWS_IMAGES
echo.
echo ===================================================
echo 3. Downloading Required Container Images from AWS
echo ===================================================
if exist "download-aws-files.ps1" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "download-aws-files.ps1" -Manifest "download-manifest.json" -TargetDir "%APP_DIR%"
    if %errorLevel% neq 0 (
        echo ERROR: AWS Image download script encountered errors.
        pause
        exit /b 1
    )
) else (
    echo WARNING: download-aws-files.ps1 script not found. Skipping AWS download...
)

:LOAD_IMAGES
echo.
echo ===================================================
echo 4. Loading Container Images into Docker
echo ===================================================
if exist "%APP_DIR%docker-images" (
    for %%F in ("%APP_DIR%docker-images\*.tar") do (
        echo Loading image: %%~nxF
        docker load -i "%%F"
    )
)

:START_APP
echo.
echo ===================================================
echo 5. Starting Container Stack via Docker Compose
echo ===================================================
if not exist "%APP_DIR%uploads" mkdir "%APP_DIR%uploads"
if not exist "%APP_DIR%logs" mkdir "%APP_DIR%logs"
if not exist "%APP_DIR%backups" mkdir "%APP_DIR%backups"

icacls "%APP_DIR%uploads" /grant Everyone:(OI)(CI)F /T >nul 2>&1
icacls "%APP_DIR%logs" /grant Everyone:(OI)(CI)F /T >nul 2>&1
icacls "%APP_DIR%backups" /grant Everyone:(OI)(CI)F /T >nul 2>&1

docker compose up -d

if %errorLevel% neq 0 (
    echo ERROR: Failed to start application containers.
    pause
    exit /b 1
)

echo.
echo ===================================================
echo Application successfully launched!
echo Opening Web Interface at http://localhost:3000...
echo ===================================================
timeout /t 5 >nul
start http://localhost:3000

pause
exit /b 0