[🏠 Inicio](../README.md) > [📂 Monitorización](prometheus.md)

# prometheus-metrics-table — Visor de métricas en tabla HTML

Herramienta web **custom** (Flask + Python) para explorar y depurar las métricas expuestas por los exporters Prometheus. Muestra en una tabla HTML legible todos los nombres de métricas, sus tipos, sus labels y los valores distintos que ha tomado cada label.

## Problema que resuelve

Cuando se construyen dashboards en Grafana o se escriben queries PromQL, es necesario conocer qué labels tiene cada métrica y qué valores concretos están presentes. La alternativa nativa (leer el texto plano de `/metrics` de cada exporter) es muy difícil de leer con cientos de métricas. Esta herramienta parsea ese formato y lo presenta como tablas HTML navegables.

## Implementación

Imagen local construida desde `/mnt/usb-data/prometheus/prometheus-metrics-table/`.

```
prometheus-metrics-table.py   ← aplicación Flask
requirements.txt              ← flask==2.3.2, requests==2.31.0
Dockerfile                    ← imagen basada en python:3.11-slim
```

**Puerto**: `9102` (mapea al puerto interno `8000`)

## Uso

Accesible en `http://prometheus.home.lab` (vía nginx reverse proxy) o directamente en `http://192.168.1.101:9102`.

Muestra por defecto las métricas de todos los exporters configurados en la variable `TARGETS`. También acepta targets personalizados via query param:

```
http://prometheus.home.lab/?targets=http://node-exporter:9100/metrics
```

### Qué muestra por cada métrica

| Campo | Descripción |
|-------|-------------|
| **Nombre** | Nombre de la métrica (ej. `node_cpu_seconds_total`) |
| **Help** | Descripción del `# HELP` |
| **Type** | Tipo Prometheus: `gauge`, `counter`, `histogram`, `summary` |
| **Label** | Cada label key que tiene la métrica |
| **Distinct values** | Todos los valores distintos observados para ese label |

## Docker Compose

```yaml
prometheus-metrics-table:
  build:
    context: ./prometheus-metrics-table
    dockerfile: Dockerfile
  container_name: prometheus-metrics-table
  restart: unless-stopped
  environment:
    - PORT=8000
    - TARGETS=http://node-exporter:9100/metrics,http://cadvisor:8080/metrics,http://smartctl-exporter:9633/metrics,http://docker-metadata-exporter:9101/metrics
  ports:
    - "9102:8000"
  networks:
    - proxy_net
    - monitoring
```

### Variable TARGETS

Lista de URLs de endpoints `/metrics`, separadas por coma. Los targets se resuelven dentro de la red Docker `monitoring` usando los nombres de contenedor.

## Job en Prometheus

```yaml
- job_name: prometheus-metrics-table
  static_configs:
    - targets: ["prometheus-metrics-table:8000"]
```

> **Nota**: Prometheus scrapea esta herramienta pero no expone métricas propias — el job sirve para verificar que el contenedor está vivo (health check implícito).

## Referencia

- Código fuente: `/mnt/usb-data/prometheus/prometheus-metrics-table/`
- [Flask](https://flask.palletsprojects.com/)
- [Formato de texto Prometheus](https://prometheus.io/docs/instrumenting/exposition_formats/)
