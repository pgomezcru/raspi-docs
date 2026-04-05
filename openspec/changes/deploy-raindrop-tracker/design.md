## Context

Gitea está corriendo en la raspi (`gitea.local:3002`) pero sin runner de Actions. El repo `raindrop-tracker` existe localmente en `c:/devs/raindrop-tracker` y tiene su `Dockerfile`, `docker-compose.yml` y `entrypoint.sh` funcionales. El sistema IaC de la raspi usa `compose/manifest.yml` + `deploy.sh` para sincronizar composes con la Pi.

Estado actual:
- `raindrop-tracker` no está registrado en el manifiesto IaC.
- No existe un compose de despliegue (separado del de desarrollo) en este repo.
- Gitea no tiene `act_runner` configurado → Actions no funciona.
- No existe ningún workflow `.gitea/workflows/` en el repo de raindrop-tracker.

## Goals / Non-Goals

**Goals:**
- Registrar raindrop-tracker como servicio IaC desplegable en la raspi.
- Habilitar Gitea Actions añadiendo `act_runner` al stack de Gitea.
- Crear el primer workflow funcional (post-push sobre `data/`) en raindrop-tracker.
- Definir la convención de despliegue para futuros proyectos personales.

**Non-Goals:**
- Automatizar el workflow de análisis de bookmarks (es el siguiente proyecto).
- Implementar notificaciones o alertas desde la Action.
- Configurar HTTPS para Gitea Actions (se usa HTTP en LAN).

## Decisions

### D1: compose de despliegue separado del de desarrollo

El `docker-compose.yml` en el repo de raindrop-tracker monta `~/.ssh` del desarrollador y es apto para desarrollo local. Para despliegue en la raspi se necesita un compose limpio que monte la key del bot específica.

**Decisión**: crear `compose/raindrop-tracker/docker-compose.yml` en este repo (raspi-docs) con la configuración de producción. El repo de raindrop-tracker se clona entero en `/mnt/usb-data/raindrop-tracker/` y el compose de raspi-docs se despliega encima vía `deploy.sh`.

**Alternativa descartada**: usar el compose del repo de raindrop-tracker directamente — contamina el repo del proyecto con configuración de infraestructura específica de la raspi.

### D2: act_runner en el mismo stack que Gitea

**Decisión**: añadir `act-runner` como servicio en `compose/gitea/docker-compose.yml`. Así reside en la misma red Docker que Gitea y se conecta por `http://gitea:3000` sin exponer el puerto.

**Alternativa descartada**: runner como servicio systemd separado — añade complejidad de gestión sin beneficio real a esta escala.

### D3: scheduling vía cron del host, no restart policy de Docker

raindrop-tracker no es un daemon; es un proceso batch que termina. El scheduling periódico lo gestiona `cron` del host lanzando `docker compose run --rm`.

**Decisión**: `restart: "no"` en el compose de producción. La entrada de cron ejecuta el contenedor y registra salida en `/var/log/raindrop-tracker.log`.

### D4: SSH key dedicada para el bot

El push automático usa una ed25519 key generada específicamente para raindrop-tracker-bot, añadida como deploy key en el repo de Gitea (no como key global del usuario).

**Motivación**: principio de mínimo privilegio — la key solo puede hacer push a ese repo.

## Risks / Trade-offs

- **[Riesgo] act_runner en la raspi tiene recursos limitados** → Los jobs usan imágenes ligeras (`python:3.11-slim`); la imagen base se hace pull una vez y queda cacheada.
- **[Riesgo] El contenedor de raindrop-tracker modifica su propio repo (write-back)** → Si el push falla el cron del siguiente ciclo reintentará automáticamente; no hay pérdida de datos.
- **[Trade-off] deploy.sh copia el compose encima del del repo** → El compose del repo de raindrop-tracker queda ignorado en producción. Esto es intencional: el repo del proyecto no debe conocer detalles de infraestructura.

## Migration Plan

1. Generar SSH key del bot en la raspi.
2. Añadir `act_runner` al compose de Gitea + desplegar.
3. Habilitar Actions en `app.ini` de Gitea + registrar el runner.
4. Añadir entrada `raindrop-tracker` en `compose/manifest.yml`.
5. Crear `compose/raindrop-tracker/docker-compose.yml`.
6. Clonar repo raindrop-tracker en la raspi y desplegar con `deploy.sh`.
7. Configurar cron en la raspi.
8. Crear `.gitea/workflows/bookmark-updated.yml` en el repo raindrop-tracker.
9. Test end-to-end: ejecución manual → commit → push → Action.

**Rollback**: desactivar la entrada de cron; el runner puede detenerse sin afectar Gitea.

## Open Questions

- ¿Versión exacta de `act_runner` a fijar? (usar latest estable al momento del despliegue, luego pinear).
- ¿El token de registro del runner se guarda en el `.env` de Gitea o en un secreto separado?
