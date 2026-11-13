# Instalación en macOS

Hay un **instalador gráfico** (recomendado) que funciona con un archivo de configuración `.rdconfig` por
destinatario, parecido a un archivo de licencia. El instalador es el mismo para todos y no lleva ningún dato
dentro; lo que cambia es el `.rdconfig` que recibe cada persona.

## Requisitos

- macOS 10.14 o superior en Intel; en Apple Silicon, 12.3 o superior (si el Mac es más antiguo, el instalador
  elige solo una versión de RustDesk compatible)
- Contraseña de administrador del Mac
- Conexión a internet (descarga RustDesk desde GitHub)
- El archivo `.rdconfig` que te haya enviado quien da el soporte

## Para quien instala

1. Abre el DMG **Instalar RustDesk** y ejecuta la app **Instalar RustDesk**.
2. Haz **doble clic en tu archivo `.rdconfig`**. Si no lo haces, el instalador lo busca solo junto a la app,
   en el Escritorio y en Descargas; también puedes arrastrarlo a la ventana o elegirlo con el botón
   *Usar otro archivo…*.
3. Pulsa **Instalar**. macOS pedirá la contraseña del Mac **una sola vez**.
4. Activa los tres permisos que el asistente te indica (ver más abajo).
5. Al terminar verás el **ID del equipo**. Si quien da el soporte te lo pide, díselo.

## Qué hace el instalador

1. Comprueba el Mac y descarga la versión de RustDesk compatible con tu macOS, verificando su firma.
2. Con permisos de administrador, y todo en una sola petición de contraseña:
    - copia RustDesk a `/Applications` (sustituye una instalación anterior);
    - coloca la configuración del servidor y la Key (se guarda copia de la anterior);
    - instala y arranca el **servicio del sistema** de RustDesk (arranque con el Mac y acceso en la pantalla
      de inicio de sesión), sin tener que pulsar el botón «Instalar» de la propia RustDesk;
    - fija la **contraseña permanente** del `.rdconfig`.
3. Lee el ID del equipo y, si el archivo lo incluye, envía el aviso por Pushover.
4. Guía por los permisos de macOS.

El registro queda en `~/Library/Logs/RustDeskInstaller.log` (nunca incluye contraseñas).

!!! warning "Un Mac que ya tiene RustDesk"
    La instalación **sobrescribe** `/Applications/RustDesk.app` y la configuración del servidor
    (`RustDesk2.toml`, con copia de seguridad). Si el equipo ya está dado de alta en otro servidor, pasará a
    este.

## Permisos necesarios

macOS no permite activarlos automáticamente, así que el asistente te lleva a cada uno. Sin ellos RustDesk no
puede ver ni controlar la pantalla:

| Permiso | Para qué |
|---------|----------|
| **Accesibilidad** | Controlar ratón y teclado |
| **Grabación de pantalla** | Compartir la pantalla |
| **Monitorización de entrada** | Recibir las teclas pulsadas |

Ruta: **Ajustes del Sistema → Privacidad y seguridad**. Si RustDesk ya estuvo instalado en ese Mac, macOS
puede recordar permisos antiguos y no pedirlos de nuevo.

!!! tip "Automatizar permisos"
    En entornos empresariales, un MDM (Jamf, Mosyle, etc.) puede conceder estos permisos automáticamente.

## Para quien da el soporte: crear el `.rdconfig`

Tres formas, de más fácil a más manual:

1. **Desde RustDesk Manager** (1.1.2 o posterior): *Ajustes → Archivo para el instalador de RustDesk*,
   escribe el nombre y pulsa el botón. Usa el servidor de IDs, la Key y la contraseña por defecto de Ajustes
   (rellénalos antes).
2. **Una línea de terminal:** `./nueva_config.sh "Clínica Raga" rustdesk.midominio.com CLAVE= contraseña`
3. **A mano:** copia `Plantilla.rdconfig` (viene dentro del DMG) y rellena cuatro líneas:

```ini
NOMBRE=Clínica Raga
SERVIDOR=rustdesk.midominio.com
KEY=clave_publica_del_servidor=
CONTRASENA=contraseña_de_acceso
```

Las líneas que empiezan por `#` son comentarios. Opcionalmente, `PUSHOVER_TOKEN` y `PUSHOVER_USER` envían un
aviso con el ID al terminar. El instalador valida el archivo y explica en pantalla cualquier error (servidor
mal escrito, falta la Key…). Desde terminal: `InstaladorRustDesk --check archivo.rdconfig`.

!!! danger "El `.rdconfig` contiene la contraseña"
    Envíalo solo a su destinatario y no lo subas a repositorios (están en `.gitignore`, salvo la plantilla).
    Usa para terceros una contraseña de acceso pensada para ellos y **nunca** las credenciales de
    administrador de tu servidor API.

## Desinstalar por completo

El DMG incluye **Desinstalar RustDesk.command**. Pide confirmación y la contraseña de administrador, y elimina:

- la app y el servicio del sistema, parando los procesos;
- los ajustes (ID y contraseña de ese equipo), los logs y las cachés;
- los restos del propio instalador.

Al reinstalar, el equipo tendrá un **ID nuevo**. Si macOS bloquea el script: clic derecho → Abrir. Algunos
permisos de privacidad de macOS pueden seguir en las listas hasta reiniciar el Mac.

## Solución de problemas

### El Manager dice «Contraseña incorrecta»

Comprueba en el registro del instalador que aparece «Contraseña permanente guardada: sí». Si no, desinstala
y vuelve a instalar. La contraseña debe ser la que lleva el `.rdconfig`.

### El equipo no aparece como conectado

Revisa que el `SERVIDOR` y la `KEY` del `.rdconfig` son los de tu servidor y que el Mac tiene salida a los
puertos 21115–21117 del servidor.

### Veo la pantalla pero no responde el ratón o el teclado

Falta algún permiso. Actívalos en **Ajustes del Sistema → Privacidad y seguridad** (Accesibilidad y
Monitorización de entrada).

### macOS avisa de «desarrollador no verificado»

El instalador está firmado y notarizado, así que no debería. Si ocurre con el desinstalador (es un script):
clic derecho → Abrir.

## Compilar el instalador (desarrolladores)

Código y `build.sh` en `deployment/mac-installer/`. `./build.sh` genera `dist/Instalar RustDesk.dmg`; para
notarizar hay que tener un perfil de `notarytool` (`NOTARY_PROFILE`). Detalles en el `README.md` de esa carpeta.

## Método antiguo: script `.command`

El script `deployment/mac/` sigue disponible pero está **obsoleto**: no instala el servicio del sistema y
requiere editar un `config.txt` a mano. Úsalo solo si no puedes usar el instalador gráfico.

### Método 1: Doble clic

1. Asegúrate de que `config.txt` está configurado
2. Haz doble clic en `Instalar_RustDesk.command`
3. Si macOS muestra un aviso de seguridad:
   - Ve a **Preferencias del Sistema > Seguridad y Privacidad**
   - En la pestaña General, haz clic en **"Abrir igualmente"**
4. Introduce tu contraseña de administrador cuando se solicite
5. Acepta los permisos de Accesibilidad y Grabación de pantalla

## Método 2: Terminal

```bash
cd ~/Downloads/deployment
chmod +x install_rustdesk_mac.sh
./install_rustdesk_mac.sh
```

## Características

- Detecta automáticamente Mac Intel o Apple Silicon
- Descarga la versión correcta de RustDesk
- Configura servidor y contraseña permanente
- Notificación opcional vía Pushover

## Permisos necesarios

Después de instalar, RustDesk necesita permisos para funcionar:

1. Ve a **Preferencias del Sistema > Seguridad y Privacidad > Privacidad**
2. Activa RustDesk en:
   - **Accesibilidad** - Para controlar el equipo
   - **Grabación de pantalla** - Para compartir pantalla

!!! tip "Automatizar permisos"
    En entornos empresariales, puedes usar MDM (Jamf, Mosyle, etc.) para otorgar estos permisos automáticamente.

## Solución de problemas

### "No se puede abrir porque es de un desarrollador no identificado"

Ve a **Preferencias del Sistema > Seguridad y Privacidad > General** y haz clic en "Abrir igualmente".

O desde Terminal:
```bash
xattr -d com.apple.quarantine Instalar_RustDesk.command
```

### RustDesk no puede controlar el ordenador

Verifica que los permisos están activados en:

- **Preferencias del Sistema > Seguridad y Privacidad > Privacidad > Accesibilidad**
- **Preferencias del Sistema > Seguridad y Privacidad > Privacidad > Grabación de pantalla**

### El script no encuentra config.txt

Asegúrate de que `config.txt` está en la misma carpeta que el script.
