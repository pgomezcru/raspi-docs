## Context

El stack de Prometheus + Grafana recolecta métricas pero no logs. Los logs de los contenedores Docker están disponibles en el socket de Docker y como ficheros JSON en `/var/lib/docker/containers/`. Grafana ya está desplegado y soporta Loki como datasource nativo. Loki + Promtail es el stack de logs nativo del ecosistema Grafana y está optimizado para trabajar junto a Prometheus.

## Goals / Non-Goals

**Goals:**
- Logs de todos los contenedores Docker disponibles en Grafana con LogQL
- Correlación visual métricas + logs en el mismo panel de Grafana
- Bajo impacto en recursos de la Raspberry Pi 4 (ARM64)

**Non-Goals:**
- Logs del sistema operativo (journald) en esta fase — añadir después si se necesita
- Parseo/indexado avanzado de logs estructurados
- Alertas basadas en logs
- Retención de logs >7 días (espacio limitado en SSD)

## Decisions

### 1. Loki + Promtail (no Grafana Agent)
**Decisión**: usar Loki y Promtail por separado en lugar del Grafana Agent unificado.
**Razón**: los componentes individuales tienen menor consumo de memoria en ARM64, la configuración es más transparente, y Promtail está maduro y ampliamente documentado.
**Alternativa descartada**: Grafana Agent — más moderno pero más pesado y con una curva de configuración mayor.

### 2. Loki en modo monolítico (single binary)
**Decisión**: usar la imagen oficial `grafana/loki` en modo de proceso único (no distribuido).
**Razón**: el modo distribuido es para alta escala. En un homelab con una sola Pi, el modo monolítico es suficiente y mucho más simple.

### 3. Almacenamiento de Loki en /mnt/usb-data/
**Decisión**: bind mount en `/mnt/usb-data/loki/` con retención de 7 días.
**Razón**: consistente con la convención de AGENTS.md. 7 días es suficiente para diagnóstico doméstico y controla el uso de disco.

### 4. Promtail recolecta solo logs de contenedores Docker
**Decisión**: Promtail configurado con `docker_sd_configs` para descubrir automáticamente los contenedores y recoger sus logs.
**Razón**: cubre el caso de uso principal (logs de servicios). Journald puede añadirse después.

### 5. Añadir al compose de prometheus (no compose separado)
**Decisión**: añadir Loki y Promtail al compose existente `compose/prometheus/docker-compose.yml`.
**Razón**: mantiene toda la infraestructura de observabilidad en un único compose, coherente con el enfoque actual.

## Risks / Trade-offs

- **Uso de memoria de Loki**: Loki puede consumir 200-400MB de RAM en ARM64 con carga baja. La Pi 4 tiene 4GB, pero hay que monitorizar el impacto.
- **Espacio en disco**: con 7 días de retención y el volumen de logs del homelab, el impacto debería ser <500MB. Establecer el límite en la configuración de Loki.
- **Permiso de acceso a logs Docker**: Promtail necesita acceso a `/var/lib/docker/containers/` — requiere que el contenedor corra con permisos adecuados o un bind mount con la ruta correcta.

## Migration Plan

1. Añadir servicios `loki` y `promtail` en `compose/prometheus/docker-compose.yml`
2. Crear `compose/prometheus/loki/loki-config.yaml` con retención 7d y almacenamiento en `/mnt/usb-data/loki/`
3. Crear `compose/prometheus/promtail/promtail-config.yaml` con `docker_sd_configs`
4. Crear `compose/grafana/provisioning/datasources/loki.yaml`
5. Redesplegar stacks: `deploy.sh prometheus && deploy.sh grafana`
6. Verificar en Grafana: Explore → datasource Loki → logs aparecen
7. Documentar en `monitoring/`: nueva sección para Loki/Promtail

## Open Questions

- ¿Qué política de retención configurar en Loki? (propuesta: 7 días)
- ¿Añadir etiquetas de Promtail personalizadas por servicio para facilitar el filtrado?
