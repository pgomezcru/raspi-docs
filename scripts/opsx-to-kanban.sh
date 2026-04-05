#!/usr/bin/env bash
# opsx-to-kanban — Crea una tarjeta Kanban a partir de un change de OpenSpec
#
# Uso:
#   opsx-to-kanban <change-id>
#   opsx-to-kanban <change-id> --project-path /ruta/al/proyecto
#   opsx-to-kanban --list        # muestra el mapping guardado
#
# Requisitos:
#   - kanban CLI instalado y runtime activo (cline / kanban)
#   - openspec inicializado en el proyecto (openspec/changes/<id>/)

set -euo pipefail

CHANGES_DIR="openspec/changes"
MAPPING_FILE="openspec/.kanban-mapping"

# ── Subcomando: --list ────────────────────────────────────────────────────────
if [[ "${1:-}" == "--list" ]]; then
  if [[ ! -f "$MAPPING_FILE" ]]; then
    echo "No hay mapping guardado todavía."
    exit 0
  fi
  echo "Change ID → Kanban Task ID"
  echo "──────────────────────────"
  cat "$MAPPING_FILE"
  exit 0
fi

# ── Validación ────────────────────────────────────────────────────────────────
CHANGE_ID="${1:?Uso: opsx-to-kanban <change-id>}"
shift

PROJECT_PATH=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --project-path) PROJECT_PATH="$2"; shift 2 ;;
    *) echo "Opción desconocida: $1" >&2; exit 1 ;;
  esac
done

CHANGE_DIR="$CHANGES_DIR/$CHANGE_ID"

if [[ ! -d "$CHANGE_DIR" ]]; then
  echo "Error: change '$CHANGE_ID' no encontrado en $CHANGES_DIR" >&2
  echo "Changes disponibles:"
  ls "$CHANGES_DIR" 2>/dev/null || echo "  (ninguno)"
  exit 1
fi

# Comprobar que no existe ya un mapping para este change
if [[ -f "$MAPPING_FILE" ]] && grep -q "^$CHANGE_ID=" "$MAPPING_FILE" 2>/dev/null; then
  EXISTING_ID=$(grep "^$CHANGE_ID=" "$MAPPING_FILE" | cut -d= -f2)
  echo "Aviso: '$CHANGE_ID' ya tiene una tarjeta asociada: $EXISTING_ID"
  echo "¿Crear otra igualmente? [s/N]"
  read -r CONFIRM
  [[ "$CONFIRM" =~ ^[sS]$ ]] || exit 0
fi

# ── Construir prompt ──────────────────────────────────────────────────────────
PROPOSAL_FILE="$CHANGE_DIR/proposal.md"
DESIGN_FILE="$CHANGE_DIR/design.md"
TASKS_FILE="$CHANGE_DIR/tasks.md"

if [[ ! -f "$PROPOSAL_FILE" ]]; then
  echo "Error: $PROPOSAL_FILE no encontrado. ¿Has ejecutado /opsx:propose?" >&2
  exit 1
fi

# Título: primera línea H1 de proposal.md
TITLE=$(grep -m1 '^# ' "$PROPOSAL_FILE" | sed 's/^# //' || echo "$CHANGE_ID")

# Resumen: primeros 60 líneas del proposal (sin el título)
PROPOSAL_BODY=$(tail -n +2 "$PROPOSAL_FILE" | head -60)

# Construir prompt completo
PROMPT="[$CHANGE_ID] $TITLE

## Propuesta
$PROPOSAL_BODY"

if [[ -f "$DESIGN_FILE" ]]; then
  DESIGN_SUMMARY=$(head -40 "$DESIGN_FILE")
  PROMPT="$PROMPT

## Diseño (resumen)
$DESIGN_SUMMARY"
fi

if [[ -f "$TASKS_FILE" ]]; then
  TASKS_PENDING=$(grep -c '^\- \[ \]' "$TASKS_FILE" 2>/dev/null || echo "0")
  PROMPT="$PROMPT

## Estado de tasks
$TASKS_PENDING tasks pendientes en $TASKS_FILE"
fi

PROMPT="$PROMPT

---
Change OpenSpec: $CHANGE_DIR
Comando de implementación: /opsx:apply"

# ── Crear tarjeta en Kanban ───────────────────────────────────────────────────
KANBAN_ARGS=(task create --prompt "$PROMPT")
if [[ -n "$PROJECT_PATH" ]]; then
  KANBAN_ARGS+=(--project-path "$PROJECT_PATH")
fi

echo "Creando tarjeta Kanban para change '$CHANGE_ID'..."
TASK_OUTPUT=$(kanban "${KANBAN_ARGS[@]}" 2>&1)
echo "$TASK_OUTPUT"

# ── Guardar mapping ───────────────────────────────────────────────────────────
# Intentar extraer task-id de la salida (ajustar patrón si cambia el formato)
TASK_ID=$(echo "$TASK_OUTPUT" | grep -oP '(?i)task.?id[:\s]+\K[\w-]+' | head -1 || true)

mkdir -p "$(dirname "$MAPPING_FILE")"
touch "$MAPPING_FILE"

if [[ -n "$TASK_ID" ]]; then
  # Reemplazar entrada existente o añadir nueva
  if grep -q "^$CHANGE_ID=" "$MAPPING_FILE" 2>/dev/null; then
    sed -i "s/^$CHANGE_ID=.*/$CHANGE_ID=$TASK_ID/" "$MAPPING_FILE"
  else
    echo "$CHANGE_ID=$TASK_ID" >> "$MAPPING_FILE"
  fi
  echo ""
  echo "✓ Mapping guardado: $CHANGE_ID → $TASK_ID"
else
  echo ""
  echo "Aviso: no se pudo extraer el task-id de la salida de kanban."
  echo "Añade el mapping manualmente en $MAPPING_FILE:"
  echo "  $CHANGE_ID=<task-id>"
fi
