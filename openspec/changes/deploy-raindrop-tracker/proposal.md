## Why

El proyecto `raindrop-tracker` está listo para ejecutarse pero no tiene ningún mecanismo de despliegue automatizado en la Raspberry Pi. Se quiere que sea el primer proyecto personal desplegado con un pipeline CI/CD completo usando Gitea Actions, sentando la base para futuros proyectos propios.

## What Changes

- Añadir `raindrop-tracker` al manifiesto IaC (`compose/manifest.yml`) con su compose de despliegue.
- Crear el compose definitivo del servicio en `compose/raindrop-tracker/docker-compose.yml`.
- Añadir el compose del `act_runner` de Gitea al stack de Gitea (`compose/gitea/docker-compose.yml`).
- Crear el workflow de Gitea Actions en el repo `raindrop-tracker` (`.gitea/workflows/bookmark-updated.yml`).
- Documentar los dos bloques nuevos: despliegue de proyectos personales y configuración de Gitea Actions.

## Capabilities

### New Capabilities

- `personal-project-deployment`: Mecanismo estándar para desplegar proyectos personales en la raspi: clone del repo, `.env` local, compose registrado en el manifiesto, cron del host para scheduling.
- `gitea-actions-runner`: Runner `act_runner` integrado en el stack de Gitea para ejecutar workflows CI/CD en la raspi.
- `raindrop-tracker-service`: Servicio concreto que ejecuta el fetch periódico de bookmarks, hace commit y push, y dispara una Gitea Action.

### Modified Capabilities

- `gitea-vcs`: Se añade el runner `act_runner` como nuevo servicio al compose existente de Gitea, extendiendo sus capacidades de VCS a CI/CD.

## Impact

- `compose/manifest.yml`: nueva entrada `raindrop-tracker`.
- `compose/gitea/docker-compose.yml`: nuevo servicio `act-runner`.
- `compose/raindrop-tracker/docker-compose.yml`: fichero nuevo.
- Repo `raindrop-tracker`: nuevo fichero `.gitea/workflows/bookmark-updated.yml`.
- Docs: `proyectos/raindrop-tracker.md` y `programacion/gitea-actions.md` (ya creados en esta sesión, pueden necesitar ajustes menores al implementar).
