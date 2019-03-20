;NSIS installer for trebuchet with stand alone options.
;
;When making yourself, change "Z:\Treb" strings to correct location

!define PROD_NAME "Trebuchet Tk"
!define VER_MAJOR 1
!define VER_MINOR 82
!define VER_REVISION 0
!define VER_BUILD 1
!define VER_FILE "1082"
!define VER_DISPLAY "1.082"

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
Caption "${PROD_NAME} ${VER_DISPLAY} Setup"
OutFile "Z:\Treb\TrebInst.exe"
InstallDir "$PROGRAMFILES\${PROD_NAME}"
LicenseData "Z:\Treb\Contrib\COPYING"

;------------------
;Interface Settings
;------------------

;Define custom look and images to be used
!define MUI_ABORTWARNING
;!define MUI_LANGDLL_ALWAYSSHOW
;!define MUI_ICON "..\images\install.ico"
;!define MUI_UNICON "..\images\uninstall.ico"
;!define MUI_HEADERIMAGE_BITMAP "..\images\header.bmp"
;!define MUI_HEADERIMAGE_UNBITMAP "..\images\header.bmp"
;!define MUI_FINISHPAGE_SHOWREADME "$INSTDIR\readme.txt"
;!define MUI_FINISHPAGE_SHOWREADME_NOTCHECKED

;-----------------------------
;Pages to be used in the setup
;-----------------------------

;General pages
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "Z:\Treb\Contrib\COPYING"
!insertmacro MUI_PAGE_COMPONENTS
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

;-------------
;Reserve Files
;-------------

;Reserve file to make installer quicker
; !insertmacro MUI_RESERVEFILE_LANGDLL



  ;Descriptions
  LangString DESC_Trebuchet ${LANG_ENGLISH} "Trebuchet Muck Client"
  LangString DESC_SSL ${LANG_ENGLISH} "Support for Secure Servers using SSL"
  LangString DESC_TCLKit ${LANG_ENGLISH} "Run Trebuchet from TCL-Kit"
  ComponentText "Please select how you would like to run Trebuchet. If unsure, choose TCL-Kit."

  ;Graphics
  !define MUI_SPECIALBITMAP "Z:\Treb\Contrib\revar.bmp"




;Install types
InstType "Run from TCLKit"
InstType "Run from TCL Enviroment"

;Installer Sections

Section "Trebuchet" Trebuchet
  SectionIn 1 2 RO

  SetOutPath "$INSTDIR"
  File "Z:\Treb\Build\*"
  File "Z:\Treb\Contrib\*"
  File /r "Z:\Treb\Build\pkgs"
  File /r "Z:\Treb\Build\lib"
  File /r "Z:\Treb\Build\docs"
  
  ;Create uninstaller
  WriteUninstaller "$INSTDIR\Uninstall.exe"

  !insertmacro MUI_STARTMENU_WRITE_BEGIN Application
    ;Create Start menu shortcuts
    CreateDirectory "$SMPROGRAMS\$STARTMENU_FOLDER"
    CreateShortCut "$SMPROGRAMS\$STARTMENU_FOLDER\Trebuchet.lnk" "$OUTDIR\start.tcl"
    CreateShortCut "$SMPROGRAMS\$STARTMENU_FOLDER\Uninstall.lnk" "$OUTDIR\Uninstall.exe"
  !insertmacro MUI_STARTMENU_WRITE_END
SectionEnd


Section "Secure Server Support" SSL
  SectionIn 1 2

  SetOutPath "$INSTDIR"
  File /r "Z:\Treb\Contrib\tls"
  File /r "Z:\Treb\Build\cacerts"
SectionEnd


Section "TCL Kit" TCLKit
  SectionIn 1

  SetOutPath "$INSTDIR"
  File /r "Z:\Treb\Contrib\tclkit"
  File /r "Z:\Treb\Contrib\img"

  !insertmacro MUI_STARTMENU_WRITE_BEGIN Application
    CreateShortCut "$SMPROGRAMS\$STARTMENU_FOLDER\Trebuchet.lnk" "$OUTDIR\tclkit\tcl-kit.exe" "start.tcl"
  !insertmacro MUI_STARTMENU_WRITE_END
SectionEnd



;--------------------------------
;Descriptions

!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
  !insertmacro MUI_DESCRIPTION_TEXT ${Trebuchet} $(DESC_Trebuchet)
  !insertmacro MUI_DESCRIPTION_TEXT ${SSL} $(DESC_SSL)
  !insertmacro MUI_DESCRIPTION_TEXT ${TCLKit} $(DESC_TCLKit)
!insertmacro MUI_FUNCTION_DESCRIPTION_END
 
;--------------------------------
;Uninstaller Section

Section "Uninstall"

  ;ADD YOUR OWN STUFF HERE!


  Delete "$INSTDIR\pkgs\*.*"
  Delete "$INSTDIR\lib\*.*"
  Delete "$INSTDIR\docs\*.*"
  Delete "$INSTDIR\tls\*.*"
  Delete "$INSTDIR\img\*.*"
  Delete "$INSTDIR\cacerts\*.*"
  Delete "$INSTDIR\*.*"

  RMDir /r "$INSTDIR"

 
  ;Remove shortcut

  !insertmacro MUI_STARTMENU_GETFOLDER Application $MUI_TEMP

  Delete "$SMPROGRAMS\$MUI_TEMP\Trebuchet.lnk"
  Delete "$SMPROGRAMS\$MUI_TEMP\Uninstall.lnk"
  RMDir "$SMPROGRAMS\$MUI_TEMP" ;Only if empty, so it won't delete other shortcuts
    
SectionEnd
