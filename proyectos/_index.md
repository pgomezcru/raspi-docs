[🏠 Inicio](../README.md)

# Proyectos Personales

Servicios desarrollados por el usuario y desplegados en la Raspberry Pi. A diferencia de los servicios de infraestructura, estos proyectos tienen su propio repositorio de código, ciclo de vida independiente y se despliegan mediante Gitea Actions.

## Convenciones

- El código fuente vive en un repositorio separado (en Gitea / GitHub).
- El despliegue se define en un fichero `docker-compose.yml` dentro del propio repo del proyecto.
- El compose se registra en [`compose/manifest.yml`](../compose/manifest.yml) de este repo para el despliegue automatizado.
- Las Actions del pipeline se definen en `.gitea/workflows/` del repo del proyecto.

## Proyectos

| Proyecto | Estado | Descripción |
|----------|--------|-------------|
| [raindrop-tracker](raindrop-tracker.md) | Planificado | Descarga y versiona bookmarks de Raindrop.io vía cron + git |
