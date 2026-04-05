## ADDED Requirements

### Requirement: Recolección de logs de contenedores Docker
Promtail debe recoger automáticamente los logs de todos los contenedores Docker en ejecución.

#### Scenario: Contenedor Docker en ejecución
- **WHEN** un contenedor Docker genera output a stdout/stderr
- **THEN** Promtail recoge el log y lo envía a Loki con etiquetas `container_name` y `image`

#### Scenario: Nuevo contenedor arranca
- **WHEN** un nuevo contenedor Docker arranca tras la configuración de Promtail
- **THEN** Promtail detecta automáticamente el contenedor (via Docker SD) y empieza a recoger sus logs sin reiniciar

---

### Requirement: Almacenamiento y consulta de logs en Loki
Loki debe almacenar los logs recibidos y hacerlos consultables vía LogQL.

#### Scenario: Consulta de logs en Grafana
- **WHEN** el usuario abre Grafana → Explore → datasource Loki
- **THEN** puede filtrar logs por `container_name`, `image` y buscar en el contenido de los logs

#### Scenario: Retención configurada
- **WHEN** los logs tienen más de 7 días de antigüedad
- **THEN** Loki los elimina automáticamente para liberar espacio en `/mnt/usb-data/loki/`

---

### Requirement: Datasource Loki provisionado en Grafana
Grafana debe tener el datasource de Loki disponible automáticamente sin configuración manual.

#### Scenario: Grafana arranca con provisioning
- **WHEN** el contenedor de Grafana arranca
- **THEN** el datasource "Loki" aparece configurado y accesible en Grafana sin intervención manual
