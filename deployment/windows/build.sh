#!/bin/bash
#
# Genera "Instalar RustDesk.exe" (asistente gráfico de Windows) desde macOS/Linux usando el NSIS
# que descarga electron-builder (npm run build:win lo deja en la caché).
#
# Uso:  ./build.sh      → dist/Instalar RustDesk.exe
#
set -euo pipefail
cd "$(dirname "$0")"

NSIS_DIR="${NSIS_DIR:-$( (ls -d "$HOME"/Library/Caches/electron-builder/nsis/nsis-3.* "$HOME"/.cache/electron-builder/nsis/nsis-3.* 2>/dev/null || true) | head -1)}"
[ -d "$NSIS_DIR" ] || { echo "No encuentro NSIS. Ejecuta antes 'npm run build:win' para que electron-builder lo descargue."; exit 1; }

case "$(uname -s)" in
  Darwin) MAKENSIS="$NSIS_DIR/mac/makensis" ;;
  *)      MAKENSIS="$NSIS_DIR/linux/makensis" ;;
esac
[ -x "$MAKENSIS" ] || chmod +x "$MAKENSIS"

mkdir -p dist
ICON="../../build/icon.ico"
DEFS=()
[ -f "$ICON" ] && DEFS+=("-DAPP_ICON=$ICON")

NSISDIR="$NSIS_DIR" NSISCONFDIR="$NSIS_DIR" "$MAKENSIS" ${DEFS[@]+"${DEFS[@]}"} installer.nsi
NSISDIR="$NSIS_DIR" NSISCONFDIR="$NSIS_DIR" "$MAKENSIS" ${DEFS[@]+"${DEFS[@]}"} desinstalador.nsi
echo
echo "Listo: $(pwd)/dist/Instalar RustDesk.exe y $(pwd)/dist/Desinstalar RustDesk.exe"
echo "(sin firmar: Windows SmartScreen avisará la primera vez; ver la documentación)"
