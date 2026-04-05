## Why

El stack Prometheus + Grafana está desplegado y recolectando métricas de 5 exporters, pero no hay ningún dashboard configurado. La infraestructura de monitorización está operativa pero es invisible: no hay forma rápida de ver el estado del sistema sin hacer queries manuales en Prometheus.

## What Changes

- Crear dashboards JSON para: métricas de sistema (node-exporter), contenedores Docker (cadvisor), salud de almacenamiento (smartctl)
- Configurar el provisioning de Grafana para cargar los dashboards automáticamente desde ficheros JSON en el repo
- Almacenar los dashboards como código en `compose/grafana/provisioning/dashboards/`

## Capabilities

### New Capabilities
_(ninguna)_

### Modified Capabilities
- `monitoring-stack`: se añade visualización mediante dashboards provisionados como código

## Impact

- **compose/grafana/provisioning/**: añadir dashboards JSON y configuración de provisioning
- **compose/grafana/docker-compose.yml**: el bind mount de provisioning ya está configurado
- **Grafana**: los dashboards se cargan automáticamente al arrancar; cambios requieren recrear el contenedor o recargar la API
- **Mantenimiento**: los dashboards se editan en el repo como JSON, no directamente en la UI de Grafana (evita pérdida de cambios)
