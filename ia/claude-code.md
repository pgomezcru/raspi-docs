[🏠 Inicio](../README.md) > [📂 IA](_index.md)

# Claude Code: Agente de IA con Acceso Controlado

> [Documentación oficial de Claude Code](https://code.claude.com/docs/en/overview)

[Claude Code](https://code.claude.com/docs/en/overview) es la herramienta de IA de Anthropic que opera como agente autónomo en la línea de comandos: puede leer ficheros, ejecutar comandos y razonar de forma independiente. El objetivo de esta guía es configurar un entorno en el que Claude pueda realizar **tareas de mantenimiento y despliegues en la Raspberry Pi** sin perder el control sobre sus acciones, usando cuatro capas de seguridad:

1. **Usuario dedicado** en la Pi con permisos mínimos.
2. **Clave SSH exclusiva** para el agente.
3. **Permisos** en `settings.json` que limitan qué comandos puede ejecutar.
4. **Hooks de auditoría** en Windows que registran y pueden bloquear operaciones.

## Arquitectura

```
┌─────────────────────────────┐         ┌─────────────────────────────┐
│         Windows             │         │       Raspberry Pi          │
│                             │         │                             │
│  Claude Code CLI            │──SSH──► │  Usuario: claude-agent      │
│  ~/.claude/settings.json    │         │  Grupo:   docker            │
│  ~/.claude/hooks/*.ps1      │         │  Sudoers: restringido       │
│  ~/.ssh/id_ed25519_claude   │         │  authorized_keys: from=LAN  │
└─────────────────────────────┘         └─────────────────────────────┘
         │
         ▼ PreToolUse Hook
    block-dangerous.ps1  ← bloquea patrones peligrosos
    audit-log.ps1        ← registra todas las acciones
```

Cada comando que Claude intenta ejecutar (`ssh raspi-claude docker ps`, etc.) pasa primero por los hooks de Windows antes de llegar a la Pi.

---

## 1. Usuario `claude-agent` en la Raspberry Pi

### 1.1 Creación del usuario

Conectado como `admin` a la Pi:

```bash
# Crear usuario sin contraseña interactiva
sudo adduser --disabled-password --gecos "Claude AI Agent" claude-agent

# Añadir al grupo docker (permite operar contenedores sin sudo)
sudo usermod -aG docker claude-agent

# Verificar grupos
groups claude-agent
# → claude-agent : claude-agent docker
```

### 1.2 Permisos granulares con sudoers

Crear un fichero dedicado en `/etc/sudoers.d/` para no tocar el fichero principal:

```bash
sudo visudo -f /etc/sudoers.d/claude-agent
```

Contenido:

```sudoers
# Cuenta de servicio sin contraseña: evitar el prompt de autenticación.
# Sin esto, sudo pide contraseña para comandos no listados antes de denegar,
# lo que bloquea la shell porque la cuenta no tiene contraseña asignada.
# Nota: no hace falta reiniciar nada; sudoers se re-lee en cada llamada a sudo.
#
# Opción 1 (preferida): deshabilitar autenticación para este usuario.
Defaults:claude-agent !authenticate

# Permisos para el agente Claude – solo lectura de logs y estado del sistema
Cmnd_Alias CLAUDE_READ = /bin/journalctl *, /usr/bin/apt list --upgradable, \
                          /bin/systemctl status *, /usr/bin/docker stats *

# Permisos de modificación – gestión de servicios y contenedores específicos
Cmnd_Alias CLAUDE_MANAGE = /usr/bin/docker restart *, /usr/bin/docker start *, \
                            /usr/bin/docker stop *, /bin/systemctl restart *, \
                            /usr/bin/apt update

# Operaciones de solo lectura: permitidas
claude-agent ALL=(root) NOPASSWD: CLAUDE_READ

# Operaciones de modificación: descomentar cuando se confíe en el agente
# claude-agent ALL=(root) NOPASSWD: CLAUDE_MANAGE
```

> ⚠️ **Empezar solo con `CLAUDE_READ`**. Añadir permisos de modificación gradualmente conforme se compruebe el comportamiento del agente en los logs de auditoría.

### 1.3 Verificación

Para probar los permisos de `claude-agent` hay que abrir una shell con ese usuario. Usar `sudo -u claude-agent sudo <cmd>` encadena dos sudos y pide la contraseña de `admin`, no del agente.

```bash
# 1. Abrir una shell interactiva como claude-agent
sudo su - claude-agent

# 2. Desde esa shell, verificar el acceso a docker (vía grupo, sin sudo)
docker ps
# → debe listar los contenedores sin pedir contraseña

# 3. Verificar que sudo restringido funciona (CLAUDE_READ)
sudo journalctl -n 10 --no-pager
# → debe mostrar las últimas 10 líneas del journal

# 4. Confirmar que comandos fuera de la lista están denegados
sudo rm /tmp/test
# → Sorry, user claude-agent is not allowed to execute /bin/rm...

# 5. Salir de la shell de claude-agent
exit
```

---

## 2. Clave SSH Dedicada

### 2.1 Generar la clave (en Windows, PowerShell)

```powershell
# Par de claves Ed25519 con comentario identificativo
ssh-keygen -t ed25519 -f "$env:USERPROFILE\.ssh\id_ed25519_claude" -C "claude-agent@windows"

# No añadir passphrase si Claude Code la va a usar de forma desatendida.
# Si se añade passphrase, configurar el agente SSH de Windows para cachearla.
```

### 2.2 Copiar la clave pública a la Raspberry Pi

```powershell
# Desde Windows PowerShell
$pubKey = Get-Content "$env:USERPROFILE\.ssh\id_ed25519_claude.pub"
$pubKey | ssh admin@192.168.1.101 `
    "sudo -u claude-agent mkdir -p /home/claude-agent/.ssh && sudo -u claude-agent tee -a /home/claude-agent/.ssh/authorized_keys"
```

En la Pi, establecer los permisos correctos:

```bash
# Conectado como admin en la Pi
sudo mkdir -p /home/claude-agent/.ssh
sudo touch /home/claude-agent/.ssh/authorized_keys
sudo chown -R claude-agent:claude-agent /home/claude-agent/.ssh
sudo chmod 700 /home/claude-agent/.ssh
sudo chmod 600 /home/claude-agent/.ssh/authorized_keys
```

**Paso 2** — Obtener el contenido de la clave pública en Windows y añadirla:

```powershell
# En Windows: mostrar la clave pública para copiarla al portapapeles
Get-Content "$env:USERPROFILE\.ssh\id_ed25519_claude.pub"
```

```bash
# De vuelta en la Pi, pegar el contenido de la clave (sustituir CLAVE por el valor real)
echo "ssh-ed25519 AAAA...CLAVE... claude-agent@windows" | sudo tee -a /home/claude-agent/.ssh/authorized_keys
```

### 2.3 Restricciones en `authorized_keys`

Editar la entrada de la clave en la Pi para añadir restricciones de origen y capacidades:

```bash
sudo nano /home/claude-agent/.ssh/authorized_keys
```

La línea debe quedar en este formato (todo en una sola línea):

```
from="192.168.1.0/24",no-agent-forwarding,no-X11-forwarding,no-port-forwarding ssh-ed25519 AAAA... claude-agent@windows
```

| Opción | Efecto |
|--------|--------|
| `from="192.168.1.0/24"` | Solo acepta conexiones desde la LAN |
| `no-agent-forwarding` | Impide reenviar el agente SSH |
| `no-X11-forwarding` | Deshabilita el reenvío gráfico |
| `no-port-forwarding` | Impide tunnels y port-forwarding |

### 2.4 Configurar `~/.ssh/config` en Windows

```
# %USERPROFILE%\.ssh\config

Host raspi-claude
    HostName 192.168.1.101
    User claude-agent
    IdentityFile ~/.ssh/id_ed25519_claude
    IdentitiesOnly yes
    ServerAliveInterval 30
    ServerAliveCountMax 3
    ConnectTimeout 10
```

Verificar:

```powershell
ssh raspi-claude "echo 'Conectado como:' && whoami && groups"
# → Conectado como: claude-agent
# → claude-agent docker
```

---

## 3. Configurar Claude Code en Windows

### 3.1 Permisos en `settings.json`

El fichero `%USERPROFILE%\.claude\settings.json` controla qué puede hacer el agente.
La lógica de evaluación es: **deny primero → ask → allow**.

```json
{
  "$schema": "https://json.schemastore.org/claude-code-settings.json",
  "permissions": {
    "allow": [
      "Bash(ssh raspi-claude docker ps*)",
      "Bash(ssh raspi-claude docker logs *)",
      "Bash(ssh raspi-claude docker inspect *)",
      "Bash(ssh raspi-claude docker stats*)",
      "Bash(ssh raspi-claude systemctl status *)",
      "Bash(ssh raspi-claude sudo journalctl *)",
      "Bash(ssh raspi-claude df *)",
      "Bash(ssh raspi-claude free *)",
      "Bash(ssh raspi-claude uptime*)",
      "Bash(ssh raspi-claude cat /mnt/usb-data/*)"
    ],
    "ask": [
      "Bash(ssh raspi-claude docker restart *)",
      "Bash(ssh raspi-claude docker stop *)",
      "Bash(ssh raspi-claude docker start *)",
      "Bash(ssh raspi-claude docker compose *)",
      "Bash(ssh raspi-claude docker pull *)",
      "Bash(ssh raspi-claude sudo systemctl restart *)",
      "Bash(ssh raspi-claude sudo apt *)"
    ],
    "deny": [
      "Bash(ssh raspi-claude rm *)",
      "Bash(ssh raspi-claude sudo rm *)",
      "Bash(ssh raspi-claude dd *)",
      "Bash(ssh raspi-claude mkfs*)",
      "Bash(ssh raspi-claude wipefs*)",
      "Bash(ssh raspi-claude sudo passwd *)",
      "Bash(ssh raspi-claude sudo userdel *)",
      "Bash(ssh raspi-claude sudo usermod *)",
      "Bash(ssh raspi-claude sudo reboot*)",
      "Bash(ssh raspi-claude sudo shutdown*)"
    ]
  }
}
```

> **Nota**: Las reglas `ask` requieren aprobación explícita del usuario antes de ejecutar. Son ideales para operaciones de modificación como reinicios y despliegues.

### 3.2 Instrucciones de contexto con `CLAUDE.md`

Crear un fichero `.claude/CLAUDE.md` en la raíz del repositorio para dar a Claude instrucciones específicas sobre la infraestructura. Claude lo carga automáticamente al arrancar en ese directorio:

```markdown
# Contexto: Infraestructura Raspberry Pi

## Acceso SSH
- Alias configurado: `raspi-claude` → 192.168.1.101
- Usuario en la Pi: `claude-agent` (miembro del grupo docker)

## Reglas de operación
- SIEMPRE mostrar el plan antes de ejecutar cambios.
- Para despliegues: revisar el docker-compose.yml antes de hacer `docker compose up`.
- NO ejecutar comandos destructivos. Si es necesario eliminar algo, pedirlo al usuario.
- Documentar cualquier cambio realizado en los ficheros Markdown del repositorio.

## Estructura de la Pi
- Compose files: `/mnt/usb-data/docker-root/<servicio>/docker-compose.yml`
- Volumes:       `/mnt/usb-data/docker-root/<servicio>/<volumen>/`
- Red interna:   `proxy_net` (external, definida en Docker)

## Comandos habituales
- Estado contenedores:  `ssh raspi-claude docker ps`
- Logs de un servicio:  `ssh raspi-claude docker logs <container> --tail 50`
- Uso de disco:         `ssh raspi-claude df -h /mnt/usb-data`
- Inspeccionar compose: `ssh raspi-claude cat /mnt/usb-data/docker-root/<srv>/docker-compose.yml`
```

---

## 4. Hooks de Auditoría en Windows

Los [hooks de Claude Code](https://code.claude.com/docs/en/hooks) son scripts que se ejecutan automáticamente antes (`PreToolUse`) o después (`PostToolUse`) de cada acción del agente. Reciben el contexto de la acción como JSON por `stdin`.

### 4.1 Crear el directorio de hooks

```powershell
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.claude\hooks"
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.claude\audit"
```

### 4.2 Script de auditoría (`audit-log.ps1`)

Registra toda actividad del agente en un fichero mensual:

```powershell
# ~/.claude/hooks/audit-log.ps1
# Registra las acciones de Claude Code. Usado como hook async (no bloquea).

$logDir  = "$env:USERPROFILE\.claude\audit"
$logFile = "$logDir\claude-audit-$(Get-Date -Format 'yyyy-MM').log"

if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Force -Path $logDir | Out-Null
}

try {
    $inputData  = [System.Console]::In.ReadToEnd()
    $event      = $inputData | ConvertFrom-Json
    $timestamp  = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $eventName  = $event.hook_event_name
    $tool       = $event.tool_name
    $detail     = if ($event.tool_input.command) { $event.tool_input.command }
                  elseif ($event.tool_input.file_path) { $event.tool_input.file_path }
                  else { $event.tool_input | ConvertTo-Json -Compress }

    Add-Content -Path $logFile -Value "[$timestamp] [$eventName] [$tool] $detail" -Encoding UTF8
} catch {
    # Silencioso – no interrumpir al agente por fallos de log
}

exit 0
```

### 4.3 Script de bloqueo (`block-dangerous.ps1`)

Segunda línea de defensa: bloquea patrones peligrosos que puedan escapar de las reglas de `settings.json`:

```powershell
# ~/.claude/hooks/block-dangerous.ps1
# Bloquea comandos destructivos. Usado como hook SÍNCRONO (exit 2 bloquea la ejecución).

$inputData = [System.Console]::In.ReadToEnd()
$event     = $inputData | ConvertFrom-Json

# Solo actúa sobre el tool Bash
if ($event.tool_name -ne "Bash") { exit 0 }

$command = $event.tool_input.command

$blockedPatterns = @(
    'rm\s+-rf',
    'rm\s+--no-preserve-root',
    '>\s*/dev/sd[a-z]',
    'dd\s+if=.*of=/dev/',
    'mkfs\.',
    'wipefs',
    'shred\s+-',
    '\|\s*(sh|bash)\s*$',     # pipe a shell
    'chmod\s+777',
    'sudo\s+passwd\b',
    'sudo\s+userdel\b',
    'sudo\s+reboot\b',
    'sudo\s+shutdown\b',
    'sudo\s+init\s+0'
)

foreach ($pattern in $blockedPatterns) {
    if ($command -match $pattern) {
        # Exit 2 = error bloqueante: Claude ve el mensaje de stderr
        Write-Error "BLOQUEADO por hook de seguridad: patrón '$pattern' detectado en: $command"
        exit 2
    }
}

exit 0
```

### 4.4 Añadir los hooks a `settings.json`

```json
{
  "$schema": "https://json.schemastore.org/claude-code-settings.json",
  "permissions": {
    "...": "ver sección 3.1"
  },
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "powershell -NoProfile -File \"%USERPROFILE%\\.claude\\hooks\\block-dangerous.ps1\""
          },
          {
            "type": "command",
            "command": "powershell -NoProfile -File \"%USERPROFILE%\\.claude\\hooks\\audit-log.ps1\"",
            "async": true
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "powershell -NoProfile -File \"%USERPROFILE%\\.claude\\hooks\\audit-log.ps1\"",
            "async": true
          }
        ]
      }
    ]
  }
}
```

> **`block-dangerous.ps1` es síncrono** (sin `async: true`) para que su `exit 2` interrumpa la acción antes de ejecutarse. **`audit-log.ps1` es asíncrono** para no añadir latencia.

### 4.5 Verificar los hooks

Dentro de Claude Code, usar `/hooks` para ver todos los hooks activos y su origen (`User`, `Project`, etc.).

Para depuración detallada:

```bash
claude --debug
```

### 4.6 Consultar el log de auditoría

```powershell
# Ver las últimas 30 entradas del log del mes actual
Get-Content "$env:USERPROFILE\.claude\audit\claude-audit-$(Get-Date -Format 'yyyy-MM').log" |
    Select-Object -Last 30
```

---

## 5. Resumen de Capas de Seguridad

| Capa | Mecanismo | Protege contra |
|------|-----------|----------------|
| Red | `from="192.168.1.0/24"` en authorized_keys | Acceso SSH desde fuera de la LAN |
| Autenticación | Clave Ed25519 dedicada, sin contraseña de usuario | Fuerza bruta y reutilización de credenciales |
| Privilegios | Grupo `docker` + sudoers con `Cmnd_Alias` restringidos | Escalada de privilegios en la Pi |
| Permisos Claude | `permissions.deny` / `allow` / `ask` en settings.json | Operaciones destructivas automáticas |
| Hooks | `block-dangerous.ps1` (síncrono) | Patrones peligrosos que escapen las reglas |
| Trazabilidad | `audit-log.ps1` (async) | Revisión posterior de todas las acciones |

### Buenas prácticas

- **Rotación de claves**: Rotar `id_ed25519_claude` periódicamente (ver [Gestión de Claves SSH](../infraestructura/ssh-keys.md)).
- **Revisión de logs**: Revisar `%USERPROFILE%\.claude\audit\` regularmente para detectar patrones inesperados.
- **Mínimos privilegios**: Ampliar `sudoers` solo cuando sea estrictamente necesario y documentar el motivo.
- **No exponer la Pi**: El agente solo debe operar desde la red local; no abrir el puerto SSH al exterior.
- **Modo plan**: Antes de tareas complejas, lanzar Claude con `claude --plan` para revisar el plan de acción antes de ejecutar nada.

---

## Referencias

- [Claude Code Documentation](https://code.claude.com/docs/en/overview) — Documentación oficial
- [Claude Code Settings](https://code.claude.com/docs/en/settings) — Configuración de permisos y hooks
- [Claude Code Hooks Reference](https://code.claude.com/docs/en/hooks) — Sistema de hooks
- [Gestión de Claves SSH](../infraestructura/ssh-keys.md) — Guía de claves SSH en este proyecto
- [Configuración Inicial y Hardening](../infraestructura/configuracion-inicial.md) — Hardening de la Raspberry Pi