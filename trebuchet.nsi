;NSIS installer for trebuchet with stand alone options.
;
;When making yourself, change "TMP_DIR" to correct location

!define NICK_NAME "Trebuchet"
!define PROD_NAME "Trebuchet Tk"
!define VER_MAJOR 1
!define VER_MINOR 75
!define VER_REVISION 0
!define VER_BUILD 1
!define VER_FILE "1075"
!define VER_DISPLAY "1.075"
!define TMP_DIR "C:\TMP\Install"
!define BUILD_DIR "${TMP_DIR}\Trebuchet"
;-------------------------------
;Use modern GUI
;-------------------------------
!include "MUI.nsh"

;---------
;Variables
;---------
Var MUI_TEMP
Var STARTMENU_FOLDER

;-------------------------
; General Config
;-------------------------
XPStyle on
Name "${PROD_NAME}"
Caption "${PROD_NAME} ${VER_DISPLAY} (build ${VER_BUILD}) - Setup"
OutFile "${TMP_DIR}\${NICK_NAME}${VER_FILE}b${VER_BUILD}.exe"
InstallDir "$PROGRAMFILES\${NICK_NAME}"
;LicenseData "${BUILD_DIR}\COPYING"

;------------------
;Interface Settings
;------------------

;Define custom look and images to be used
!define MUI_ABORTWARNING
;!define MUI_LANGDLL_ALWAYSSHOW
;!define MUI_ICON "install.ico"
;!define MUI_UNICON "uninstall.ico"
;!define MUI_HEADERIMAGE_BITMAP "header.bmp"
;!define MUI_HEADERIMAGE_UNBITMAP "header.bmp"
;!define MUI_FINISHPAGE_SHOWREADME "$INSTDIR\readme.txt"
;!define MUI_FINISHPAGE_SHOWREADME_NOTCHECKED

;-----------------------------
;Pages to be used in the setup
;-----------------------------

;General pages
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "${BUILD_DIR}\COPYING"
;!insertmacro MUI_PAGE_COMPONENTS
!insertmacro MUI_PAGE_DIRECTORY

;Start Menu Folder Page Configuration
!insertmacro MUI_PAGE_STARTMENU Application $STARTMENU_FOLDER

;Installation progress and finish
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

;Uninstallation pages
!insertmacro MUI_UNPAGE_WELCOME
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_UNPAGE_FINISH

;---------
;Languages
;---------

;Define installer languages
!insertmacro MUI_LANGUAGE "English"

;--------------------------------
;Installer Section

Section "Install"
  SetOutPath "$INSTDIR"
  File "${BUILD_DIR}\*"
  File /r "${BUILD_DIR}\pkgs"
  File /r "${BUILD_DIR}\lib"
  File /r "${BUILD_DIR}\docs"
  File /r "${BUILD_DIR}\cacerts"
  File /r "${BUILD_DIR}\icons"

  ;Create uninstaller
  WriteUninstaller "$INSTDIR\Uninstall.exe"

  !insertmacro MUI_STARTMENU_WRITE_BEGIN Application
    ;Create Start menu shortcuts
    CreateDirectory "$SMPROGRAMS\$STARTMENU_FOLDER"
    CreateShortCut "$SMPROGRAMS\$STARTMENU_FOLDER\Trebuchet.lnk" "$OUTDIR\Trebuchet.tcl" "" "$OUTDIR\icons\Treb.ico"
    CreateShortCut "$SMPROGRAMS\$STARTMENU_FOLDER\Uninstall.lnk" "$OUTDIR\Uninstall.exe"
  !insertmacro MUI_STARTMENU_WRITE_END
SectionEnd

;--------------------------------
;Uninstaller Section

Section "Uninstall"

  ;ADD YOUR OWN STUFF HERE!

  Delete "$INSTDIR\pkgs\*.*"
  Delete "$INSTDIR\lib\*.*"
  Delete "$INSTDIR\docs\*.*"
  Delete "$INSTDIR\cacerts\*.*"
  Delete "$INSTDIR\icons\*.*"
  Delete "$INSTDIR\*.*"

  RMDir /r "$INSTDIR"

  ;Remove shortcut

  !insertmacro MUI_STARTMENU_GETFOLDER Application $MUI_TEMP

  Delete "$SMPROGRAMS\$MUI_TEMP\Trebuchet.lnk"
  Delete "$SMPROGRAMS\$MUI_TEMP\Uninstall.lnk"
  RMDir "$SMPROGRAMS\$MUI_TEMP" ;Only if empty, so it won't delete other shortcuts
    
SectionEnd
