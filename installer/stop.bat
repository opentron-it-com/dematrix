@echo off
REM Stop script for Adesso Document Analyzer

setlocal

set "APP_DIR=%~dp0"

echo.
echo Stopping Adesso Document Analyzer services...
echo.

cd /d "%APP_DIR%"
docker compose down

if errorlevel 1 (
    echo ERROR: Failed to stop services
    pause
    exit /b 1
)

echo.
echo Services stopped successfully.
echo.
echo Data is preserved. Run launch.bat to restart.
echo.
pause
