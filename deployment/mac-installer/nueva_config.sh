#!/bin/bash
#
# Crea un archivo .rdconfig en una sola línea.
# Uso:  ./nueva_config.sh "Clínica Raga" rustdesk.midominio.com CLAVE_PUBLICA= contraseña
#       → "Clínica Raga.rdconfig" en la carpeta actual
#
set -euo pipefail
[ $# -eq 4 ] || { echo 'Uso: ./nueva_config.sh "Nombre" servidor.com KEY contraseña'; exit 1; }
NAME="$1"; SERVER="$2"; KEY="$3"; PASS="$4"
FILE="$(echo "$NAME" | tr -d '/:')".rdconfig
printf '# Configuración de RustDesk — %s\nNOMBRE=%s\nSERVIDOR=%s\nKEY=%s\nCONTRASENA=%s\n' "$NAME" "$NAME" "$SERVER" "$KEY" "$PASS" > "$FILE"
chmod 600 "$FILE"
echo "Creado: $FILE"
