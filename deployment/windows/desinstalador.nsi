; Desinstalador de RustDesk para Windows — abDatabase. Quita RustDesk, su servicio, el ID y la contraseña.
; Compilar: ./build.sh   Modo silencioso: "Desinstalar RustDesk.exe" /S
Unicode true
!include "MUI2.nsh"
!include "LogicLib.nsh"

Name "Desinstalar RustDesk"
Caption "Desinstalar RustDesk"
OutFile "dist\Desinstalar RustDesk.exe"
RequestExecutionLevel admin
BrandingText "abDatabase"
ShowInstDetails show
InstallDir "$TEMP\abDatabase-RustDesk"
!ifdef APP_ICON
  Icon "${APP_ICON}"
!endif
VIProductVersion "1.0.0.0"
VIAddVersionKey /LANG=3082 "ProductName" "Desinstalar RustDesk"
VIAddVersionKey /LANG=3082 "CompanyName" "abDatabase"
VIAddVersionKey /LANG=3082 "FileDescription" "Desinstalador completo de RustDesk"
VIAddVersionKey /LANG=3082 "FileVersion" "1.0.0.0"

!define MUI_ABORTWARNING
!define MUI_WELCOMEPAGE_TITLE "Desinstalar RustDesk"
!define MUI_WELCOMEPAGE_TEXT "Este asistente elimina RustDesk de este equipo: el programa, el servicio, los ajustes, el ID y la contraseña.$\r$\n$\r$\nEl ID de este equipo se perderá: si vuelves a instalar RustDesk, tendrá uno nuevo y habrá que darlo de alta otra vez en el Manager.$\r$\n$\r$\nHaz clic en Siguiente para continuar."
!define MUI_PAGE_HEADER_TEXT "Desinstalando RustDesk"
!define MUI_PAGE_HEADER_SUBTEXT "Esto puede tardar un minuto. No cierres esta ventana."
!define MUI_FINISHPAGE_TITLE "Desinstalación terminada"
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH
!insertmacro MUI_LANGUAGE "Spanish"

Section "Desinstalar"
  InitPluginsDir
  SetOutPath "$PLUGINSDIR"
  File "desinstalar_rustdesk_windows.ps1"
  ; asistente de 32 bits: PowerShell de 64 bits (Sysnative) para tocar el «Program Files» real
  StrCpy $R8 "powershell.exe"
  IfFileExists "$WINDIR\Sysnative\WindowsPowerShell\v1.0\powershell.exe" 0 +2
    StrCpy $R8 "$WINDIR\Sysnative\WindowsPowerShell\v1.0\powershell.exe"
  DetailPrint "Desinstalando RustDesk..."
  nsExec::ExecToLog '"$R8" -NoProfile -ExecutionPolicy Bypass -File "$PLUGINSDIR\desinstalar_rustdesk_windows.ps1" -NoPause'
  Pop $0
  ${If} $0 != "0"
    MessageBox MB_ICONEXCLAMATION "No se ha podido quitar todo (código $0).$\r$\nReinicia el equipo y ejecuta este programa otra vez.$\r$\nRegistro: $TEMP\desinstalar_rustdesk.log" /SD IDOK
    SetErrorLevel 1
  ${EndIf}
SectionEnd
