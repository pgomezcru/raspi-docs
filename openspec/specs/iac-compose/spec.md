## Requirements

### Requirement: Un compose por servicio en el repositorio
Cada servicio desplegado debe tener su propio `docker-compose.yml` en `compose/<servicio>/`.

#### Scenario: Servicio con compose propio
- **WHEN** se quiere desplegar o actualizar un servicio
- **THEN** existe `compose/<servicio>/docker-compose.yml` como fuente de verdad en el repo

---

### Requirement: Mapa de despliegue centralizado
Debe existir un fichero `manifest.yml` que mapee cada servicio a su ruta en el repo y su destino en la Pi.

#### Scenario: Consulta del manifest
- **WHEN** `deploy.sh` necesita saber dónde copiar un compose
- **THEN** lee `compose/manifest.yml` para obtener la ruta de destino en la Pi (`/mnt/usb-data/<servicio>/docker-compose.yml`)

---

### Requirement: Script de despliegue automatizado
`deploy.sh` debe automatizar la copia del compose al destino correcto en la Pi y ejecutar `docker compose up -d`.

#### Scenario: Despliegue de un servicio
- **WHEN** se ejecuta `bash ~/raspi-docs/compose/deploy.sh <servicio>` en la Pi
- **THEN** el compose se copia al destino definido en `manifest.yml` y el servicio se actualiza

---

### Requirement: Versión controlada en Gitea
Todos los ficheros de compose deben estar versionados en el repositorio Gitea de la Pi.

#### Scenario: Cambio en un compose
- **WHEN** se modifica un `docker-compose.yml` en el repo
- **THEN** el cambio se propaga a la Pi mediante `git pull` en la Pi seguido de `deploy.sh`

---

### Requirement: Versiones de imágenes pinneadas
Todos los servicios en compose deben usar tags de imagen exactos, nunca `:latest`.

#### Scenario: Imagen con tag pinneado
- **WHEN** se define una imagen en un compose
- **THEN** el tag es una versión concreta (ej. `grafana/grafana-oss:12.3.1`), no `:latest`
