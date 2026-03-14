# AGENTS.md

## Project Overview

This repository contains documentation, guides, and logs for a home server setup on a Raspberry Pi. The primary goal is not to create a software product, but to document the process, develop ideas, and maintain a log of activities related to the home lab.

**Key Technologies**: Raspberry Pi, Linux, Home Assistant, Docker, Networking, Markdown.

## Content Guidelines

- **Primary Language**: Spanish (Español). All documentation and guides should be written in Spanish.
- **Focus**: Create clear, example-focused documents.
- **Code Snippets**: Prefer embedded code snippets that are ready to copy-paste over complete scripts, unless explicitly requested otherwise.
- **Style**: Practical, guide-oriented, and log-style entries.
- **User Comments**: Double blockquotes (`>>`) are strictly reserved for user comments (opinions, actions taken, doubts, reflections).
- **Standard Blockquotes**: Single blockquotes (`>`) are authorized for general documentation content (notes, warnings, info boxes).
- **Navigation Header**: Every document must start with a navigation header linking to the Parent Index and the Root (Home). Example: `[🏠 Inicio](../README.md) > [📂 Parent Section](_index.md)`
- **Official References**: When introducing new software or technology, ALWAYS include a link to the official documentation for reference.
- **URL Verification**: When adding links to official documentation or external resources, ALWAYS use `fetch` to verify that the URL is valid (returns status 200 OK) before including it.
- **Technology Context**: When documenting new technologies, ALWAYS address the following cross-cutting concerns:
  - **Security**: Authentication, permissions, and exposure risks.
  - **Proxy**: Reverse proxy configuration (if applicable).
  - **Firewall**: Ports to open/close (UFW).
  - **Fail2Ban**: Jail configuration for brute-force protection.
  - **Storage**: Persistence strategy (SD vs. SSD vs. NAS) based on I/O needs.
  - **Homarr**: Integration instructions for the dashboard, ranging from simple links to complex API integrations. **Cuando se añadan servicios a Homarr, documentar dos valores separados en el Markdown del servicio:**
    - **URL pública (enlaces de Homarr)**: usar el nombre DNS gestionado por `nginx` (ej. `https://grafana.home.lab`). Verificar el enlace con `fetch` antes de incluirlo.
    - **Configuración de integración (Homarr internal)**: usar el `container_name` interno y el puerto interno del servicio (ej. `grafana:3000`) como objetivo de la integración.
    - **Requisito en documentación**: Todo servicio nuevo o modificado debe incluir una sección `Homarr` en su documento Markdown con los campos claros: `public_url` (DNS nginx) y `integration_target` (container:port). Esto ayuda a mantener la separación entre la URL visible por el usuario y la configuración de red interna requerida por Homarr.
- **Horizontal Technologies**: Identify technologies with broad implications across the project. If a new horizontal technology is introduced, suggest adding it to the "Key Technologies" list in `AGENTS.md`.

## Docker Guidelines

When generating `docker-compose.yml` examples or documentation, strictly follow these volume strategies:

- **Bind-Mounts**: Use `bind mounts` for persistent internal data.
 -**Volume Assigned Folders**: When describing a docker-compose setup, folders should be created in the filesystem in the docker-root path (``/mnt/usb-data/docker-root/<container-name>/<volume>``) and permissions set accordingly:
  - Config and logs owned by admin:docker (regular user)
  - Private certificates owned by root:root with 750 permissions.
  - Other data folders should be secured as needed, but only root owned if absolutely necessary.
- **Explicit Naming**: ALWAYS explicitly name volumes to ensure predictability.
  ```yaml
  volumes:
    my-volume:
      name: my-volume
  ```
- **Structure**:
  ```yaml
  services:
    app:
      volumes:
        - ./config:/app/config     # Bind mount for config
  volumes:
    app-data:
      name: app-data
  ```

- **Network Configuration**:
  - All services intended to be exposed via the reverse proxy MUST connect to the `proxy_net` external network.
  - Ensure `proxy_net` is defined as external in the `networks` section.
  ```yaml
  services:
    app:
      networks:
        - proxy_net
        - default
  networks:
    proxy_net:
      external: true
  ```
 - **Run on startup**: For each service, we should evaluate if we want the service on boot. If so, include `restart: unless-stopped` in the service definition.

## Architecture & Decision Making

- **Consult ADRs**: Before making significant changes or proposing new architecture, ALWAYS consult existing Architecture Decision Records (ADRs) to understand past decisions.
- **ADR Requirement**: When discussing architectural questions or significant changes, ALWAYS propose a complete Architecture Decision Record (ADR) to maintain a history of decisions.
- **Update ADRs**: Create new ADRs or update existing ones as needed when decisions evolve or new contexts arise.
- **ADR Format**:
  1.  **Title**: Short and descriptive.
  2.  **Status**: Proposed, Accepted, Deprecated, etc.
  3.  **Context**: What is the issue that we're seeing that is motivating this decision or change?
  4.  **Decision**: What is the change that we're proposing and/or doing?
  5.  **Consequences**: What becomes easier or more difficult to do and any risks introduced by this change.

## Directory Structure Context

Based on the project goals, the documentation covers:
- **Hardware**: Network gear, servers (Pi 4, NAS, etc.), clients.
- **Services**: Self-hosted services (NAS, Media, Print, Pi-hole, Home Assistant, etc.).
- **Experiments**: Dev, Security, Electronics.

**Subproject Organization**:
- Each subproject (e.g., Multimedia, Coding, NAS, Ebook or others) MUST have its own dedicated folder.
- Always search for relevant information within the specific subproject folder.
- Maintain a clean separation of concerns by keeping files within their respective subproject directories.
- If a suitable subproject folder does not exist for new content, create one following the established naming conventions.

**Indexing & Navigation**:
- **_index.md**: Each subproject folder MUST contain an `_index.md` file serving as the table of contents for that section.
- **Content Listing**: The `_index.md` must list all documents in that folder with a brief description of each.
- **Main README**: The root `README.md` must reference these subproject indices.
- **Cross-Referencing**: Ensure documents are cross-referenced where relevant to maintain a cohesive knowledge base.

**Project Logs**:
- **_log.md**: Each subproject contains a `_log.md` file where the user manually records progress.
- **Agent Restriction**: Agents MUST NOT modify `_log.md` files.
- **Context Usage**: Agents SHOULD read `_log.md` to understand the current implementation status.

## Workspace & Live Environment

- **Drive I: (Raspberry Pi Mount)**: The `I:` drive represents the live filesystem of the Raspberry Pi.
- **Read-Only Policy**: Agents should be extremely careful when editing, creating, or deleting files on the `I:` drive. Only explicitly authorized changes should be made.
- **Reference Use**: Agents SHOULD use the `I:` drive to verify current configurations, file paths, and existing deployments.
- **Manual Changes**: Any necessary changes to the live environment identified by the agent must be communicated to the user for manual execution.

## SSH & Remote Execution

- **Target**: The Raspberry Pi server is located at `192.168.1.101`.
- **User**: `admin`.
- **Authentication**: The user will handle password entry for SSH sessions.
- **Read-Only Policy**: Agents are STRICTLY PROHIBITED from executing commands that modify the system state (e.g., `apt install`, `rm`, `systemctl restart`, editing files).
- **Allowed Actions**: Agents may only execute inspection commands (e.g., `ls`, `cat`, `docker ps`, `systemctl status`, `df -h`) to gather context.

## Development Workflow

- This is a documentation-centric project.
- Files are primarily Markdown (`.md`).
- Ensure links between documents are relative and working.
- **TODO Maintenance**: Keep [TODO.md](TODO.md) updated. When new ideas, tasks, or pending work arise during documentation or planning, add them to the TODO list immediately.

## Setup Commands

- Currently, this is a plain Markdown repository.
- No specific build steps are required yet (unless a static site generator is added later).

## Control de versiones y compatibilidad

- **Prioridad alta**: Antes de actualizar cualquier software o imagen, documentar la versión exacta usada y la fecha de la prueba.
- **Pinear versiones**: En ejemplos y `docker-compose.yml` preferir etiquetas concretas (`image: grafana/grafana:9.0.2`) y evitar `:latest` en documentación reproducible.
- **Matriz de compatibilidad**: Mantener (en la carpeta `infraestructura/` o `docs/`) un archivo `compatibilidad.md` o una tabla en el documento del servicio que indique las versiones recomendadas y las comprobadas entre componentes críticos (ej. Docker Engine, Compose, Prometheus, Grafana, Home Assistant, Vaultwarden).
- **Pruebas de compatibilidad**: Antes de desplegar, probar actualizaciones en un entorno controlado (puede ser una VM o un host de pruebas) e incluir resultados en la ADR o en la documentación del servicio.
- **Notas de lanzamiento**: Revisar siempre las notas de release upstream para breaking changes y documentar cualquier ajuste requerido en la guía del servicio.
- **Automatización mínima**: Cuando sea posible, añadir checks simples (scripts en `scripts/`) que verifiquen versiones instaladas y alerten si hay incompatibilidades conocidas.
- **Registro en documentación del servicio**: Cada guía de servicio (p. ej. `infraestructura/bitwarden-setup.md`, `monitoring/prometheus.md`) debe incluir una sección `Compatibilidad` con:
  - **Versiones probadas**: lista corta con versiones exactas.
  - **Restricciones conocidas**: bloqueo o requisitos mínimos.
  - **Enlaces a notas de lanzamiento**: links verificados con `fetch` cuando se incluyan.
- **Rollback y backups**: Documentar el plan de rollback y puntos de restauración antes de aplicar actualizaciones que cambien esquemas o datos persistentes.
- **Reporte de incompatibilidades**: Si un agente detecta o reproduce una incompatibilidad, crear una entrada en `TODO.md` y generar o actualizar un ADR si la decisión de compatibilidad afecta la arquitectura.

## Pull Request / Contribution Guidelines

- **Language**: All contributions must be in Spanish.
- **Commits**: Should be descriptive of the documentation added or updated.
- **New Guides**: Should follow the "Content Guidelines" above (Example-focused, Snippets).
