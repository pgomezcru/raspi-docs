[🏠 Inicio](../README.md) > [📂 Monitoring](_index.md)

## Estado de contenedores Docker

A continuación se listan las métricas más relevantes para un panel "Estado de contenedores" en Grafana: uso, unidad y propuesta de presentación/Notas.

| ID | Métrica | Uso | Unidad | Presentación / Notas (Grafana) | Query (PromQL ejemplo) |
|----:|--------|-----|--------|---------------------------------|------------------------|
| 1 | cadvisor_version_info | Información de versión del exporter/contenedor | info | Single stat / texto con labels (image, version). | cadvisor_version_info |
| 2 | container_start_time_seconds | Uptime del contenedor | duration | Single stat (time since); formatear como duración. | time() - container_start_time_seconds{container!=""} |
| 3 | container_last_seen | Última vez visto por el exporter | timestamp | Single stat; detectar contenedores fugaces. | container_last_seen{container!=""} |
| 4 | container_cpu_usage_seconds_total | Consumo CPU acumulado | seconds / s (rate) | Time series % o rate; usar rate() para obtener CPU/s. | 100 * sum by(container,instance)(rate(container_cpu_usage_seconds_total[5m])) |
| 5 | container_cpu_system_seconds_total / container_cpu_user_seconds_total | CPU kernel / user | seconds / s | Series apiladas o barras por tipo (system/user). | sum by(container)(rate(container_cpu_system_seconds_total[5m])) |
| 6 | container_cpu_load_average_10s | Load promedio contenedor (10s) | ratio | Time series corta; útil para spikes. | container_cpu_load_average_10s{container!=""} |
| 7 | container_memory_usage_bytes | Memoria usada total (incluye cache) | bytes / % | Time series y single stat; convertir a MiB/GiB; comparar con limits. | container_memory_usage_bytes{container!=""} |
| 8 | container_memory_working_set_bytes | Working set (mem real en uso) | bytes | Preferible al usage para alertas; Time series. | container_memory_working_set_bytes{container!=""} |
| 9 | container_memory_max_usage_bytes | Pico de memoria | bytes | Single stat para dimensionamiento. | container_memory_max_usage_bytes{container!=""} |
| 10 | container_memory_failcnt / container_memory_failures_total | Fallos de memoria / intentos de asignación fallida | count | Alertas si aumentan; mostrar como counter/increase(). | increase(container_memory_failcnt[1h]) |
| 11 | container_fs_usage_bytes / container_fs_limit_bytes | Uso de disco por contenedor | bytes / % | Table por contenedor/mount; alertar si uso > 85%. | 100 * container_fs_usage_bytes / container_fs_limit_bytes |
| 12 | container_fs_reads_bytes_total / container_fs_writes_bytes_total | Throughput disco contenedor | bytes/s | Time series (rate) en B/s o MB/s. | rate(container_fs_reads_bytes_total[5m]) |
| 13 | container_fs_read_seconds_total / container_fs_write_seconds_total | Latencia I/O acumulada | seconds | Time series para calcular latencia promedio (time/ops). | rate(container_fs_read_seconds_total[5m]) / rate(container_fs_reads_total[5m]) |
| 14 | container_fs_io_current / container_fs_io_time_seconds_total | I/O en curso / tiempo I/O | count / seconds | Gauge + time series; detectar saturación. | container_fs_io_current{container!=""} |
| 15 | container_network_receive_bytes_total / container_network_transmit_bytes_total | Tráfico por contenedor | bytes/s | Time series por container interfaz; formatear en KB/s o MB/s. | rate(container_network_receive_bytes_total[5m]) by (container) |
| 16 | container_network_receive_errors_total / transmit_errors_total | Errores de red | count | Time series; alertar si errores sostenidos. | increase(container_network_receive_errors_total[5m]) |
| 17 | container_oom_events_total | OOMs por contenedor | count | Crítico: usar increase(...) para detectar eventos en ventana. | increase(container_oom_events_total[1h]) > 0 |
| 18 | container_tasks_state | Número de procesos por estado | count | Table/stacked (running/sleeping/zombie). | container_tasks_state{state="running"} |
| 19 | container_pressure_* (cpu/io/memory) | PSI por contenedor (esperas) | seconds | Time series; indica congestión de recursos. | rate(container_pressure_io_stalled_seconds_total[5m]) |
| 20 | container_scrape_error | Error en scrape del exporter | boolean | Single stat / table; marcar contenedores con scrape_error=1. | container_scrape_error{container!=""} |
| 21 | container_spec_memory_limit_bytes / container_spec_cpu_shares | Límites y reservas del contenedor | bytes / shares | Mostrar junto a usage para verificar límites. | container_spec_memory_limit_bytes{container!=""} |

Consideraciones rápidas para el panel de contenedores
- Variables: crear variables container, image, instance y pod (si aplica) para panels repetibles.  
- Unidades: Bytes (IEC) para memoria/disco; B/s para throughput; Percentage para CPU si se calcula %.  
- Filtrado: excluir métricas de contenedores de infraestructura (por ejemplo "POD" en k8s) o usar label container!~"^$".  
- Alertas: usar increase(...) o rate(...) con duraciones (5m/10m/1h) y condiciones "for" para evitar falsos positivos.  
- Persistencia y volumen: correlacionar container_fs_usage_bytes con los bind mounts montados (labels) para identificar origen del uso.
