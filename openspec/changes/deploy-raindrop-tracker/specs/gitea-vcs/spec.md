## ADDED Requirements

### Requirement: Runner act_runner en el stack de Gitea
El compose de Gitea SHALL incluir el servicio `act-runner` para habilitar la ejecución de Gitea Actions workflows.

#### Scenario: act-runner arranca con el stack de Gitea
- **WHEN** se ejecuta `docker compose up -d` en el stack de Gitea
- **THEN** el servicio `act-runner` arranca junto a `gitea` y `gitea-db`, con acceso al socket Docker del host
