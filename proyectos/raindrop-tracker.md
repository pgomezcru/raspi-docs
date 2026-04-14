[🏠 Inicio](../README.md) > [📂 Proyectos](_index.md)

# raindrop-tracker

**Estado**: Planificado  
**Repo**: `gitea.local/pablo/raindrop-tracker` (mirror de GitHub)  
**Ruta en raspi**: `/mnt/usb-data/raindrop-tracker/`

Servicio que descarga periódicamente todos los bookmarks de [Raindrop.io](https://raindrop.io) y los versiona como YAML + Markdown en el propio repositorio Git. Cada ejecución genera un commit con los cambios reales, convirtiendo `git diff` en la forma natural de ver qué enlaces se añadieron, movieron o eliminaron.

## Arquitectura del pipeline

```
┌──────────────────────────────────────────┐
│  Contenedor Docker (cron en la raspi)    │
│                                          │
│  1. python src/fetch.py                  │
│     → data/yaml/*.yml                   │
│     → data/markdown/*.md                │
│  2. git add data/                        │
│  3. git commit -m "chore: update..."    │   ← solo si hay cambios
│  4. git push (SSH)                       │
└──────────────────┬───────────────────────┘
                   │ push event
                   ▼
┌──────────────────────────────────────────┐
│  Gitea Action (.gitea/workflows/)        │
│  (análisis, alertas, etc.)              │
└──────────────────────────────────────────┘
```

## Requisitos en la Raspberry Pi

### 1. SSH key para el push automático

El contenedor necesita una SSH key autorizada en Gitea para hacer `git push`. El script `setup.sh` la genera automáticamente (ver [Despliegue inicial](#despliegue-inicial)).

Nombre de la key generada: `~/.ssh/raindrop_tracker_ed25519`

```bash
# Si se genera manualmente (sin setup.sh):
ssh-keygen -t ed25519 -C "raindrop-tracker" -f ~/.ssh/raindrop_tracker_ed25519 -N ""

# Añadir la clave pública en Gitea:
# Repo → Settings → Deploy Keys → Add Key  (marcar "Write access")
cat ~/.ssh/raindrop_tracker_ed25519.pub
```

La clave se monta en el contenedor montando todo el directorio `~/.ssh` (ver compose abajo).

### 2. Variables de entorno

Crear `/mnt/usb-data/raindrop-tracker/.env` en la raspi (o copiar `.env.example`):

```ini
# Token personal de Raindrop.io
# Obtener en: app.raindrop.io/settings/integrations
RAINDROP_TOKEN=tu_test_token_aqui

# Directorio de salida (por defecto: data)
# DATA_DIR=data

# Identidad del committer automático
GIT_USER_NAME=raindrop-tracker
GIT_USER_EMAIL=raindrop-tracker@raspi.local

# Habilitar commit y push automático
GIT_COMMIT=true
GIT_PUSH=true

# Alternativa a SSH: URL con credenciales embebidas (HTTPS)
# GIT_REMOTE_URL=https://pablo:gitea_token@gitea.local/pablo/raindrop-tracker.git
```

## Docker Compose

El fichero vive en el propio repo del proyecto. La versión canónica está en:  
`/mnt/usb-data/raindrop-tracker/docker-compose.yml`

```yaml
services:
  raindrop-tracker:
    build: .
    env_file: .env
    volumes:
      # Repo montado completo para que git opere sobre el árbol real
      - .:/app
      # Directorio SSH del host (solo lectura) — incluye key + known_hosts
      - ${HOME}/.ssh:/root/.ssh:ro
    working_dir: /app
```

> El scheduling lo gestiona `cron` del host, no Docker — el contenedor se levanta, ejecuta y se destruye en cada llamada (`docker compose run --rm`).

## Scheduling (cron en la raspi)

El contenedor no corre permanentemente. El host lo lanza diariamente mediante cron.  
El script `setup.sh` puede añadir la entrada automáticamente al final del proceso de instalación.

```bash
# Añadir manualmente si no se usó setup.sh
crontab -e
```

```cron
# Ejecutar raindrop-tracker cada día a las 06:00
0 6 * * * cd /mnt/usb-data/raindrop-tracker && docker compose run --rm raindrop-tracker >> /var/log/raindrop-tracker.log 2>&1
```

## Registro en compose/manifest.yml

Añadir la entrada al [manifiesto IaC](../compose/manifest.yml) para que `deploy.sh` gestione el despliegue del compose:

```yaml
  raindrop-tracker:
    compose: compose/raindrop-tracker/docker-compose.yml
    target:  /mnt/usb-data/raindrop-tracker/docker-compose.yml
```

> El `docker-compose.yml` del manifiesto es una copia de despliegue (sin los bind mounts de desarrollo). El repo completo se clona directamente en la raspi.

## Despliegue inicial

### Opción A — setup.sh (recomendado)

El repo incluye `setup.sh` que automatiza el proceso completo: crea el `.env`, genera la SSH key, hace un build de prueba y opcionalmente instala el cron.

```bash
# 1. Clonar el repo en la raspi
cd /mnt/usb-data/
git clone git@gitea.local:pablo/raindrop-tracker.git

# 2. Ejecutar el asistente de instalación
cd raindrop-tracker
bash setup.sh
```

El script pedirá interactivamente el token de Raindrop.io y mostrará la clave pública generada para añadir en Gitea.

### Opción B — manual

```bash
# 1. Clonar el repo
cd /mnt/usb-data/
git clone git@gitea.local:pablo/raindrop-tracker.git
cd raindrop-tracker

# 2. Crear el .env con el token
cp .env.example .env
nano .env

# 3. Generar SSH key para el push automático
ssh-keygen -t ed25519 -C "raindrop-tracker" -f ~/.ssh/raindrop_tracker_ed25519 -N ""
# → Añadir la clave pública en Gitea: Repo → Settings → Deploy Keys

# 4. Añadir Gitea a known_hosts para evitar el prompt interactivo
ssh-keyscan -p 2222 gitea.local >> ~/.ssh/known_hosts

# 5. Build de la imagen
docker compose build

# 6. Test manual (sin commit/push) antes de activar el cron
GIT_COMMIT=false GIT_PUSH=false docker compose run --rm \
  -e GIT_COMMIT=false -e GIT_PUSH=false raindrop-tracker
```

## Gitea Action (pipeline post-push)

El workflow reside en `.gitea/workflows/` del repo de raindrop-tracker.  
Ver [Gitea Actions — configuración del runner](../programacion/gitea-actions.md) para los prerrequisitos.

Ejemplo de primer workflow (`on: push` en la rama `main`):

```yaml
# .gitea/workflows/notify.yml
name: bookmark-updated

on:
  push:
    branches: [main]
    paths:
      - 'data/**'

jobs:
  log:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Mostrar resumen de cambios
        run: |
          echo "=== Bookmarks actualizados ==="
          git diff HEAD~1 HEAD --stat data/ || echo "(primer commit)"
```

## Referencias

- [Gitea Actions — configuración del runner](../programacion/gitea-actions.md)
- [SSH keys en la raspi](../host/ssh-keys.md)
- [Estrategia de almacenamiento](../host/estrategia-almacenamiento.md)
