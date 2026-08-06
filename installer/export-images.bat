@echo off
REM Export Docker images for standalone installer
REM This script exports all necessary Docker images as TAR files

setlocal enabledelayedexpansion

set "EXPORT_DIR=%~dp0docker-images"
set "LOG_FILE=%~dp0export.log"

echo. > "%LOG_FILE%"
echo ============================================ >> "%LOG_FILE%"
echo Docker Image Export - %date% %time% >> "%LOG_FILE%"
echo ============================================ >> "%LOG_FILE%"
echo. >> "%LOG_FILE%"

echo.
echo ============================================
echo Adesso Document Analyzer - Image Export
echo ============================================
echo.
echo This will export all Docker images needed for the standalone installer.
echo This may take 10-15 minutes and require 15GB+ disk space.
echo.

if not exist "%EXPORT_DIR%" (
    mkdir "%EXPORT_DIR%"
    echo Created export directory: %EXPORT_DIR%
)

REM List of images to export
set "IMAGES[0]=enterprise-doc-analyzer-backend:latest"
set "IMAGES[1]=enterprise-doc-analyzer-frontend:latest"
set "IMAGES[2]=postgres:16-alpine"
set "IMAGES[3]=ghcr.io/chroma-core/chroma:latest"
set "IMAGES[4]=ollama/ollama:latest"
set "IMAGES[5]=nginx:alpine"

set "COUNT=0"
for /l %%i in (0,1,5) do (
    call set "IMAGE=!IMAGES[%%i]!"
    if defined IMAGE (
        set /a COUNT+=1
    )
)

echo Found %COUNT% images to export.
echo.

set "FAILED=0"

REM Export each image
for /l %%i in (0,1,5) do (
    call set "IMAGE=!IMAGES[%%i]!"
    if defined IMAGE (
        REM Convert image name to filename
        set "FILENAME=!IMAGE:/=-!"
        set "FILENAME=!FILENAME::=-!"
        set "FILENAME=!FILENAME! .tar"
        
        echo.
        echo Exporting: !IMAGE!
        echo Output: !FILENAME!
        echo.
        
        docker save -o "%EXPORT_DIR%\!FILENAME!" "!IMAGE!" >> "%LOG_FILE%" 2>&1
        
        if errorlevel 1 (
            echo ERROR: Failed to export !IMAGE!
            echo ERROR: Failed to export !IMAGE! >> "%LOG_FILE%"
            set /a FAILED+=1
        ) else (
            REM Get file size
            for %%F in ("%EXPORT_DIR%\!FILENAME!") do (
                set "SIZE=%%~zF"
                echo Successfully exported: !FILENAME! (!SIZE! bytes)
                echo Successfully exported: !FILENAME! (!SIZE! bytes) >> "%LOG_FILE%"
            )
        )
    )
)

echo.
echo ============================================
echo Export Complete
echo ============================================
echo.
echo Location: %EXPORT_DIR%
echo.
if %FAILED% EQU 0 (
    echo All images exported successfully!
    echo.
    echo Next steps:
    echo 1. Create a 7z archive of the docker-images folder
    echo 2. Include in the installer
    echo 3. Create extraction/loading scripts
) else (
    echo WARNING: %FAILED% image(s) failed to export
)

echo.
echo Log saved to: %LOG_FILE%
echo.
pause
