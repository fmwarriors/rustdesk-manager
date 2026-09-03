# RustDesk Manager — CLAUDE.md

## Proyecto
Aplicación de escritorio Electron para gestionar conexiones RustDesk, compilada para Mac y Windows. Desarrollada por abDatabase.

- **Repositorio**: https://github.com/angelbonet/rustdesk-manager
- **Fork**: https://github.com/fmwarriors/rustdesk-manager (sincronizar con `gh repo sync fmwarriors/rustdesk-manager`)
- **Docs (GitHub Pages)**: https://angelbonet.github.io/rustdesk-manager/
- **Versión actual**: 1.1.0

## Stack
- **Frontend**: HTML + Tailwind CSS + Nunjucks templates
- **Backend**: Node.js + Express (puerto 5050)
- **Base de datos**: SQLite via sql.js
- **Empaquetado**: Electron + electron-builder

## Estructura
```
electron/main.js          — proceso principal Electron
server/index.js           — servidor Express
server/database.js        — acceso SQLite
server/config.js          — gestión configuración
server/i18n.js            — traducciones (es, en, fr)
templates/index.html      — UI principal
deployment/mac/           — instalador macOS
deployment/windows/       — instalador Windows
docs/                     — documentación MkDocs Material
```

## Comandos
```bash
npm start                 # desarrollo
npm run build:mac         # compilar Mac
npm run build:win         # compilar Windows
npm run build:all         # compilar ambos
```

## Desarrollo y pruebas — IMPORTANTE
- **Antes de arrancar un servidor de pruebas** (`node server/index.js` o `npm start`) contra el puerto 5050, comprobar que `/Applications/RustDesk Manager.app` no esté ya abierta (`lsof -nP -iTCP:5050 -sTCP:LISTEN`). Si lo está, las peticiones de prueba pueden acabar sirviéndolas la app real en lugar del proceso de pruebas — sin ningún aviso — y cualquier escritura de prueba (crear equipo/grupo) se cuela en la base de datos de producción real del usuario. Pasó el 2026-09-03: un `POST` de prueba creó un equipo falso en un grupo de cliente real. Si el usuario tiene la app abierta, pedirle que la cierre antes de probar.
- **Asimetría de rutas de datos**: `server/config.js` usa siempre `app.getPath('userData')` cuando corre bajo Electron (dev **o** empaquetado) — dev y producción comparten `config.json` (servidor API, credenciales). `server/database.js` solo usa `userData` cuando `app.isPackaged` es `true` — en modo dev (`npm start`), la base de datos de equipos es la local del repo (`rustdesk_manager.db`), aislada de producción. Por eso `npm start` es seguro para crear/borrar datos de prueba, siempre que no haya colisión de puerto con la app empaquetada (punto anterior).

## Datos de usuario (runtime, no en repo)
- **Mac**: `~/Library/Application Support/rustdesk-manager/`
- **Win**: `%APPDATA%\rustdesk-manager\`
- Contiene: `rustdesk_manager.db` y `config.json`

## Servidor API RustDesk (abdatabase.com)
- HTTPS: `https://rustdesk.abdatabase.com:21443`
- Admin panel: `/_admin/` — usuario `admin`
- Key: `yQEvgGIyApESt9heFmszb15ec9haoxwJYoznV7iU3q4=`
- **IMPORTANTE**: NO configurar "Servidor API" en los clientes RustDesk — causa error "deadline has elapsed". La sincronización se hace solo desde RustDesk Manager.

## Instaladores de deployment
Cada carpeta (`mac/`, `windows/`) es autónoma y se distribuye al usuario final:
- Contiene su propio `config.txt.example` → el usuario copia a `config.txt` y rellena los datos
- `config.txt` está en `.gitignore` (nunca se sube al repo)
- Los scripts descargan automáticamente la última versión de RustDesk desde GitHub
- Envían notificación Pushover con ID y nombre del equipo al completar

## MkDocs
- Config: `mkdocs.yml`
- Se despliega automáticamente al hacer push a `docs/` o `mkdocs.yml` (GitHub Actions)
- Build local: `mkdocs serve`

## Git
- Rama principal: `master`
- Tras cada push a `angelbonet`, sincronizar fork: `gh repo sync fmwarriors/rustdesk-manager`
