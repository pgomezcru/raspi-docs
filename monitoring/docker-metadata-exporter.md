[🏠 Inicio](../README.md) > [📂 Monitorización](prometheus.md)

# docker-metadata-exporter — Exporter de metadatos de contenedores

Exporter Prometheus **custom** (escrito en Python) que expone metadatos de los contenedores Docker en ejecución. Su función principal es relacionar el `container_id` con el `container_name` en Grafana, ya que cAdvisor solo expone el ID hexadecimal del contenedor y no su nombre legible.

## Problema que resuelve

cAdvisor expone métricas con el label `id` del contenedor en formato hash (`/docker/a1b2c3...`). Sin metadatos adicionales, en Grafana las gráficas muestran hashes en lugar de nombres. Este exporter expone la tabla de correspondencia `container_id → container_name` para que Grafana pueda hacer joins via `label_replace` o `*on(container_id)*`.

## Implementación

Imagen local construida desde `/mnt/usb-data/prometheus/docker_metadata_exporter/`.

```
docker_metadata_exporter.py   ← lógica del exporter
Dockerfile                    ← imagen basada en python:3-alpine
```

**Puerto**: `9101`

### Métricas expuestas

Una única métrica de tipo `gauge`, siempre con valor `1`:

```
# HELP docker_container_info Container metadata (always 1)
# TYPE docker_container_info gauge
docker_container_info{container_id="<id_completo>",container_name="<nombre>"} 1
```

Ejemplo real:
```
docker_container_info{container_id="fee0e5e55d...",container_name="gitea"} 1
docker_container_info{container_id="ca871a86d4...",container_name="nginx_proxy"} 1
```

### Funcionamiento interno

1. En cada request a `/metrics`, abre conexión al socket Docker (`/var/run/docker.sock`)
2. Lista los contenedores en ejecución con `docker.containers.list()`
3. Genera una línea de métrica por contenedor con su ID completo y nombre

El endpoint `/` también responde con las métricas (además de `/metrics`) para facilitar el acceso desde el reverse proxy.

## Docker Compose

Definido en `compose/prometheus/docker-compose.yml` junto al resto del stack de monitorización:

```yaml
docker-metadata-exporter:
  build:
    context: ./docker_metadata_exporter
    dockerfile: Dockerfile
  container_name: docker-metadata-exporter
  restart: unless-stopped
  volumes:
    - /var/run/docker.sock:/var/run/docker.sock:ro
  ports:
    - "9101:9101"
  networks:
    - proxy_net
    - monitoring
```

## Job en Prometheus

```yaml
- job_name: docker-metadata-exporter
  static_configs:
    - targets: ["docker-metadata-exporter:9101"]
```

## Seguridad

El contenedor tiene acceso de **solo lectura** al socket Docker (`docker.sock:ro`). Aun así, la API de Docker con acceso de lectura permite listar contenedores, imágenes y configuraciones — no otorgar este acceso a contenedores no confiables.

## Referencia

- Código fuente: `/mnt/usb-data/prometheus/docker_metadata_exporter/`
- [Docker SDK for Python](https://docker-py.readthedocs.io/en/stable/)
