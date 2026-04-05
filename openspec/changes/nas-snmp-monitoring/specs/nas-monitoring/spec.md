## ADDED Requirements

### Requirement: Métricas del NAS en Prometheus
Prometheus debe recoger métricas del NAS Synology DS110j vía SNMP y almacenarlas en su TSDB.

#### Scenario: NAS accesible y SNMP habilitado
- **WHEN** el NAS está encendido con SNMP v2c habilitado en `192.168.1.102`
- **THEN** Prometheus scrape el job `snmp` cada 60 segundos y las métricas son consultables con `up{job="snmp"} == 1`

#### Scenario: NAS apagado o inaccesible
- **WHEN** el NAS no está disponible en la red
- **THEN** el scrape falla con `up{job="snmp"} == 0` pero el resto del stack de monitorización no se ve afectado

---

### Requirement: Dashboard de estado del NAS en Grafana
Debe existir un dashboard en Grafana con las métricas básicas del NAS.

#### Scenario: Visualización del estado del NAS
- **WHEN** el usuario abre el dashboard "NAS — Synology DS110j" en Grafana
- **THEN** puede ver CPU %, RAM %, temperatura, estado de los volúmenes y tráfico de red del NAS

---

### Requirement: Métricas mínimas requeridas
El exporter SNMP debe exponer al menos las métricas básicas de salud del NAS.

#### Scenario: Métricas básicas disponibles
- **WHEN** se consulta `http://snmp-exporter:9116/snmp?module=synology&target=192.168.1.102`
- **THEN** la respuesta incluye métricas de CPU, RAM, temperatura de discos y estado de volúmenes RAID
