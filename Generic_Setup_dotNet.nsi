!define EXE_NAME "program.exe"
!define EXTRA_DLL "library.dll"
!define PRODUCT_PUBLISHER "CompanyName"
!define PRODUCT_NAME "ProductName"
!define PRODUCT_VERSION "1.0"
!define PRODUCT_DIR_REGKEY "Software\Microsoft\Windows\CurrentVersion\App Paths\${EXE_NAME}"
!define PRODUCT_UNINST_KEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}"
!define PRODUCT_UNINST_ROOT_KEY "HKLM"

; MUI 1.67 compatible ------
!include "MUI.nsh"

; MUI Settings
!define MUI_ABORTWARNING
!define MUI_ICON "${NSISDIR}\Contrib\Graphics\Icons\modern-install.ico"
!define MUI_UNICON "${NSISDIR}\Contrib\Graphics\Icons\modern-uninstall.ico"

; Welcome page
!insertmacro MUI_PAGE_WELCOME
; Directory page
!insertmacro MUI_PAGE_DIRECTORY
; Instfiles page
!insertmacro MUI_PAGE_INSTFILES
; Finish page
!define MUI_FINISHPAGE_RUN "$INSTDIR\${EXE_NAME}"
!insertmacro MUI_PAGE_FINISH

; Uninstaller pages
!insertmacro MUI_UNPAGE_INSTFILES

; Language files
!insertmacro MUI_LANGUAGE "English"

; MUI end ------

Name "${PRODUCT_NAME} ${PRODUCT_VERSION}"
OutFile "${PRODUCT_NAME}_Setup.exe"
InstallDir "$DESKTOP\${PRODUCT_PUBLISHER}"
;InstallDir "$PROGRAMFILES\${PRODUCT_PUBLISHER}"
InstallDirRegKey HKLM "${PRODUCT_DIR_REGKEY}" ""
ShowInstDetails show
ShowUnInstDetails show
SetCompress off

;--------------------------------------
; Microsoft Windows Installer 3.1 Check
;--------------------------------------
!define MSIMajorVersion 3
!define MSIMinorVersion 1
!define MSIInstaller "WindowsInstaller_3.1_v2_x86.exe"
Section "MSI 3.1" SecInstaller
  GetDllVersion "$SYSDIR\MSI.dll" $R0 $R1
  IntOp $R2 $R0 / 0x00010000
  IntOp $R3 $R0 & 0x0000FFFF
 
  IntCmp $R2 3 0 InstallMSI RightMSI
  IntCmp $R3 1 RightMSI InstallMSI RightMSI
  
  InstallMSI:
    DetailPrint "Starting Windows Installer v${MSIMajorVersion}.${MSIMinorVersion} Setup..."
	File /oname=$TEMP\${MSIInstaller} ${MSIInstaller}
	ExecWait "$TEMP\${MSIInstaller}"
    Return

  RightMSI:
    DetailPrint "Microsoft Windows Installer 3.1 Already Installed!"

SectionEnd

;-------------------------------------------
; Windows Imaging Component Check
; Using a makeshift way to make .NET 
; Framework 4.0 think that WIC is Installed
;-------------------------------------------
!define WICFile "windowscodecs.dll"
!define WICFileExt "windowscodecsext.dll"
Section "WIC" SecWIC
  IfFileExists "$SYSDIR\${WICFile}" WICInstalled 0
  
  DetailPrint "Copying WIC Files..."
  File /oname=$TEMP\${WICFile} ${WICFile}
  File /oname=$TEMP\${WICFileExt} ${WICFileExt}
  CopyFiles /SILENT /FILESONLY $TEMP\${WICFile} $SYSDIR
  CopyFiles /SILENT /FILESONLY $TEMP\${WICFileExt} $SYSDIR
  Return
  
  WICInstalled:
  DetailPrint "WIC already installed!"
  
SectionEnd

 
;--------------------------------
; .NET Framework 4.0 Check
;--------------------------------
!define NETVersion "4.0.30319"
!define NETInstaller "dotNetFx40_Client_x86_x64.exe"
Section "MS .NET Framework v${NETVersion}" SecFramework
  IfFileExists "$WINDIR\Microsoft.NET\Framework\v${NETVersion}" NETFrameworkInstalled 0
  
  DetailPrint "Starting Microsoft .NET Framework v${NETVersion} Setup..."
  File /oname=$TEMP\${NETInstaller} ${NETInstaller}
  ExecWait "$TEMP\${NETInstaller}"
  Return
 
  NETFrameworkInstalled:
  DetailPrint "Microsoft .NET Framework is already installed!"
 
SectionEnd

Section "MainSection" SEC01
  SetOutPath "$INSTDIR"
  SetOverwrite ifnewer
  File ${EXE_NAME}
  File ${EXTRA_DLL}
  CreateDirectory "$SMPROGRAMS\${PRODUCT_PUBLISHER}"
  CreateShortCut "$SMPROGRAMS\${PRODUCT_PUBLISHER}\${PRODUCT_NAME}.lnk" "$INSTDIR\${EXE_NAME}"
  CreateShortCut "$DESKTOP\${PRODUCT_NAME}.lnk" "$INSTDIR\${EXE_NAME}"
SectionEnd

Section -AdditionalIcons
  CreateShortCut "$SMPROGRAMS\${PRODUCT_PUBLISHER}\Uninstall_${PRODUCT_NAME}.lnk" "$INSTDIR\uninstall_${PRODUCT_NAME}.exe"
SectionEnd

Section -Post
  WriteUninstaller "$INSTDIR\uninstall_${PRODUCT_NAME}.exe"
  WriteRegStr HKLM "${PRODUCT_DIR_REGKEY}" "" "$INSTDIR\${EXE_NAME}"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "DisplayName" "$(^Name)"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "UninstallString" "$INSTDIR\uninstall_${PRODUCT_NAME}.exe"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "DisplayIcon" "$INSTDIR\${EXE_NAME}"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "DisplayVersion" "${PRODUCT_VERSION}"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "Publisher" "${PRODUCT_PUBLISHER}"
SectionEnd


Function un.onUninstSuccess
  HideWindow
  MessageBox MB_ICONINFORMATION|MB_OK "$(^Name) was successfully removed from your computer."
FunctionEnd

Function un.onInit
  MessageBox MB_ICONQUESTION|MB_YESNO|MB_DEFBUTTON2 "Are you sure you want to completely remove $(^Name) and all of its components?" IDYES +2
  Abort
FunctionEnd

Section Uninstall
  Delete "$INSTDIR\uninstall_${PRODUCT_NAME}.exe"
  Delete "$INSTDIR\${EXE_NAME}"
  Delete "$INSTDIR\${EXTRA_DLL}"

  Delete "$SMPROGRAMS\${PRODUCT_PUBLISHER}\Uninstall_${PRODUCT_NAME}.lnk"
  Delete "$DESKTOP\${PRODUCT_NAME}.lnk"
  Delete "$SMPROGRAMS\${PRODUCT_PUBLISHER}\${PRODUCT_NAME}.lnk"

  RMDir "$SMPROGRAMS\${PRODUCT_PUBLISHER}"
  RMDir "$INSTDIR"

  DeleteRegKey ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}"
  DeleteRegKey HKLM "${PRODUCT_DIR_REGKEY}"
  SetAutoClose true
SectionEnd