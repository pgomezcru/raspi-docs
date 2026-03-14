[🏠 Inicio](../README.md) > [📂 Infraestructura](_index.md)

# Glances - Referencia Histórica

> **⚠️ NOTA IMPORTANTE**: Esta guía corresponde al [ADR-0002](../docs/adr/adr-0002-monitorizacion-sistema.md), que fue **superseded** por el [ADR-0005](../docs/adr/adr-0005-stack-monitoreo-prometheus-grafana.md).
> 
> **NO se implementará Glances** en el proyecto. Esta documentación se mantiene solo como referencia histórica del proceso de decisión.
> 
> Para la implementación actual, consulta [Prometheus](prometheus.md) y [Grafana](grafana.md).

---

## Concepto: Monitorizar el Host desde Docker

Para que un contenedor pueda ver la CPU, RAM y temperaturas del sistema anfitrión ("host"), necesitamos romper parcialmente el aislamiento del contenedor usando:

- `pid: host`: Permite al contenedor ver todos los procesos del sistema.
- Volúmenes `/proc` y `/sys`: Permiten leer estadísticas del kernel y hardware.

## Implementación (Docker Compose)

```yaml
version: "3"
services:
  glances:
    image: nicolargo/glances:latest-full
    container_name: glances
    restart: unless-stopped
    pid: host  # CRÍTICO: Permite ver procesos del host
    privileged: true # NECESARIO: Para leer S.M.A.R.T. de los discos físicos
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - /var/log:/var/log:ro
      - /dev:/dev:ro
    environment:
      - GLANCES_OPT=-w
    ports:
      - "61208:61208"
```

## Problemas Identificados

### 1. Dificultad de Personalización
- Los dashboards de Glances no son editables.
- No se pueden crear vistas personalizadas sin modificar el código fuente.

### 2. Configuración de S.M.A.R.T.
La lectura de métricas S.M.A.R.T. requiere instalar `pysmartctl` en un virtualenv debido a PEP-668:

```dockerfile
FROM nicolargo/glances:latest-full
USER root
RUN apk add --no-cache py3-virtualenv build-base python3-dev \
 && python3 -m venv /opt/venv \
 && /opt/venv/bin/pip install pySMART \
 && apk del build-base python3-dev
ENV PATH="/opt/venv/bin:$PATH"
USER glances
```

### 3. Limitaciones de Alertas
Glances no tiene un sistema robusto de alertas. Las notificaciones requieren exportar a sistemas externos (Prometheus, InfluxDB), en cuyo caso es más eficiente usar esos sistemas directamente.

## Razón del Rechazo

La complejidad de salir de la configuración "out-of-the-box" de Glances (especialmente para S.M.A.R.T. y alertas personalizadas) no justifica su uso frente a un stack más modular y potente como Prometheus + Grafana.
