# Instalador de RustDesk para macOS (asistente gráfico + archivo de configuración)

Un **único instalador, igual para todos y sin ningún dato dentro** (se firma y notariza una sola vez),
más un **archivo de configuración `.rdconfig`** por destinatario, parecido a un archivo de licencia:
lleva el servidor, la key y la contraseña. Sustituye a `deployment/mac/` (script `.command`).

## Para quien instala (usuario final)
1. Abrir el DMG y arrastrar **Instalar RustDesk** donde quiera (o ejecutarlo desde el DMG).
2. Hacer **doble clic en el archivo `.rdconfig`** que le han enviado
   (o dejarlo en el Escritorio / Descargas, o arrastrarlo a la ventana, o elegirlo con un botón).
3. Pulsar **Instalar**, escribir la contraseña de su Mac cuando macOS la pida y activar los tres
   permisos que el asistente le indica (Accesibilidad, Grabación de pantalla, Monitorización de entrada).

## Para quien da el soporte: crear el `.rdconfig`
- **Desde RustDesk Manager** (lo más fácil): Ajustes → *Archivo para el instalador de RustDesk* →
  escribir el nombre → *Crear archivo .rdconfig*. Usa el servidor de IDs, la Key y la contraseña por
  defecto que ya tienes en Ajustes (rellénalos antes).
- **Una línea de terminal:** `./nueva_config.sh "Clínica Raga" rustdesk.midominio.com CLAVE= contraseña`
- **A mano:** copiar `Plantilla.rdconfig` (viene en el DMG), cambiarle el nombre y rellenar 4 líneas:

```
NOMBRE=Clínica Raga
SERVIDOR=rustdesk.midominio.com
KEY=clave_publica_del_servidor=
CONTRASENA=contraseña_de_acceso
```
(`#` = comentario. `PUSHOVER_TOKEN` / `PUSHOVER_USER` opcionales: aviso con el ID al terminar.)
El archivo contiene la contraseña: envíalo solo a su destinatario. Los `.rdconfig` están en `.gitignore`.

El instalador comprueba el archivo y explica cualquier error en pantalla (servidor mal escrito, falta la
key…). Desde terminal: `InstaladorRustDesk --check archivo.rdconfig`.

## Dónde busca el archivo (por este orden)
Incrustado en la app (opcional) → el que se abre con doble clic / se arrastra → misma carpeta que la app
(p. ej. el DMG) → Escritorio → Descargas (el más reciente que sea válido). Al mirar Escritorio/Descargas
macOS puede mostrar su aviso de acceso a esas carpetas; con doble clic o arrastrando no aparece.

## Qué versión de RustDesk instala
Consulta GitHub (versiones estables con DMG para la arquitectura del Mac, de más reciente a más
antigua), descarga, lee `LSMinimumSystemVersion` del `RustDesk.app` y verifica su firma. Si el macOS del
Mac no llega, prueba la siguiente. Valores medidos (2026-11):

| Arquitectura | Versiones | macOS mínimo |
|---|---|---|
| Intel (x86_64) | todas (1.2.x – 1.5.x) | 10.14 |
| Apple Silicon | 1.3.3 y posteriores (hasta 1.5.3) | 12.3 |
| Apple Silicon | hasta 1.3.2 | 10.14 |

Si GitHub no responde a la API, usa las versiones de reserva 1.4.9 y 1.3.2.

## Compilar el instalador
```bash
./build.sh                    # → dist/Instalar RustDesk.dmg  (app + Plantilla.rdconfig)
./build.sh cliente.rdconfig   # opcional: incrusta ese archivo (no pide nada al usuario)
```
Requisitos: Xcode (el script usa su `swiftc`: en `/Library/Developer/Toolchains` hay Swift antiguos que
`xcrun` puede preferir), `create-dmg` (`brew install create-dmg`) y un certificado
*Developer ID Application* (`SIGN_IDENTITY` para elegir otro). Corre en macOS 10.15+ (Intel) y 11+ (Apple Silicon).

### Notarización
`build.sh` notariza y grapa si encuentra el perfil de `notarytool` (`NOTARY_PROFILE`, por defecto `notary`;
`SKIP_NOTARIZE=1` para saltarla). Sin notarizar, macOS avisa de «desarrollador no verificado» (clic derecho → Abrir).
Crear el perfil una vez: `xcrun notarytool store-credentials "notary" --apple-id <ID> --team-id <TEAM>`
(contraseña específica de app de appleid.apple.com). Si Apple responde **403 «agreement missing or expired»**,
hay que aceptar el acuerdo vigente en developer.apple.com/account.

## Pruebas sin instalar nada
```bash
RDI_DRY_RUN=1 RDI_AUTOSTART=1 "dist/Instalar RustDesk.app/Contents/MacOS/InstaladorRustDesk"
RDI_DRY_RUN=1 RDI_AUTOSTART=1 RDI_FAKE_OS=11.5 ...     # simula otro macOS
RDI_SNAPSHOT=/ruta/capturas ...                         # PNG de cada pantalla
open -n --env RDI_DRY_RUN=1 --env RDI_AUTOSTART=1 -a "/ruta/Instalar RustDesk.app" archivo.rdconfig
```
Registro: `~/Library/Logs/RustDeskInstaller.log` (nunca incluye contraseñas).
La instalación real **sobrescribe** `/Applications/RustDesk.app` y `RustDesk2.toml` (copia de este último).
