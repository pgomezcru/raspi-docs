#!/usr/bin/env bash
set -euo pipefail

# ------------------------------------------------------------------------------
# Genera una tabla Markdown con:
#   Metric | Help | Type
# combinando métricas de los 3 exporters directamente desde localhost
# ------------------------------------------------------------------------------

# Endpoints locales (puertos mapeados en docker-compose.yml)
ENDPOINTS=(
  "http://localhost:9100/metrics"  # node-exporter
  "http://localhost:8081/metrics"  # cadvisor
  "http://localhost:9633/metrics"  # smartctl-exporter
)

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

need() { command -v "$1" >/dev/null 2>&1 || { echo "ERROR: falta $1" >&2; exit 1; }; }
need curl
need awk
need sort

echo "Descargando métricas desde endpoints locales..."
echo

# 2) Descargar /metrics de cada endpoint
metrics_concat="$TMP_DIR/metrics_all.txt"
: > "$metrics_concat"

i=0
for url in "${ENDPOINTS[@]}"; do
  i=$((i+1))
  echo "[$i] Descargando: $url"
  if curl -fsS --max-time 10 "$url" >> "$metrics_concat"; then
    echo >> "$metrics_concat"
  else
    echo "WARN: fallo al descargar $url" >&2
    echo >> "$metrics_concat"
  fi
done

echo
echo "Parseando HELP/TYPE y nombres de métricas..."

# 3) Parsear: crear un TSV (metric \t help \t type) incluyendo métricas sin HELP/TYPE
tsv="$TMP_DIR/metrics.tsv"

awk '
# HELP
$1 == "#" && $2 == "HELP" {
  metric = $3
  help_text = ""
  for (i = 4; i <= NF; i++) help_text = help_text (i==4 ? "" : " ") $i
  help[metric] = help_text
  seen[metric] = 1
  next
}

# TYPE
$1 == "#" && $2 == "TYPE" {
  metric = $3
  type[metric] = $4
  seen[metric] = 1
  next
}

# Métricas (líneas que no empiezan por #)
$1 !~ /^#/ && NF > 0 {
  metric = $1
  sub(/\{.*/, "", metric)
  seen[metric] = 1
  next
}

END {
  for (m in seen) {
    printf "%s\t%s\t%s\n", m, (m in help ? help[m] : ""), (m in type ? type[m] : "")
  }
}
' "$metrics_concat" \
| sort -u > "$tsv"

# 4) Convertir TSV a tabla Markdown (escapando | para que no rompa la tabla)
echo
echo "| Metric | Help | Type |"
echo "|--------|------|------|"

awk -F'\t' '
{
  metric = $1
  help = $2
  type = $3

  # Escapar pipes en HELP (y evitar CRLF si lo hubiera)
  gsub(/\r/, "", help)
  gsub(/\|/, "\\|", help)
  gsub(/\r/, "", type)

  printf "| `%s` | %s | %s |\n", metric, help, type
}
' "$tsv"
