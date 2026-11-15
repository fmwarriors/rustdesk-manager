# Desinstala RustDesk por completo en Windows (programa, servicio, ajustes, ID y contraseña). Requiere administrador.
# Uso: powershell -File desinstalar_rustdesk_windows.ps1 [-NoPause]
param([switch]$NoPause)
$ErrorActionPreference = 'Continue'
$log = Join-Path $env:TEMP 'desinstalar_rustdesk.log'
function Log($m) { $l = "$(Get-Date -Format 'HH:mm:ss') $m"; Write-Host $l; Add-Content -Path $log -Value $l -Encoding UTF8 }

Log 'Parando el servicio y los procesos de RustDesk...'
Stop-Service -Name 'RustDesk' -Force -ErrorAction SilentlyContinue
Get-Process -Name 'rustdesk' -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

$pf = if ($env:ProgramW6432) { $env:ProgramW6432 } else { $env:ProgramFiles }
$exe = Join-Path $pf 'RustDesk\rustdesk.exe'
if (Test-Path $exe) {
    Log 'Ejecutando el desinstalador de RustDesk...'
    $p = Start-Process -FilePath $exe -ArgumentList '--uninstall' -PassThru -WindowStyle Hidden
    if (-not $p.WaitForExit(120000)) { Log 'El desinstalador tarda demasiado; se continua con la limpieza manual.' }
    Start-Sleep -Seconds 3
    Get-Process -Name 'rustdesk' -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
}

Log 'Eliminando el servicio y los restos...'
if (Get-Service -Name 'RustDesk' -ErrorAction SilentlyContinue) { & sc.exe delete RustDesk | Out-Null }
$rutas = @(
    (Join-Path $pf 'RustDesk'),
    'C:\Windows\ServiceProfiles\LocalService\AppData\Roaming\RustDesk',
    'C:\Windows\ServiceProfiles\LocalService\AppData\Local\RustDesk',
    (Join-Path $env:ProgramData 'RustDesk'),
    (Join-Path $env:ProgramData 'Microsoft\Windows\Start Menu\Programs\RustDesk')
)
# ajustes de todos los usuarios del equipo (ID, contraseña y config de servidor)
Get-ChildItem 'C:\Users' -Directory -ErrorAction SilentlyContinue | ForEach-Object {
    $rutas += (Join-Path $_.FullName 'AppData\Roaming\RustDesk')
    $rutas += (Join-Path $_.FullName 'AppData\Local\RustDesk')
    $rutas += (Join-Path $_.FullName 'AppData\Roaming\Microsoft\Windows\Start Menu\Programs\RustDesk')
}
foreach ($r in $rutas) {
    if (Test-Path $r) { Remove-Item -Path $r -Recurse -Force -ErrorAction SilentlyContinue; Log "Borrado: $r" }
}
Remove-Item 'C:\Users\Public\Desktop\RustDesk.lnk' -Force -ErrorAction SilentlyContinue
Remove-Item 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\RustDesk' -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\RustDesk' -Recurse -Force -ErrorAction SilentlyContinue

$resto = (Test-Path (Join-Path $pf 'RustDesk')) -or [bool](Get-Service -Name 'RustDesk' -ErrorAction SilentlyContinue)
if ($resto) { Log 'AVISO: quedan restos de RustDesk (reinicia el equipo y vuelve a ejecutar este desinstalador).'; $code = 1 }
else { Log 'RustDesk se ha desinstalado por completo. El ID de este equipo se ha perdido: al reinstalar tendra uno nuevo.'; $code = 0 }
if (-not $NoPause) { Read-Host 'Pulsa Intro para cerrar' | Out-Null }
exit $code
