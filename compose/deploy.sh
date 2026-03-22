#!/usr/bin/env bash
# deploy.sh — Copia el docker-compose.yml de un servicio a su ruta en la Pi.
# NO arranca ni reinicia contenedores. Solo actualiza el fichero.
#
# Uso:
#   ./compose/deploy.sh <servicio>
#   ./compose/deploy.sh nginx
#   ./compose/deploy.sh prometheus
#
# Ejecutar desde la raíz del repo clonado en la Pi, como usuario admin.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Mapa: nombre de servicio → ruta destino en la Pi
declare -A TARGET
TARGET["nginx"]="/mnt/usb-data/nginx/docker-compose.yml"
TARGET["prometheus"]="/mnt/usb-data/prometheus/docker-compose.yml"
TARGET["grafana"]="/mnt/usb-data/grafana/docker-compose.yml"
TARGET["adguard-home"]="/mnt/usb-data/adguard-home/docker-compose.yml"
TARGET["gitea"]="/mnt/usb-data/gitea/docker-compose.yml"
TARGET["homarr"]="/mnt/usb-data/homarr/docker-compose.yml"

usage() {
    echo "Uso: $0 <servicio>"
    echo ""
    echo "Servicios disponibles:"
    for svc in "${!TARGET[@]}"; do
        echo "  - $svc  →  ${TARGET[$svc]}"
    done | sort
    exit 1
}

if [[ $# -ne 1 ]]; then
    usage
fi

SERVICE="$1"

if [[ -z "${TARGET[$SERVICE]+x}" ]]; then
    echo "Error: servicio '$SERVICE' no encontrado."
    echo ""
    usage
fi

SOURCE="${REPO_ROOT}/compose/${SERVICE}/docker-compose.yml"
DEST="${TARGET[$SERVICE]}"

# Verificar que el fichero fuente existe
if [[ ! -f "$SOURCE" ]]; then
    echo "Error: no se encuentra el fichero fuente: $SOURCE"
    exit 1
fi

# Verificar que el directorio destino existe
DEST_DIR="$(dirname "$DEST")"
if [[ ! -d "$DEST_DIR" ]]; then
    echo "Error: el directorio destino no existe: $DEST_DIR"
    exit 1
fi

# Backup del fichero actual antes de sobreescribir
if [[ -f "$DEST" ]]; then
    BACKUP="${DEST}.bak.$(date +%Y%m%d_%H%M%S)"
    cp "$DEST" "$BACKUP"
    echo "Backup creado: $BACKUP"
fi

# Copiar
cp "$SOURCE" "$DEST"
echo "OK: compose/${SERVICE}/docker-compose.yml → $DEST"
echo ""
echo "Para aplicar los cambios:"
echo "  cd $DEST_DIR && docker compose up -d"
