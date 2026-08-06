@echo off
REM Adesso Document Analyzer - Standalone Installer
REM Self-extracting installer with automatic setup
REM Windows 10/11 compatible

setlocal enabledelayedexpansion

set "INSTALLER_DIR=%~dp0"
set "TEMP_EXTRACT=%TEMP%\adesso-install-%RANDOM%-%RANDOM%"
set "LOG_FILE=%INSTALLER_DIR%install.log"

echo. > "%LOG_FILE%"
echo ============================================ >> "%LOG_FILE%"
echo Adesso Document Analyzer Installation >> "%LOG_FILE%"
echo %date% %time% >> "%LOG_FILE%"
echo ============================================ >> "%LOG_FILE%"
echo. >> "%LOG_FILE%"

cls
echo.
echo ============================================
echo Adesso Document Analyzer Setup
echo ============================================
echo.
echo This will install the complete standalone
echo application with Docker and all services.
echo.
echo Installation Directory:
echo C:\Program Files\Adesso\DocumentAnalyzer
echo.

REM Check Windows version
ver | find /i "Windows" >nul
if errorlevel 1 (
    echo ERROR: Could not determine Windows version
    pause
    exit /b 1
)

REM Create install directory
set "INSTALL_DIR=C:\Program Files\Adesso\DocumentAnalyzer"

if exist "%INSTALL_DIR%" (
    echo.
    echo Installation directory already exists.
    choice /C YN /N /M "Continue and update? (Y/N): "
    if errorlevel 2 exit /b 1
)

echo.
echo Creating installation directory...
mkdir "%INSTALL_DIR%" 2>nul

REM Create temp directory
mkdir "%TEMP_EXTRACT%" 2>nul

echo.
echo Extracting files...
echo This may take several minutes. Please wait...
echo.

REM Extract tar.gz archive
REM The archive is appended to this batch file
tar -xzf "%~f0" -C "%TEMP_EXTRACT%" 2>> "%LOG_FILE%"

if errorlevel 1 (
    echo ERROR: Failed to extract files
    echo Check log: %LOG_FILE%
    rmdir /s /q "%TEMP_EXTRACT%" 2>nul
    pause
    exit /b 1
)

echo.
echo Copying files to installation directory...
echo.

REM Copy extracted files
if exist "%TEMP_EXTRACT%\staging" (
    xcopy "%TEMP_EXTRACT%\staging\*.*" "%INSTALL_DIR%\" /E /I /Y /Q >> "%LOG_FILE%" 2>&1
) else (
    echo ERROR: Installation files not found
    rmdir /s /q "%TEMP_EXTRACT%" 2>nul
    pause
    exit /b 1
)

echo.
echo Creating shortcuts...

REM Create desktop shortcut using PowerShell
powershell -NoProfile -Command "^
$shell = New-Object -COM WScript.Shell;^
$desktop = [Environment]::GetFolderPath('Desktop');^
$link = $shell.CreateShortcut($desktop + '\Adesso Document Analyzer.lnk');^
$link.TargetPath = '%INSTALL_DIR%\launch.bat';^
$link.WorkingDirectory = '%INSTALL_DIR%';^
$link.Description = 'Adesso Document Analyzer';^
$link.Save();^
Write-Host 'Desktop shortcut created'
" 2>> "%LOG_FILE%"

REM Create Start Menu shortcut
mkdir "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Adesso" 2>nul
powershell -NoProfile -Command "^
$shell = New-Object -COM WScript.Shell;^
$startMenu = '%APPDATA%\Microsoft\Windows\Start Menu\Programs\Adesso\';^
$link = $shell.CreateShortcut($startMenu + 'Adesso Document Analyzer.lnk');^
$link.TargetPath = '%INSTALL_DIR%\launch.bat';^
$link.WorkingDirectory = '%INSTALL_DIR%';^
$link.Description = 'Adesso Document Analyzer';^
$link.Save();^
Write-Host 'Start Menu shortcut created'
" 2>> "%LOG_FILE%"

echo.
echo Registering application...

REM Register in Windows
reg add "HKCU\Software\Adesso\DocumentAnalyzer" /v "InstallPath" /d "%INSTALL_DIR%" /f >> "%LOG_FILE%" 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Uninstall\AdessoDocumentAnalyzer" /v "DisplayName" /d "Adesso Document Analyzer" /f >> "%LOG_FILE%" 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Uninstall\AdessoDocumentAnalyzer" /v "UninstallString" /d "%INSTALL_DIR%\uninstall.bat" /f >> "%LOG_FILE%" 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Uninstall\AdessoDocumentAnalyzer" /v "DisplayVersion" /d "1.0.0" /f >> "%LOG_FILE%" 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Uninstall\AdessoDocumentAnalyzer" /v "Publisher" /d "Adesso" /f >> "%LOG_FILE%" 2>&1

REM Clean up
echo.
echo Cleaning up temporary files...
rmdir /s /q "%TEMP_EXTRACT%" 2>nul

echo.
echo ============================================
echo Installation Complete!
echo ============================================
echo.
echo All files installed successfully to:
echo %INSTALL_DIR%
echo.
echo Next steps:
echo 1. Click the desktop shortcut or
echo    find 'Adesso Document Analyzer' in Start Menu
echo 2. First launch will initialize Docker
echo    (this may take 5-10 minutes)
echo 3. Browser will open automatically
echo.
echo Log file: %LOG_FILE%
echo.
echo Ready to launch? Press any key...
pause >nul

REM Launch the application
echo.
echo Launching Adesso Document Analyzer...
start "" "%INSTALL_DIR%\launch.bat"

exit /b 0

REM ============================================
REM ARCHIVE DATA FOLLOWS - DO NOT MODIFY
REM ============================================
