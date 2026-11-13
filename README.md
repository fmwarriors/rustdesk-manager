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

## Requisitos

| Componente | Descripción | Enlace |
|------------|-------------|--------|
| RustDesk | Cliente de escritorio remoto | [rustdesk.com](https://rustdesk.com/) |
| Servidor API | Panel web y API REST | [lejianwen/rustdesk-api](https://github.com/lejianwen/rustdesk-api) |
| Node.js 18+ | Solo para desarrollo | [nodejs.org](https://nodejs.org/) |

## Instalación

### macOS

1. Descarga `RustDesk Manager-x.x.x-universal.dmg` de [Releases](../../releases)
2. Abre el DMG y arrastra la app a Aplicaciones
3. Configura tu servidor en Ajustes

### Windows

1. Descarga `RustDesk Manager Setup x.x.x.exe` de [Releases](../../releases)
2. Ejecuta el instalador
3. Configura tu servidor en Ajustes

## Documentación

| Guía | Descripción |
|------|-------------|
| [📖 Manual de usuario](docs/guia/manual.md) | Cómo usar la aplicación |
| [🖥️ Montar servidor RustDesk](docs/servidor/index.md) | Instalación self-hosted completa |
| [📦 Scripts de despliegue](docs/deployment/index.md) | Instalar RustDesk en equipos remotos |
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
