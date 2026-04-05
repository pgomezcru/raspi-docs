## Context

Tres servicios usan volúmenes Docker nombrados: `adguard-work`, `adguard-conf` (AdGuard), `grafana-data` (Grafana), `prometheus-data` (Prometheus). Los datos de estos volúmenes residen en `/var/lib/docker/volumes/` en la Pi. La convención de AGENTS.md exige bind mounts en `/mnt/usb-data/docker-root/<container>/`. Los directorios en `/mnt/usb-data/` para estos servicios existen pero contienen solo config/provisioning parcial, no los datos principales.

## Goals / Non-Goals

**Goals:**
- Los datos de AdGuard, Grafana y Prometheus persisten en bind mounts bajo `/mnt/usb-data/`
- Los volúmenes nombrados se eliminan tras la migración exitosa
- Los compose files reflejan la nueva configuración de almacenamiento

**Non-Goals:**
- Migrar otros servicios que ya usan bind mounts correctamente (nginx, gitea, homarr)
- Cambiar la estructura interna de los datos (solo cambia dónde se almacenan)

## Decisions

### 1. Migración con docker cp + parada de servicio
**Decisión**: parar cada servicio, copiar datos del volumen nombrado al directorio SSD, actualizar el compose, y arrancar.
**Razón**: garantiza consistencia de datos (sin escrituras concurrentes durante la copia). Para Prometheus y Grafana el riesgo de corrupción al copiar en caliente es bajo, pero para AdGuard la consistencia de la base de datos de estadísticas es importante.
**Alternativa**: `docker run --rm -v <volumen>:/source -v <destino>:/dest alpine cp -a /source/. /dest/` — también válido.

### 2. Permisos específicos por servicio
**Decisión**: ajustar permisos del directorio destino antes de arrancar el contenedor.
**Razón**: Grafana corre como UID 472 (usuario grafana), Prometheus como UID 0 (root configurado en compose). Sin los permisos correctos, los contenedores fallarán al arrancar.

| Servicio | UID | Permisos directorio |
|----------|-----|---------------------|
| AdGuard  | root (0) | `root:root 755` |
| Grafana  | 472 | `472:472 755` |
| Prometheus | 0 (root) | `root:root 755` |

### 3. Migrar un servicio a la vez
**Decisión**: migrar en orden: Prometheus → Grafana → AdGuard.
**Razón**: reducir el tiempo total de inactividad por servicio. AdGuard al final porque su parada implica pérdida de resolución DNS local.

## Risks / Trade-offs

- **AdGuard offline = sin DNS local**: durante la migración de AdGuard, la resolución DNS de `*.home.lab` no funciona. Mitigación: realizarlo en horario de baja actividad; la migración debería durar <5 minutos.
- **Pérdida de datos históricos de Prometheus**: si la copia falla a mitad, reiniciar Prometheus sin datos no es crítico (recomienza a recoger métricas), pero se pierde el historial. Mitigación: verificar que el directorio destino tiene datos antes de borrar el volumen original.
- **Estado de Grafana**: las sesiones activas se pierden al reiniciar el contenedor (irrelevante en uso doméstico).

## Migration Plan

Para cada servicio (Prometheus, Grafana, AdGuard):
1. `docker stop <container>`
2. `mkdir -p /mnt/usb-data/<servicio>/data && chown <uid>:<gid> ...`
3. `docker run --rm -v <volumen>:/source -v /mnt/usb-data/<servicio>/data:/dest alpine sh -c "cp -a /source/. /dest/"`
4. Actualizar `compose/<servicio>/docker-compose.yml`: reemplazar volumen nombrado por bind mount
5. `bash ~/raspi-docs/compose/deploy.sh <servicio>`
6. Verificar que el servicio arranca y los datos son accesibles
7. `docker volume rm <volumen>` (solo tras verificación exitosa)

## Open Questions

- ¿Necesitamos conservar el historial de métricas de Prometheus o es aceptable empezar desde cero?
- ¿Hay datos útiles en `adguard-work` (estadísticas DNS) que merezca la pena preservar?
