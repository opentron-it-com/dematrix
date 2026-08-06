@echo off
REM Adesso Document Analyzer - Standalone Desktop Installer Builder
REM This creates a complete, self-contained installer with no external dependencies

echo.
echo ============================================
echo Adesso Document Analyzer v1.0.0
echo Standalone Desktop Installer Builder
echo ============================================
echo.

REM Get to the correct directory
cd /d "%~dp0"
echo Working directory: %cd%

REM Check if Node.js is installed
node --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Node.js is not installed or not in PATH
    echo Please install Node.js from https://nodejs.org/
    pause
    exit /b 1
)

REM Check if we have package.json in frontend directory
if not exist "frontend\package.json" (
    echo ERROR: frontend/package.json not found
    echo Please run this script from the project root directory
    echo Current directory: %cd%
    pause
    exit /b 1
)

echo [1/5] Installing frontend dependencies...
cd frontend
call npm install --legacy-peer-deps
if errorlevel 1 (
    echo ERROR: Failed to install frontend dependencies
    cd ..
    pause
    exit /b 1
)

echo [2/5] Building React application...
call npm run build
if errorlevel 1 (
    echo ERROR: Failed to build React application
    cd ..
    pause
    exit /b 1
)

cd ..

echo [3/5] Installing main app dependencies...
call npm install --legacy-peer-deps
if errorlevel 1 (
    echo ERROR: Failed to install app dependencies
    pause
    exit /b 1
)

echo [4/5] Preparing resources...
if not exist "resources\backend" mkdir resources\backend
if exist "target\enterprise-doc-analyzer-1.0.0.jar" (
    echo Copying backend JAR to resources...
    copy "target\enterprise-doc-analyzer-1.0.0.jar" "resources\backend\doc-analyzer.jar"
) else if exist "target\doc-analyzer.jar" (
    echo Copying backend JAR to resources...
    copy "target\doc-analyzer.jar" "resources\backend\doc-analyzer.jar"
) else (
    echo WARNING: Backend JAR not found
    echo The installer will not include the backend
)

echo [5/5] Building Windows installer...
call npm run build-win
if errorlevel 1 (
    echo ERROR: Failed to create installer
    pause
    exit /b 1
)

echo.
echo ============================================
echo Installer Created Successfully!
echo ============================================
echo.
echo Installer location: %cd%\dist\
echo.
echo File: Adesso Document Analyzer Setup 1.0.0.exe
echo.
echo ============================================
echo SYSTEM REQUIREMENTS FOR USERS:
echo ============================================
echo - Windows 10/11 64-bit
echo - 8GB RAM minimum (16GB recommended)
echo - 20GB free disk space
echo - No additional software needed
echo.
echo The installer includes everything needed:
echo + Electron runtime
echo + React frontend
echo + Spring Boot backend
echo + PostgreSQL database
echo + Chroma vector store
echo + Ollama LLM engine
echo + All required dependencies
echo.
pause
