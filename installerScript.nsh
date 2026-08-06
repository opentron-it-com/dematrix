; NSIS Installer Script for Adesso Document Analyzer
; This creates a fully self-contained installer with all dependencies

!include "MUI2.nsh"
!include "x64.nsh"
!include "WinVer.nsh"

; Basic Settings
Name "Adesso Document Analyzer"
OutFile "Adesso Document Analyzer Setup 1.0.0.exe"
InstallDir "$PROGRAMFILES64\Adesso\DocumentAnalyzer"
InstallDirRegKey HKCU "Software\Adesso\DocumentAnalyzer" "InstallPath"

; MUI Settings
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_LANGUAGE "English"

; Installer Sections
Section "Install"
  SetOutPath "$INSTDIR"
  
  ; Copy all application files
  File /r "dist\*.*"
  
  ; Create shortcuts
  CreateDirectory "$SMPROGRAMS\Adesso"
  CreateShortCut "$SMPROGRAMS\Adesso\Document Analyzer.lnk" "$INSTDIR\Adesso Document Analyzer.exe"
  CreateShortCut "$DESKTOP\Adesso Document Analyzer.lnk" "$INSTDIR\Adesso Document Analyzer.exe"
  
  ; Registry entries
  WriteRegStr HKCU "Software\Adesso\DocumentAnalyzer" "InstallPath" "$INSTDIR"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\AdessoDocumentAnalyzer" "DisplayName" "Adesso Document Analyzer"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\AdessoDocumentAnalyzer" "UninstallString" "$INSTDIR\uninstall.exe"
  WriteUninstaller "$INSTDIR\uninstall.exe"
  
  ; Create uninstaller
  WriteUninstaller "$INSTDIR\uninstall.exe"
  
  MessageBox MB_OK "Installation complete!$\n$\nAdesso Document Analyzer has been installed to:$\n$INSTDIR$\n$\nA shortcut has been created on your Desktop and Start Menu."
SectionEnd

; Uninstaller Section
Section "Uninstall"
  RMDir /r "$INSTDIR"
  Delete "$SMPROGRAMS\Adesso\Document Analyzer.lnk"
  Delete "$DESKTOP\Adesso Document Analyzer.lnk"
  RMDir "$SMPROGRAMS\Adesso"
  DeleteRegKey HKCU "Software\Adesso\DocumentAnalyzer"
  DeleteRegKey HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\AdessoDocumentAnalyzer"
SectionEnd
