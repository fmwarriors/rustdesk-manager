#!/bin/bash
#
# Genera el instalador de RustDesk para macOS: un DMG genérico (app asistente + Plantilla.rdconfig)
# que NO lleva datos de ningún servidor; se configura con un archivo .rdconfig.
#
# Uso:   ./build.sh                    → dist/Instalar RustDesk.dmg   (el normal, el mismo para todos)
#        ./build.sh cliente.rdconfig   → dist/Instalar RustDesk - <nombre>.dmg con el archivo incrustado
#
# Variables opcionales:
#   SIGN_IDENTITY   hash o nombre del certificado "Developer ID Application"
#   NOTARY_PROFILE  perfil de notarytool en el llavero (por defecto: notary)
#   SKIP_NOTARIZE=1 firmar sin notarizar
#
set -euo pipefail
cd "$(dirname "$0")"

# Opcional: un .rdconfig para incrustarlo (instalador "de un solo destinatario", sin pedir archivo).
EMBED="${1:-}"
if [ -n "$EMBED" ]; then
    [ -f "$EMBED" ] || { echo "No existe $EMBED"; exit 1; }
fi

SIGN_IDENTITY="${SIGN_IDENTITY:-7FDEB7677B3CEA58578C79C08AD693D0084B2991}"   # Innovaorto AIE (54HHDMD6T8)
NOTARY_PROFILE="${NOTARY_PROFILE:-notary}"
XCODE_BIN="/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin"
SWIFTC="$XCODE_BIN/swiftc"
[ -x "$SWIFTC" ] || SWIFTC="$(xcrun --find swiftc)"   # /Library/Developer/Toolchains puede traer Swift antiguos
SDK="$(DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun --show-sdk-path)"

APP_NAME="Instalar RustDesk"
OUT="dist"
APP="$OUT/$APP_NAME.app"
DMG="$OUT/Instalar RustDesk.dmg"
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
[ -n "$EMBED" ] && cp "$EMBED" "$APP/Contents/Resources/embedded.rdconfig"
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
  <key>CFBundleDocumentTypes</key><array><dict>
    <key>CFBundleTypeName</key><string>Configuración de RustDesk</string>
    <key>CFBundleTypeExtensions</key><array><string>rdconfig</string></array>
    <key>CFBundleTypeRole</key><string>Viewer</string>
    <key>LSHandlerRank</key><string>Owner</string>
  </dict></array>
</dict></plist>
PLIST

echo "==> Firmando la app"
codesign --force --options runtime --timestamp --sign "$SIGN_IDENTITY" "$APP"
codesign --verify --strict --verbose=1 "$APP"

echo "==> Creando DMG"
STAGE="$BUILD/dmg"; mkdir -p "$STAGE"; cp -R "$APP" "$STAGE/"; cp Plantilla.rdconfig "$STAGE/"
create-dmg --volname "Instalar RustDesk" \
  --window-pos 200 160 --window-size 560 340 --icon-size 110 \
  --icon "$APP_NAME.app" 150 150 --hide-extension "$APP_NAME.app" \
  --icon "Plantilla.rdconfig" 410 150 \
  "$DMG" "$STAGE" >/dev/null
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
echo "Notarizado: $NOTARIZED"
