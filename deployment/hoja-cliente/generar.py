#!/usr/bin/env python3
"""
Genera la hoja de instrucciones para una clínica (HTML + PDF), con la parte de Mac y la de Windows.

Uso:   ./generar.py "Clínica Padrón" [Padron]  [carpeta_salida]
         1.er argumento: nombre que verá el cliente
         2.º  argumento: nombre del archivo .rdconfig sin extensión (por defecto, el nombre sin tildes ni espacios)
         3.er argumento: carpeta de salida (por defecto, la actual)

No lleva contraseñas ni datos del servidor: el .rdconfig se envía aparte. Nada al cliente sin que Ángel la apruebe.
El PDF se genera con Google Chrome (modo headless) si está instalado.
"""
import sys, os, re, html, subprocess, unicodedata

def plano(s):
    s = unicodedata.normalize('NFKD', s).encode('ascii', 'ignore').decode()
    return re.sub(r'[^A-Za-z0-9]+', '', s.replace('Clínica', '').replace('Clinica', '')) or 'Clinica'

nombre = sys.argv[1] if len(sys.argv) > 1 else "tu clínica"
cfg = (sys.argv[2] if len(sys.argv) > 2 else plano(nombre)) + ".rdconfig"
salida = sys.argv[3] if len(sys.argv) > 3 else "."
N = html.escape(nombre); C = html.escape(cfg)

HTML = f"""<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Acceso remoto — {N}</title>
<style>
  :root {{ --ink:#1f2933; --muted:#667085; --accent:#2f5fd0; --warn:#b4540a; --line:#e4e7ec; }}
  * {{ box-sizing: border-box; }}
  body {{ margin:0; background:#fff; color:var(--ink); font:16px/1.55 -apple-system, "Helvetica Neue", "Segoe UI", Arial, sans-serif; }}
  main {{ max-width:760px; margin:0 auto; padding:48px 24px 64px; }}
  h1 {{ font-size:28px; margin:0 0 4px; }}
  .sub {{ color:var(--muted); margin:0 0 36px; }}
  h2 {{ font-size:19px; margin:40px 0 12px; color:var(--accent); }}
  h3 {{ font-size:16px; margin:22px 0 6px; }}
  .so {{ display:inline-block; font-size:12px; font-weight:700; letter-spacing:.04em; text-transform:uppercase;
        color:#fff; background:var(--accent); border-radius:4px; padding:1px 8px; margin-right:6px; }}
  .so.win {{ background:#0b6bb8; }} .so.mac {{ background:#444; }}
  ol, ul {{ padding-left:22px; }} li {{ margin:6px 0; }}
  .box {{ border:1px solid var(--line); border-radius:10px; padding:16px 20px; margin:16px 0; }}
  .warn {{ border-color:var(--warn); }} .warn strong:first-child {{ color:var(--warn); }}
  table {{ border-collapse:collapse; width:100%; margin:12px 0; }}
  th, td {{ text-align:left; padding:8px 10px; border-bottom:1px solid var(--line); vertical-align:top; }}
  th {{ width:38%; color:var(--muted); font-weight:600; }}
  code {{ background:#f2f4f7; padding:1px 6px; border-radius:4px; font-size:.92em; }}
  footer {{ margin-top:48px; color:var(--muted); font-size:14px; border-top:1px solid var(--line); padding-top:16px; }}
  @media print {{
    main {{ padding:0; max-width:none; }} body {{ font-size:11.5pt; }}
    h2, h3 {{ break-after:avoid; }} .box, li, tr {{ break-inside:avoid; }}
  }}
</style>
</head>
<body>
<main>
  <h1>Acceso remoto a los equipos de {N}</h1>
  <p class="sub">Guía de instalación · RustDesk + RustDesk Manager · abDatabase</p>

  <p>Con estas dos aplicaciones podrás conectarte a los ordenadores de tu clínica desde un único panel y ver cuáles están encendidos. Verás <strong>solo los equipos que tú añadas</strong>.</p>

  <h2>Qué recibes</h2>
  <table>
    <tr><th>Instalador de RustDesk</th><td><span class="so mac">Mac</span> <code>Instalar-RustDesk-Mac.dmg</code><br><span class="so win">Windows</span> <code>Instalar-RustDesk-Windows.exe</code><br>Se usa en <strong>cada ordenador</strong> al que quieras poder conectarte.</td></tr>
    <tr><th>{C}</th><td>El archivo con la configuración de tu clínica (servidor, clave y contraseña). Es privado: no lo reenvíes ni lo publiques. Te llega <strong>por separado</strong>.</td></tr>
    <tr><th>RustDesk Manager</th><td><span class="so mac">Mac</span> <code>RustDesk-Manager-1.1.3-universal.dmg</code><br><span class="so win">Windows</span> <code>RustDesk-Manager-Setup-1.1.3.exe</code><br>El panel desde el que te conectas. Se instala <strong>solo en tu ordenador de trabajo</strong>.</td></tr>
  </table>

  <h2>1. En cada ordenador al que quieras conectarte</h2>
  <p>Copia al ordenador el instalador de RustDesk y <code>{C}</code>, déjalos juntos (o en el Escritorio) y sigue los pasos de tu sistema.</p>

  <h3><span class="so win">Windows</span> Ordenadores con Windows 10 u 11</h3>
  <ol>
    <li>Haz <strong>doble clic en <code>Instalar-RustDesk-Windows.exe</code></strong>.</li>
    <li>Si aparece <em>«Windows protegió su PC»</em>, pulsa <strong>Más información</strong> y después <strong>Ejecutar de todos modos</strong>. Es normal: el instalador no está firmado con certificado de Microsoft.</li>
    <li>Acepta el aviso de permisos de administrador (<strong>Sí</strong>).</li>
    <li>En el asistente, pulsa <strong>Siguiente</strong>: reconocerá tu archivo <code>{C}</code> si está junto al instalador, en el Escritorio o en Descargas. Si no, usa <strong>Elegir archivo…</strong>. Después pulsa <strong>Instalar</strong>.</li>
    <li>Espera uno o dos minutos. Al terminar verás el <strong>ID</strong> del ordenador (un número de 9 o 10 dígitos). <strong>Anótalo</strong>: lo necesitas en el paso 3. Pulsa <strong>Cerrar</strong>.</li>
  </ol>

  <h3><span class="so mac">Mac</span> Ordenadores Mac</h3>
  <ol>
    <li>Abre <code>Instalar-RustDesk-Mac.dmg</code> y ejecuta <strong>Instalar RustDesk</strong>. Si macOS pregunta si quieres abrirla, pulsa <strong>Abrir</strong>.</li>
    <li>Haz <strong>doble clic en <code>{C}</code></strong> (o déjalo en el Escritorio) y pulsa <strong>Instalar</strong>. Escribe la contraseña de ese Mac cuando se pida.</li>
    <li>El asistente te indicará tres permisos que hay que activar en <em>Ajustes del Sistema → Privacidad y seguridad</em>: <strong>Accesibilidad</strong>, <strong>Grabación de pantalla</strong> y <strong>Monitorización de entrada</strong>. Actívalos tal como te lo muestra. Sin ellos no se puede controlar el equipo.</li>
    <li>Al terminar verás el <strong>ID</strong> del ordenador. <strong>Anótalo</strong>: lo necesitas en el paso 3.</li>
  </ol>

  <h2>2. En tu ordenador de trabajo: instalar el Manager</h2>
  <ol>
    <li><span class="so mac">Mac</span> Abre el <code>.dmg</code> y arrastra la aplicación a <strong>Aplicaciones</strong>. La primera vez pulsa <strong>Abrir</strong> en el aviso de macOS.<br>
        <span class="so win">Windows</span> Haz doble clic en <code>RustDesk-Manager-Setup-1.1.3.exe</code> (si sale <em>«Windows protegió su PC»</em>: <strong>Más información → Ejecutar de todos modos</strong>) y sigue el asistente.</li>
    <li>Abre el Manager y entra en <strong>Ajustes</strong> (icono del engranaje).</li>
    <li>Pulsa <strong>Importar archivo .rdconfig</strong> y elige <code>{C}</code>.</li>
  </ol>
  <div class="box">
    <strong>Eso es todo.</strong> La importación rellena y guarda sola el servidor, la clave y la contraseña de tu clínica. No tienes que escribir ni buscar nada. Los campos de «Servidor API» (URL, usuario, contraseña) <strong>déjalos vacíos</strong>: no los necesitas.
  </div>

  <h2>3. Añadir tus equipos</h2>
  <ol>
    <li>Pulsa <strong>Nuevo Equipo</strong>.</li>
    <li>Escribe el <strong>ID</strong> que anotaste y un nombre que reconozcas (por ejemplo «Recepción» o «Gabinete 2»).</li>
    <li>Guarda. Repite con cada equipo.</li>
  </ol>
  <p>En unos segundos el equipo aparece en verde si está encendido y conectado. Haz clic en él para abrir la sesión remota.</p>

  <div class="box warn">
    <strong>Importante.</strong> La contraseña de tu clínica es lo que protege el acceso a tus equipos. No la compartas ni la dejes a la vista. Si crees que otra persona la conoce, avísanos y la cambiamos.
  </div>

  <h2>Si algo no funciona</h2>
  <ul>
    <li><strong>Un equipo sale en gris:</strong> está apagado, sin internet, o RustDesk no se está ejecutando en él.</li>
    <li><strong>«Contraseña incorrecta»:</strong> el equipo no tiene la contraseña de tu clínica. Vuelve a instalar RustDesk en él con tu <code>{C}</code>.</li>
    <li><strong>Pantalla negra o el ratón no responde (Mac):</strong> faltan permisos en <em>Privacidad y seguridad</em> del ordenador remoto.</li>
    <li><strong>El instalador de Windows se queda parado o da error:</strong> comprueba que el ordenador tiene internet y envíanos el archivo <code>%TEMP%\\instalar_rustdesk.log</code> (pega esa ruta en la barra del Explorador de archivos).</li>
    <li><strong>El antivirus bloquea el instalador:</strong> avísanos antes de desactivarlo; podemos darte otra forma de instalarlo.</li>
  </ul>

  <footer>abDatabase · Soporte técnico. Documento confidencial para {N}.</footer>
</main>
</body>
</html>
"""

os.makedirs(salida, exist_ok=True)
base = os.path.join(salida, f"Instrucciones - {nombre}")
with open(base + ".html", "w", encoding="utf-8") as f:
    f.write(HTML)
print("HTML:", base + ".html")

chrome = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
if os.path.exists(chrome):
    subprocess.run([chrome, "--headless", "--disable-gpu", "--no-pdf-header-footer",
                    f"--print-to-pdf={base}.pdf", "file://" + os.path.abspath(base + ".html")],
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    print("PDF: ", base + ".pdf")
else:
    print("(sin Google Chrome: abre el HTML e imprime a PDF)")
