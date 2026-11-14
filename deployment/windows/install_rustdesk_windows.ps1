#
# Instalador de RustDesk para Windows (lee un archivo .rdconfig)
# Se ejecuta desde Instalar_RustDesk.bat (que lo eleva a administrador).
#
# Un solo instalador, igual para todos y sin datos dentro: el servidor, la key y
# la contraseña vienen en el archivo .rdconfig (el mismo que usa el instalador de Mac).
#
# Orden importante (ver comentarios): la configuración se deja puesta ANTES de arrancar
# el servicio, y la contraseña permanente solo se fija con el servicio en marcha.
#
param([string]$ConfigFile = "", [switch]$NoPause, [string]$ResultFile = "", [switch]$Plain)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$logFile = Join-Path $env:TEMP "instalar_rustdesk.log"
try { Start-Transcript -Path $logFile -Force | Out-Null } catch {}

# Sin tildes cuando lo lanza el asistente gráfico (.exe): evita problemas de codificación en su registro
function Remove-Diacritics([string]$t) { return ($t.Normalize([Text.NormalizationForm]::FormD) -replace '\p{M}', '') -replace '[¿¡]', '' }
function Write-Host {
    param([Parameter(Position = 0)][object]$Object = '', [string]$ForegroundColor)
    $t = [string]$Object
    if ($Plain) { $t = Remove-Diacritics $t }
    if ($ForegroundColor) { Microsoft.PowerShell.Utility\Write-Host $t -ForegroundColor $ForegroundColor }
    else { Microsoft.PowerShell.Utility\Write-Host $t }
}
# Resultado para el asistente: ASCII, una clave por línea
function Write-Result([string[]]$lines) {
    if ($ResultFile) { [IO.File]::WriteAllText($ResultFile, ((($lines | ForEach-Object { Remove-Diacritics $_ }) -join "`r`n") + "`r`n"), [Text.Encoding]::ASCII) }
}

function Fail([string]$msg) {
    Write-Host ""
    Write-Host "ERROR: $msg" -ForegroundColor Red
    Write-Host "Registro: $logFile"
    Write-Result @("OK=0", "ERROR=$($msg -replace '[\r\n]+',' ')", "LOG=$logFile")
    try { Stop-Transcript | Out-Null } catch {}
    if (-not $NoPause) { Read-Host "Pulsa Intro para salir" }
    exit 1
}

# ---------------------------------------------------------------- 0. Archivo .rdconfig
function Read-Rdconfig([string]$path) {
    $cfg = @{}
    foreach ($line in (Get-Content -LiteralPath $path -Encoding UTF8)) {
        if ($line -match '^\s*([A-Z_]+)\s*=\s*(.*?)\s*$') { $cfg[$Matches[1]] = $Matches[2] }
    }
    return $cfg
}

function Test-Rdconfig($cfg) {
    if (-not $cfg.SERVIDOR)   { return "Falta SERVIDOR en el archivo de configuración." }
    if ($cfg.SERVIDOR -notmatch '^[A-Za-z0-9.-]+$') { return "SERVIDOR no es válido (solo el nombre, sin http:// ni puerto)." }
    if (-not $cfg.KEY)        { return "Falta KEY en el archivo de configuración." }
    if ($cfg.KEY -notmatch '^[A-Za-z0-9+/=_-]+$')   { return "KEY no es válida." }
    if (-not $cfg.CONTRASENA) { return "Falta CONTRASENA en el archivo de configuración." }
    if ($cfg.CONTRASENA -match '[''"`$%^&|<>]')     { return "CONTRASENA contiene caracteres no admitidos (comillas, `$ % ^ & | < >)." }
    return $null
}

$candidates = @()
if ($ConfigFile) { $candidates += $ConfigFile }
$desktop = [Environment]::GetFolderPath('Desktop')
$downloads = Join-Path $env:USERPROFILE 'Downloads'
foreach ($dir in @($scriptDir, $desktop, $downloads)) {
    if (Test-Path -LiteralPath $dir) {
        $candidates += (Get-ChildItem -LiteralPath $dir -Filter *.rdconfig -File -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -notmatch 'plantilla' } | Sort-Object LastWriteTime -Descending |
            ForEach-Object { $_.FullName })
    }
}

$cfg = $null; $cfgPath = $null; $lastErr = $null
foreach ($c in $candidates) {
    $try = Read-Rdconfig $c
    $err = Test-Rdconfig $try
    if (-not $err) { $cfg = $try; $cfgPath = $c; break } else { $lastErr = "$(Split-Path $c -Leaf): $err" }
}
if (-not $cfg) {
    if ($lastErr) { Fail "Archivo de configuración no válido. $lastErr" }
    Fail "No se encuentra ningún archivo .rdconfig.`nDéjalo en la misma carpeta que este instalador, en el Escritorio o en Descargas y vuelve a ejecutarlo."
}

$SERVER   = $cfg.SERVIDOR
$KEY      = $cfg.KEY
$PASSWORD = $cfg.CONTRASENA
$NAME     = if ($cfg.NOMBRE) { $cfg.NOMBRE } else { $env:COMPUTERNAME }

Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "  Instalando RustDesk - $NAME" -ForegroundColor Green
Write-Host "  Configuración: $(Split-Path $cfgPath -Leaf)" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green

# ---------------------------------------------------------------- 1. Descargar
Write-Host "`n[1/5] Buscando la última versión estable..." -ForegroundColor Yellow
try {
    $release = Invoke-RestMethod -Uri "https://api.github.com/repos/rustdesk/rustdesk/releases/latest" -UseBasicParsing
} catch { Fail "No se pudo consultar GitHub ($_). Comprueba la conexión a internet." }
$asset = $release.assets | Where-Object { $_.name -match '^rustdesk-[\d.]+-x86_64\.exe$' } | Select-Object -First 1
if (-not $asset) { Fail "No se encontró el instalador de Windows en la versión $($release.tag_name)." }
$version = $release.tag_name -replace '^v', ''
Write-Host "Versión $version" -ForegroundColor Green

Write-Host "`n[2/5] Descargando..." -ForegroundColor Yellow
$installer = Join-Path $env:TEMP $asset.name
try { Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $installer -UseBasicParsing }
catch { Fail "Error al descargar: $_" }
$sig = Get-AuthenticodeSignature -FilePath $installer
if ($sig.Status -ne 'Valid') { Fail "La firma del instalador descargado no es válida ($($sig.Status)). No se instala." }
Write-Host "Descargado y firma verificada." -ForegroundColor Green

# ---------------------------------------------------------------- 2. Instalar
Write-Host "`n[3/5] Instalando RustDesk..." -ForegroundColor Yellow
Get-Service -Name 'RustDesk' -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq 'Running' } | Stop-Service -Force -ErrorAction SilentlyContinue
Get-Process -Name 'rustdesk' -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1

# OJO: no usar «Start-Process -Wait»: espera también a todos los procesos que arranca el instalador
# (servicio, servidor, bandeja), que no terminan nunca, y el script se queda colgado.
$proc = Start-Process -FilePath $installer -ArgumentList '--silent-install' -PassThru
if (-not $proc.WaitForExit(180000)) { Write-Host "El instalador tarda más de lo normal; se continúa." -ForegroundColor Yellow }
Remove-Item $installer -Force -ErrorAction SilentlyContinue

# El instalador puede terminar antes de que la instalación acabe: esperar a que aparezcan el programa y el servicio
$exe = $null
for ($i = 0; $i -lt 90 -and -not $exe; $i++) {
    # ProgramW6432 = «Program Files» real (64 bits), aunque este PowerShell sea de 32 bits
    $exe = @("$env:ProgramW6432\RustDesk\rustdesk.exe", "$env:ProgramFiles\RustDesk\rustdesk.exe", "${env:ProgramFiles(x86)}\RustDesk\rustdesk.exe") |
        Where-Object { Test-Path $_ } | Select-Object -First 1
    if (-not $exe) { Start-Sleep -Seconds 2 }
}
if (-not $exe) { Fail "La instalación no ha terminado: no se encuentra rustdesk.exe." }
for ($i = 0; $i -lt 45 -and -not (Get-Service -Name 'RustDesk' -ErrorAction SilentlyContinue); $i++) { Start-Sleep -Seconds 2 }
Start-Sleep -Seconds 5

# ---------------------------------------------------------------- 3. Configurar (antes de arrancar)
Write-Host "`n[4/5] Configurando el servidor..." -ForegroundColor Yellow
# Parar todo para que nadie pise el archivo con la configuración por defecto
Get-Service -Name 'RustDesk' -ErrorAction SilentlyContinue | Stop-Service -Force -ErrorAction SilentlyContinue
Get-Process -Name 'rustdesk' -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

$toml = @"
rendezvous_server = '${SERVER}:21116'
nat_type = 1
serial = 0

[options]
custom-rendezvous-server = '$SERVER'
relay-server = '$SERVER'
key = '$KEY'
"@
# UTF-8 SIN BOM (Out-File -Encoding UTF8 añade BOM en Windows PowerShell 5.1 y RustDesk podría ignorar el archivo)
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

# Dos sitios: el perfil del servicio (atiende las conexiones entrantes) y el del usuario que instala (la interfaz)
$configDirs = @(
    "$env:windir\ServiceProfiles\LocalService\AppData\Roaming\RustDesk\config",
    "$env:APPDATA\RustDesk\config"
)
foreach ($dir in $configDirs) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    [IO.File]::WriteAllText((Join-Path $dir 'RustDesk2.toml'), $toml, $utf8NoBom)
    Write-Host "  Configuración escrita en $dir"
}

# ---------------------------------------------------------------- 4. Arrancar y fijar contraseña
Write-Host "`n[5/5] Arrancando RustDesk y fijando la contraseña..." -ForegroundColor Yellow
Start-Service -Name 'RustDesk' -ErrorAction SilentlyContinue
Start-Sleep -Seconds 4
Start-Process -FilePath $exe -ArgumentList '--tray' -ErrorAction SilentlyContinue
Start-Sleep -Seconds 3

# --password solo funciona con el servicio en marcha: se reintenta
for ($i = 1; $i -le 6; $i++) {
    & $exe --password $PASSWORD 2>&1 | Out-Null
    Start-Sleep -Seconds 2
}

$rustdeskId = $null
for ($i = 1; $i -le 6 -and -not $rustdeskId; $i++) {
    $rustdeskId = (& $exe --get-id 2>$null | Out-String).Trim()
    if ($rustdeskId -notmatch '^\d{6,}$') { $rustdeskId = $null; Start-Sleep -Seconds 2 }
}
if (-not $rustdeskId) { $rustdeskId = "no disponible" }

$svc = Get-Service -Name 'RustDesk' -ErrorAction SilentlyContinue
Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "  Instalación completada" -ForegroundColor Green
Write-Host "  ID:        $rustdeskId" -ForegroundColor Green
Write-Host "  Versión:   $version" -ForegroundColor Green
Write-Host "  Servidor:  $SERVER" -ForegroundColor Green
Write-Host "  Servicio:  $(if ($svc) { $svc.Status } else { 'no encontrado' })" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green

# Aviso Pushover opcional (PUSHOVER_TOKEN / PUSHOVER_USER en el .rdconfig)
if ($cfg.PUSHOVER_TOKEN -and $cfg.PUSHOVER_USER) {
    try {
        Invoke-RestMethod -Uri "https://api.pushover.net/1/messages.json" -Method Post -Body @{
            token = $cfg.PUSHOVER_TOKEN; user = $cfg.PUSHOVER_USER
            title = "RustDesk instalado: $NAME"
            message = "ID: $rustdeskId`nEquipo: $env:COMPUTERNAME`nVersión: $version"
        } | Out-Null
    } catch {}
}

Write-Result @("OK=1", "ID=$rustdeskId", "VERSION=$version", "SERVIDOR=$SERVER", "NOMBRE=$NAME", "LOG=$logFile")
try { Stop-Transcript | Out-Null } catch {}
if (-not $NoPause) { Read-Host "Anota el ID y pulsa Intro para cerrar" }
