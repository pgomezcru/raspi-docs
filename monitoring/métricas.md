# Métricas disponibles en prometheus

[🏠 Inicio](../README.md) > [📂 Monitoring](_index.md)

En esta página se listan las métricas que prometheus puede recoger de los distintos exporters instalados en la infraestructura. Es el resultado de ejecutar el script list_metrics.sh que está en la carpeta de prometheus en la raspberry pi.

## Listado

> Nota: se ha añadido una columna "ID" (entera) para identificar cada métrica de forma única. Para poblar automáticamente las IDs en la tabla principal use el script `monitoring/scripts/assign_metric_ids.py` (hace backup antes de modificar).

| ID | Metric | Help | Type | Uso |
|----:|--------|------|------|-----|
| `cadvisor_version_info` | A metric with a constant '1' value labeled by kernel version, OS version, docker version, cadvisor version & cadvisor revision. | gauge | Información de versiones del sistema. Útil para verificar qué versión de cAdvisor y Docker estás ejecutando. |
| `container_blkio_device_usage_total` | Blkio Device bytes usage | counter | Total de bytes leídos/escritos por contenedor en disco. Para detectar contenedores con alto I/O que desgastan la SD. |
| `container_cpu_load_average_10s` | Value of container cpu load average over the last 10 seconds. | gauge | Carga promedio de CPU del contenedor en los últimos 10s. Identifica picos de carga momentáneos. |
| `container_cpu_load_d_average_10s` | Value of container cpu load.d average over the last 10 seconds. | gauge | Carga de CPU del contenedor (load.d) en 10s. Variante de la métrica anterior. |
| `container_cpu_system_seconds_total` | Cumulative system cpu time consumed in seconds. | counter | Tiempo de CPU en modo kernel por contenedor. Alto valor indica muchas syscalls (I/O, red). |
| `container_cpu_usage_seconds_total` | Cumulative cpu time consumed in seconds. | counter | **Métrica clave**: Tiempo total de CPU usado. Para gráficas de % CPU por contenedor con rate(). |
| `container_cpu_user_seconds_total` | Cumulative user cpu time consumed in seconds. | counter | Tiempo de CPU en modo usuario. Identifica contenedores con procesamiento intensivo. |
| `container_fs_inodes_free` | Number of available Inodes | gauge | Inodos libres en filesystem del contenedor. Crucial en sistemas con muchos archivos pequeños. |
| `container_fs_inodes_total` | Number of Inodes | gauge | Total de inodos disponibles. Compara con inodes_free para detectar agotamiento. |
| `container_fs_io_current` | Number of I/Os currently in progress | gauge | Operaciones I/O en curso. Valores altos indican cuellos de botella en disco. |
| `container_fs_io_time_seconds_total` | Cumulative count of seconds spent doing I/Os | counter | Tiempo total haciendo I/O. Para calcular % tiempo en I/O. |
| `container_fs_io_time_weighted_seconds_total` | Cumulative weighted I/O time in seconds | counter | Tiempo I/O ponderado por operaciones en cola. Detecta saturación de disco. |
| `container_fs_limit_bytes` | Number of bytes that can be consumed by the container on this filesystem. | gauge | Límite de espacio asignado al contenedor. Para alertas de cuotas. |
| `container_fs_reads_bytes_total` | Cumulative count of bytes read | counter | Bytes leídos desde disco. Panel de throughput de lectura por contenedor. |
| `container_fs_read_seconds_total` | Cumulative count of seconds spent reading | counter | Tiempo total leyendo. Para calcular latencia promedio de lectura. |
| `container_fs_reads_merged_total` | Cumulative count of reads merged | counter | Lecturas fusionadas por el kernel. Indica eficiencia del I/O scheduler. |
| `container_fs_reads_total` | Cumulative count of reads completed | counter | Número de operaciones de lectura. Para IOPS de lectura. |
| `container_fs_sector_reads_total` | Cumulative count of sector reads completed | counter | Sectores leídos (512 bytes). Nivel bajo de lectura de disco. |
| `container_fs_sector_writes_total` | Cumulative count of sector writes completed | counter | Sectores escritos. Monitoriza desgaste de SD/SSD. |
| `container_fs_usage_bytes` | Number of bytes that are consumed by the container on this filesystem. | gauge | **Métrica clave**: Espacio usado por contenedor. Alertas de disco lleno. |
| `container_fs_writes_bytes_total` | Cumulative count of bytes written | counter | Bytes escritos a disco. Panel de throughput de escritura. |
| `container_fs_write_seconds_total` | Cumulative count of seconds spent writing | counter | Tiempo total escribiendo. Calcula latencia de escritura. |
| `container_fs_writes_merged_total` | Cumulative count of writes merged | counter | Escrituras fusionadas. Eficiencia del I/O scheduler. |
| `container_fs_writes_total` | Cumulative count of writes completed | counter | Operaciones de escritura completadas. IOPS de escritura. |
| `container_last_seen` | Last time a container was seen by the exporter | gauge | Timestamp de última vez visto. Detecta contenedores que se reinician. |
| `container_memory_cache` | Number of bytes of page cache memory. | gauge | Memoria usada como caché de archivos. Se libera bajo presión. |
| `container_memory_failcnt` | Number of memory usage hits limits | counter | Veces que el contenedor alcanzó su límite de RAM. Indica necesidad de más memoria. |
| `container_memory_failures_total` | Cumulative count of memory allocation failures. | counter | Fallos al asignar memoria. Indica presión extrema de RAM. |
| `container_memory_kernel_usage` | Size of kernel memory allocated in bytes. | gauge | Memoria del kernel usada por el contenedor (slabs, page tables). |
| `container_memory_mapped_file` | Size of memory mapped files in bytes. | gauge | Archivos mapeados en memoria (mmap). Común en bases de datos. |
| `container_memory_max_usage_bytes` | Maximum memory usage recorded in bytes | gauge | Pico máximo de memoria usado. Para dimensionar límites. |
| `container_memory_rss` | Size of RSS in bytes. | gauge | Memoria residente anónima (no caché). La "real" usada por procesos. |
| `container_memory_swap` | Container swap usage in bytes. | gauge | Swap usado. Valor >0 indica RAM insuficiente (muy lento en RPi). |
| `container_memory_total_active_file_bytes` | Current total active file in bytes. | gauge | Caché de archivos activamente usado. |
| `container_memory_total_inactive_file_bytes` | Current total inactive file in bytes. | gauge | Caché de archivos inactivo (candidato a liberarse). |
| `container_memory_usage_bytes` | Current memory usage in bytes, including all memory regardless of when it was accessed | gauge | **Métrica clave**: Memoria total usada (incluye caché). Para gráficas de uso de RAM. |
| `container_memory_working_set_bytes` | Current working set in bytes. | gauge | **Mejor que usage**: Working set (excluye caché inactivo). Uso "real" de memoria. |
| `container_network_receive_bytes_total` | Cumulative count of bytes received | counter | **Métrica clave**: Bytes recibidos por red. Panel de tráfico de entrada. |
| `container_network_receive_errors_total` | Cumulative count of errors encountered while receiving | counter | Errores al recibir paquetes. Indica problemas de red. |
| `container_network_receive_packets_dropped_total` | Cumulative count of packets dropped while receiving | counter | Paquetes descartados en recepción. Saturación de interfaz. |
| `container_network_receive_packets_total` | Cumulative count of packets received | counter | Paquetes recibidos. Para calcular PPS (packets per second). |
| `container_network_transmit_bytes_total` | Cumulative count of bytes transmitted | counter | **Métrica clave**: Bytes transmitidos. Panel de tráfico de salida. |
| `container_network_transmit_errors_total` | Cumulative count of errors encountered while transmitting | counter | Errores al transmitir. Problemas de red o congestión. |
| `container_network_transmit_packets_dropped_total` | Cumulative count of packets dropped while transmitting | counter | Paquetes descartados en transmisión. Saturación. |
| `container_network_transmit_packets_total` | Cumulative count of packets transmitted | counter | Paquetes transmitidos. PPS de salida. |
| `container_oom_events_total` | Count of out of memory events observed for the container | counter | **Crítico**: Contenedor matado por falta de RAM. Aumenta límites. |
| `container_pressure_cpu_stalled_seconds_total` | Total time duration no tasks in the container could make progress due to CPU congestion. | counter | Tiempo bloqueado esperando CPU. Indica contenedor throttled. |
| `container_pressure_cpu_waiting_seconds_total` | Total time duration tasks in the container have waited due to CPU congestion. | counter | Tiempo esperando CPU. PSI (Pressure Stall Information). |
| `container_pressure_io_stalled_seconds_total` | Total time duration no tasks in the container could make progress due to IO congestion. | counter | Tiempo bloqueado por I/O. Disco lento o saturado. |
| `container_pressure_io_waiting_seconds_total` | Total time duration tasks in the container have waited due to IO congestion. | counter | Tiempo esperando I/O. Identifica cuellos de botella. |
| `container_pressure_memory_stalled_seconds_total` | Total time duration no tasks in the container could make progress due to memory congestion. | counter | Tiempo bloqueado por falta de RAM. Swapping intenso. |
| `container_pressure_memory_waiting_seconds_total` | Total time duration tasks in the container have waited due to memory congestion. | counter | Tiempo esperando memoria. Presión de RAM. |
| `container_scrape_error` | 1 if there was an error while getting container metrics, 0 otherwise | gauge | Error al scrapear métricas. Verifica que el contenedor existe. |
| `container_spec_cpu_period` | CPU period of the container. | gauge | Período de cuota de CPU (microsegundos). Parte de CPU limits. |
| `container_spec_cpu_shares` | CPU share of the container. | gauge | Shares de CPU asignadas. Peso relativo entre contenedores. |
| `container_spec_memory_limit_bytes` | Memory limit for the container. | gauge | **Importante**: Límite de RAM configurado. Compara con usage. |
| `container_spec_memory_reservation_limit_bytes` | Memory reservation limit for the container. | gauge | Soft limit de memoria. Garantía mínima. |
| `container_spec_memory_swap_limit_bytes` | Memory swap limit for the container. | gauge | Límite de swap. Debería ser 0 en producción RPi. |
| `container_start_time_seconds` | Start time of the container since unix epoch in seconds. | gauge | Timestamp de inicio. Para calcular uptime del contenedor. |
| `container_tasks_state` | Number of tasks in given state | gauge | Procesos en diferentes estados (running, sleeping). Debug de comportamiento. |
| `go_gc_duration_seconds` | A summary of the pause duration of garbage collection cycles. | summary | Tiempo de pausa del GC de Go. Para tuning de servicios Go. |
| `go_gc_duration_seconds_count` |  |  | Contador de ciclos de GC. |
| `go_gc_duration_seconds_sum` |  |  | Suma total de tiempo en GC. |
| `go_gc_gogc_percent` | Heap size target percentage configured by the user, otherwise 100. This value is set by the GOGC environment variable, and the runtime/debug.SetGCPercent function. Sourced from /gc/gogc:percent | gauge | Target de heap del GC. Configuración de memoria de Go. |
| `go_gc_gomemlimit_bytes` | Go runtime memory limit configured by the user, otherwise math.MaxInt64. This value is set by the GOMEMLIMIT environment variable, and the runtime/debug.SetMemoryLimit function. Sourced from /gc/gomemlimit:bytes | gauge | Límite de memoria del runtime de Go. |
| `go_goroutines` | Number of goroutines that currently exist. | gauge | Goroutines activas. Detecta goroutine leaks en servicios Go. |
| `go_info` | Information about the Go environment. | gauge | Versión de Go usada. Metadata. |
| `go_memstats_alloc_bytes` | Number of bytes allocated and still in use. | gauge | Bytes asignados actualmente en heap de Go. |
| `go_memstats_alloc_bytes_total` | Total number of bytes allocated, even if freed. | counter | Total histórico de allocations. Para rate de allocations. |
| `go_memstats_buck_hash_sys_bytes` | Number of bytes used by the profiling bucket hash table. | gauge | Memoria del profiler. Despreciable. |
| `go_memstats_frees_total` | Total number of frees. | counter | Total de liberaciones de memoria. |
| `go_memstats_gc_sys_bytes` | Number of bytes used for garbage collection system metadata. | gauge | Overhead del GC en memoria. |
| `go_memstats_heap_alloc_bytes` | Number of heap bytes allocated and still in use. | gauge | Heap actualmente en uso. Métrica clave de memoria Go. |
| `go_memstats_heap_idle_bytes` | Number of heap bytes waiting to be used. | gauge | Heap idle (reservado pero no usado). |
| `go_memstats_heap_inuse_bytes` | Number of heap bytes that are in use. | gauge | Heap realmente usado por objetos. |
| `go_memstats_heap_objects` | Number of allocated objects. | gauge | Número de objetos en heap. Muchos = presión en GC. |
| `go_memstats_heap_released_bytes` | Number of heap bytes released to OS. | gauge | Heap devuelto al OS. |
| `go_memstats_heap_sys_bytes` | Number of heap bytes obtained from system. | gauge | Total de heap pedido al OS. |
| `go_memstats_last_gc_time_seconds` | Number of seconds since 1970 of last garbage collection. | gauge | Timestamp del último GC. |
| `go_memstats_lookups_total` | Total number of pointer lookups. | counter | Lookups de punteros (raro en Go moderno). |
| `go_memstats_mallocs_total` | Total number of mallocs. | counter | Total de allocations. |
| `go_memstats_mcache_inuse_bytes` | Number of bytes in use by mcache structures. | gauge | Memoria de mcache (per-P cache). |
| `go_memstats_mcache_sys_bytes` | Number of bytes used for mcache structures obtained from system. | gauge | Total mcache del sistema. |
| `go_memstats_mspan_inuse_bytes` | Number of bytes in use by mspan structures. | gauge | Memoria de mspan (gestión de heap). |
| `go_memstats_mspan_sys_bytes` | Number of bytes used for mspan structures obtained from system. | gauge | Total mspan del sistema. |
| `go_memstats_next_gc_bytes` | Number of heap bytes when next garbage collection will take place. | gauge | Threshold para próximo GC. |
| `go_memstats_other_sys_bytes` | Number of bytes used for other system allocations. | gauge | Memoria de otros subsistemas. |
| `go_memstats_stack_inuse_bytes` | Number of bytes in use by the stack allocator. | gauge | Memoria usada por stacks de goroutines. |
| `go_memstats_stack_sys_bytes` | Number of bytes obtained from system for stack allocator. | gauge | Total de stack reservado. |
| `go_memstats_sys_bytes` | Number of bytes obtained from system. | gauge | **Total memoria del proceso Go**. Incluye todo. |
| `go_sched_gomaxprocs_threads` | The current runtime.GOMAXPROCS setting, or the number of operating system threads that can execute user-level Go code simultaneously. Sourced from /sched/gomaxprocs:threads | gauge | GOMAXPROCS (núcleos usados). En RPi4 debería ser 4. |
| `go_threads` | Number of OS threads created. | gauge | Threads del OS (no goroutines). |
| `machine_cpu_cores` | Number of logical CPU cores. | gauge | Cores lógicos totales (con HT). En RPi4 = 4. |
| `machine_cpu_physical_cores` | Number of physical CPU cores. | gauge | Cores físicos. En RPi4 = 4 (sin HT). |
| `machine_cpu_sockets` | Number of CPU sockets. | gauge | Sockets de CPU. RPi = 1. |
| `machine_memory_bytes` | Amount of memory installed on the machine. | gauge | **RAM total instalada**. En RPi4 debería ser 4GB o 8GB. |
| `machine_nvm_avg_power_budget_watts` | NVM power budget. | gauge | Presupuesto de potencia de NVM (N/A en RPi). |
| `machine_nvm_capacity` | NVM capacity value labeled by NVM mode (memory mode or app direct mode). | gauge | Capacidad de memoria NVM (N/A en RPi). |
| `machine_scrape_error` | 1 if there was an error while getting machine metrics, 0 otherwise. | gauge | Error al obtener métricas de hardware. |
| `machine_swap_bytes` | Amount of swap memory available on the machine. | gauge | Swap total disponible. En RPi debería ser 0 o mínimo. |
| `node_arp_entries` | ARP entries by device | gauge | Entradas en tabla ARP. Dispositivos vistos en red local. |
| `node_boot_time_seconds` | Node boot time, in unixtime. | gauge | Timestamp de arranque del sistema. Para calcular uptime. |
| `node_context_switches_total` | Total number of context switches. | counter | Context switches totales. Alto = mucha concurrencia o interrupciones. |
| `node_cpu_frequency_max_hertz` | Maximum CPU thread frequency in hertz. | gauge | Frecuencia máxima de CPU. En RPi4 ~1.8GHz. |
| `node_cpu_frequency_min_hertz` | Minimum CPU thread frequency in hertz. | gauge | Frecuencia mínima. Para throttling/ahorro energético. |
| `node_cpu_guest_seconds_total` | Seconds the CPUs spent in guests (VMs) for each mode. | counter | Tiempo en guests (VMs). Siempre 0 en RPi. |
| `node_cpu_scaling_frequency_hertz` | Current scaled CPU thread frequency in hertz. | gauge | **Frecuencia actual de CPU**. Detecta throttling por temperatura. |
| `node_cpu_scaling_frequency_max_hertz` | Maximum scaled CPU thread frequency in hertz. | gauge | Máxima frecuencia alcanzable actualmente. |
| `node_cpu_scaling_frequency_min_hertz` | Minimum scaled CPU thread frequency in hertz. | gauge | Mínima frecuencia en scaling. |
| `node_cpu_scaling_governor` | Current enabled CPU frequency governor. | gauge | Governor activo (ondemand, performance). Afecta rendimiento. |
| `node_cpu_seconds_total` | Seconds the CPUs spent in each mode. | counter | **Métrica clave**: Tiempo de CPU por modo (user, system, idle, iowait). |
| `node_disk_discarded_sectors_total` | The total number of sectors discarded successfully. | counter | Sectores descartados (TRIM/discard en SSD). |
| `node_disk_discards_completed_total` | The total number of discards completed successfully. | counter | Operaciones TRIM completadas. Mantenimiento de SSD. |
| `node_disk_discards_merged_total` | The total number of discards merged. | counter | TRIM mergeados. Eficiencia del scheduler. |
| `node_disk_discard_time_seconds_total` | This is the total number of seconds spent by all discards. | counter | Tiempo total en TRIM. |
| `node_disk_flush_requests_time_seconds_total` | This is the total number of seconds spent by all flush requests. | counter | Tiempo en flush (fsync). Importante para bases de datos. |
| `node_disk_flush_requests_total` | The total number of flush requests completed successfully | counter | Flush requests completados. |
| `node_disk_info` | Info of /sys/block/<block_device>. | gauge | Información del dispositivo de bloque. |
| `node_disk_io_now` | The number of I/Os currently in progress. | gauge | **I/Os en curso**. Detecta saturación de disco. |
| `node_disk_io_time_seconds_total` | Total seconds spent doing I/Os. | counter | Tiempo total en I/O. Para % utilización del disco. |
| `node_disk_io_time_weighted_seconds_total` | The weighted # of seconds spent doing I/Os. | counter | Tiempo ponderado. Detecta colas largas de I/O. |
| `node_disk_read_bytes_total` | The total number of bytes read successfully. | counter | **Bytes leídos del disco**. Throughput de lectura. |
| `node_disk_reads_completed_total` | The total number of reads completed successfully. | counter | Lecturas completadas. IOPS de lectura. |
| `node_disk_reads_merged_total` | The total number of reads merged. | counter | Lecturas fusionadas por el kernel. |
| `node_disk_read_time_seconds_total` | The total number of seconds spent by all reads. | counter | Tiempo total leyendo. Latencia de lectura. |
| `node_disk_writes_completed_total` | The total number of writes completed successfully. | counter | Escrituras completadas. IOPS de escritura. |
| `node_disk_writes_merged_total` | The number of writes merged. | counter | Escrituras fusionadas. |
| `node_disk_write_time_seconds_total` | This is the total number of seconds spent by all writes. | counter | Tiempo total escribiendo. Latencia de escritura. |
| `node_disk_written_bytes_total` | The total number of bytes written successfully. | counter | **Bytes escritos**. Monitoriza desgaste de SD/SSD. |
| `node_entropy_available_bits` | Bits of available entropy. | gauge | Entropía disponible para /dev/random. Bajo = esperas en crypto. |
| `node_entropy_pool_size_bits` | Bits of entropy pool. | gauge | Tamaño del pool de entropía. |
| `node_exporter_build_info` | A metric with a constant '1' value labeled by version, revision, branch, goversion from which node_exporter was built, and the goos and goarch for the build. | gauge | Versión de node_exporter. Metadata. |
| `node_filefd_allocated` | File descriptor statistics: allocated. | gauge | **File descriptors abiertos**. Monitorizacontra leaks. |
| `node_filefd_maximum` | File descriptor statistics: maximum. | gauge | FD máximos del sistema. Alerta si allocated se acerca. |
| `node_filesystem_avail_bytes` | Filesystem space available to non-root users in bytes. | gauge | **Espacio disponible** (para usuarios). Métrica clave para alertas. |
| `node_filesystem_device_error` | Whether an error occurred while getting statistics for the given device. | gauge | Error al leer stats del filesystem. |
| `node_filesystem_files` | Filesystem total file nodes. | gauge | Inodos totales. |
| `node_filesystem_files_free` | Filesystem total free file nodes. | gauge | Inodos libres. Crucial para muchos archivos pequeños. |
| `node_filesystem_free_bytes` | Filesystem free space in bytes. | gauge | Espacio libre (incluye reservado a root). |
| `node_filesystem_mount_info` | Filesystem mount information. | gauge | Info del mountpoint. Labels con device, fstype, opciones. |
| `node_filesystem_purgeable_bytes` | Filesystem space available including purgeable space (MacOS specific). | gauge | Espacio purgeable (N/A en Linux). |
| `node_filesystem_readonly` | Filesystem read-only status. | gauge | Filesystem montado ro. Indica problema grave. |
| `node_filesystem_size_bytes` | Filesystem size in bytes. | gauge | Tamaño total del filesystem. |
| `node_forks_total` | Total number of forks. | counter | Forks totales. Muchos = creación constante de procesos. |
| `node_hwmon_chip_names` | Annotation metric for human-readable chip names | gauge | Nombres de sensores hardware. |
| `node_hwmon_in_lcrit_alarm_volts` | Hardware monitor for voltage (lcrit_alarm) | gauge | Alarma de voltaje crítico bajo. |
| `node_hwmon_temp_celsius` | Hardware monitor for temperature (input) | gauge | **Temperatura de sensores**. Monitoriza throttling térmico. |
| `node_intr_total` | Total number of interrupts serviced. | counter | Interrupciones totales. Muchas = problemas de hardware/drivers. |
| `node_load1` | 1m load average. | gauge | **Load average 1 min**. >4 en RPi4 indica sobrecarga. |
| `node_load15` | 15m load average. | gauge | Load average 15 min. Tendencia a largo plazo. |
| `node_load5` | 5m load average. | gauge | Load average 5 min. Balance entre reactividad y estabilidad. |
| `node_memory_Active_anon_bytes` | Memory information field Active_anon_bytes. | gauge | Memoria anónima activa (usada recientemente). |
| `node_memory_Active_bytes` | Memory information field Active_bytes. | gauge | Memoria activa total. |
| `node_memory_Active_file_bytes` | Memory information field Active_file_bytes. | gauge | Caché de archivos activo. |
| `node_memory_AnonPages_bytes` | Memory information field AnonPages_bytes. | gauge | Páginas anónimas (heap de procesos). |
| `node_memory_Bounce_bytes` | Memory information field Bounce_bytes. | gauge | Bounce buffers (DMA). Despreciable. |
| `node_memory_Buffers_bytes` | Memory information field Buffers_bytes. | gauge | Buffers de I/O. Parte del caché. |
| `node_memory_Cached_bytes` | Memory information field Cached_bytes. | gauge | **Caché de archivos**. Se libera bajo presión. |
| `node_memory_CmaFree_bytes` | Memory information field CmaFree_bytes. | gauge | CMA free (contiguous memory allocator). Para hardware. |
| `node_memory_CmaTotal_bytes` | Memory information field CmaTotal_bytes. | gauge | CMA total reservado. |
| `node_memory_CommitLimit_bytes` | Memory information field CommitLimit_bytes. | gauge | Límite de overcommit. |
| `node_memory_Committed_AS_bytes` | Memory information field Committed_AS_bytes. | gauge | Memoria comprometida (overcommit). |
| `node_memory_Dirty_bytes` | Memory information field Dirty_bytes. | gauge | **Páginas sucias** (pendientes de escribir). Alto = I/O lento. |
| `node_memory_Inactive_anon_bytes` | Memory information field Inactive_anon_bytes. | gauge | Anónima inactiva. Candidata a swap. |
| `node_memory_Inactive_bytes` | Memory information field Inactive_bytes. | gauge | Memoria inactiva total. |
| `node_memory_Inactive_file_bytes` | Memory information field Inactive_file_bytes. | gauge | Caché inactivo. Se libera primero. |
| `node_memory_KernelStack_bytes` | Memory information field KernelStack_bytes. | gauge | Memoria de kernel stacks. |
| `node_memory_Mapped_bytes` | Memory information field Mapped_bytes. | gauge | Archivos mapeados en memoria. |
| `node_memory_MemAvailable_bytes` | Memory information field MemAvailable_bytes. | gauge | **RAM disponible estimada**. Mejor que MemFree. |
| `node_memory_MemFree_bytes` | Memory information field MemFree_bytes. | gauge | RAM completamente libre (sin caché). |
| `node_memory_MemTotal_bytes` | Memory information field MemTotal_bytes. | gauge | **RAM total**. En RPi4 ~3.7GB de 4GB. |
| `node_memory_Mlocked_bytes` | Memory information field Mlocked_bytes. | gauge | Memoria bloqueada (no swappeable). |
| `node_memory_NFS_Unstable_bytes` | Memory information field NFS_Unstable_bytes. | gauge | Páginas NFS pendientes. |
| `node_memory_PageTables_bytes` | Memory information field PageTables_bytes. | gauge | Memoria de tablas de páginas. |
| `node_memory_Percpu_bytes` | Memory information field Percpu_bytes. | gauge | Memoria per-CPU. |
| `node_memory_Shmem_bytes` | Memory information field Shmem_bytes. | gauge | Shared memory (/dev/shm, tmpfs). |
| `node_memory_Slab_bytes` | Memory information field Slab_bytes. | gauge | Slab total (kernel caches). |
| `node_memory_SReclaimable_bytes` | Memory information field SReclaimable_bytes. | gauge | Slab reclaimable. Se libera bajo presión. |
| `node_memory_SUnreclaim_bytes` | Memory information field SUnreclaim_bytes. | gauge | Slab no reclaimable. Overhead del kernel. |
| `node_memory_SwapCached_bytes` | Memory information field SwapCached_bytes. | gauge | Swap en caché (ya leído de swap). |
| `node_memory_SwapFree_bytes` | Memory information field SwapFree_bytes. | gauge | Swap libre. |
| `node_memory_SwapTotal_bytes` | Memory information field SwapTotal_bytes. | gauge | **Swap total**. En RPi debería ser 0 o mínimo. |
| `node_memory_Unevictable_bytes` | Memory information field Unevictable_bytes. | gauge | Memoria no evictable (mlocked). |
| `node_memory_VmallocChunk_bytes` | Memory information field VmallocChunk_bytes. | gauge | Mayor chunk vmalloc disponible. |
| `node_memory_VmallocTotal_bytes` | Memory information field VmallocTotal_bytes. | gauge | Total de espacio vmalloc. |
| `node_memory_VmallocUsed_bytes` | Memory information field VmallocUsed_bytes. | gauge | Vmalloc usado. |
| `node_memory_Writeback_bytes` | Memory information field Writeback_bytes. | gauge | Páginas escribiéndose ahora. Subset de Dirty. |
| `node_memory_WritebackTmp_bytes` | Memory information field WritebackTmp_bytes. | gauge | Writeback temporal (FUSE). |
| `node_memory_Zswap_bytes` | Memory information field Zswap_bytes. | gauge | Zswap usado (compresión de swap en RAM). |
| `node_netstat_Icmp6_InErrors` | Statistic Icmp6InErrors. | untyped | Errores ICMP6 recibidos. |
| `node_netstat_Icmp6_InMsgs` | Statistic Icmp6InMsgs. | untyped | Mensajes ICMP6 recibidos. |
| `node_netstat_Icmp6.OutMsgs` | Statistic Icmp6OutMsgs. | untyped | Mensajes ICMP6 enviados. |
| `node_netstat_Icmp_InErrors` | Statistic IcmpInErrors. | untyped | Errores ICMP recibidos. |
| `node_netstat_Icmp_InMsgs` | Statistic IcmpInMsgs. | untyped | Mensajes ICMP recibidos (pings). |
| `node_netstat_Icmp.OutMsgs` | Statistic IcmpOutMsgs. | untyped | Mensajes ICMP enviados. |
| `node_netstat_Ip6_InOctets` | Statistic Ip6InOctets. | untyped | Bytes IPv6 recibidos. |
| `node_netstat_Ip6.OutOctets` | Statistic Ip6OutOctets. | untyped | Bytes IPv6 enviados. |
| `node_netstat_IpExt_InOctets` | Statistic IpExtInOctets. | untyped | **Bytes IP recibidos totales**. Tráfico de entrada del host. |
| `node_netstat_IpExt.OutOctets` | Statistic IpExtOutOctets. | untyped | **Bytes IP enviados totales**. Tráfico de salida del host. |
| `node_netstat_Ip_Forwarding` | Statistic IpForwarding. | untyped | IP forwarding habilitado (1=sí, 2=no). |
| `node_netstat_Tcp_ActiveOpens` | Statistic TcpActiveOpens. | untyped | Conexiones TCP iniciadas (clientes). |
| `node_netstat_Tcp_CurrEstab` | Statistic TcpCurrEstab. | untyped | **Conexiones TCP establecidas**. Monitoriza carga de red. |
| `node_netstat_TcpExt_ListenDrops` | Statistic TcpExtListenDrops. | untyped | Conexiones descartadas por listen queue llena. Aumenta somaxconn. |
| `node_netstat_TcpExt_ListenOverflows` | Statistic TcpExtListenOverflows. | untyped | Overflows de listen queue. Problema grave de tuning. |
| `node_netstat_TcpExt_SyncookiesFailed` | Statistic TcpExtSyncookiesFailed. | untyped | Syncookies fallidas. |
| `node_netstat_TcpExt_SyncookiesRecv` | Statistic TcpExtSyncookiesRecv. | untyped | Syncookies recibidas (protección SYN flood). |
| `node_netstat_TcpExt_SyncookiesSent` | Statistic TcpExtSyncookiesSent. | untyped | Syncookies enviadas. Indica ataque SYN. |
| `node_netstat_TcpExt_TCPOFOQueue` | Statistic TcpExtTCPOFOQueue. | untyped | Paquetes TCP out-of-order encolados. |
| `node_netstat_TcpExt_TCPRcvQDrop` | Statistic TcpExtTCPRcvQDrop. | untyped | Drops en receive queue de TCP. Buffer pequeño. |
| `node_netstat_TcpExt_TCPSynRetrans` | Statistic TcpExtTCPSynRetrans. | untyped | **Retransmisiones SYN**. Red con pérdidas o filtros. |
| `node_netstat_TcpExt_TCPTimeouts` | Statistic TcpExtTCPTimeouts. | untyped | Timeouts de TCP. Conexiones lentas o perdidas. |
| `node_netstat_Tcp_InErrs` | Statistic TcpInErrs. | untyped | Errores TCP recibidos. Checksums incorrectos. |
| `node_netstat_Tcp_InSegs` | Statistic TcpInSegs. | untyped | Segmentos TCP recibidos. |
| `node_netstat_Tcp.OutRsts` | Statistic TcpOutRsts. | untyped | RST enviados (conexiones rechazadas/reseteadas). |
| `node_netstat_Tcp.OutSegs` | Statistic TcpOutSegs. | untyped | Segmentos TCP enviados. |
| `node_netstat_Tcp_PassiveOpens` | Statistic TcpPassiveOpens. | untyped | Conexiones TCP aceptadas (servidor). |
| `node_netstat_Tcp_RetransSegs` | Statistic TcpRetransSegs. | untyped | **Retransmisiones TCP**. Alto = red con pérdidas. |
| `node_netstat_Udp6_InDatagrams` | Statistic Udp6InDatagrams. | untyped | Datagramas UDP6 recibidos. |
| `node_netstat_Udp6_InErrors` | Statistic Udp6InErrors. | untyped | Errores UDP6. |
| `node_netstat_Udp6_NoPorts` | Statistic Udp6NoPorts. | untyped | UDP6 a puerto sin listener. |
| `node_netstat_Udp6_OutDatagrams` | Statistic Udp6OutDatagrams. | untyped | Datagramas UDP6 enviados. |
| `node_netstat_Udp6_RcvbufErrors` | Statistic Udp6RcvbufErrors. | untyped | Buffer de recepción UDP6 lleno. |
| `node_netstat_Udp6_SndbufErrors` | Statistic Udp6SndbufErrors. | untyped | Buffer de envío UDP6 lleno. |
| `node_netstat_Udp_InDatagrams` | Statistic UdpInDatagrams. | untyped | Datagramas UDP recibidos. |
| `node_netstat_Udp_InErrors` | Statistic UdpInErrors. | untyped | Errores UDP. |
| `node_netstat_UdpLite6_InErrors` | Statistic UdpLite6InErrors. | untyped | Errores UDPLite6. |
| `node_netstat_UdpLite_InErrors` | Statistic UdpLiteInErrors. | untyped | Errores UDPLite. |
| `node_netstat_Udp_NoPorts` | Statistic UdpNoPorts. | untyped | UDP a puerto sin listener. Port scan? |
| `node_netstat_Udp_OutDatagrams` | Statistic UdpOutDatagrams. | untyped | Datagramas UDP enviados. |
| `node_netstat_Udp_RcvbufErrors` | Statistic UdpRcvbufErrors. | untyped | **Buffer UDP lleno**. Aumenta net.core.rmem. |
| `node_netstat_Udp_SndbufErrors` | Statistic UdpSndbufErrors. | untyped | Buffer de envío UDP lleno. |
| `node_network_address_assign_type` | Network device property: address_assign_type | gauge | Tipo de asignación de dirección de red. |
| `node_network_carrier_changes_total` | Network device property: carrier_changes_total | counter | Cambios de carrier (cable conectado/desconectado). |
| `node_network_carrier_down_changes_total` | Network device property: carrier_down_changes_total | counter | Veces que se perdió carrier. Problemas de cable. |
| `node_network_carrier` | Network device property: carrier | gauge | **Carrier activo** (1=cable conectado, 0=desconectado). |
| `node_network_carrier_up_changes_total` | Network device property: carrier_up_changes_total | counter | Veces que se obtuvo carrier. |
| `node_network_device_id` | Network device property: device_id | gauge | ID del dispositivo de red. |
| `node_network_dormant` | Network device property: dormant | gauge | Interfaz dormant (802.1X). |
| `node_network_flags` | Network device property: flags | gauge | Flags del dispositivo. |
| `node_network_iface_id` | Network device property: iface_id | gauge | ID de interfaz. |
| `node_network_iface_link_mode` | Network device property: iface_link_mode | gauge | Modo de link. |
| `node_network_iface_link` | Network device property: iface_link | gauge | Link de interfaz. |
| `node_network_info` | Non-numeric data from /sys/class/net/<iface>, value is always 1. | gauge | Info de interfaz (labels: address, device, duplex, etc). |
| `node_network_mtu_bytes` | Network device property: mtu_bytes | gauge | MTU de la interfaz. 1500 para Ethernet estándar. |
| `node_network_name_assign_type` | Network device property: name_assign_type | gauge | Tipo de asignación de nombre. |
| `node_network_net_dev_group` | Network device property: net_dev_group | gauge | Grupo del dispositivo. |
| `node_network_protocol_type` | Network device property: protocol_type | gauge | Tipo de protocolo (1=Ethernet). |
| `node_network_receive_bytes_total` | Network device statistic receive_bytes. | counter | **Bytes recibidos por interfaz**. Tráfico de entrada. |
| `node_network_receive_compressed_total` | Network device statistic receive_compressed. | counter | Paquetes comprimidos recibidos (raro). |
| `node_network_receive_drop_total` | Network device statistic receive_drop. | counter | **Paquetes descartados en RX**. Buffer lleno o errores. |
| `node_network_receive_errs_total` | Network device statistic receive_errs. | counter | Errores en recepción. Problemas físicos. |
| `node_network_receive_fifo_total` | Network device statistic receive_fifo. | counter | Errores FIFO en RX. Buffer overflow. |
| `node_network_receive_frame_total` | Network device statistic receive_frame. | counter | Errores de frame (capa física). |
| `node_network_receive_multicast_total` | Network device statistic receive_multicast. | counter | Paquetes multicast recibidos. |
| `node_network_receive_nohandler_total` | Network device statistic receive_nohandler. | counter | Paquetes sin handler (protocolo desconocido). |
| `node_network_receive_packets_total` | Network device statistic receive_packets. | counter | Paquetes recibidos totales. |
| `node_network_speed_bytes` | Network device property: speed_bytes | gauge | **Velocidad del link** en bytes/s. 125MB/s = 1Gbps. |
| `node_network_transmit_bytes_total` | Network device statistic transmit_bytes. | counter | **Bytes transmitidos por interfaz**. Tráfico de salida. |
| `node_network_transmit_carrier_total` | Network device statistic transmit_carrier. | counter | Errores de carrier en TX. |
| `node_network_transmit_colls_total` | Network device statistic transmit_colls. | counter | Colisiones (solo half-duplex, raro hoy). |
| `node_network_transmit_compressed_total` | Network device statistic transmit_compressed. | counter | Paquetes comprimidos enviados. |
| `node_network_transmit_drop_total` | Network device statistic transmit_drop. | counter | **Paquetes descartados en TX**. QoS o congestión. |
| `node_network_transmit_errs_total` | Network device statistic transmit_errs. | counter | Errores en transmisión. |
| `node_network_transmit_fifo_total` | Network device statistic transmit_fifo. | counter | Errores FIFO en TX. |
| `node_network_transmit_packets_total` | Network device statistic transmit_packets. | counter | Paquetes transmitidos totales. |
| `node_network_transmit_queue_length` | Network device property: transmit_queue_length | gauge | Longitud de cola TX (txqueuelen). |
| `node_network_up` | Value is 1 if operstate is 'up', 0 otherwise. | gauge | **Interfaz UP**. Monitoriza disponibilidad de red. |
| `node_nf_conntrack_entries_limit` | Maximum size of connection tracking table. | gauge | **Límite de conntrack**. En RPi ~65k. |
| `node_nf_conntrack_entries` | Number of currently allocated flow entries for connection tracking. | gauge | **Entradas conntrack usadas**. Alerta si se acerca al límite. |
| `node_nfs_connections_total` | Total number of NFSd TCP connections. | counter | Conexiones NFS (si usas NFS). |
| `node_nfs_packets_total` | Total NFSd network packets (sent+received) by protocol type. | counter | Paquetes NFS. |
| `node_nfs_requests_total` | Number of NFS procedures invoked. | counter | Requests NFS por tipo de operación. |
| `node_nfs_rpc_authentication_refreshes_total` | Number of RPC authentication refreshes performed. | counter | Refreshes de autenticación RPC. |
| `node_nfs_rpc_retransmissions_total` | Number of RPC transmissions performed. | counter | Retransmisiones RPC. Red lenta. |
| `node_nfs_rpcs_total` | Total number of RPCs performed. | counter | RPCs totales de NFS. |
| `node_os_info` | A metric with a constant '1' value labeled by build_id, id, id_like, image_id, image_version, name, pretty_name, variant, variant_id, version, version_codename, version_id. | gauge | **Info del OS**. Labels con versión, distro, etc. |
| `node_os_version` | Metric containing the major.minor part of the OS version. | gauge | Versión del OS en formato numérico. |
| `node_procs_blocked` | Number of processes blocked waiting for I/O to complete. | gauge | **Procesos bloqueados en I/O**. Alto = disco lento. |
| `node_procs_running` | Number of processes in runnable state. | gauge | Procesos ejecutables (en cola CPU). |
| `node_schedstat_running_seconds_total` | Number of seconds CPU spent running a process. | counter | Tiempo de CPU ejecutando procesos. |
| `node_schedstat_timeslices_total` | Number of timeslices executed by CPU. | counter | Timeslices ejecutados. Métrica de scheduler. |
| `node_schedstat_waiting_seconds_total` | Number of seconds spent by processing waiting for this CPU. | counter | Tiempo esperando CPU. Indica contención. |
| `node_scrape_collector_duration_seconds` | node_exporter: Duration of a collector scrape. | gauge | Tiempo que tarda node_exporter en scrapear. |
| `node_scrape_collector_success` | node_exporter: Whether a collector succeeded. | gauge | Éxito del collector (1=ok, 0=error). |
| `node_selinux_enabled` | SELinux is enabled, 1 is true, 0 is false | gauge | SELinux habilitado. En Debian/Ubuntu = 0. |
| `node_sockstat_FRAG6_inuse` | Number of FRAG6 sockets in state inuse. | gauge | Sockets de fragmentación IPv6. |
| `node_sockstat_FRAG6_memory` | Number of FRAG6 sockets in state memory. | gauge | Memoria de fragmentación IPv6. |
| `node_sockstat_FRAG_inuse` | Number of FRAG sockets in state inuse. | gauge | Sockets de fragmentación IPv4. |
| `node_sockstat_FRAG_memory` | Number of FRAG sockets in state memory. | gauge | Memoria de fragmentación. |
| `node_sockstat_RAW6_inuse` | Number of RAW6 sockets in state inuse. | gauge | Sockets RAW IPv6 (ping6, etc). |
| `node_sockstat_RAW_inuse` | Number of RAW sockets in state inuse. | gauge | Sockets RAW (ping, traceroute). |
| `node_sockstat_sockets_used` | Number of IPv4 sockets in use. | gauge | **Total de sockets IPv4**. Incluye todos los tipos. |
| `node_sockstat_TCP6_inuse` | Number of TCP6 sockets in state inuse. | gauge | Sockets TCP IPv6 en uso. |
| `node_sockstat_TCP_alloc` | Number of TCP sockets in state alloc. | gauge | Sockets TCP allocados (incluye TIME_WAIT). |
| `node_sockstat_TCP_inuse` | Number of TCP sockets in state inuse. | gauge | **Sockets TCP en uso**. Monitoriza carga de conexiones. |
| `node_sockstat_TCP_mem_bytes` | Number of TCP sockets in state mem_bytes. | gauge | Memoria usada por sockets TCP en bytes. |
| `node_sockstat_TCP_mem` | Number of TCP sockets in state mem. | gauge | Páginas de memoria TCP. |
| `node_sockstat_TCP_orphan` | Number of TCP sockets in state orphan. | gauge | **Sockets TCP huérfanos**. Conexiones cerradas pero no liberadas. |
| `node_sockstat_TCP_tw` | Number of TCP sockets in state tw. | gauge | Sockets en TIME_WAIT. Muchos = alta rotación de conexiones. |
| `node_sockstat_UDP6_inuse` | Number of UDP6 sockets in state inuse. | gauge | Sockets UDP IPv6. |
| `node_sockstat_UDP_inuse` | Number of UDP sockets in state inuse. | gauge | Sockets UDP en uso. |
| `node_sockstat_UDPLITE6_inuse` | Number of UDPLITE6 sockets in state inuse. | gauge | Sockets UDPLite IPv6. |
| `node_sockstat_UDPLITE_inuse` | Number of UDPLITE sockets in state inuse. | gauge | Sockets UDPLite. |
| `node_sockstat_UDP_mem_bytes` | Number of UDP sockets in state mem_bytes. | gauge | Memoria UDP en bytes. |
| `node_sockstat_UDP_mem` | Number of UDP sockets in state mem. | gauge | Páginas de memoria UDP. |
| `node_softnet_backlog_len` | Softnet backlog status | gauge | Longitud del backlog de softirq. |
| `node_softnet_cpu_collision_total` | Number of collision occur while obtaining device lock while transmitting | counter | Colisiones de lock en transmisión. Raro. |
| `node_softnet_dropped_total` | Number of dropped packets | counter | **Paquetes descartados en softirq**. CPU no da abasto procesando red. |
| `node_softnet_flow_limit_count_total` | Number of times flow limit has been reached | counter | Veces que se alcanzó flow limit (RFS). |
| `node_softnet_processed_total` | Number of processed packets | counter | Paquetes procesados por softirq. |
| `node_softnet_received_rps_total` | Number of times cpu woken up received_rps | counter | Wakeups por RPS (Receive Packet Steering). |
| `node_softnet_times_squeezed_total` | Number of times processing packets ran out of quota | counter | Veces que softirq se quedó sin quota. Alto = CPU saturada. |
| `node_textfile_scrape_error` | 1 if there was an error opening or reading a file, 0 otherwise | gauge | Error al leer textfile collector. |
| `node_thermal_zone_temp` | Zone temperature in Celsius | gauge | **Temperatura de zonas térmicas**. En RPi monitoriza CPU temp. |
| `node_time_clocksource_available_info` | Available clocksources read from '/sys/devices/system/clocksource'. | gauge | Clocksources disponibles. |
| `node_time_clocksource_current_info` | Current clocksource read from '/sys/devices/system/clocksource'. | gauge | Clocksource activo (arch_sys_counter en RPi). |
| `node_time_seconds` | System time in seconds since epoch (1970). | gauge | Timestamp actual del sistema. |
| `node_timex_estimated_error_seconds` | Estimated error in seconds. | gauge | Error estimado del reloj. |
| `node_timex_frequency_adjustment_ratio` | Local clock frequency adjustment. | gauge | Ajuste de frecuencia del reloj (NTP). |
| `node_timex_loop_time_constant` | Phase-locked loop time constant. | gauge | Constante de PLL del reloj. |
| `node_timex_maxerror_seconds` | Maximum error in seconds. | gauge | Error máximo del reloj. |
| `node_timex_offset_seconds` | Time offset in between local system and reference clock. | gauge | Offset del reloj local vs NTP. |
| `node_timex_pps_calibration_total` | Pulse per second count of calibration intervals. | counter | Calibraciones PPS. |
| `node_timex_pps_error_total` | Pulse per second count of calibration errors. | counter | Errores de calibración PPS. |
| `node_timex_pps_frequency_hertz` | Pulse per second frequency. | gauge | Frecuencia PPS. |
| `node_timex_pps_jitter_seconds` | Pulse per second jitter. | gauge | Jitter de PPS. |
| `node_timex_pps_jitter_total` | Pulse per second count of jitter limit exceeded events. | counter | Veces que se excedió jitter. |
| `node_timex_pps_shift_seconds` | Pulse per second interval duration. | gauge | Intervalo PPS. |
| `node_timex_pps_stability_exceeded_total` | Pulse per second count of stability limit exceeded events. | counter | Veces que se excedió estabilidad. |
| `node_timex_pps_stability_hertz` | Pulse per second stability, average of recent frequency changes. | gauge | Estabilidad PPS. |
| `node_timex_status` | Value of the status array bits. | gauge | Status del reloj (bitmask). |
| `node_timex_sync_status` | Is clock synchronized to a reliable server (1 = yes, 0 = no). | gauge | **Reloj sincronizado con NTP** (1=sí). |
| `node_timex_tai_offset_seconds` | International Atomic Time (TAI) offset. | gauge | Offset TAI. |
| `node_timex_tick_seconds` | Seconds between clock ticks. | gauge | Tick del reloj (HZ). |
| `node_time_zone_offset_seconds` | System time zone offset in seconds. | gauge | Offset de zona horaria. |
| `node_udp_queues` | Number of allocated memory in the kernel for UDP datagrams in bytes. | gauge | Memoria de colas UDP. |
| `node_uname_info` | Labeled system information as provided by the uname system call. | gauge | **Info del sistema**: hostname, kernel, machine, etc. |
| `node_vmstat_oom_kill` | /proc/vmstat information field oom_kill. | untyped | **Procesos matados por OOM**. Crítico: falta RAM. |
| `node_vmstat_pgfault` | /proc/vmstat information field pgfault. | untyped | Page faults (minor). Normal en sistemas con caché. |
| `node_vmstat_pgmajfault` | /proc/vmstat information field pgmajfault. | untyped | **Major page faults** (requieren I/O). Alto = swapping o falta RAM. |
| `node_vmstat_pgpgin` | /proc/vmstat information field pgpgin. | untyped | Páginas leídas desde disco (swap in). |
| `node_vmstat_pgpgout` | /proc/vmstat information field pgpgout. | untyped | Páginas escritas a disco (swap out). |
| `node_vmstat_pswpin` | /proc/vmstat information field pswpin. | untyped | **Swap in**. >0 indica RAM insuficiente. |
| `node_vmstat_pswpout` | /proc/vmstat information field pswpout. | untyped | **Swap out**. Sistema swapping activamente. |
| `node_watchdog_bootstatus` | Value of /sys/class/watchdog/<watchdog>/bootstatus | gauge | Status del watchdog en boot. |
| `node_watchdog_fw_version` | Value of /sys/class/watchdog/<watchdog>/fw_version | gauge | Versión del watchdog. |
| `node_watchdog_info` | Info of /sys/class/watchdog/<watchdog> | gauge | Info del watchdog hardware. |
| `node_watchdog_nowayout` | Value of /sys/class/watchdog/<watchdog>/nowayout | gauge | Watchdog no puede deshabilitarse. |
| `node_watchdog_timeleft_seconds` | Value of /sys/class/watchdog/<watchdog>/timeleft | gauge | Tiempo restante antes de reset. |
| `node_watchdog_timeout_seconds` | Value of /sys/class/watchdog/<watchdog>/timeout | gauge | Timeout del watchdog. |
| `process_cpu_seconds_total` | Total user and system CPU time spent in seconds. | counter | CPU total del proceso del exporter. |
| `process_max_fds` | Maximum number of open file descriptors. | gauge | FD máximos del proceso. |
| `process_network_receive_bytes_total` | Number of bytes received by the process over the network. | counter | Bytes recibidos por el proceso. |
| `process_network_transmit_bytes_total` | Number of bytes sent by the process over the network. | counter | Bytes enviados por el proceso. |
| `process_open_fds` | Number of open file descriptors. | gauge | FDs abiertos por el proceso. Detecta leaks. |
| `process_resident_memory_bytes` | Resident memory size in bytes. | gauge | RSS del proceso. |
| `process_start_time_seconds` | Start time of the process since unix epoch in seconds. | gauge | Timestamp de inicio del proceso. |
| `process_virtual_memory_bytes` | Virtual memory size in bytes. | gauge | VSS del proceso. |
| `process_virtual_memory_max_bytes` | Maximum amount of virtual memory available in bytes. | gauge | Límite virtual del proceso. |
| `promhttp_metric_handler_errors_total` | Total number of internal errors encountered by the promhttp metric handler. | counter | Errores internos del handler HTTP de Prometheus. |
| `promhttp_metric_handler_requests_in_flight` | Current number of scrapes being served. | gauge | Scrapes en curso simultáneos. |
| `promhttp_metric_handler_requests_total` | Total number of scrapes by HTTP status code. | counter | Total de scrapes por código HTTP. |
| `smartctl_devices` | Number of devices configured or dynamically discovered | gauge | Dispositivos SMART descubiertos. |

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
| 13 | node_network_up, node_network_speed_bytes | Estado de interfaz y link speed | boolean (0/1) / bytes/s | Single stat + table; network_up como status; speed mostrar en Mbps. | node_network_up |
| 14 | node_nf_conntrack_entries, node_nf_conntrack_entries_limit | Conntrack (NAT table) | count / % | Gauge (porcentaje de uso); alerta si >90%. | 100 * node_nf_conntrack_entries / node_nf_conntrack_entries_limit |
| 15 | node_procs_running, node_procs_blocked | Procesos en ejecución y bloqueados | count | Time series; node_procs_blocked >0 sostenido indica I/O problem. | node_procs_blocked |
| 16 | node_sockstat_TCP_inuse, node_sockstat_TCP_tw | Conexiones TCP y TIME_WAIT | count | Table/Single stat; vigilar TIME_WAIT altos. | node_sockstat_TCP_inuse |
| 17 | node_hwmon_temp_celsius, node_thermal_zone_temp | Temperaturas (CPU) | °C | Gauge + Time series; thresholds (70°C amarillo / 80°C rojo). | node_hwmon_temp_celsius |
| 18 | node_boot_time_seconds / node_time_seconds | Uptime | seconds / duration | Single stat; formatear como duración (d hh:mm). | time() - node_boot_time_seconds |
| 19 | node_vmstat_oom_kill, container_oom_events_total | OOMs sistema/contenedores | count | Counter; usar increase(...) para detectar OOMs en ventana (ej. 1h). | increase(node_vmstat_oom_kill[1h]) or increase(container_oom_events_total[1h]) > 0 |
| 20 | node_scrape_collector_success, node_scrape_collector_duration_seconds | Salud del exporter | boolean / seconds | Table con iconos; marcar collectors con success=0 como fallidos y mostrar durations. | node_scrape_collector_success |

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

