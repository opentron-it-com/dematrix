; NSIS Installer Script - Adesso Document Analyzer Standalone
; INCLUDES EVERYTHING: Docker Engine + Docker Images
; No manual steps - completely automated

!include "MUI2.nsh"
!include "x64.nsh"

Name "Adesso Document Analyzer Standalone"
OutFile "Adesso-Document-Analyzer-Standalone-Setup.exe"
InstallDir "$LOCALAPPDATA\Adesso\DocumentAnalyzer"
InstallDirRegKey HKCU "Software\Adesso\DocumentAnalyzer" "InstallPath"

; AppData install does not require admin elevation
; RequestExecutionLevel user is default and omitted here

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_LANGUAGE "English"

Section "Install"
  CreateDirectory "$INSTDIR"
  SetOutPath "$INSTDIR"
  
  SetDetailsPrint both
  DetailPrint "Installing Adesso Document Analyzer Standalone..."
  DetailPrint ""
  
  ; Step 1: Extract configuration
  DetailPrint "Step 1/7: Extracting configuration files..."
  File "docker-compose.yml"
  File ".env"
  File "README.txt"
  File "README_MANUAL_IMAGE_COPY.txt"
  File "sharepoint-manifest.json"
  File "download-from-sharepoint.ps1"
  
  ; Step 2: Extract scripts
  DetailPrint "Step 2/7: Extracting launcher scripts..."
  File "launch.bat"
  File "stop.bat"
  File "load-images.bat"
  File "docker-start.bat"
  File "init-docker.bat"
  File "standalone-launcher.bat"
  
  ; Step 3: Prepare for SharePoint payload download
  DetailPrint "Step 3/7: Preparing SharePoint download helper files..."
  DetailPrint "This installer does not bundle Docker engine or images."
  DetailPrint "Required payloads are downloaded on first launch from SharePoint."
  
  ; Step 4: Extract optional SharePoint downloader helpers
  DetailPrint "Step 4/7: Extracting SharePoint download helpers..."
  ; These files allow the launcher to download missing large payloads automatically.
  
  ; Step 7: Finalizing installation
  DetailPrint "Step 7/7: Finalizing installation..."
  SetOutPath "$INSTDIR"
  CreateDirectory "$LOCALAPPDATA\Adesso\DocumentAnalyzer\data"
  
  ; Create shortcuts
  CreateDirectory "$SMPROGRAMS\Adesso"
  CreateShortCut "$SMPROGRAMS\Adesso\Document Analyzer.lnk" "$INSTDIR\launch.bat" "" "$INSTDIR\launch.bat" 0
  CreateShortCut "$SMPROGRAMS\Adesso\Stop Services.lnk" "$INSTDIR\stop.bat" "" "$INSTDIR\stop.bat" 0
  CreateShortCut "$DESKTOP\Adesso Document Analyzer.lnk" "$INSTDIR\launch.bat" "" "$INSTDIR\launch.bat" 0
  
  ; Registry
  WriteRegStr HKCU "Software\Adesso\DocumentAnalyzer" "InstallPath" "$INSTDIR"
  WriteRegStr HKCU "Software\Adesso\DocumentAnalyzer" "Version" "1.0.0-Standalone"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\AdessoDocumentAnalyzerStandalone" "DisplayName" "Adesso Document Analyzer Standalone"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\AdessoDocumentAnalyzerStandalone" "UninstallString" "$INSTDIR\uninstall.exe"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\AdessoDocumentAnalyzerStandalone" "DisplayVersion" "1.0.0"
  
  WriteUninstaller "$INSTDIR\uninstall.exe"
  
  DetailPrint ""
  DetailPrint "============================================"
  DetailPrint "Installation Complete!"
  DetailPrint "============================================"
  DetailPrint ""
  DetailPrint "The application is installed under %LOCALAPPDATA% and is ready to launch."
  
  MessageBox MB_OK "Installation Complete!$\n$\nThe application has been installed under your user profile.$\n$\nClick the desktop shortcut 'Adesso Document Analyzer' to launch.$\n$\nOn first run, the launcher will start the bundled Docker engine and download any missing payloads from SharePoint. This may take 5-15 minutes."
SectionEnd

Section "Uninstall"
  SetDetailsPrint both
  DetailPrint "Uninstalling..."
  
  ExecWait '"$INSTDIR\stop.bat"' $0
  Sleep 2000
  
  Delete "$INSTDIR\docker-compose.yml"
  Delete "$INSTDIR\.env"
  Delete "$INSTDIR\launch.bat"
  Delete "$INSTDIR\stop.bat"
  Delete "$INSTDIR\load-images.bat"
  Delete "$INSTDIR\docker-start.bat"
  Delete "$INSTDIR\init-docker.bat"
  Delete "$INSTDIR\standalone-launcher.bat"
  Delete "$INSTDIR\README.txt"
  Delete "$INSTDIR\download-from-sharepoint.ps1"
  Delete "$INSTDIR\sharepoint-manifest.json"
  Delete "$INSTDIR\uninstall.exe"
  
  RMDir "$INSTDIR"
  
  Delete "$SMPROGRAMS\Adesso\Document Analyzer.lnk"
  Delete "$SMPROGRAMS\Adesso\Stop Services.lnk"
  Delete "$DESKTOP\Adesso Document Analyzer.lnk"
  RMDir "$SMPROGRAMS\Adesso"
  
  DeleteRegKey HKCU "Software\Adesso\DocumentAnalyzer"
  DeleteRegKey HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\AdessoDocumentAnalyzerStandalone"
  
  MessageBox MB_OK "Uninstalled!"
SectionEnd
