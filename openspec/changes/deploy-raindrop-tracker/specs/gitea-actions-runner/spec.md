## ADDED Requirements

### Requirement: act_runner integrado en el stack de Gitea
El servicio `act-runner` SHALL ejecutarse como contenedor Docker dentro del mismo compose que Gitea, conectado a Gitea por la red interna de Docker.

#### Scenario: Runner conectado a Gitea por red interna
- **WHEN** el servicio `act-runner` arranca junto al stack de Gitea
- **THEN** se registra contra `http://gitea:3000` (sin pasar por el puerto expuesto al host) y aparece como activo en el panel de administración

---

### Requirement: Acceso al socket de Docker del host
El runner SHALL tener acceso al socket `/var/run/docker.sock` del host para poder lanzar contenedores de ejecución de jobs.

#### Scenario: Jobs ejecutados como contenedores Docker
- **WHEN** Gitea dispara un job en un workflow
- **THEN** el runner crea un contenedor Docker en el host de la raspi para ejecutar los pasos del job

---

### Requirement: Persistencia del estado del runner
Los datos de registro del runner (token, nombre, configuración) SHALL persistir en un bind mount para sobrevivir recreaciones del contenedor.

#### Scenario: Runner no necesita re-registro tras recreación
- **WHEN** el contenedor `act-runner` se recrea (update, restart)
- **THEN** el runner mantiene su registro previo en Gitea sin necesitar un nuevo token

---

### Requirement: Gitea Actions habilitado en app.ini
Actions SHALL estar habilitado en la configuración de Gitea (`[actions] ENABLED = true`) para que los repos puedan usar workflows.

#### Scenario: Panel de Actions visible en repos
- **WHEN** Actions está habilitado en app.ini y el runner está registrado
- **THEN** los repositorios muestran la pestaña "Actions" en su interfaz web
