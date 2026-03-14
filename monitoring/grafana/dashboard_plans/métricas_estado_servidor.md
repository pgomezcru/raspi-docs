## Estado del servidor

A continuación se listan las métricas más relevantes para componer un panel de "Estado de la Raspberry Pi" en Grafana: uso, unidad y propuesta de presentación/Notas.

| ID | Métrica | Uso | Unidad | Presentación / Notas (Grafana) | Query (PromQL ejemplo) |
|----:|--------|-----|--------|---------------------------------|------------------------|
| 1 | node_cpu_seconds_total (mode=idle) / node_cpu_seconds_total | Monitorizar carga CPU / %CPU | % | Time series; formatear como porcentaje (1 d.p.); thresholds (75% / 90%). | 100 * (1 - avg by(instance)(rate(node_cpu_seconds_total{mode="idle"}[5m]))) |
| 2 | node_load1, node_load5, node_load15 | Load average (1/5/15m) | ratio (nº de procesos) | Gauge + Time series; mostrar ratio load/cores para interpretar (ver machine_cpu_cores). | node_load1 or node_load1 / machine_cpu_cores | 
| 3 | machine_cpu_cores | Núcleos lógicos | cores | Single stat; útil para calcular ratios. | avg by(instance)(machine_cpu_cores) |
| 4 | node_cpu_scaling_frequency_hertz, node_cpu_frequency_max_hertz | Throttling y frecuencia | Hz (mostrar en MHz) | Time series; formatear en MHz (divide por 1e6). | avg by(instance)(node_cpu_scaling_frequency_hertz) / 1e6 |
| 5 | node_memory_MemAvailable_bytes, node_memory_MemTotal_bytes | RAM disponible vs total | bytes / % | Gauge (porcentaje) y Time series (bytes); convertir a GiB para legibilidad. | 100 * (1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) |
| 6 | node_memory_SwapTotal_bytes, node_vmstat_pswpin, node_vmstat_pswpout | Swap y swapping | bytes / pages | Time series; mostrar activity (pages/s) con rate/increase; alerta si swap activo sostenido. | increase(node_vmstat_pswpout[5m]) |
| 7 | node_filesystem_avail_bytes, node_filesystem_size_bytes | Uso de disco por mount | bytes / % | Table o Bar gauge por mount; mostrar % y tamaño legible (GiB); filtrar fstype != "tmpfs". | 100 * (1 - node_filesystem_avail_bytes / node_filesystem_size_bytes) |
| 8 | node_disk_read_bytes_total, node_disk_written_bytes_total | Throughput de disco | bytes/s (B/s) | Time series; formatear en MB/s o MiB/s; añadir IOPS con reads/writes_completed counters. | rate(node_disk_read_bytes_total[5m]) / 1024 / 1024 |
| 9 | node_disk_io_time_seconds_total, node_disk_io_now | Latencia / I/O en curso | seconds / count | Time series; convertir io_time a % de ocupación sobre ventana; node_disk_io_now como gauge count. | 100 * rate(node_disk_io_time_seconds_total[5m]) / 5 |
| 10 | node_filesystem_files_free, node_filesystem_files | Inodos | count / % | Gauge o table; mostrar % inodos libres. | 100 * node_filesystem_files_free / node_filesystem_files |
| 11 | node_network_receive_bytes_total, node_network_transmit_bytes_total | Tráfico por interfaz | bytes/s | Time series por device; formatear en Mbps o MB/s según link. | rate(node_network_receive_bytes_total[5m]) by (device) |
| 12 | node_network_receive_drop_total, node_network_transmit_drop_total | Paquetes descartados | packets/s | Time series; alertar si drops sostenidos. | rate(node_network_receive_drop_total[5m]) by (device) |
| 13 | node_procs_running, node_procs_blocked | Procesos en ejecución y bloqueados | count | Time series; node_procs_blocked >0 sostenido indica I/O problem. | node_procs_blocked |
| 14 | node_sockstat_TCP_inuse, node_sockstat_TCP_tw | Conexiones TCP y TIME_WAIT | count | Table/Single stat; ordenar por valor; vigilar TIME_WAIT altos. | node_sockstat_TCP_inuse |
| 15 | node_hwmon_temp_celsius, node_thermal_zone_temp | Temperaturas (CPU) | °C | Gauge + Time series; thresholds (70°C amarillo / 80°C rojo). | node_hwmon_temp_celsius |
| 16 | node_boot_time_seconds / node_time_seconds | Uptime | seconds / duration | Single stat; formatear como duración (d hh:mm). | time() - node_boot_time_seconds |
| 17 | node_vmstat_oom_kill, container_oom_events_total | OOMs sistema/contenedores | count | Counter; usar increase(...) para detectar OOMs en ventana (ej. 1h). | increase(node_vmstat_oom_kill[1h]) or increase(container_oom_events_total[1h]) > 0 |
| 18 | node_scrape_collector_success, node_scrape_collector_duration_seconds | Salud del exporter | boolean / seconds | Table con iconos; marcar collectors con success=0 como fallidos y mostrar durations. | node_scrape_collector_success |

Consideraciones para la presentación en Grafana (prácticas y rápidas)
- Unidades: configurar unidad en el panel (Percentage, Bytes (IEC), B/s, ms/seconds, Celsius, Short) en "Field options" para que Grafana muestre valores legibles automáticamente.
- Conversiones: mostrar bytes como GiB usando /1024^3 o seleccionar "Bytes (IEC)" en unidades; frecuencias -> MHz (Hz/1e6).
- Rango temporal y resolución: usar 5m-1h para alertas y 24h para tendencias; ajustar min interval/step del datasource si hay many series.
- Variables: crear variables para instance, device, mountpoint y fstype (permiten panels repetibles y filtrado dinámico).
- Filtrado: filtrar node_filesystem por fstype != "tmpfs" y por mountpoint (evitar pseudo-filesystems).
- Transformaciones: calcular % en Grafana si la query devuelve numerador/denominador o usar PromQL que devuelva ya la % (mejor).
- Thresholds y colores: definir thresholds claros (ejemplos en la tabla); usar status mappings (OK/WARN/CRIT) para single stat.
- Paneles de resumen: crear un "Health overview" single stat compuesto (0/1) usando booleanas PromQL OR para resumir condiciones críticas.
- Legibilidad: usar leyendas con {{instance}}/{{device}} y ordenar tablas por importancia; limitar decimales (1–2 d.p.) para lecturas humanas.
- Alertas: definir alertas en Prometheus/Alertmanager o en Grafana con reglas claras y duraciones (ej. for 5m/10m).

