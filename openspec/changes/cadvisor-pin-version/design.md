## Context

El commit `db91910` actualizó `compose/prometheus/docker-compose.yml` para pinear `cadvisor` a `gcr.io/cadvisor/cadvisor:v0.55.1`, pero el contenedor en producción nunca se redeployó tras ese cambio. El contenedor actual usa `:latest`. `deploy.sh` automatiza el redespliegue copiando el compose al destino correcto y ejecutando `docker compose up -d`.

## Goals / Non-Goals

**Goals:**
- El contenedor cadvisor en producción usa `v0.55.1`
- El estado de producción coincide con el compose del repositorio

**Non-Goals:**
- Cambiar la versión de cadvisor (ya está correcta en el compose)
- Modificar la configuración de cadvisor
- Actualizar otras imágenes (son objeto de otros cambios)

## Decisions

### 1. Redespliegue vía deploy.sh sin cambios en el compose
**Decisión**: ejecutar `deploy.sh prometheus` en la Pi para aplicar el compose existente.
**Razón**: el compose ya tiene la versión correcta. No hay cambio de configuración, solo hay que alinear producción con el repo.

## Risks / Trade-offs

- **Interrupción breve**: `docker compose up -d` recrea solo el contenedor cadvisor (los demás del stack prometheus no se ven afectados). Las métricas de cadvisor se interrumpen durante ~10 segundos.
- **Pull de imagen**: si `v0.55.1` no está en cache local de la Pi, Docker hará pull (puede tardar unos minutos en ARM64).

## Migration Plan

1. En la Pi como `admin`: `git pull` en `~/raspi-docs`
2. Ejecutar: `bash ~/raspi-docs/compose/deploy.sh prometheus`
3. Verificar versión: `docker inspect cadvisor --format '{{.Config.Image}}'`
   - Resultado esperado: `gcr.io/cadvisor/cadvisor:v0.55.1`
4. Actualizar `estado.md`: marcar divergencia #5 como resuelta
