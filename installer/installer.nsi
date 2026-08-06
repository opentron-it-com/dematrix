!define APP_NAME "Adesso Document Analyzer"
!define COMP_NAME "Adesso"
!define VERSION "1.0.0"
!define INSTALL_DIR "$PROGRAMFILES64\Adesso\DocumentAnalyzer"

Name "${APP_NAME}"
OutFile "Adesso-Document-Analyzer-Setup.exe"
InstallDir "${INSTALL_DIR}"
RequestExecutionLevel admin

Page directory
Page instfiles

Section "MainSection" SEC01
    SetOutPath "$INSTDIR"
    
    ; 1. Pre-create runtime data directories
    CreateDirectory "$INSTDIR\backups"
    CreateDirectory "$INSTDIR\uploads"
    CreateDirectory "$INSTDIR\logs"
    CreateDirectory "$INSTDIR\docker-images"
    
    ; 2. Deployment scripts & configurations
    File "docker-compose.yml"
    File ".env"
    File "launch.bat"
    File /nonfatal "stop.bat"
    File /nonfatal "uninstall.bat"
    File "docker-start.bat"
    File "load-images.bat"
    
    ; 3. AWS download pipeline
    File "download-manifest.json"
    File "download-aws-files.ps1"
    
    ; 4. Service dependencies & execution scripts
    File "nginx.conf"
    File /nonfatal "backup.sh"
    File /nonfatal "Dockerfile.backup"
    
    ; 5. Shortcuts setup
    CreateDirectory "$SMPROGRAMS\Adesso"
    CreateShortCut "$SMPROGRAMS\Adesso\${APP_NAME}.lnk" "$INSTDIR\launch.bat" "" "$INSTDIR\launch.bat" 0
    CreateShortCut "$DESKTOP\${APP_NAME}.lnk" "$INSTDIR\launch.bat" "" "$INSTDIR\launch.bat" 0
    
    ; 6. Windows Registry keys for Uninstaller
    WriteRegStr HKCU "Software\Adesso\DocumentAnalyzer" "InstallPath" "$INSTDIR"
    WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\AdessoDocumentAnalyzer" "DisplayName" "${APP_NAME}"
    WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\AdessoDocumentAnalyzer" "UninstallString" "$INSTDIR\uninstall.bat"
SectionEnd