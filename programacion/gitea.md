[🏠 Inicio](../README.md) > [📂 Programación](_index.md)

# Gitea - Git Service & Mirroring

**Estado**: Planificación Preliminar

[Gitea](https://docs.gitea.com/) será nuestro servidor de Git auto-alojado. El objetivo principal es que actúe como un **Mirror (Espejo)** de los repositorios alojados en [GitHub](https://docs.github.com/), asegurando redundancia y propiedad de los datos.

## Requisitos

- Imagen Docker: `gitea/gitea:latest`
- Base de datos: [PostgreSQL](https://www.postgresql.org/docs/) (recomendado) o [SQLite](https://www.sqlite.org/docs.html) (para cargas bajas).
- Persistencia: Volúmenes para `data` y `config`.

## Estrategia de Sincronización (Mirroring)

El usuario requiere que se mantengan sincronizados con GitHub. Gitea soporta dos tipos de mirroring nativo:

### 1. Pull Mirroring (GitHub -> Gitea)
*Gitea descarga cambios de GitHub periódicamente.*
- **Uso**: Backup automático de repositorios de GitHub en local.
- **Configuración**: Al crear un "Nuevo Migración" en Gitea, se selecciona la opción "Este repositorio será un espejo".
- **Frecuencia**: Configurable (ej. cada 8 horas).

### 2. Push Mirroring (Gitea -> GitHub)
*Gitea sube cambios a GitHub cuando hay un push local.*
- **Uso**: Trabajar localmente en la Raspberry Pi y que los cambios se reflejen en GitHub.
- **Configuración**: En los ajustes del repositorio en Gitea > Mirror Settings > Push Mirrors.
- **Requisito**: Token de acceso personal (PAT) de GitHub con permisos de repo.

## Configuración Docker (Borrador)

```yaml
version: "3"
services:
  server:
    image: gitea/gitea:latest
    container_name: gitea
    environment:
      - USER_UID=1000
      - USER_GID=1000
    restart: always
    volumes:
      - ./data:/data
      - /etc/timezone:/etc/timezone:ro
      - /etc/localtime:/etc/localtime:ro
    ports:
      - "3000:3000"
      - "2222:22" # Puerto SSH alternativo para evitar conflicto con el host
```

## Notas de Implementación
- Se necesitará crear un **GitHub Personal Access Token** para configurar la sincronización.
- Definir si la sincronización será bidireccional automática o si se priorizará una dirección (ej. GitHub como fuente de verdad).
