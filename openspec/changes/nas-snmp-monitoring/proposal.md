## Why

El fichero `infraestructura/NAS_monitoring.md` documenta la integración de monitorización del NAS Synology DS110j vía SNMP, pero no hay ningún exporter desplegado ni job configurado en Prometheus. El NAS es un componente crítico de la infraestructura (almacenamiento, backups) y no tiene visibilidad en Grafana.

## What Changes

- Habilitar SNMP v2c en el NAS Synology DS110j desde su panel de administración
- Añadir `snmp_exporter` al compose del stack de monitorización
- Configurar el fichero `snmp.yml` con el módulo para Synology
- Añadir job `snmp` en `prometheus.yml` apuntando al NAS (`192.168.1.102`)
- Crear dashboard en Grafana con métricas básicas del NAS (CPU, RAM, discos, estado de volúmenes)

## Capabilities

### New Capabilities
- `nas-monitoring`: visibilidad del estado del NAS (CPU, RAM, temperatura, volúmenes) en Prometheus/Grafana

### Modified Capabilities
_(ninguna)_

## Impact

- **compose/prometheus/docker-compose.yml**: añadir servicio `snmp-exporter`
- **compose/prometheus/prometheus/prometheus.yml**: añadir job `snmp` con target `192.168.1.102`
- **compose/prometheus/snmp_exporter/snmp.yml**: nuevo fichero de configuración de módulos SNMP
- **NAS**: habilitar SNMP en el panel de administración de Synology
- **Red**: tráfico SNMP UDP/161 entre Pi y NAS en la LAN
- **Dependencia**: requiere que el NAS esté encendido y accesible para que las métricas se recojan
