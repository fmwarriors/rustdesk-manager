# Instaladores de despliegue

Poner RustDesk en los equipos de tus clientes **ya configurado con tu servidor**, con la misma comodidad que las
herramientas comerciales como **TeamViewer** o **AnyDesk**: el cliente hace doble clic, pulsa *Instalar* y el
equipo queda listo para recibir soporte.

## La idea: un instalador y una «licencia»

- **Un instalador igual para todos**, con asistente gráfico, que no lleva ningún dato dentro.
- **Un archivo `.rdconfig` por destinatario** (servidor, Key y contraseña), como una licencia. Se genera con un
  clic desde *Ajustes → Archivo para el instalador de RustDesk* en RustDesk Manager y se envía solo a su dueño.

| | macOS | Windows |
|---|---|---|
| Instalador | `Instalar-RustDesk-Mac.dmg` (asistente SwiftUI) | `Instalar-RustDesk-Windows.exe` (asistente NSIS) |
| Desinstalador | `Desinstalar RustDesk.command` | `Desinstalar RustDesk.exe` |
| Guía | [macOS](macos.md) | [Windows](windows.md) |

## Qué hacen por el usuario

1. Descargan la última versión de RustDesk y **verifican su firma digital**.
2. Instalan RustDesk y su **servicio del sistema** (arranca con el equipo, acceso desatendido).
3. Configuran **tu servidor y tu Key** y fijan la **contraseña permanente**.
4. Muestran el **ID del equipo** al terminar y, opcionalmente, te avisan por **Pushover**.
5. En macOS, guían por los permisos del sistema (Accesibilidad, Grabación de pantalla, Acceso total al disco).

## Estado de las pruebas

- **macOS**: probado, incluido reiniciar el Mac (RustDesk vuelve solo).
- **Windows**: instalador probado en Windows 11 (silencioso y gráfico). El **desinstalador** y Windows 10 están
  **sin probar**.
- Ninguno está firmado con certificado de pago (Apple Developer ID / Authenticode): macOS y SmartScreen avisan la
  primera vez y hay que confirmar la ejecución.

!!! note "Método antiguo"
    Debajo se describe el método anterior, basado en scripts y un `config.txt` (carpetas `deployment/mac/` y
    `deployment/windows/` del repositorio). Se mantiene como alternativa, pero **los instaladores de arriba son el
    método recomendado**.

# Método antiguo: scripts y `config.txt`

## ¿Qué incluyen?

Los scripts de la carpeta `deployment/` permiten:

- Descargar e instalar RustDesk automáticamente
- Configurar el servidor (ID server y relay)
- Establecer una contraseña permanente
- Notificación opcional vía Pushover con el ID generado

## Archivos incluidos

| Archivo | Descripción |
|---------|-------------|
| `config.txt` | **Configuración del servidor** (editar antes de usar) |
| `config.txt.example` | Ejemplo de configuración |
| `Instalar_RustDesk.command` | Launcher macOS (doble clic) |
| `install_rustdesk_mac.sh` | Script de instalación macOS |
| `Instalar_RustDesk.bat` | Launcher Windows (doble clic) |
| `install_rustdesk_windows.ps1` | Script de instalación Windows |

## Configuración inicial

!!! warning "Antes de usar"
    Debes configurar `config.txt` con los datos de tu servidor.

1. Abre el archivo `config.txt`
2. Rellena los valores:

```ini
RENDEZVOUS_SERVER=tu-servidor.com
KEY=tu-clave-publica-del-servidor
PASSWORD=contraseña-para-clientes
RUSTDESK_VERSION=1.4.6
```

3. Guarda el archivo

!!! danger "No subir a repositorios públicos"
    El archivo `config.txt` contiene datos sensibles. Está incluido en `.gitignore` para evitar que se suba accidentalmente.

## Guías de instalación

### :material-apple: macOS

Instalación en equipos Mac (Intel y Apple Silicon).

[:octicons-arrow-right-24: Guía macOS](macos.md)

### :material-microsoft-windows: Windows

Instalación en equipos Windows.

[:octicons-arrow-right-24: Guía Windows](windows.md)

## Distribución a clientes

### Para tu uso personal

Configura `config.txt` una vez y usa los instaladores en todos los equipos.

### Para distribución pública

1. **No incluyas** `config.txt` en la distribución
2. Proporciona un `config.txt.example` con valores de ejemplo
3. Los usuarios deben crear su propio `config.txt`

## Notificaciones Pushover

Si configuras las credenciales de Pushover en `config.txt`, recibirás una notificación cada vez que se instale RustDesk en un equipo con:

- Nombre del equipo
- ID de RustDesk generado
- Contraseña configurada
- Fecha y hora

Obtén tus credenciales en [pushover.net](https://pushover.net)

## Actualizar versión de RustDesk

Edita `RUSTDESK_VERSION` en `config.txt`:

```ini
RUSTDESK_VERSION=1.4.6
```

Consulta las versiones disponibles en [github.com/rustdesk/rustdesk/releases](https://github.com/rustdesk/rustdesk/releases)
