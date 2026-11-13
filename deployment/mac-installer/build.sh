#!/bin/bash
#
# Genera el instalador de RustDesk para macOS (DMG con app asistente) para un destinatario.
#
# Uso:   ./build.sh clientes/mi-cliente.json
# Salida: dist/Instalar RustDesk - <nombre>.dmg
#
# Variables opcionales:
#   SIGN_IDENTITY   hash o nombre del certificado "Developer ID Application"
#   NOTARY_PROFILE  perfil de notarytool en el llavero (por defecto: notary)
#   SKIP_NOTARIZE=1 firmar sin notarizar
#
set -euo pipefail
cd "$(dirname "$0")"

CONFIG="${1:-}"
[ -n "$CONFIG" ] && [ -f "$CONFIG" ] || { echo "Uso: $0 clientes/<cliente>.json  (ver clientes/ejemplo.json.example)"; exit 1; }

SIGN_IDENTITY="${SIGN_IDENTITY:-7FDEB7677B3CEA58578C79C08AD693D0084B2991}"   # Innovaorto AIE (54HHDMD6T8)
NOTARY_PROFILE="${NOTARY_PROFILE:-notary}"
XCODE_BIN="/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin"
SWIFTC="$XCODE_BIN/swiftc"
[ -x "$SWIFTC" ] || SWIFTC="$(xcrun --find swiftc)"   # /Library/Developer/Toolchains puede traer Swift antiguos
SDK="$(DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun --show-sdk-path)"

# --- Validar configuración (evita romper el TOML o el shell del instalador) ---
field() { /usr/bin/python3 -c 'import json,sys; print(json.load(open(sys.argv[1])).get(sys.argv[2],""))' "$CONFIG" "$1"; }
NAME="$(field name)"; SERVER="$(field server)"; KEY="$(field key)"; PASSWORD="$(field password)"
[ -n "$NAME" ] || { echo "Falta 'name' en $CONFIG"; exit 1; }
[[ "$SERVER" =~ ^[A-Za-z0-9.-]+$ ]] || { echo "'server' debe ser solo un host (sin http://, puerto ni espacios): '$SERVER'"; exit 1; }
[[ "$KEY" =~ ^[A-Za-z0-9+/=_-]+$ ]] || { echo "'key' contiene caracteres no válidos"; exit 1; }
[ -n "$PASSWORD" ] || { echo "Falta 'password' en $CONFIG"; exit 1; }
SAFE_NAME="$(echo "$NAME" | tr -cd 'A-Za-z0-9 ._&-')"
[ -n "$SAFE_NAME" ] || SAFE_NAME="cliente"

APP_NAME="Instalar RustDesk"
OUT="dist"
APP="$OUT/$APP_NAME.app"
DMG="$OUT/Instalar RustDesk - $SAFE_NAME.dmg"
BUILD="$(mktemp -d)"
trap 'rm -rf "$BUILD"' EXIT
rm -rf "$APP" "$DMG"; mkdir -p "$OUT"

echo "==> Compilando (arm64 + x86_64) con $("$SWIFTC" --version | head -1)"
"$SWIFTC" -O -sdk "$SDK" -target arm64-apple-macos11.0  Sources/main.swift -o "$BUILD/arm64"
"$SWIFTC" -O -sdk "$SDK" -target x86_64-apple-macos10.15 Sources/main.swift -o "$BUILD/x86_64"

echo "==> Montando $APP_NAME.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
lipo -create "$BUILD/arm64" "$BUILD/x86_64" -output "$APP/Contents/MacOS/InstaladorRustDesk"
cp ../../build/icon.icns "$APP/Contents/Resources/icon.icns"
cp "$CONFIG" "$APP/Contents/Resources/installer-config.json"
cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleName</key><string>$APP_NAME</string>
  <key>CFBundleDisplayName</key><string>$APP_NAME</string>
  <key>CFBundleIdentifier</key><string>com.abdatabase.rustdesk-installer</string>
  <key>CFBundleExecutable</key><string>InstaladorRustDesk</string>
  <key>CFBundleIconFile</key><string>icon</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>1.0.0</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>LSMinimumSystemVersion</key><string>10.15</string>
  <key>NSHighResolutionCapable</key><true/>
  <key>NSPrincipalClass</key><string>NSApplication</string>
</dict></plist>
PLIST

echo "==> Firmando la app"
codesign --force --options runtime --timestamp --sign "$SIGN_IDENTITY" "$APP"
codesign --verify --strict --verbose=1 "$APP"

echo "==> Creando DMG"
create-dmg --volname "Instalar RustDesk" \
  --window-pos 200 160 --window-size 520 340 --icon-size 110 \
  --icon "$APP_NAME.app" 260 150 --hide-extension "$APP_NAME.app" \
  "$DMG" "$APP" >/dev/null
codesign --force --timestamp --sign "$SIGN_IDENTITY" "$DMG"

if [ "${SKIP_NOTARIZE:-0}" != "1" ] && xcrun notarytool history --keychain-profile "$NOTARY_PROFILE" >/dev/null 2>&1; then
    echo "==> Notarizando con Apple (puede tardar unos minutos)"
    xcrun notarytool submit "$DMG" --keychain-profile "$NOTARY_PROFILE" --wait
    xcrun stapler staple "$DMG"
    NOTARIZED="sí"
else
    NOTARIZED="NO (falta el perfil '$NOTARY_PROFILE': xcrun notarytool store-credentials \"$NOTARY_PROFILE\")"
fi

echo
echo "Listo: $DMG"
echo "Destinatario: $NAME · servidor: $SERVER · notarizado: $NOTARIZED"
