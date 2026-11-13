#!/bin/bash
# Desinstalador completo de RustDesk para macOS.
# Quita la app, el servicio y el agente del sistema, ajustes (ID, contraseña, config de servidor),
# logs, cachés y permisos de privacidad. Doble clic (si macOS lo bloquea: clic derecho > Abrir).
# Uso: ./Desinstalar RustDesk.command [--yes]   (--yes: sin preguntar)

H="$HOME"
echo "=== Desinstalar RustDesk por completo ==="
echo "Se borrará la app, su servicio, los ajustes (ID y contraseña de este equipo) y los logs."
echo "El ID de este equipo se perderá: al reinstalar tendrá uno nuevo."
if [ "$1" != "--yes" ]; then
  read -r -p "¿Continuar? (s/N) " R; [[ "$R" =~ ^[sS]$ ]] || { echo "Cancelado."; exit 0; }
fi

echo "Se pedirá la contraseña de administrador (no se ve al escribirla)."
sudo -v || { echo "Sin permisos de administrador, no se puede continuar."; exit 1; }

echo "- Parando servicios y procesos…"
sudo launchctl bootout system /Library/LaunchDaemons/com.carriez.RustDesk_service.plist 2>/dev/null
launchctl bootout "gui/$(id -u)" /Library/LaunchAgents/com.carriez.RustDesk_server.plist 2>/dev/null
launchctl bootout "gui/$(id -u)" "$H/Library/LaunchAgents/com.carriez.RustDesk_server.plist" 2>/dev/null
sudo pkill -f "RustDesk.app/Contents/MacOS" 2>/dev/null; sleep 1
sudo pkill -9 -f "RustDesk.app/Contents/MacOS" 2>/dev/null

echo "- Borrando app y servicios del sistema…"
sudo rm -rf /Applications/RustDesk.app
sudo rm -f /Library/LaunchDaemons/com.carriez.RustDesk_service.plist \
           /Library/LaunchAgents/com.carriez.RustDesk_server.plist \
           "$H/Library/LaunchAgents/com.carriez.RustDesk_server.plist"
sudo rm -rf /var/root/Library/Preferences/com.carriez.RustDesk \
            /var/root/Library/Logs/RustDesk /Library/Logs/RustDesk

echo "- Borrando ajustes, logs y cachés del usuario…"
rm -rf "$H/Library/Preferences/com.carriez.RustDesk" \
       "$H/Library/Preferences/com.carriez.RustDesk.plist" \
       "$H/Library/Logs/RustDesk" \
       "$H/Library/Application Support/RustDesk" \
       "$H/Library/Application Support/com.carriez.RustDesk" \
       "$H/Library/Caches/com.carriez.RustDesk" \
       "$H/Library/Saved Application State/com.carriez.RustDesk.savedState" \
       "$H/Library/HTTPStorages/com.carriez.RustDesk" \
       "$H/Library/WebKit/com.carriez.RustDesk"
defaults delete com.carriez.RustDesk 2>/dev/null
killall cfprefsd 2>/dev/null

echo "- Quitando permisos de privacidad (Accesibilidad, Grabación de pantalla, Monitorización de entrada)…"
tccutil reset All com.carriez.rustdesk >/dev/null 2>&1
sudo tccutil reset All com.carriez.rustdesk >/dev/null 2>&1

echo "- Olvidando paquetes registrados…"
for p in $(pkgutil --pkgs 2>/dev/null | grep -i -E 'carriez|rustdesk'); do sudo pkgutil --forget "$p" >/dev/null 2>&1; done

LEFT=$(find /Applications "$H/Library" /Library -maxdepth 3 \( -iname '*rustdesk*' -o -iname '*carriez*' \) 2>/dev/null)
if [ -z "$LEFT" ]; then echo "Listo: RustDesk se ha eliminado por completo."
else echo "Quedan estos restos:"; echo "$LEFT"; fi
echo "Nota: si estaba en Ajustes > Privacidad, reinicia el Mac para que desaparezca de las listas."
