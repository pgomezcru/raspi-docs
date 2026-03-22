[🏠 Inicio](../README.md) > [📂 Infraestructura](_index.md)

# Prometheus - Motor de Métricas

Prometheus es la base de datos de series temporales y el motor de recolección del stack de monitorización ([ADR-0005](../docs/adr/adr-0005-stack-monitoreo-prometheus-grafana.md)).

> **⚠️ Importante para Raspberry Pi (ARM64)**: Algunas imágenes Docker no tienen soporte oficial para ARM64. Esta guía usa alternativas compatibles con Raspberry Pi 4.

## Arquitectura

Prometheus **extrae** (pull) métricas de los **exporters** cada X segundos (scrape interval) y las almacena en su base de datos local.

```
Prometheus ---scrape---> node_exporter            (métricas del SO)
           ---scrape---> smartctl_exporter         (S.M.A.R.T. de discos)
           ---scrape---> cadvisor                  (métricas de contenedores)
           ---scrape---> docker_metadata_exporter  (container_id → nombre)
           ---scrape---> prometheus_metrics_table  (health check implícito)
           <---query---- Grafana                   (visualización)

docker_metadata_exporter ---lee---> Docker socket (container_id ↔ nombre)
prometheus_metrics_table ---scrape--> todos los exporters (exploración interactiva)
```

## Implementación (Docker Compose)

Crea `~/docker/monitoring/docker-compose.yml`:

```yaml
services:
  prometheus:
    image: prom/prometheus:latest    # Imagen Docker oficial de Prometheus
    container_name: prometheus      # Nombre del contenedor
    restart: unless-stopped         # Reinicia automáticamente a menos que se pare manualmente
    command:                        # Comandos/flags pasados al binario de Prometheus
      - '--config.file=/etc/prometheus/prometheus.yml'    # Ruta del fichero de configuración dentro del contenedor
      - '--storage.tsdb.path=/prometheus'                 # Ruta donde Prometheus guarda su base de datos TSDB
      - '--storage.tsdb.retention.time=30d'  # Retención de datos: mantener 30 días
      - '--web.console.libraries=/etc/prometheus/console_libraries'  # Plantillas de consola
      - '--web.console.templates=/etc/prometheus/consoles'          # Directorio de templates
      - '--web.enable-lifecycle'       # Habilita endpoints para recargar configuración en caliente
    volumes:
      - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:ro  # Bind-mount del fichero de config (solo lectura)
      - prometheus-data:/prometheus   # Volumen nombrado para persistencia de TSDB
    ports:
      - "9090:9090"                   # Mapea puerto 9090 del host al contenedor (UI/API de Prometheus)
    networks:
      - monitoring                    # Conexión a la red Docker "monitoring"

  node-exporter:
    image: quay.io/prometheus/node-exporter:latest # Exporter que expone métricas del sistema operativo - ARM64
    container_name: node-exporter
    restart: unless-stopped
    pid: host                         # Comparte el namespace de PID con el host (necesario para algunas métricas)
    command:
      - '--path.rootfs=/host'         # Rootfs a inspeccionar dentro del contenedor
      - '--path.procfs=/host/proc'    # Ruta a procfs del host
      - '--path.sysfs=/host/sys'      # Ruta a sysfs del host
      - '--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/)'  # Excluir mounts del host según regex
    volumes:
      - /:/host:ro,rslave              # Bind-mount de todo el filesystem del host (solo lectura, rslave)
    ports:
      - "9100:9100"                    # Puerto del exporter expuesto en el host
    networks:
      - monitoring

  smartctl-exporter:
    image: prometheuscommunity/smartctl-exporter-linux-arm64:master  # Exporter para leer S.M.A.R.T. de discos
    container_name: smartctl-exporter
    restart: unless-stopped
    privileged: true                 # Necesita privilegios para acceder a dispositivos de bloque
    volumes:
      - /dev:/host/dev:ro            # Acceso a dispositivos de bloque del host (solo lectura)
    ports:
      - "9633:9633"                  # Puerto del exporter
    networks:
      - monitoring

  cadvisor:
    image: gcr.io/cadvisor/cadvisor:v0.52.1     # Monitor de contenedores Docker - Cambiado por compatibilidad ARM64
    container_name: cadvisor
    restart: unless-stopped
    privileged: true                 # Requiere permisos elevados para acceder a métricas del sistema
    devices:
      - /dev/kmsg                    # Acceso a logs del kernel si se necesita
    volumes:
      - /:/rootfs:ro                 # Root filesystem del host (solo lectura)
      - /var/run:/var/run:ro         # Acceso a sockets de runtime (docker)
      - /sys:/sys:ro                 # sysfs del host
      - /var/lib/docker/:/var/lib/docker:ro  # Datos de Docker para mapear contenedores
      - /dev/disk/:/dev/disk:ro      # Acceso a información de discos
    ports:
      - "8081:8080"                  # Interfaz web/API de cAdvisor
    networks:
      - monitoring

volumes:
  prometheus-data:
    name: prometheus-data            # Volumen nombrado para persistencia de datos de Prometheus

networks:
  monitoring:
    name: monitoring                 # Red Docker usada por los servicios de monitorización
    driver: bridge
```

> **Arquitectura de Redes**:
> - La red `monitoring` es **interna** para comunicación entre Prometheus y sus exporters.
> - **No expongas** Prometheus directamente a internet (no usar proxy_net aquí).
> - Grafana (en otro compose) se conectará a esta red usando `external: true` para consultar métricas.
> - Solo Grafana debe estar en `proxy_net` para exposición vía Nginx.

## Archivo de Configuración

Crea `~/docker/prometheus/prometheus.yml`:

```yaml
global:
  scrape_interval: 15s  # Frecuencia de recolección de métricas
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'node-exporter'
    static_configs:
      - targets: ['node-exporter:9100']
        labels:
          instance: 'raspberry-pi' # Etiqueta personalizada para identificar la instancia

  - job_name: 'smartctl'
    static_configs:
      - targets: ['smartctl-exporter:9633']

  - job_name: 'cadvisor'
    static_configs:
      - targets: ['cadvisor:8081']
```

## Despliegue

```bash
cd ~/docker/prometheus
# Crear prometheus.yml (ver arriba)
docker-compose up -d
```

### Solución de Problemas (ARM64)

Si encuentras errores de "no matching manifest for linux/arm64/v8":

1. **Verificar arquitectura**:
   ```bash
   docker version | grep -i arch
   ```

2. **Imágenes alternativas para ARM64**:
   - **cAdvisor**: Usar `zcube/cadvisor:latest` (ya incluido arriba)
   - **node_exporter**: `prom/node-exporter:latest` tiene soporte ARM64 oficial
   - **Prometheus**: `prom/prometheus:latest` tiene soporte ARM64 oficial
   - **smartctl_exporter**: `prometheuscommunity/smartctl-exporter:latest` tiene soporte ARM64

3. **Forzar pull de arquitectura específica** (solo si es necesario):
   ```bash
   docker pull --platform linux/arm64 zcube/cadvisor:latest
   ```

## Verificación

1. **Acceder a Prometheus**: `http://<IP-RASPBERRY>:9090`
2. **Verificar targets**: `http://<IP-RASPBERRY>:9090/targets` (todos deben estar "UP")
3. **Consulta de prueba**: En la UI de Prometheus, ejecuta:
   ```promql
   node_cpu_seconds_total
   ```

## Mantenimiento Habitual

### Recargar Configuración (Sin Reiniciar)

Cuando edites `prometheus.yml`, puedes recargar la configuración sin reiniciar el contenedor:

```bash
# Opción 1: Usando el endpoint de lifecycle (requiere --web.enable-lifecycle)
curl -X POST http://localhost:9090/-/reload

# Opción 2: Enviar señal SIGHUP al proceso
docker exec prometheus kill -HUP 1
```

Verifica que la configuración es válida antes de recargar:
```bash
docker exec prometheus promtool check config /etc/prometheus/prometheus.yml
```

### Ver Logs

```bash
# Logs en tiempo real
docker logs -f prometheus

# Últimas 100 líneas
docker logs --tail 100 prometheus

# Logs de un exporter específico
docker logs -f node-exporter
```

### Actualizar Imágenes

```bash
# Detener stack
docker compose down

# Actualizar imágenes (mantiene datos en volúmenes)
docker compose pull

# Levantar con nuevas imágenes
docker compose up -d
```

### Backup de Datos de Prometheus

```bash
# Crear snapshot (requiere --web.enable-admin-api en command)
curl -X POST http://localhost:9090/api/v1/admin/tsdb/snapshot

# O hacer backup manual del volumen
docker run --rm -v prometheus-data:/data -v $(pwd):/backup alpine \
  tar czf /backup/prometheus-backup-$(date +%Y%m%d).tar.gz -C /data .
```

### Restaurar Backup

```bash
# Detener Prometheus
docker compose stop prometheus

# Restaurar datos
docker run --rm -v prometheus-data:/data -v $(pwd):/backup alpine \
  sh -c "cd /data && tar xzf /backup/prometheus-backup-YYYYMMDD.tar.gz"

# Reiniciar
docker compose start prometheus
```

### Limpiar Datos Antiguos Manualmente

Si necesitas liberar espacio antes de que expire la retención configurada (30d):

```bash
# Acceder al contenedor
docker exec -it prometheus sh

# Dentro del contenedor (ajustar fecha según necesidad)
# Esto borrará datos anteriores a hace 15 días
promtool tsdb delete -d /prometheus --time.max=15d
```

## Exporters Explicados

### node_exporter
Recolecta métricas del sistema operativo:
- CPU, RAM, red, disco
- Temperaturas (si el hardware las expone)
- Uptime, load average

**Métricas clave**:
- `node_cpu_seconds_total`: Uso de CPU
- `node_memory_MemAvailable_bytes`: RAM disponible
- `node_filesystem_avail_bytes`: Espacio en disco

### smartctl_exporter
Lee el estado S.M.A.R.T. de discos físicos:
- Sectores dañados
- Temperatura del disco
- Horas de funcionamiento
- Predicción de fallos

**Métricas clave**:
- `smartctl_device_smart_healthy`: 1 = OK, 0 = FALLO
- `smartctl_device_temperature`: Temperatura en °C

### cAdvisor
Monitoriza contenedores Docker:
- CPU y RAM por contenedor
- Tráfico de red
- I/O de disco

**Métricas clave**:
- `container_cpu_usage_seconds_total`
- `container_memory_usage_bytes`
- `container_network_receive_bytes_total`

## Alertas (Futuro)

Prometheus tiene un sistema de alertas nativo. Ejemplo de regla:

```yaml
# prometheus/alerts.yml
groups:
  - name: raspberry_pi
    rules:
      - alert: HighTemperature
        expr: node_hwmon_temp_celsius > 75
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Temperatura alta en {{ $labels.instance }}"
```

Añadir al `docker-compose.yml`:
```yaml
  alertmanager:
    image: prom/alertmanager:latest
    # ... configuración ...
```
## Borrado de datos antiguos

Sí — es posible, pero es destructivo: haz backup antes. Opciones y pasos concisos (elige 1 o 2).  

Precaución: NO ejecutes nada sin copia de /prometheus (TSDB). Comprueba versión de Prometheus; algunas APIs/funciones dependen de la versión.

1) Respaldo (obligatorio)
````bash
# desde la máquina que ejecuta Prometheus (ejemplo docker)
docker stop prometheus
docker cp prometheus:/prometheus ./prometheus-backup-$(date -I)
# o copiar la carpeta data si Prometheus no está en contenedor
````

2) Opción rápida — borrar series completas (todas las muestras de esas series)
- Si quieres eliminar por label (p. ej. la serie antigua instance="node-exporter:9100") y no te importa borrar todo su histórico:
````bash
# borra series que casen con el matcher (API admin)
curl -X POST -H "Content-Type: application/json" \
  http://127.0.0.1:9090/api/v1/admin/tsdb/delete_series \
  -d '{"matchers":["instance=\"node-exporter:9100\""]}'

# compactar/limpiar tombstones
curl -X POST http://127.0.0.1:9090/api/v1/admin/tsdb/clean_tombstones
````

Nota: delete_series borra la serie completa (todo el tiempo). Útil si quieres eliminar las series "malas" por etiqueta.

3) Opción precisa — borrar sólo hasta un timestamp (recomendado si quieres eliminar sólo histórico)
- Usar promtool tsdb delete (requiere detener Prometheus y tener promtool compatible):
````bash
# example: montar la carpeta data y ejecutar promtool en un contenedor
docker run --rm -v /ruta/local/prometheus-data:/prometheus prom/prometheus:latest \
  promtool tsdb delete --match='instance="node-exporter:9100"' \
    --start='2025-01-01T00:00:00Z' --end='2025-01-15T00:00:00Z' /prometheus
````

- Tras eso, arranca Prometheus; puede ser necesario ejecutar la API clean_tombstones y esperar a la compactación.

4) Alternativa NO destructiva (recomendada si dudas)
- Normalizar en consultas/dashboards usando label_replace/or o crear recording rules normalizadas; evita tocar TSDB histórico.

5) Checklist antes de proceder
- Hacer backup completo.
- Confirmar que la versión de Prometheus soporta la operación elegida.
- Probar la operación en un entorno de staging o con copia de datos.
- Después de borrado: ejecutar clean_tombstones y esperar a compactación; verificar en Explore que las series han desaparecido.
