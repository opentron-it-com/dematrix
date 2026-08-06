@echo off
TITLE Adesso Document Analyzer - Uninstaller

net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Requesting Administrative Privileges...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

echo Stopping and removing Docker containers...
cd /d "%~dp0"
docker compose down -v --remove-orphans >nul 2>&1

echo Removing shortcuts...
if exist "%DESKTOP%\Adesso Document Analyzer.lnk" del /f /q "%DESKTOP%\Adesso Document Analyzer.lnk"
if exist "%SMPROGRAMS%\Adesso" rmdir /s /q "%SMPROGRAMS%\Adesso"

echo Unregistration complete. You may now delete the installation folder.
pause