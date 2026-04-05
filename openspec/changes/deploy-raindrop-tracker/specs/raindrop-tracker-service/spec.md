## ADDED Requirements

### Requirement: Ejecución periódica vía cron del host
El servicio raindrop-tracker SHALL ejecutarse periódicamente mediante una entrada de cron en la raspi, no como daemon Docker.

#### Scenario: Cron lanza el contenedor cada 6 horas
- **WHEN** el cron del host ejecuta `docker compose run --rm raindrop-tracker`
- **THEN** el contenedor arranca, descarga los bookmarks, hace commit si hay cambios, hace push, y termina

#### Scenario: Sin cambios, no hay commit
- **WHEN** el fetch de Raindrop no produce diferencias respecto al estado anterior
- **THEN** el script no genera ningún commit (`git diff --quiet --cached` retorna 0)

---

### Requirement: Push automático con SSH key dedicada
El contenedor SHALL usar una SSH key específica para el bot (`raindrop-tracker-bot`) al hacer git push a Gitea, montada como volumen de solo lectura.

#### Scenario: Push exitoso con key del bot
- **WHEN** el contenedor ejecuta `git push` con la key montada en `/root/.ssh/id_ed25519`
- **THEN** el push se autentica en Gitea usando la deploy key del repo y los cambios llegan al remoto

---

### Requirement: Disparo de Gitea Action tras push
Cada push al repo raindrop-tracker SHALL disparar el workflow `.gitea/workflows/bookmark-updated.yml` únicamente cuando hay cambios en `data/`.

#### Scenario: Action ejecutada tras push con cambios en data/
- **WHEN** el contenedor hace push y el commit incluye ficheros bajo `data/`
- **THEN** Gitea dispara el workflow `bookmark-updated` y el runner ejecuta los pasos definidos

#### Scenario: Action no ejecutada si no hay cambios en data/
- **WHEN** un push al repo no incluye cambios en `data/` (ej. cambio en README)
- **THEN** el workflow `bookmark-updated` no se dispara (filtrado por `paths:`)

---

### Requirement: Logging persistente de ejecuciones
La salida de cada ejecución del cron SHALL redirigirse a `/var/log/raindrop-tracker.log` en la raspi.

#### Scenario: Log disponible tras ejecución
- **WHEN** el cron ejecuta el contenedor
- **THEN** stdout y stderr del proceso se añaden a `/var/log/raindrop-tracker.log` en el host
