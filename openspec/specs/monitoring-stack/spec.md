## Requirements

### Requirement: Recolección de métricas del sistema host
El stack debe recolectar métricas de CPU, RAM, disco, red y sistema de ficheros del host Raspberry Pi.

#### Scenario: node-exporter activo con acceso al sistema de ficheros del host
- **WHEN** node-exporter está en ejecución con `pid: host` y mount `/:/host:ro,rslave`
- **THEN** expone métricas de sistema real en `:9100/metrics`, incluyendo filesystems del host

---

### Requirement: Recolección de métricas de contenedores Docker
El stack debe recolectar métricas de uso de recursos por contenedor (CPU, RAM, red, I/O).

#### Scenario: cadvisor activo con acceso a Docker
- **WHEN** cadvisor está en ejecución con acceso a `/var/run/docker.sock` y `/sys`
- **THEN** expone métricas por contenedor en `:8081/metrics`

---

### Requirement: Monitorización de salud del almacenamiento
El stack debe recolectar datos SMART del disco SSD conectado por USB.

#### Scenario: smartctl-exporter activo con acceso a dispositivos
- **WHEN** smartctl-exporter está en ejecución con `privileged: true` y acceso a `/dev`
- **THEN** expone métricas SMART en `:9633/metrics`

---

### Requirement: Metadatos de contenedores Docker
El stack debe exponer metadatos enriquecidos de los contenedores (imagen, versión, estado).

#### Scenario: docker-metadata-exporter activo
- **WHEN** docker-metadata-exporter está en ejecución con acceso a `/var/run/docker.sock`
- **THEN** expone metadatos de contenedores en `:9101/metrics`

---

### Requirement: Tabla de métricas Prometheus
El stack debe ofrecer una vista tabular de las métricas en formato HTML.

#### Scenario: prometheus-metrics-table activo
- **WHEN** prometheus-metrics-table está en ejecución con las variables `TARGETS` configuradas
- **THEN** sirve una tabla navegable de métricas en `:9102`

---

### Requirement: Almacenamiento y consulta de métricas
Prometheus debe almacenar las métricas con retención de 30 días y exponerlas vía API.

#### Scenario: Prometheus configurado con retención
- **WHEN** Prometheus arranca con `--storage.tsdb.retention.time=30d`
- **THEN** las métricas se conservan 30 días y son consultables en `:9090`

---

### Requirement: Visualización de métricas
Grafana debe estar disponible para crear y visualizar dashboards sobre los datos de Prometheus.

#### Scenario: Grafana conectado a Prometheus
- **WHEN** Grafana está en ejecución con provisioning de datasource apuntando a `prometheus:9090`
- **THEN** el datasource Prometheus aparece activo en Grafana en `:3001`

---

### Requirement: Aislamiento de red del stack de monitorización
Los servicios del stack deben comunicarse en una red interna `monitoring` aislada del tráfico externo.

#### Scenario: Red monitoring definida
- **WHEN** todos los exporters y Prometheus están conectados a la red `monitoring`
- **THEN** los exporters no son accesibles desde `proxy_net` salvo Prometheus y los servicios que lo requieran
