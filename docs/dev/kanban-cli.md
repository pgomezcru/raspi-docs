# kanban CLI — Referencia completa

> Versión explorada: 2026-03-31
> Runtime URL por defecto: `http://127.0.0.1:3484`

`kanban` es un tablero de orquestación local para agentes de código.

---

## Opciones globales

```
kanban [opciones] [comando]
```

| Opción | Descripción |
|---|---|
| `-v, --version` | Muestra la versión instalada |
| `--host <ip>` | IP a la que enlazar el servidor (por defecto: `127.0.0.1`) |
| `--port <number\|auto>` | Puerto (1-65535) o `auto` para asignación automática |
| `--no-open` | No abrir el navegador automáticamente al iniciar |
| `--skip-shutdown-cleanup` | Al apagar, no mover sesiones a trash ni borrar worktrees de tareas |
| `-h, --help` | Muestra la ayuda |

---

## Comandos de primer nivel

| Comando | Descripción |
|---|---|
| `task` / `tasks` | Gestiona tareas del tablero Kanban desde la CLI |
| `hooks` | Helpers para integración con agentes externos |
| `mcp` | Comando de compatibilidad (deprecado) |

---

## `kanban task` — Gestión de tareas

```
kanban task [comando]
```

### `kanban task list`

Lista las tareas de un workspace.

| Opción | Descripción |
|---|---|
| `--project-path <path>` | Ruta del workspace (por defecto: directorio actual) |
| `--column <column>` | Filtra por columna: `backlog` \| `in_progress` \| `review` \| `trash` |
| `-h, --help` | Muestra la ayuda |

---

### `kanban task create`

Crea una tarea en el backlog.

| Opción | Descripción |
|---|---|
| `--prompt <text>` | Texto del prompt de la tarea |
| `--project-path <path>` | Ruta del workspace (por defecto: directorio actual) |
| `--base-ref <branch>` | Rama/ref base de la tarea |
| `--start-in-plan-mode [value]` | Activa el modo plan (`true`\|`false`). Solo el flag implica `true` |
| `--auto-review-enabled [value]` | Habilita revisión automática (`true`\|`false`). Solo el flag implica `true` |
| `--auto-review-mode <mode>` | Modo de revisión automática: `commit` \| `pr` \| `move_to_trash` |
| `-h, --help` | Muestra la ayuda |

---

### `kanban task update`

Actualiza una tarea existente.

| Opción | Descripción |
|---|---|
| `--task-id <id>` | ID de la tarea a actualizar |
| `--prompt <text>` | Nuevo texto del prompt (reemplaza el anterior) |
| `--project-path <path>` | Ruta del workspace (por defecto: directorio actual) |
| `--base-ref <branch>` | Nueva rama/ref base |
| `--start-in-plan-mode [value]` | Activa el modo plan (`true`\|`false`) |
| `--auto-review-enabled [value]` | Habilita revisión automática (`true`\|`false`) |
| `--auto-review-mode <mode>` | Modo de revisión: `commit` \| `pr` \| `move_to_trash` |
| `-h, --help` | Muestra la ayuda |

---

### `kanban task trash`

Mueve una tarea o una columna completa a trash y limpia sus workspaces.

| Opción | Descripción |
|---|---|
| `--task-id <id>` | ID de la tarea a mover a trash |
| `--column <column>` | Columna a mover en bloque: `backlog` \| `in_progress` \| `review` \| `trash` |
| `--project-path <path>` | Ruta del workspace (por defecto: directorio actual) |
| `-h, --help` | Muestra la ayuda |

---

### `kanban task delete`

Elimina permanentemente una tarea o todas las tareas de una columna.

| Opción | Descripción |
|---|---|
| `--task-id <id>` | ID de la tarea a eliminar permanentemente |
| `--column <column>` | Columna a eliminar en bloque: `backlog` \| `in_progress` \| `review` \| `trash` |
| `--project-path <path>` | Ruta del workspace (por defecto: directorio actual) |
| `-h, --help` | Muestra la ayuda |

> **Diferencia con `trash`:** `delete` es irreversible. `trash` es recuperable.

---

### `kanban task link`

Vincula dos tareas creando una dependencia (una espera a la otra).

| Opción | Descripción |
|---|---|
| `--task-id <id>` | ID de una de las dos tareas a vincular |
| `--linked-task-id <id>` | ID de la otra tarea a vincular |
| `--project-path <path>` | Ruta del workspace (por defecto: directorio actual) |
| `-h, --help` | Muestra la ayuda |

**Lógica de dirección de dependencia:**

- Si **ambas tareas** están en `backlog`: `--task-id` espera a `--linked-task-id` (la flecha apunta hacia `--linked-task-id`).
- Si **solo una** está en `backlog`: Kanban reorienta el vínculo automáticamente para que la tarea en backlog sea la dependiente.
- Cuando el prerrequisito termina revisión y pasa a `trash`, la tarea dependiente queda lista para iniciar.

---

### `kanban task unlink`

Elimina un vínculo de dependencia existente.

| Opción | Descripción |
|---|---|
| `--dependency-id <id>` | ID de la dependencia a eliminar |
| `--project-path <path>` | Ruta del workspace (por defecto: directorio actual) |
| `-h, --help` | Muestra la ayuda |

---

### `kanban task start`

Inicia una sesión de tarea y la mueve a `in_progress`.

| Opción | Descripción |
|---|---|
| `--task-id <id>` | ID de la tarea a iniciar |
| `--project-path <path>` | Ruta del workspace (por defecto: directorio actual) |
| `-h, --help` | Muestra la ayuda |

---

## `kanban hooks` — Integración con agentes

```
kanban hooks [comando]
```

### `kanban hooks ingest`

Ingesta un evento de hook en el runtime de Kanban. Lanza error si falla.

```
kanban hooks ingest [opciones] [payload]
```

| Opción | Descripción |
|---|---|
| `--event <event>` | Tipo de evento: `to_review` \| `to_in_progress` \| `activity` |
| `--source <source>` | Origen del hook |
| `--activity-text <text>` | Texto resumen de la actividad |
| `--tool-name <name>` | Nombre de la herramienta que dispara el hook |
| `--final-message <message>` | Mensaje final del agente |
| `--hook-event-name <name>` | Nombre original del evento de hook |
| `--notification-type <type>` | Tipo de notificación |
| `--metadata-base64 <base64>` | Payload de metadatos JSON codificado en Base64 |
| `-h, --help` | Muestra la ayuda |

---

### `kanban hooks notify`

Idéntico a `ingest` pero **best-effort**: nunca lanza excepciones aunque falle.

```
kanban hooks notify [opciones] [payload]
```

Acepta exactamente las mismas opciones que `kanban hooks ingest`.

> **Cuándo usar `notify` vs `ingest`:** Usar `notify` en integraciones donde el fallo del hook no debe interrumpir el flujo del agente.

---

### `kanban hooks gemini-hook`

Punto de entrada específico para el hook de Gemini. Sin opciones adicionales.

```
kanban hooks gemini-hook
```

---

### `kanban hooks codex-wrapper`

Wrapper de Codex que emite notificaciones de hook a Kanban.

```
kanban hooks codex-wrapper [opciones] [agentArgs...]
```

| Opción | Descripción |
|---|---|
| `--real-binary <path>` | Ruta al binario real de Codex |
| `-h, --help` | Muestra la ayuda |

---

## `kanban mcp` (deprecado)

Comando de compatibilidad. No tiene opciones adicionales. No usar en instalaciones nuevas.

---

## Árbol de comandos

```
kanban
├── --host, --port, --no-open, --skip-shutdown-cleanup
├── task / tasks
│   ├── list        --project-path, --column
│   ├── create      --prompt, --project-path, --base-ref, --start-in-plan-mode,
│   │               --auto-review-enabled, --auto-review-mode
│   ├── update      --task-id, --prompt, --project-path, --base-ref,
│   │               --start-in-plan-mode, --auto-review-enabled, --auto-review-mode
│   ├── trash       --task-id, --column, --project-path
│   ├── delete      --task-id, --column, --project-path
│   ├── link        --task-id, --linked-task-id, --project-path
│   ├── unlink      --dependency-id, --project-path
│   └── start       --task-id, --project-path
├── hooks
│   ├── ingest      --event, --source, --activity-text, --tool-name,
│   │               --final-message, --hook-event-name, --notification-type,
│   │               --metadata-base64
│   ├── notify      (mismas opciones que ingest, best-effort)
│   ├── gemini-hook (sin opciones)
│   └── codex-wrapper --real-binary
└── mcp             (deprecado)
```
