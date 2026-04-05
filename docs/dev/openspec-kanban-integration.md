# Integración OpenSpec + Kanban

> Fecha: 2026-03-31
> Estado: Diseño — pendiente de implementación

## Objetivo

Usar Kanban como frontend de orquestación para OpenSpec: se propone changes con OpenSpec y los ejecuta en paralelo con agentes (Claude Code o GitHub Copilot CLI) desde el tablero Kanban.

---

## Modelo de datos

**Unidad de trabajo: el change de OpenSpec.**

```
1 OpenSpec change  →  1 tarjeta Kanban
```

Cada change tiene sus propios artefactos de planificación y su lista interna de tasks. El agente gestiona esos tasks internamente durante su sesión; Kanban sólo necesita saber del change como unidad.

| OpenSpec | Kanban | Notas |
|---|---|---|
| `openspec/changes/<id>/` | 1 card | Unidad de trabajo |
| `proposal.md` + `design.md` | Prompt de la card | Contexto del agente |
| `tasks.md` | Progreso interno | Gestionado por el agente, no por Kanban |
| Change recién propuesto | `backlog` | Listo para ejecutar |
| Change en ejecución | `in_progress` | Agente trabajando en worktree |
| Change terminado | `review` | Usuario revisa el diff |
| Change archivado | `trash` | `/opsx:archive` ejecutado |

### Por qué no task = card

OpenSpec divide habitualmente un change en 10-20 tasks granulares. Mapear cada task a una card:
- Generaría tableros inmanejables
- Fragmentaría el contexto del agente (cada task depende de los anteriores)
- Rompería el modelo de worktree: un agente necesita el change completo en su rama

El agente ejecuta `/opsx:apply` sobre el change completo y marca los tasks en `tasks.md` a medida que avanza. Eso es suficiente granularidad interna.

---

## Arquitectura

```
┌──────────────────────────────────────────────────────┐
│  USUARIO                                              │
│  /opsx:propose "descripción del cambio"               │
│  → genera openspec/changes/<id>/{proposal,design,     │
│    tasks}.md                                          │
└─────────────────────────┬────────────────────────────┘
                          │
┌─────────────────────────▼────────────────────────────┐
│  CAPA 1: SYNC  (script opsx-to-kanban)                │
│                                                       │
│  Lee openspec/changes/<id>/proposal.md                │
│  Construye prompt = título + resumen del change       │
│  Ejecuta: kanban task create --prompt "..."           │
│  Almacena mapping: change-id ↔ kanban-task-id         │
│  Opcionalmente vincula dependencias entre changes     │
└─────────────────────────┬────────────────────────────┘
                          │
┌─────────────────────────▼────────────────────────────┐
│  CAPA 2: AGENTES                                      │
│                                                       │
│  Kanban lanza agente en worktree aislado              │
│  Agente recibe prompt con contexto del change         │
│  Agente ejecuta /opsx:apply en su worktree            │
│  Hooks reportan progreso → kanban hooks notify        │
│                                                       │
│  Claude Code:  hooks en .claude/settings.json         │
│  Copilot CLI:  wrapper shell con hooks manuales       │
└─────────────────────────┬────────────────────────────┘
                          │
┌─────────────────────────▼────────────────────────────┐
│  CAPA 3: CICLO DE VIDA                                │
│                                                       │
│  Card → review:  usuario revisa diff en Kanban        │
│  Aprobado:       commit / PR desde Kanban             │
│  Card → trash:   script ejecuta /opsx:archive <id>   │
└──────────────────────────────────────────────────────┘
```

---

## Flujo completo del usuario

```
1. PLANIFICACIÓN (OpenSpec)
   /opsx:propose "añadir autenticación JWT"
   → crea openspec/changes/feat-jwt/
       ├── proposal.md    (qué y por qué)
       ├── design.md      (cómo)
       └── tasks.md       (checklist interna para el agente)

2. SINCRONIZACIÓN (script)
   opsx-to-kanban feat-jwt
   → lee proposal.md, extrae título y contexto
   → kanban task create --prompt "[feat-jwt] Añadir auth JWT\n\n<resumen>"
   → guarda: feat-jwt → kanban-task-id-xxxx

3. EJECUCIÓN (Kanban + agente)
   Usuario pulsa ▶ en la card
   → Kanban lanza agente en worktree aislado (rama feat-jwt)
   → Agente ejecuta /opsx:apply en ese worktree
   → Agente marca tasks en tasks.md conforme avanza
   → Hooks reportan actividad al runtime de Kanban

4. REVISIÓN (Kanban)
   Card pasa a "review"
   → Usuario revisa el diff inline en Kanban
   → Deja comentarios si es necesario (agente retoma)
   → Aprueba → commit o PR

5. CIERRE (OpenSpec)
   Card pasa a "trash"
   → Script ejecuta: /opsx:archive feat-jwt
   → Delta specs se fusionan en openspec/specs/
   → Change se mueve a openspec/changes/archive/
```

---

## Configuración por agente

### Claude Code

**Hooks en `.claude/settings.json`:**

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "kanban hooks notify --event activity --activity-text \"$CLAUDE_TOOL_NAME completado\""
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "kanban hooks notify --event to_review"
          }
        ]
      }
    ]
  }
}
```

**Commands OpenSpec** (instalados por `openspec init --tools claude-code`):
- `.claude/commands/opsx/apply.md` — el agente usa este comando durante la sesión

---

### GitHub Copilot CLI

Copilot CLI no tiene hooks nativos equivalentes a los de Claude Code, por lo que requiere un wrapper shell:

**`scripts/copilot-kanban-wrapper.sh`:**

```bash
#!/usr/bin/env bash
# Wrapper que lanza Copilot CLI y emite hooks Kanban

CHANGE_ID="$1"
shift

# Notificar inicio
kanban hooks notify --event to_in_progress --source copilot

# Ejecutar Copilot con los argumentos pasados
gh copilot suggest "$@"
EXIT_CODE=$?

# Notificar fin (éxito o error)
if [ $EXIT_CODE -eq 0 ]; then
  kanban hooks notify --event to_review --source copilot
else
  kanban hooks notify --event activity --source copilot \
    --activity-text "Copilot terminó con código $EXIT_CODE"
fi

exit $EXIT_CODE
```

**Commands OpenSpec para Copilot** (instalados por `openspec init --tools github-copilot`):
- `.github/copilot-instructions.md` — instrucciones de contexto
- `.github/prompts/opsx-apply.prompt.md` — prompt de apply ya presente en el repo

---

## Script `opsx-to-kanban`

Archivo: `scripts/opsx-to-kanban.sh`

```bash
#!/usr/bin/env bash
# Crea una tarjeta Kanban a partir de un change de OpenSpec
# Uso: opsx-to-kanban <change-id> [--project-path <path>]

set -euo pipefail

CHANGE_ID="${1:?Proporciona el change-id}"
CHANGES_DIR="openspec/changes"
CHANGE_DIR="$CHANGES_DIR/$CHANGE_ID"
MAPPING_FILE="openspec/.kanban-mapping"

if [ ! -d "$CHANGE_DIR" ]; then
  echo "Error: change '$CHANGE_ID' no encontrado en $CHANGES_DIR" >&2
  exit 1
fi

# Extraer título de proposal.md (primera línea H1)
TITLE=$(grep -m1 '^# ' "$CHANGE_DIR/proposal.md" | sed 's/^# //')

# Construir prompt con contexto completo
PROMPT="[$CHANGE_ID] $TITLE

$(head -50 "$CHANGE_DIR/proposal.md")

---
Change OpenSpec: $CHANGE_DIR
Ejecutar: /opsx:apply"

# Crear tarjeta en Kanban
TASK_OUTPUT=$(kanban task create --prompt "$PROMPT" 2>&1)
echo "$TASK_OUTPUT"

# Guardar mapping change-id → task-id (si kanban devuelve el id)
# Formato: change-id=task-id
TASK_ID=$(echo "$TASK_OUTPUT" | grep -oP 'task[- ]id[:\s]+\K[\w-]+' || true)
if [ -n "$TASK_ID" ]; then
  echo "$CHANGE_ID=$TASK_ID" >> "$MAPPING_FILE"
  echo "Mapping guardado: $CHANGE_ID → $TASK_ID"
fi
```

---

## Dependencias entre changes

OpenSpec no tiene dependencias explícitas entre changes, pero si el usuario las conoce puede vincularlas en Kanban:

```bash
# Vincular dos changes: feat-jwt espera a feat-user-model
opsx-to-kanban feat-user-model
opsx-to-kanban feat-jwt

# Leer mapping y enlazar
USER_MODEL_ID=$(grep feat-user-model openspec/.kanban-mapping | cut -d= -f2)
JWT_ID=$(grep feat-jwt openspec/.kanban-mapping | cut -d= -f2)
kanban task link --task-id "$JWT_ID" --linked-task-id "$USER_MODEL_ID"
```

---

## Archivos del repositorio afectados

```
.claude/
  settings.json              ← hooks Claude Code → Kanban
  commands/opsx/             ← instalado por openspec init

.github/
  prompts/opsx-apply.prompt.md    ← ya presente
  copilot-instructions.md         ← instalado por openspec init

scripts/
  opsx-to-kanban.sh          ← sync change → card (nuevo)
  copilot-kanban-wrapper.sh  ← wrapper Copilot con hooks (nuevo)

openspec/
  .kanban-mapping            ← mapping change-id ↔ task-id (generado)
```

---

## Trabajo pendiente

- [ ] Implementar `scripts/opsx-to-kanban.sh`
- [ ] Implementar `scripts/copilot-kanban-wrapper.sh`
- [ ] Configurar hooks Claude Code en `.claude/settings.json`
- [ ] Verificar formato de salida de `kanban task create` para extraer task-id
- [ ] Probar flujo completo con un change real de OpenSpec
