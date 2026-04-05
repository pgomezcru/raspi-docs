#!/usr/bin/env bash
# copilot-kanban-wrapper — Lanza GitHub Copilot CLI emitiendo hooks a Kanban
#
# Uso:
#   copilot-kanban-wrapper <change-id> <prompt>
#   copilot-kanban-wrapper <change-id> --explain <código>
#
# El wrapper:
#   1. Notifica a Kanban que la tarea pasa a in_progress
#   2. Construye el contexto desde el change de OpenSpec
#   3. Lanza gh copilot suggest con el prompt enriquecido
#   4. Notifica a Kanban el resultado (to_review o activity con error)
#
# Requisitos:
#   - gh CLI con extensión copilot instalada (gh extension install github/gh-copilot)
#   - kanban CLI con runtime activo

set -euo pipefail

CHANGES_DIR="openspec/changes"
SOURCE="copilot"

# ── Validación ────────────────────────────────────────────────────────────────
CHANGE_ID="${1:?Uso: copilot-kanban-wrapper <change-id> <prompt>}"
shift

if [[ $# -eq 0 ]]; then
  echo "Error: proporciona un prompt o argumentos para gh copilot" >&2
  exit 1
fi

CHANGE_DIR="$CHANGES_DIR/$CHANGE_ID"

# ── Notificar inicio ──────────────────────────────────────────────────────────
kanban hooks notify \
  --event to_in_progress \
  --source "$SOURCE" \
  --activity-text "Iniciando Copilot para change: $CHANGE_ID" \
  || true   # best-effort: no interrumpir si Kanban no está disponible

# ── Construir contexto desde OpenSpec ─────────────────────────────────────────
CONTEXT=""
if [[ -d "$CHANGE_DIR" ]]; then
  if [[ -f "$CHANGE_DIR/proposal.md" ]]; then
    TITLE=$(grep -m1 '^# ' "$CHANGE_DIR/proposal.md" | sed 's/^# //' || echo "$CHANGE_ID")
    CONTEXT="Contexto del change '$CHANGE_ID' ($TITLE):"$'\n'
    CONTEXT+=$(head -30 "$CHANGE_DIR/proposal.md")$'\n\n'
  fi
  if [[ -f "$CHANGE_DIR/tasks.md" ]]; then
    CONTEXT+="Tasks pendientes:"$'\n'
    CONTEXT+=$(grep '^\- \[ \]' "$CHANGE_DIR/tasks.md" | head -10 || echo "(ninguno)")$'\n\n'
  fi
fi

# El primer argumento es el prompt del usuario; el resto son flags para gh copilot
USER_PROMPT="$1"
shift || true

FULL_PROMPT="${CONTEXT}${USER_PROMPT}"

# ── Ejecutar Copilot ──────────────────────────────────────────────────────────
echo "Ejecutando GitHub Copilot para change '$CHANGE_ID'..."
EXIT_CODE=0
gh copilot suggest "$FULL_PROMPT" "$@" || EXIT_CODE=$?

# ── Notificar resultado ───────────────────────────────────────────────────────
if [[ $EXIT_CODE -eq 0 ]]; then
  kanban hooks notify \
    --event to_review \
    --source "$SOURCE" \
    --final-message "Copilot completó el change $CHANGE_ID" \
    || true
else
  kanban hooks notify \
    --event activity \
    --source "$SOURCE" \
    --activity-text "Copilot terminó con código de salida $EXIT_CODE en change $CHANGE_ID" \
    || true
fi

exit $EXIT_CODE
