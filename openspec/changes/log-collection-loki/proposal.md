## Why

Las métricas del sistema se recolectan correctamente, pero los logs de los contenedores y del sistema operativo no. Cuando un servicio falla o se comporta de forma anómala, la única forma de investigar es hacer SSH a la Pi y ejecutar `docker logs` o `journalctl` manualmente. Con Loki + Promtail, los logs serían consultables desde Grafana, en el mismo lugar que las métricas.

## What Changes

- Añadir `loki` al compose de monitorización como backend de almacenamiento y consulta de logs
- Añadir `promtail` como agente de recolección que sigue los logs de los contenedores Docker
- Configurar el datasource de Loki en Grafana (provisioning)
- Crear un panel básico de exploración de logs en Grafana

## Capabilities

### New Capabilities
- `log-collection`: recolección, almacenamiento y consulta de logs de contenedores vía Loki + Promtail desde Grafana

### Modified Capabilities
_(ninguna)_

## Impact

- **compose/prometheus/docker-compose.yml** (o compose separado): añadir servicios `loki` y `promtail`
- **compose/prometheus/loki/**: nueva carpeta con `loki-config.yaml`
- **compose/prometheus/promtail/**: nueva carpeta con `promtail-config.yaml`
- **compose/grafana/provisioning/datasources/**: añadir datasource Loki
- **Almacenamiento**: Loki almacena logs en disco — definir ruta en `/mnt/usb-data/` y política de retención
- **Rendimiento**: Promtail tiene bajo consumo de CPU/RAM en ARM64; Loki puede ser más exigente — monitorizar impacto en la Pi
