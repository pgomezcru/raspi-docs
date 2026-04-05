## ADDED Requirements

### Requirement: Registro de proyectos personales en el manifiesto IaC
Los proyectos personales desplegables en la raspi SHALL registrarse en `compose/manifest.yml` siguiendo la misma convención que los servicios de infraestructura.

#### Scenario: Proyecto registrado en manifest.yml
- **WHEN** se añade un proyecto personal al manifiesto con entradas `compose` y `target`
- **THEN** `deploy.sh` puede copiar el compose de despliegue a la ruta correcta en la raspi

---

### Requirement: Compose de despliegue separado del de desarrollo
Cada proyecto personal SHALL tener un `docker-compose.yml` de producción en `compose/<proyecto>/` de este repo, distinto del compose que pueda tener el repo del proyecto.

#### Scenario: Compose de producción sin montajes de desarrollo
- **WHEN** el compose de producción de un proyecto se despliega en la raspi
- **THEN** no incluye montajes de directorios del desarrollador (ej. `~/.ssh` personal) y usa rutas absolutas de la raspi

---

### Requirement: Repo del proyecto clonado en /mnt/usb-data/
El código fuente de cada proyecto personal SHALL residir en `/mnt/usb-data/<proyecto>/` en la raspi, clonado desde Gitea.

#### Scenario: Clone inicial del proyecto
- **WHEN** se despliega un proyecto personal por primera vez
- **THEN** se clona el repo en `/mnt/usb-data/<proyecto>/` y el compose de producción se copia encima vía `deploy.sh`

---

### Requirement: Variables de entorno en fichero .env local
Las credenciales y configuración sensible de cada proyecto SHALL residir en `/mnt/usb-data/<proyecto>/.env`, nunca en el repositorio.

#### Scenario: .env no versionado
- **WHEN** el repo del proyecto se clona en la raspi
- **THEN** el fichero `.env` no existe; debe crearse manualmente a partir de `.env.example`
