; Instalador de RustDesk para Windows (asistente gráfico) — abDatabase
;
; Un único instalador, igual para todos y sin ningún dato dentro. El servidor, la Key y la contraseña
; vienen en un archivo .rdconfig (el mismo que usa el instalador de Mac). La lógica real está en
; install_rustdesk_windows.ps1, que se incrusta aquí y se ejecuta con permisos de administrador.
;
; Compilar (desde un Mac, con el NSIS que trae electron-builder):  ./build.sh
; Parámetros de línea de comandos:  "Instalar RustDesk.exe" [archivo.rdconfig]   y   /S  (modo silencioso)

Unicode true
!include "MUI2.nsh"
!include "nsDialogs.nsh"
!include "LogicLib.nsh"
!include "FileFunc.nsh"

!define APP_NAME "Instalar RustDesk"

Name "${APP_NAME}"
Caption "Instalar RustDesk"
OutFile "dist\Instalar RustDesk.exe"
RequestExecutionLevel admin
BrandingText "abDatabase"
ShowInstDetails show
InstallDir "$TEMP\abDatabase-RustDesk"

!ifdef APP_ICON
  Icon "${APP_ICON}"
!endif

VIProductVersion "1.0.0.0"
VIAddVersionKey /LANG=3082 "ProductName" "Instalar RustDesk"
VIAddVersionKey /LANG=3082 "CompanyName" "abDatabase"
VIAddVersionKey /LANG=3082 "FileDescription" "Instalador de RustDesk configurado con archivo .rdconfig"
VIAddVersionKey /LANG=3082 "FileVersion" "1.0.0.0"
VIAddVersionKey /LANG=3082 "LegalCopyright" "abDatabase"

Var CfgPath        ; ruta del .rdconfig elegido
Var Dlg
Var LblEstado
Var LblArchivo
Var BtnElegir
Var IdResultado
Var TxtId

; ------------------------------------------------------------------ páginas
!define MUI_ABORTWARNING
!define MUI_WELCOMEPAGE_TITLE "Instalar RustDesk"
!define MUI_WELCOMEPAGE_TEXT "Este asistente instala RustDesk en este equipo, ya configurado para tu servidor, para que podamos darte soporte remoto.$\r$\n$\r$\nNecesita el archivo de configuración (.rdconfig) que te ha enviado quien te da soporte. Déjalo en el Escritorio o en Descargas, o elígelo en el siguiente paso.$\r$\n$\r$\nHaz clic en Siguiente para continuar."
!insertmacro MUI_PAGE_WELCOME
Page custom PaginaConfigCreate PaginaConfigLeave
!define MUI_PAGE_HEADER_TEXT "Instalando RustDesk"
!define MUI_PAGE_HEADER_SUBTEXT "Esto puede tardar uno o dos minutos. No cierres esta ventana."
!insertmacro MUI_PAGE_INSTFILES
Page custom PaginaIdCreate PaginaIdLeave
!insertmacro MUI_LANGUAGE "Spanish"

; ------------------------------------------------------------------ búsqueda del .rdconfig
Function BuscarEn
  ; entrada: pila = carpeta. Si CfgPath está vacío, toma el primer .rdconfig que no sea la plantilla.
  Exch $0
  Push $1
  Push $2
  ${If} $CfgPath == ""
    FindFirst $1 $2 "$0\*.rdconfig"
    ${While} $2 != ""
      ${If} $2 != "Plantilla.rdconfig"
        StrCpy $CfgPath "$0\$2"
        ${Break}
      ${EndIf}
      FindNext $1 $2
    ${EndWhile}
    FindClose $1
  ${EndIf}
  Pop $2
  Pop $1
  Pop $0
FunctionEnd

Function BuscarConfig
  StrCpy $CfgPath ""
  ; 1) argumento de la línea de comandos (doble clic / "Abrir con")
  ${GetParameters} $0
  ${If} $0 != ""
    StrCpy $1 $0 1
    ${If} $1 == '"'
      StrCpy $0 $0 "" 1
      StrLen $2 $0
      IntOp $2 $2 - 1
      StrCpy $0 $0 $2
    ${EndIf}
    IfFileExists "$0" 0 +2
      StrCpy $CfgPath "$0"
  ${EndIf}
  ; 2) junto al instalador, Escritorio, Descargas
  Push $EXEDIR
  Call BuscarEn
  Push "$DESKTOP"
  Call BuscarEn
  Push "$PROFILE\Downloads"
  Call BuscarEn
FunctionEnd

; ------------------------------------------------------------------ página: archivo de configuración
Function PaginaConfigCreate
  Call BuscarConfig
  !insertmacro MUI_HEADER_TEXT "Archivo de configuración" "Datos de tu servidor RustDesk"
  nsDialogs::Create 1018
  Pop $Dlg
  ${If} $Dlg == error
    Abort
  ${EndIf}
  ${NSD_CreateLabel} 0 0 100% 24u "Este instalador no lleva ningún dato del servidor. Usa el archivo .rdconfig que te ha enviado quien te da soporte."
  Pop $0
  ${NSD_CreateLabel} 0 34u 100% 12u "Archivo encontrado:"
  Pop $0
  ${NSD_CreateLabel} 0 48u 100% 24u ""
  Pop $LblArchivo
  ${NSD_CreateLabel} 0 76u 100% 24u ""
  Pop $LblEstado
  ${NSD_CreateButton} 0 106u 120u 14u "Elegir archivo..."
  Pop $BtnElegir
  ${NSD_OnClick} $BtnElegir PaginaConfigElegir
  Call ActualizarEstadoConfig
  nsDialogs::Show
FunctionEnd

Function ActualizarEstadoConfig
  ${If} $CfgPath == ""
    ${NSD_SetText} $LblArchivo "(ninguno)"
    ${NSD_SetText} $LblEstado "No se ha encontrado ningún archivo .rdconfig. Déjalo en el Escritorio o en Descargas y pulsa «Elegir archivo...», o selecciónalo directamente."
    GetDlgItem $0 $HWNDPARENT 1
    EnableWindow $0 0
  ${Else}
    ${NSD_SetText} $LblArchivo "$CfgPath"
    ${NSD_SetText} $LblEstado "Listo. Pulsa Instalar para continuar. Se te pedirá confirmar los permisos de administrador."
    GetDlgItem $0 $HWNDPARENT 1
    EnableWindow $0 1
  ${EndIf}
FunctionEnd

Function PaginaConfigElegir
  nsDialogs::SelectFileDialog open "$DESKTOP" "Archivos de configuración (*.rdconfig)|*.rdconfig|Todos los archivos|*.*"
  Pop $0
  ${If} $0 != ""
    StrCpy $CfgPath $0
    Call ActualizarEstadoConfig
  ${EndIf}
FunctionEnd

Function PaginaConfigLeave
  ${If} $CfgPath == ""
    MessageBox MB_ICONEXCLAMATION "Primero elige el archivo .rdconfig."
    Abort
  ${EndIf}
FunctionEnd

; ------------------------------------------------------------------ instalación
Section "Instalar"
  ; en modo silencioso (/S) las páginas no se muestran: buscar el .rdconfig aquí
  ${If} $CfgPath == ""
    Call BuscarConfig
  ${EndIf}
  ${If} $CfgPath == ""
    MessageBox MB_ICONSTOP "No se ha encontrado ningún archivo .rdconfig." /SD IDOK
    SetErrorLevel 3
    Abort
  ${EndIf}
  InitPluginsDir
  SetOutPath "$PLUGINSDIR"
  File "install_rustdesk_windows.ps1"
  Delete "$TEMP\instalar_rustdesk_resultado.txt"

  DetailPrint "Configuración: $CfgPath"
  DetailPrint "Descargando e instalando RustDesk (puede tardar unos minutos)..."
  ; este asistente es de 32 bits: usar el PowerShell de 64 bits (Sysnative) para que «Program Files» sea el real
  StrCpy $R8 "powershell.exe"
  IfFileExists "$WINDIR\Sysnative\WindowsPowerShell\v1.0\powershell.exe" 0 +2
    StrCpy $R8 "$WINDIR\Sysnative\WindowsPowerShell\v1.0\powershell.exe"
  StrCpy $R9 '"$R8" -NoProfile -ExecutionPolicy Bypass -File "$PLUGINSDIR\install_rustdesk_windows.ps1" -ConfigFile "$CfgPath" -NoPause -Plain -ResultFile "$TEMP\instalar_rustdesk_resultado.txt"'
  nsExec::ExecToLog '$R9'
  Pop $0
  ; registro del asistente (para diagnosticar)
  FileOpen $8 "$TEMP\instalar_rustdesk_asistente.log" w
  FileWrite $8 "cmd: $R9$\r$\nresultado nsExec: $0$\r$\n"
  FileClose $8

  ; leer el resultado (OK=1 / ID=...)
  StrCpy $IdResultado ""
  StrCpy $R1 ""
  IfFileExists "$TEMP\instalar_rustdesk_resultado.txt" 0 sinresultado
  FileOpen $2 "$TEMP\instalar_rustdesk_resultado.txt" r
  leer:
    FileRead $2 $3
    ${If} $3 == ""
      Goto finleer
    ${EndIf}
    StrCpy $4 $3 3
    ${If} $4 == "ID="
      StrCpy $IdResultado $3 "" 3
      ; quitar el salto de línea
      StrCpy $IdResultado $IdResultado -2
    ${EndIf}
    StrCpy $4 $3 6
    ${If} $4 == "ERROR="
      StrCpy $R1 $3 "" 6
      StrCpy $R1 $R1 -2
    ${EndIf}
    Goto leer
  finleer:
  FileClose $2

  ${If} $IdResultado == ""
    DetailPrint "La instalación no se ha completado: $R1"
    MessageBox MB_ICONSTOP "La instalación no se ha completado.$\r$\n$\r$\n$R1$\r$\n$\r$\nRegistro: $TEMP\instalar_rustdesk.log$\r$\nEnvía ese archivo a quien te da soporte." /SD IDOK
    SetErrorLevel 2
    Abort
  ${EndIf}
  DetailPrint "Instalación completada. ID: $IdResultado"
  Goto fin
  sinresultado:
    MessageBox MB_ICONSTOP "La instalación no se ha completado (sin resultado).$\r$\nRegistro: $TEMP\instalar_rustdesk.log" /SD IDOK
    SetErrorLevel 2
    Abort
  fin:
SectionEnd

; ------------------------------------------------------------------ página final: el ID
Function PaginaIdCreate
  !insertmacro MUI_HEADER_TEXT "Instalación completada" "RustDesk ya está instalado y configurado"
  nsDialogs::Create 1018
  Pop $Dlg
  ${If} $Dlg == error
    Abort
  ${EndIf}
  ${NSD_CreateLabel} 0 0 100% 24u "RustDesk se ha instalado correctamente. Este es el ID de este equipo. Anótalo (o cópialo): lo necesitarás para añadir el equipo en RustDesk Manager."
  Pop $0
  ${NSD_CreateText} 0 34u 100% 22u "$IdResultado"
  Pop $TxtId
  SendMessage $TxtId ${EM_SETREADONLY} 1 0
  CreateFont $1 "Segoe UI" 16 700
  SendMessage $TxtId ${WM_SETFONT} $1 1
  ${NSD_CreateLabel} 0 66u 100% 36u "Si Windows muestra avisos de seguridad de RustDesk, acéptalos. El equipo ya puede recibir conexiones con la contraseña de tu archivo de configuración."
  Pop $0
  GetDlgItem $0 $HWNDPARENT 2
  EnableWindow $0 0
  GetDlgItem $0 $HWNDPARENT 1
  SendMessage $0 ${WM_SETTEXT} 0 "STR:Cerrar"
  nsDialogs::Show
FunctionEnd

Function PaginaIdLeave
FunctionEnd
