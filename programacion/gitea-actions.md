[🏠 Inicio](../README.md) > [📂 Programación](_index.md)

# Gitea Actions — Configuración del Runner

**Estado**: Planificado  
**Dependencia**: Gitea corriendo en `gitea.local:3002`

Gitea Actions es el sistema de CI/CD nativo de Gitea, compatible con la sintaxis de GitHub Actions. Para ejecutar workflows hace falta un **runner** (`act_runner`) registrado contra la instancia de Gitea.

## Conceptos clave

| Término | Descripción |
|---------|-------------|
| `act_runner` | Proceso que escucha jobs de Gitea y los ejecuta. Puede correr como contenedor Docker o servicio systemd. |
| Runner token | Token de registro generado en Gitea para vincular el runner a la instancia. |
| Labels | Etiquetas del runner que determinan qué `runs-on:` puede atender (ej. `ubuntu-latest`). |
| Workflow | Fichero YAML en `.gitea/workflows/` del repo que define el pipeline. |

> Gitea Actions usa internamente [nektos/act](https://github.com/nektos/act) para ejecutar los jobs en contenedores Docker. Por eso el runner necesita acceso al socket de Docker del host.

## Paso 1 — Habilitar Actions en Gitea

En la instancia de Gitea, editar la configuración del servidor:

```bash
# Editar app.ini dentro del volumen de datos de Gitea
nano /mnt/usb-data/docker-root/gitea/data/gitea/conf/app.ini
```

Añadir o modificar la sección `[actions]`:

```ini
[actions]
ENABLED = true
```

Reiniciar el contenedor para aplicar los cambios:

```bash
docker compose -f /mnt/usb-data/gitea/docker-compose.yml restart server
```

Verificar en el panel de administración:  
`http://gitea.local:3002/-/admin/self-check`

## Paso 2 — Obtener el token de registro

En Gitea como administrador:

```
Gitea → Site Administration → Actions → Runners → Create new runner
```

Copiar el **Registration token** que se genera. Es de un solo uso.

Alternativamente, para registrar el runner a nivel de organización o repositorio:

```
Repo → Settings → Actions → Runners → Create new runner
```

## Paso 3 — Desplegar act_runner como contenedor Docker

Añadir el runner al compose de Gitea en `compose/gitea/docker-compose.yml`:

```yaml
  act-runner:
    image: gitea/act_runner:0.2.11
    container_name: act-runner
    restart: unless-stopped
    environment:
      - GITEA_INSTANCE_URL=http://gitea:3000   # red interna Docker
      - GITEA_RUNNER_REGISTRATION_TOKEN=${ACT_RUNNER_TOKEN}
      - GITEA_RUNNER_NAME=raspi-runner
      - GITEA_RUNNER_LABELS=ubuntu-latest:docker://node:20-bullseye,ubuntu-22.04:docker://node:20-bullseye
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock   # runner lanza contenedores en el host
      - /mnt/usb-data/docker-root/act-runner:/data
    depends_on:
      - server
    networks:
      - default
```

> **Importante**: El runner se conecta al servicio `gitea` por la red interna de Docker (`http://gitea:3000`), no por el puerto expuesto al host. Esto evita problemas de loopback en la raspi.

Añadir la variable al `.env` del compose de Gitea:

```ini
# .env del compose de gitea
GITEA_DB_PASSWORD=...
ACT_RUNNER_TOKEN=<token-de-registro-del-paso-2>
```

Levantar el runner:

```bash
docker compose -f /mnt/usb-data/gitea/docker-compose.yml up -d act-runner
```

## Paso 4 — Verificar el registro

En Gitea:

```
Site Administration → Actions → Runners
```

El runner `raspi-runner` debe aparecer con estado **Active** y los labels configurados.

## Paso 5 — Habilitar Actions en cada repositorio

Por defecto, Actions puede estar deshabilitado a nivel de repositorio:

```
Repo → Settings → General → Features → Actions ✓
```

## Limitaciones en Raspberry Pi

La raspi tiene recursos limitados. Tener en cuenta:

- Cada job levanta un contenedor Docker nuevo. En la raspi, el pull de imágenes base (`ubuntu-latest`, `node:20`) puede tardar varios minutos la primera vez.
- Usar imágenes ligeras en los workflows: `alpine`, `python:3.11-slim`, etc.
- Los jobs se ejecutan secuencialmente (el runner tiene 1 worker por defecto). Configurar `max_concurrent_runs` si fuera necesario.
- La imagen `ubuntu-latest` mapeada a `node:20-bullseye` es una simplificación. Para workflows que necesiten `apt-get`, usar `debian:bookworm-slim`.

## Primer workflow: raindrop-tracker

Ver [raindrop-tracker → Gitea Action](../proyectos/raindrop-tracker.md#gitea-action-pipeline-post-push) para el workflow concreto que dispara tras cada push con cambios en `data/`.

## Estructura de un workflow

```yaml
# .gitea/workflows/mi-workflow.yml
name: nombre-del-workflow

on:
  push:
    branches: [main]

jobs:
  mi-job:
    runs-on: ubuntu-latest   # debe coincidir con un label del runner
    steps:
      - uses: actions/checkout@v4
      - name: Paso de ejemplo
        run: echo "Hola desde la raspi"
```

> La sintaxis es casi idéntica a GitHub Actions. Las principales diferencias son:
> - No todas las actions del Marketplace de GitHub son compatibles.
> - Usar `actions/checkout@v4` (o superior) para compatibilidad con Gitea.
> - El contexto `github.*` se sustituye por `gitea.*` aunque `github.*` también funciona por compatibilidad.

## Referencias

- [Documentación oficial act_runner](https://gitea.com/gitea/act_runner)
- [Gitea Actions — documentación](https://docs.gitea.com/usage/actions/overview)
- [nektos/act](https://github.com/nektos/act) — motor subyacente
- [Gitea en la raspi](gitea.md)
