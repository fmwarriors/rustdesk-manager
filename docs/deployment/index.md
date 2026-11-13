# Scripts de despliegue

Instaladores para poner RustDesk en equipos remotos, ya configurado con tu servidor.

!!! tip "macOS: instalador gráfico"
    En Mac hay un **instalador con asistente** que se configura con un archivo `.rdconfig` por destinatario,
    instala también el servicio del sistema y fija la contraseña. Es el método recomendado:
    [Guía macOS](macos.md). El `config.txt` de abajo se usa en Windows y en el script antiguo de Mac.

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
