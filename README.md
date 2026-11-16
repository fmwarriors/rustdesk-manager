# RustDesk Manager

[![Documentation](https://img.shields.io/badge/docs-online-blue?logo=readthedocs)](https://angelbonet.github.io/rustdesk-manager/)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)

Aplicación de escritorio para gestionar conexiones RustDesk de forma centralizada. Cada usuario construye su propia agenda de equipos (solo con los IDs que él añade), ve en tiempo real cuáles están disponibles y los organiza en categorías y grupos.

**[📖 Documentación completa](https://angelbonet.github.io/rustdesk-manager/)**

![RustDesk Manager](static/logo.png)

## Características

- **Agenda propia**: solo aparecen los equipos que tú añades, nunca los de otros usuarios del servidor
- **Estado online/offline** en tiempo real, consultado directamente al servidor de IDs de RustDesk (sin credenciales de administrador)
- **Organización jerárquica** por categorías y grupos
- **Conexión directa** con un clic (requiere RustDesk instalado)
- **Transferencia de archivos** integrada
- **Multiidioma**: Español, English, Français
- **Tema claro/oscuro**
- **Import/Export** de configuración y datos
- **Multiplataforma**: macOS y Windows

## Despliegue profesional: como TeamViewer o AnyDesk

Además del Manager, el proyecto incluye **instaladores con asistente gráfico** para poner RustDesk en los equipos
de tus clientes **ya configurado con tu servidor**, igual que se hace con las herramientas comerciales
(TeamViewer, AnyDesk): el cliente hace doble clic, pulsa *Instalar* y el equipo queda listo para recibir soporte.

| | macOS | Windows |
|---|---|---|
| Instalador | `Instalar-RustDesk-Mac.dmg` (asistente SwiftUI) | `Instalar-RustDesk-Windows.exe` (asistente NSIS) |
| Desinstalador | `Desinstalar RustDesk.command` | `Desinstalar RustDesk.exe` |
| Configuración | un archivo `.rdconfig` por destinatario | un archivo `.rdconfig` por destinatario |

**Qué hacen, sin que el usuario toque nada técnico:**

- Descargan la última versión de RustDesk y **verifican su firma digital**
- Instalan RustDesk y su **servicio del sistema** (arranca con el equipo y permite acceso desatendido)
- Configuran **tu servidor y tu Key** y fijan una **contraseña permanente**
- Muestran el **ID del equipo** al terminar y, si quieres, te avisan por Pushover
- Guían por los permisos de macOS (Accesibilidad, Grabación de pantalla, Acceso total al disco)

**El instalador es el mismo para todos y no lleva datos dentro**: lo que cambia es el archivo `.rdconfig`
(servidor, Key y contraseña), que se genera con un clic desde *Ajustes* de RustDesk Manager y se envía solo a su
destinatario, como una licencia. El propio Manager también puede **importar** un `.rdconfig` para configurarse solo.

> Estado: el instalador de macOS está probado, incluido reiniciar el Mac. El de Windows está probado en
> Windows 11 (silencioso y gráfico). Ninguno está firmado con certificado de pago: macOS y SmartScreen avisan la
> primera vez (ver la [guía](docs/deployment/index.md)). El desinstalador de Windows aún no se ha probado.

[📦 Guía de despliegue](docs/deployment/index.md) · [🍎 macOS](docs/deployment/macos.md) · [🪟 Windows](docs/deployment/windows.md)

## Requisitos

| Componente | Descripción | Enlace |
|------------|-------------|--------|
| RustDesk | Cliente de escritorio remoto | [rustdesk.com](https://rustdesk.com/) |
| Servidor API | Panel web y API REST | [lejianwen/rustdesk-api](https://github.com/lejianwen/rustdesk-api) |
| Node.js 18+ | Solo para desarrollo | [nodejs.org](https://nodejs.org/) |

## Instalación

### macOS

1. Descarga `RustDesk-Manager-x.x.x-universal.dmg` de [Releases](../../releases)
2. Abre el DMG y arrastra la app a Aplicaciones
3. Configura tu servidor en Ajustes, o importa el archivo `.rdconfig` que te hayan enviado

### Windows

1. Descarga `RustDesk-Manager-Setup-x.x.x.exe` de [Releases](../../releases)
2. Ejecuta el instalador
3. Configura tu servidor en Ajustes, o importa el archivo `.rdconfig` que te hayan enviado

## Documentación

| Guía | Descripción |
|------|-------------|
| [📖 Manual de usuario](docs/guia/manual.md) | Cómo usar la aplicación |
| [🖥️ Montar servidor RustDesk](docs/servidor/index.md) | Instalación self-hosted completa |
| [📦 Instaladores de despliegue](docs/deployment/index.md) | Instalar RustDesk ya configurado en equipos remotos (Mac y Windows) |
| [🛠️ Desarrollo](docs/desarrollo/estructura.md) | Contribuir al proyecto |

## Desarrollo

```bash
# Clonar e instalar
git clone https://github.com/abdatabase/rustdesk-manager.git
cd rustdesk-manager
npm install

# Ejecutar en desarrollo
npm start

# Compilar
npm run build:mac   # macOS
npm run build:win   # Windows
npm run build:all   # Ambos
```

## Documentación con MkDocs

```bash
pip install mkdocs-material
mkdocs serve
```

## Licencia

MIT License

---

**abDatabase** · [abdatabase.com](https://abdatabase.com) · [☕ Invita un café](https://buymeacoffee.com/angelbonet)
