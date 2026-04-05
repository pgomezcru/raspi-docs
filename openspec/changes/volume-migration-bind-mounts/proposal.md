## Why

AdGuard Home, Grafana y Prometheus almacenan sus datos en volúmenes Docker nombrados en lugar de bind mounts en `/mnt/usb-data/`. Esto viola la convención de AGENTS.md, hace los datos inaccesibles para inspección o backup manual, y rompe la estrategia de almacenamiento que centraliza todos los datos persistentes en el SSD.

## What Changes

- Migrar datos de `adguard-work` y `adguard-conf` → `/mnt/usb-data/adguard-home/work/` y `.../conf/`
- Migrar datos de `grafana-data` → `/mnt/usb-data/grafana/data/`
- Migrar datos de `prometheus-data` → `/mnt/usb-data/prometheus/data/`
- Actualizar los tres compose files para usar bind mounts en lugar de volúmenes nombrados
- Eliminar los volúmenes nombrados tras verificar la migración

## Capabilities

### New Capabilities
_(ninguna)_

### Modified Capabilities
_(ninguna — cambio de persistencia, no de requisitos funcionales)_

## Impact

- **compose/adguard-home/docker-compose.yml**: reemplazar volúmenes nombrados por bind mounts
- **compose/grafana/docker-compose.yml**: reemplazar `grafana-data` por bind mount
- **compose/prometheus/docker-compose.yml**: reemplazar `prometheus-data` por bind mount
- **Tiempo de inactividad**: necesario parar cada servicio durante la migración de datos
- **Riesgo**: pérdida de datos si la copia no se completa antes de recrear el contenedor → hacer snapshot previo
- **Permisos**: Grafana corre como UID 472, Prometheus como root (UID 0), ajustar permisos del directorio en SSD
