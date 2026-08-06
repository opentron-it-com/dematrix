@echo off
REM Adesso Document Analyzer - Standalone Installer
REM This extracts and installs the complete application

setlocal enabledelayedexpansion

set "INSTALLER_DIR=%~dp0"
set "TEMP_EXTRACT=%TEMP%\adesso-install-%RANDOM%"
set "INSTALL_DIR=C:\Program Files\Adesso\DocumentAnalyzer"
set "LOG_FILE=%INSTALLER_DIR%install.log"

echo. > "%LOG_FILE%"
echo ============================================ >> "%LOG_FILE%"
echo Adesso Document Analyzer Installation >> "%LOG_FILE%"
echo %date% %time% >> "%LOG_FILE%"
echo ============================================ >> "%LOG_FILE%"

cls
echo.
echo ============================================
echo Adesso Document Analyzer Setup
echo ============================================
echo.

REM Create directories
mkdir "%INSTALL_DIR%" 2>nul
mkdir "%TEMP_EXTRACT%" 2>nul

REM Extract archive
echo Extracting files (this may take several minutes)...
echo.

tar -xzf "%INSTALLER_DIR%application-payload.tar.gz" -C "%TEMP_EXTRACT%" 2>> "%LOG_FILE%"

if errorlevel 1 (
    echo ERROR: Failed to extract files
    rmdir /s /q "%TEMP_EXTRACT%" 2>nul
    pause
    exit /b 1
)

echo Files extracted successfully.
echo.
echo Copying to installation directory...

REM Copy files
if exist "%TEMP_EXTRACT%\staging" (
    xcopy "%TEMP_EXTRACT%\staging\*.*" "%INSTALL_DIR%\" /E /I /Y /Q >> "%LOG_FILE%" 2>&1
) else (
    echo ERROR: Staging directory not found
    rmdir /s /q "%TEMP_EXTRACT%" 2>nul
    pause
    exit /b 1
)

echo Files copied successfully.
echo.
echo Creating shortcuts...

REM Create shortcuts using PowerShell
powershell -NoProfile -Command "^
\$shell = New-Object -COM WScript.Shell;^
\$desktop = [Environment]::GetFolderPath('Desktop');^
\$link = \$shell.CreateShortcut(\$desktop + '\Adesso Document Analyzer.lnk');^
\$link.TargetPath = '%INSTALL_DIR%\launch.bat';^
\$link.WorkingDirectory = '%INSTALL_DIR%';^
\$link.Save();^
Write-Host 'Shortcuts created'
" 2>> "%LOG_FILE%"

REM Register
reg add "HKCU\Software\Adesso\DocumentAnalyzer" /v "InstallPath" /d "%INSTALL_DIR%" /f >> "%LOG_FILE%" 2>&1

REM Cleanup
rmdir /s /q "%TEMP_EXTRACT%" 2>nul

echo.
echo ============================================
echo Installation Complete!
echo ============================================
echo.
echo Application installed to: %INSTALL_DIR%
echo.
echo Click desktop shortcut to launch.
echo.
pause

REM Launch
start "" "%INSTALL_DIR%\launch.bat"

exit /b 0
