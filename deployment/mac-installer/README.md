# Instalador de RustDesk para macOS (asistente gráfico)

App firmada dentro de un DMG que instala y configura RustDesk con el servidor del destinatario.
Sustituye a `deployment/mac/` (script `.command`, que se mantiene como alternativa).

## Qué ve el usuario
1. **Bienvenida** — explica en tres puntos qué va a pasar.
2. **Instalación** — comprueba el Mac, descarga la versión de RustDesk compatible, pide la contraseña
   de administrador con el diálogo nativo de macOS, instala y configura el servidor.
3. **Permisos** — guía para activar Accesibilidad, Grabación de pantalla y Monitorización de entrada
   (macOS no permite concederlos por script) con botones que abren cada panel de Ajustes del Sistema.
4. **Listo** — muestra el ID del equipo y permite copiarlo.

## Generar un instalador para un destinatario
```bash
cp clientes/ejemplo.json.example clientes/mi-cliente.json   # rellenar name, server, key, password
./build.sh clientes/mi-cliente.json
# → dist/Instalar RustDesk - <nombre>.dmg
```
Cada DMG lleva **sus datos incrustados** (servidor, key y contraseña permanente de acceso): no es un
instalador genérico, no lo publiques. `clientes/*.json` y `dist/` están en `.gitignore`.

Campos: `name` (se muestra en pantalla), `server` (solo host, sin `http://` ni puerto), `key`, `password`,
y opcionales `pushover_token` / `pushover_user` (aviso con ID y equipo al terminar).

## Qué versión de RustDesk instala
Consulta GitHub (versiones estables con DMG para la arquitectura del Mac, de la más reciente a la más
antigua), descarga, lee `LSMinimumSystemVersion` del `RustDesk.app` y verifica su firma. Si el macOS del
Mac no llega, prueba la siguiente. Valores medidos (2026-11):

| Arquitectura | Versiones | macOS mínimo |
|---|---|---|
| Intel (x86_64) | todas (1.2.x – 1.5.x) | 10.14 |
| Apple Silicon | 1.3.3 y posteriores (hasta 1.5.3) | 12.3 |
| Apple Silicon | hasta 1.3.2 | 10.14 |

Si GitHub no responde a la API, usa las versiones de reserva 1.4.9 y 1.3.2.

## Notarización (para que macOS no avise de «desarrollador no verificado»)
Una sola vez, con un Apple ID y una contraseña específica de app (appleid.apple.com → Seguridad):
```bash
xcrun notarytool store-credentials "notary" --apple-id TU_APPLE_ID --team-id 54HHDMD6T8
```
`build.sh` detecta el perfil y notariza + grapa el DMG automáticamente. Sin perfil, genera el DMG solo
firmado (se abre con clic derecho → Abrir). `SKIP_NOTARIZE=1` fuerza saltarlo.

## Requisitos de compilación
Xcode (el script usa el `swiftc` de Xcode: en `/Library/Developer/Toolchains` hay Swift antiguos que
`xcrun` puede preferir), `create-dmg` (`brew install create-dmg`) y un certificado
*Developer ID Application* en el llavero (`SIGN_IDENTITY` para elegir otro).
El instalador corre en macOS 10.15+ (Intel) y 11+ (Apple Silicon).

## Pruebas sin instalar nada
```bash
RDI_DRY_RUN=1 RDI_AUTOSTART=1 "dist/Instalar RustDesk.app/Contents/MacOS/InstaladorRustDesk"
RDI_DRY_RUN=1 RDI_AUTOSTART=1 RDI_FAKE_OS=11.5 ...     # simula otro macOS
RDI_SNAPSHOT=/ruta/capturas ...                         # genera PNG de cada pantalla
```
El registro está en `~/Library/Logs/RustDeskInstaller.log` (nunca incluye contraseñas).
La instalación real **sobrescribe** `/Applications/RustDesk.app` y `RustDesk2.toml` (hace copia de este último).
