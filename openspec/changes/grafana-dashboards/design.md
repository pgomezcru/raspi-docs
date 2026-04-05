## Context

Grafana (`v12.3.1`) está desplegado con un bind mount de provisioning en `compose/grafana/provisioning/`. El directorio existe pero contiene solo el datasource de Prometheus. No hay dashboards configurados. Los datos están disponibles desde 5 exporters activos: node-exporter (sistema), cadvisor (containers), smartctl-exporter (SMART), docker-metadata-exporter (metadatos), prometheus-metrics-table (tabla de métricas).

## Goals / Non-Goals

**Goals:**
- Dashboards para los tres casos de uso principales: estado del sistema, contenedores Docker, salud del disco
- Los dashboards se cargan automáticamente al arrancar Grafana (provisioning como código)
- Los ficheros JSON de dashboards están versionados en el repo

**Non-Goals:**
- Dashboard para el NAS (pendiente del change `nas-snmp-monitoring`)
- Dashboard para logs (pendiente del change `log-collection-loki`)
- Alertas en Grafana (puede añadirse después)
- Dashboards interactivos con variables dinámicas complejas (empezar con dashboards simples y útiles)

## Decisions

### 1. Dashboards como código (provisioning)
**Decisión**: todos los dashboards se definen como JSON en `compose/grafana/provisioning/dashboards/` y se cargan mediante la configuración de provisioning de Grafana.
**Razón**: los dashboards creados solo en la UI de Grafana se pierden si el volumen se borra o migra. El provisioning garantiza que los dashboards son reproducibles y están bajo control de versiones.
**Trade-off**: editar dashboards requiere exportar el JSON desde la UI y guardarlo en el repo, un paso extra comparado con guardar directamente en la UI.

### 2. Tres dashboards iniciales
| Dashboard | Fuente principal | Métricas clave |
|-----------|-----------------|----------------|
| Sistema | node-exporter | CPU %, RAM %, disco %, red I/O, uptime |
| Contenedores Docker | cadvisor | CPU/RAM por container, estado up/down |
| Almacenamiento SMART | smartctl-exporter | Temperatura disco, horas encendido, estado SMART |

### 3. Usar dashboards de Grafana Community como base
**Decisión**: partir de dashboards importados de `grafana.com/grafana/dashboards` (IDs conocidos para node-exporter y cadvisor) y adaptarlos.
**Razón**: más rápido que crear desde cero; los dashboards de la comunidad ya tienen las métricas correctas mapeadas.

## Risks / Trade-offs

- **Actualización de dashboards**: modificar un dashboard provisionado desde fichero requiere editar el JSON en el repo y recrear el contenedor (o usar la API de recarga). En Grafana 12, los dashboards provisionados se pueden editar en la UI pero los cambios no se persisten automáticamente al fichero.
- **Compatibilidad de versiones**: los JSON de dashboards de Grafana Community pueden tener campos no compatibles con la versión desplegada. Verificar con la versión exacta (`12.3.1`).

## Migration Plan

1. Crear `compose/grafana/provisioning/dashboards/dashboard.yml` con la configuración del proveedor
2. Descargar/exportar JSON para los 3 dashboards iniciales
3. Guardar en `compose/grafana/provisioning/dashboards/*.json`
4. Redesplegar Grafana: `deploy.sh grafana`
5. Verificar en la UI que los dashboards aparecen en la carpeta provisionada
6. Documentar en `monitoring/grafana.md`: cómo añadir nuevos dashboards al provisioning
