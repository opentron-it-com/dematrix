@echo off
REM Docker daemon starter for standalone installation
REM This script detects and starts Docker in the most compatible way

set "APP_DIR=%~dp0"
set "LOG_FILE=%APP_DIR%docker-start.log"

echo Starting Docker daemon...
echo %date% %time% - Starting Docker >> "%LOG_FILE%"

REM Try method 1: Docker service
for %%S in (com.docker.service Docker) do (
    sc query "%%S" >nul 2>&1
    if not errorlevel 1 (
        echo Checking Docker service: %%S...
        net start "%%S" >> "%LOG_FILE%" 2>&1
        if %ERRORLEVEL% EQU 0 (
            echo Docker service started
            goto :WAIT_FOR_DOCKER
        ) else if %ERRORLEVEL% EQU 2 (
            echo Docker service already running
            goto :WAIT_FOR_DOCKER
        )
    )
)

REM Try method 2: Docker Desktop executable
if exist "%ProgramFiles%\Docker\Docker\Docker Desktop.exe" (
    echo Starting Docker Desktop...
    start "" "%ProgramFiles%\Docker\Docker\Docker Desktop.exe"
    timeout /t 15
    goto :WAIT_FOR_DOCKER
)

if exist "%LOCALAPPDATA%\Docker\Docker\Docker.exe" (
    echo Starting Docker...
    start "" "%LOCALAPPDATA%\Docker\Docker\Docker.exe"
    timeout /t 15
    goto :WAIT_FOR_DOCKER
)

REM Try method 2a: portable docker engine in Program Files installation
if exist "%ProgramFiles%\Adesso\DocumentAnalyzer\docker-engine\dockerd.exe" (
    set "DOCKER_HOME=%ProgramFiles%\Adesso\DocumentAnalyzer\docker-engine"
    echo Found installed portable Docker engine in: %DOCKER_HOME% >> "%LOG_FILE%"
    if exist "%DOCKER_HOME%\docker.exe" (
        set "PATH=%DOCKER_HOME%;%PATH%"
        echo Added %DOCKER_HOME% to PATH >> "%LOG_FILE%"
        set "DOCKER_CLI=%DOCKER_HOME%\docker.exe"
    )
    echo Starting installed portable dockerd.exe >> "%LOG_FILE%"
    start "" "%DOCKER_HOME%\dockerd.exe" --log-level=info --data-root "%LOCALAPPDATA%\Adesso\DocumentAnalyzer\docker-data"
    timeout /t 5
    goto :WAIT_FOR_DOCKER
)

REM Try method 2b: portable docker engine bundled in installer
set "BUNDLED_ENGINE=%APP_DIR%docker-engine"
if not exist "%BUNDLED_ENGINE%\dockerd.exe" (
    if exist "%BUNDLED_ENGINE%\docker-engine\dockerd.exe" (
        set "BUNDLED_ENGINE=%BUNDLED_ENGINE%\docker-engine"
    )
)
if exist "%BUNDLED_ENGINE%\dockerd.exe" (
    echo Found portable Docker engine in: %BUNDLED_ENGINE% >> "%LOG_FILE%"
    set "DOCKER_HOME=%BUNDLED_ENGINE%"
    rem Add portable docker-cli if present
    if exist "%DOCKER_HOME%\docker.exe" (
        set "PATH=%DOCKER_HOME%;%PATH%"
        echo Added %DOCKER_HOME% to PATH >> "%LOG_FILE%"
        set "DOCKER_CLI=%DOCKER_HOME%\docker.exe"
    )
    rem Try starting dockerd from the portable folder
    if exist "%DOCKER_HOME%\dockerd.exe" (
        echo Starting portable dockerd.exe >> "%LOG_FILE%"
        echo Starting portable Docker daemon on pipe npipe:////./pipe/docker_engine
        set "DOCKER_HOST=npipe:////./pipe/docker_engine"
        set "DOCKER_ARGS=--host %DOCKER_HOST%"
        set "DOCKER_CLI=%DOCKER_HOME%\docker.exe"
        echo Docker CLI: %DOCKER_CLI%
        echo Docker host: %DOCKER_HOST%
        echo Docker startup log: %LOG_FILE%
        start "" "%DOCKER_HOME%\dockerd.exe" --log-level=info --data-root "%LOCALAPPDATA%\Adesso\DocumentAnalyzer\docker-data" --host=npipe:////./pipe/docker_engine
        timeout /t 5
        goto :WAIT_FOR_DOCKER
    )
)

REM Try method 3: Docker daemon directly
for /f "delims=" %%i in ('where docker 2^>nul') do (
    set "DOCKER_PATH=%%i"
)

if defined DOCKER_PATH (
    echo Found Docker at: %DOCKER_PATH%
    set "DOCKER_CLI=%DOCKER_PATH%"
    echo Using system Docker CLI: %DOCKER_CLI% >> "%LOG_FILE%"
    goto :WAIT_FOR_DOCKER
)

echo WARNING: Docker could not be auto-started
echo Please start Docker Desktop manually
echo.
pause
exit /b 1

:WAIT_FOR_DOCKER
echo Waiting for Docker daemon to respond...
set /a WAIT_COUNT=0
:WAIT_LOOP
if defined DOCKER_CLI (
    "%DOCKER_CLI%" %DOCKER_ARGS% ps >nul 2>&1
) else (
    docker %DOCKER_ARGS% ps >nul 2>&1
)
if errorlevel 0 (
    echo Docker daemon is ready
    if defined DOCKER_CLI (
        echo Using Docker CLI: %DOCKER_CLI% >> "%LOG_FILE%"
    ) else (
        set "DOCKER_CLI=docker"
        echo Using system docker CLI: %DOCKER_CLI% >> "%LOG_FILE%"
    )
    if defined DOCKER_HOST echo Using DOCKER_HOST: %DOCKER_HOST% >> "%LOG_FILE%"
    echo Docker CLI active: %DOCKER_CLI%
    if defined DOCKER_HOST echo Connecting to: %DOCKER_HOST%
    call :SaveDockerEnv
    exit /b 0
)

if %WAIT_COUNT% GEQ 30 (
    echo ERROR: Docker daemon did not respond after 30 seconds.
    echo Please start Docker Desktop and try again.
    exit /b 1
)

set /a WAIT_COUNT+=1
timeout /t 2 /nobreak >nul
goto :WAIT_LOOP

:SaveDockerEnv
(
    echo set "DOCKER_CLI=%DOCKER_CLI%"
    echo set "DOCKER_HOST=%DOCKER_HOST%"
    echo set "DOCKER_ARGS=%DOCKER_ARGS%"
) > "%APP_DIR%docker-env.cmd"
goto :EOF
