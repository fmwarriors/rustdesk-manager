# Instalación en Windows

Hay un **instalador gráfico** (`Instalar RustDesk.exe`) que funciona con un archivo de configuración `.rdconfig`
por destinatario, igual que el de macOS. El instalador es el mismo para todos y no lleva ningún dato dentro; lo
que cambia es el `.rdconfig` que recibe cada persona (servidor, Key y contraseña).

## Requisitos

- Windows 10 o superior (64 bits)
- Permisos de administrador
- Conexión a internet (descarga RustDesk desde GitHub y verifica su firma)
- El archivo `.rdconfig` que te haya enviado quien da el soporte

## Para quien instala

1. Copia `Instalar RustDesk.exe` y tu archivo `.rdconfig` al equipo (déjalos juntos o en el Escritorio / Descargas).
2. Haz **doble clic en `Instalar RustDesk.exe`**.
3. Si Windows muestra *«Windows protegió su PC»*, pulsa **Más información → Ejecutar de todos modos**
   (ver la nota de SmartScreen más abajo). Acepta el aviso de permisos de administrador.
4. En el asistente comprueba que reconoce tu archivo y pulsa **Siguiente → Instalar**. Si no lo encuentra,
   pulsa **Elegir archivo…**.
5. Espera uno o dos minutos. Al terminar verás el **ID del equipo**: anótalo, o díselo a quien da el soporte.

## Qué hace el instalador

1. Descarga la última versión estable de RustDesk y verifica su firma digital.
2. Instala RustDesk (instalación silenciosa) y espera a que el programa y el servicio estén listos.
3. Escribe la configuración del servidor y la Key en **dos sitios**: el perfil del servicio (el que atiende las
   conexiones entrantes) y el del usuario que instala.
4. Arranca el servicio, fija la contraseña permanente (con reintentos: solo funciona con el servicio en marcha) y
   lee el ID.

## Nota sobre SmartScreen

El instalador no está firmado con un certificado de firma de código de Windows, así que SmartScreen avisa la
primera vez. Es normal y se supera con **Más información → Ejecutar de todos modos**. Para evitar el aviso haría
falta un certificado Authenticode (de pago).

## Para quien da el soporte: crear el `.rdconfig`

Es el mismo archivo que en macOS: en RustDesk Manager, *Ajustes → Archivo para el instalador de RustDesk*, o a
mano:

```
NOMBRE=Clínica Raga
SERVIDOR=rustdesk.midominio.com
KEY=clave_publica_del_servidor=
CONTRASENA=contraseña_de_acceso
```

Usa una contraseña distinta para cada clínica y envía el archivo solo a su destinatario. La contraseña no puede
llevar comillas, `$`, `%`, `^`, `&`, `|`, `<` ni `>`.

## Generar el instalador (desarrolladores)

```bash
cd deployment/windows
./build.sh        # → dist/Instalar RustDesk.exe
```

Se compila desde macOS/Linux con el NSIS que descarga electron-builder (si no está en la caché, ejecuta antes
`npm run build:win`). La lógica está en `install_rustdesk_windows.ps1`, que se incrusta en el `.exe` (fuente del
asistente: `installer.nsi`).

## Solución de problemas

- **Registro:** `%TEMP%\instalar_rustdesk.log` (detalle del script) y `%TEMP%\instalar_rustdesk_asistente.log`
  (lo que ejecutó el asistente). Envía el primero a quien da el soporte si algo falla.
- **«No se ha encontrado ningún archivo .rdconfig»:** déjalo junto al instalador, en el Escritorio o en
  Descargas, o usa *Elegir archivo…*.
- **Se queda esperando mucho tiempo:** comprueba que hay internet y que el antivirus no bloquea la descarga
  desde github.com.
- **«Contraseña incorrecta» al conectar:** el equipo tiene la contraseña del `.rdconfig` con que se instaló;
  actualiza la ficha del equipo en el Manager.
- **Antivirus:** algunos antivirus desconfían de instaladores sin firmar. Añade una excepción si hace falta.

## Notas técnicas (por qué se hace así)

- No se usa `Start-Process -Wait`: espera también a todos los procesos que arranca el instalador de RustDesk
  (servicio, servidor, bandeja), que no terminan nunca, y el instalador se queda colgado.
- El instalador de RustDesk puede terminar antes de que la instalación acabe: hay que esperar a que aparezcan
  `rustdesk.exe` y el servicio.
- El asistente es un programa de 32 bits: lanza el PowerShell de 64 bits (`Sysnative`) y el script usa
  `ProgramW6432`, porque si no `Program Files` apunta a `Program Files (x86)`.
- El `.ps1` se guarda con BOM UTF-8 para que Windows PowerShell 5.1 lea bien las tildes.
