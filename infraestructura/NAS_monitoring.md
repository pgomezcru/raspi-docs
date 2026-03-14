[🏠 Inicio](../README.md) > [📂 Infraestructura](_index.md)

# Monitorización del NAS Synology

Estrategia para integrar las métricas del Synology NAS DS110j con el stack de Prometheus + Grafana.

## Desafío

El NAS Synology no puede ser directamente "scrapeado" por Prometheus desde contenedores Docker en la Raspberry Pi, ya que:
- El NAS gestiona su propio hardware (S.M.A.R.T., temperatura, estado RAID).
- No podemos instalar exporters en el Synology directamente (modelo antiguo, sin Docker).

## Estrategias Posibles

### Opción 1: SNMP Exporter (Recomendado)

Synology DSM expone métricas a través de **SNMP** (Simple Network Management Protocol).

#### Configuración en el NAS
1. Acceder a DSM > **Panel de Control > Terminal & SNMP**
2. Pestaña **SNMP**: Habilitar servicio SNMP v2c
3. Establecer **Community String**: `public` (o uno personalizado)
4. Anotar la IP del NAS (ej. `192.168.1.11`)

#### Añadir SNMP Exporter a Prometheus Stack

Añadir al `docker-compose.yml`:

```yaml
  snmp-exporter:
    image: prom/snmp-exporter:latest
    container_name: snmp-exporter
    restart: unless-stopped
    command:
      - '--config.file=/etc/snmp_exporter/snmp.yml'
    volumes:
      - ./snmp_exporter:/etc/snmp_exporter
    ports:
      - "9116:9116"
    networks:
      - monitoring
```

#### Configurar Prometheus para scrapear el NAS

En `prometheus.yml`:

```yaml
  - job_name: 'synology-nas'
    static_configs:
      - targets:
        - 192.168.1.11  # IP del NAS
    metrics_path: /snmp
    params:
      module: [synology]  # Usar módulo predefinido de Synology
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: snmp-exporter:9116  # Dirección del exporter
```

#### Métricas Disponibles

- **Temperatura**: `hrDeviceDescr`, `laLoad`
- **Uso de disco**: `hrStorageUsed`, `hrStorageSize`
- **Estado del sistema**: `sysUpTime`, `ifInOctets`, `ifOutOctets` (tráfico de red)
- **Discos RAID**: Estados específicos de Synology vía OIDs propietarios

#### Dashboards para Grafana

- **ID**: 14284 (Synology NAS Details)
- Importar en Grafana para ver: CPU, RAM, volúmenes, temperatura.

---

### Opción 2: Synology Exporter (GitHub Community)

Existen exporters no oficiales desarrollados por la comunidad que utilizan la API de Synology DSM.

**Ejemplo**: [synology-prometheus-exporter](https://github.com/mad-ady/synology-prometheus-exporter)

#### Despliegue

```yaml
  synology-exporter:
    image: ghcr.io/mad-ady/synology-prometheus-exporter:latest
    container_name: synology-exporter
    restart: unless-stopped
    environment:
      - SYNOLOGY_HOST=192.168.1.11
      - SYNOLOGY_PORT=5001  # Puerto HTTPS del DSM
      - SYNOLOGY_USER=monitoring  # Crear usuario de solo lectura
      - SYNOLOGY_PASSWORD=secret
    ports:
      - "9142:9142"
    networks:
      - monitoring
```

**Ventajas**:
- Acceso a métricas más detalladas que SNMP.
- S.M.A.R.T. de discos individuales.

**Desventajas**:
- Requiere credenciales de acceso al NAS.
- Proyecto comunitario (menor estabilidad que SNMP oficial).

---

### Opción 3: Notificaciones por Email + Manual

**Para detección de fallos críticos**:

Configurar en Synology DSM:
1. **Panel de Control > Notificación**
2. Habilitar notificaciones por **Email** o **SMS**
3. Configurar alertas para:
   - Disco dañado
   - Volumen casi lleno
   - Temperatura alta

Esta opción **no integra con Grafana**, pero es un respaldo crítico.

---

## Recomendación Final

**Usar SNMP Exporter (Opción 1)** por ser:
- Protocolo estándar soportado oficialmente por Synology.
- Sin necesidad de credenciales sensibles en contenedores.
- Ampliamente documentado.

Mantener **notificaciones por email** como sistema de alerta redundante para eventos críticos.
