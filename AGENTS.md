# AGENTS.md

## Descripción del proyecto

Este repositorio contiene documentación, guías y registros de un servidor doméstico en una Raspberry Pi. El objetivo principal no es crear un producto software, sino documentar el proceso, desarrollar ideas y mantener un registro de actividades del home lab.

**Tecnologías clave**: Raspberry Pi, Linux, Home Assistant, Docker, Networking, Markdown, Claude Code.

## Guías de contenido

- **Idioma principal**: Español. Toda la documentación y guías deben escribirse en español.
- **Enfoque**: Documentos claros y orientados a ejemplos.
- **Fragmentos de código**: Preferir snippets embebidos listos para copiar-pegar sobre scripts completos, salvo que se pida explícitamente lo contrario.
- **Estilo**: Práctico, orientado a guías y entradas de registro.
- **Comentarios del usuario**: Las comillas dobles (`>>`) están estrictamente reservadas para comentarios del usuario (opiniones, acciones realizadas, dudas, reflexiones).
- **Bloques de cita estándar**: Las comillas simples (`>`) están autorizadas para contenido general de documentación (notas, advertencias, cajas informativas).
- **Cabecera de navegación**: Todo documento debe comenzar con una cabecera de navegación que enlace al índice padre y a la raíz. Ejemplo: `[🏠 Inicio](../README.md) > [📂 Sección padre](_index.md)`
- **Referencias oficiales**: Al introducir software o tecnología nueva, SIEMPRE incluir un enlace a la documentación oficial.
- **Verificación de URLs**: Al añadir enlaces a documentación oficial o recursos externos, SIEMPRE usar `fetch` para verificar que la URL es válida (código 200 OK) antes de incluirla.
- **Contexto tecnológico**: Al documentar nuevas tecnologías, SIEMPRE abordar los siguientes aspectos transversales:
  - **Seguridad**: Autenticación, permisos y riesgos de exposición.
  - **Proxy**: Configuración del proxy inverso (si aplica).
  - **Firewall**: Puertos a abrir/cerrar (UFW).
  - **Fail2Ban**: Configuración de jail para protección contra fuerza bruta.
  - **Almacenamiento**: Estrategia de persistencia (SD vs. SSD vs. NAS) según necesidades de I/O.
  - **Homarr**: Instrucciones de integración en el dashboard. **Documentar dos valores separados en el Markdown del servicio:**
    - **URL pública (enlaces de Homarr)**: usar el nombre DNS gestionado por `nginx` (ej. `https://grafana.home.lab`). Verificar el enlace con `fetch` antes de incluirlo.
    - **Configuración de integración (Homarr internal)**: usar el `container_name` interno y el puerto interno del servicio (ej. `grafana:3000`) como objetivo de la integración.
    - **Requisito en documentación**: Todo servicio nuevo o modificado debe incluir una sección `Homarr` con los campos: `public_url` (DNS nginx) e `integration_target` (container:port).
- **Tecnologías horizontales**: Identificar tecnologías con implicaciones amplias en el proyecto. Si se introduce una nueva, añadirla a la lista de **Tecnologías clave**.

## Guías de Docker

Al generar ejemplos de `docker-compose.yml` o documentación, seguir estrictamente estas convenciones:

- **Bind-Mounts**: Usar bind mounts para datos internos persistentes. Las carpetas deben crearse en `/mnt/usb-data/docker-root/<container-name>/<volumen>/` con los permisos adecuados:
  - Config y logs: propietario `admin:docker`.
  - Certificados privados: `root:root` con permisos 750.
- **Nombrado explícito**: SIEMPRE nombrar los volúmenes explícitamente para garantizar predecibilidad.
- **Red**: Los servicios expuestos via proxy inverso DEBEN conectarse a la red externa `proxy_net`. Incluir `restart: unless-stopped` si se desea arranque automático.
- **Estructura de referencia**:
  ```yaml
  services:
    app:
      volumes:
        - ./config:/app/config
      networks:
        - proxy_net
        - default
      restart: unless-stopped
  volumes:
    app-data:
      name: app-data
  networks:
    proxy_net:
      external: true
  ```

## Arquitectura y toma de decisiones

- **Consultar ADRs**: Antes de realizar cambios significativos o proponer nueva arquitectura, SIEMPRE consultar los Architecture Decision Records (ADRs) existentes para conocer decisiones pasadas.
- **Obligatoriedad de ADR**: Ante preguntas arquitectónicas o cambios relevantes, SIEMPRE proponer un ADR completo para mantener el historial de decisiones.
- **Actualizar ADRs**: Crear nuevos ADRs o actualizar los existentes cuando las decisiones evolucionen o surja nuevo contexto.
- **Formato ADR**:
  1. **Título**: Corto y descriptivo.
  2. **Estado**: Proposed, Accepted, Deprecated, etc.
  3. **Contexto**: ¿Qué problema motiva esta decisión o cambio?
  4. **Decisión**: ¿Qué cambio se propone y/o realiza?
  5. **Consecuencias**: ¿Qué se vuelve más fácil o difícil? ¿Qué riesgos introduce?

## Estructura de directorios

La documentación cubre:
- **Hardware**: Equipos de red, servidores (Pi 4, NAS, etc.), clientes.
- **Servicios**: Servicios self-hosted (NAS, Media, Impresión, Pi-hole, Home Assistant, etc.).
- **Experimentos**: Dev, Seguridad, Electrónica.

**Organización en subproyectos**:
- Cada subproyecto (ej. Multimedia, Programación, NAS, Ebook) DEBE tener su propia carpeta dedicada.
- Buscar siempre información relevante dentro de la carpeta del subproyecto correspondiente.
- Mantener separación clara de responsabilidades; si no existe una carpeta adecuada, crearla siguiendo las convenciones de nomenclatura establecidas.

**Índices y navegación**:
- **_index.md**: Cada carpeta de subproyecto DEBE contener un `_index.md` como tabla de contenidos de esa sección.
- El `_index.md` debe listar todos los documentos de la carpeta con una breve descripción de cada uno.
- El `README.md` raíz debe referenciar estos índices de subproyecto.
- Asegurar referencias cruzadas entre documentos donde sea relevante.

**Registros del proyecto**:
- **_log.md**: Cada subproyecto contiene un `_log.md` donde el usuario registra el progreso manualmente.
- **Restricción para agentes**: Los agentes NO DEBEN modificar los ficheros `_log.md`.
- **Uso de contexto**: Los agentes DEBEN leer `_log.md` para entender el estado actual de la implementación.

## Workspace & Live Environment

- **Unidad I: (montaje de la Raspberry Pi)**: La unidad `I:` representa el sistema de ficheros en vivo de la Raspberry Pi.
- **Lectura libre**: Los agentes DEBEN usar la unidad `I:` para verificar configuraciones actuales, rutas de ficheros y despliegues existentes.
- **Escritura con precaución**: Los agentes PUEDEN editar y crear ficheros en `I:` cuando sea necesario para completar una tarea (ej. modificar un `docker-compose.yml`, ajustar configuración de nginx). Antes de hacerlo, deben mostrar el plan al usuario.
- **Operaciones destructivas**: Eliminar ficheros o directorios en `I:` requiere confirmación explícita del usuario.
- **Ejecución remota**: Para operaciones que requieran ejecutar comandos en la Pi (reiniciar servicios, aplicar cambios), usar SSH según las reglas definidas en la sección **SSH & Remote Execution**.

## SSH y ejecución remota

Los agentes tienen acceso a la Raspberry Pi a través de una cuenta de servicio dedicada (`claude-agent`) con permisos restringidos. El modelo de seguridad completo (creación de usuario, clave SSH, sudoers, hooks de auditoría) está detallado en [ia/claude-code.md](ia/claude-code.md).

### Acceso SSH

- **Alias configurado**: `raspi-claude` → `192.168.1.101`
- **Usuario en la Pi**: `claude-agent` (miembro del grupo `docker`)
- **Autenticación**: Clave Ed25519 dedicada, sin contraseña interactiva.

### Estructura de la Pi

- **Compose files (fuente de verdad)**: `compose/<servicio>/docker-compose.yml` en este repositorio
- **Compose files (destino en la Pi)**: `/mnt/usb-data/<servicio>/docker-compose.yml`
- **Script de despliegue**: `bash ~/raspi-docs/compose/deploy.sh <servicio>` (como `admin` en la Pi)
- Volumes: `/mnt/usb-data/<servicio>/` y `/mnt/usb-data/docker-root/volumes/` (volúmenes nombrados)
- Red interna: `proxy_net` (external, definida en Docker)

### Flujo de despliegue

Cualquier cambio en un `docker-compose.yml` sigue este flujo:
1. Editar `compose/<servicio>/docker-compose.yml` en el repo
2. `git push` → Gitea
3. En la Pi como `admin`: `git pull && bash ~/raspi-docs/compose/deploy.sh <servicio>`
4. `cd /mnt/usb-data/<servicio> && docker compose up -d`

Ver [infraestructura/despliegue-compose.md](infraestructura/despliegue-compose.md) para la guía completa.

### Reglas de operación

- SIEMPRE mostrar el plan antes de ejecutar cambios.
- Para despliegues: revisar el `docker-compose.yml` antes de hacer `docker compose up`.
- NO ejecutar comandos destructivos (`rm -rf`, `dd`, `mkfs`, etc.). Si es necesario eliminar algo, pedirlo al usuario.
- Documentar cualquier cambio realizado en los ficheros Markdown del repositorio.

Los comandos permitidos, los que requieren confirmación y los prohibidos están detallados en [ia/agent-ssh-commands.md](ia/agent-ssh-commands.md).

## Flujo de trabajo

- Proyecto centrado en documentación; los ficheros son principalmente Markdown (`.md`).
- Asegurar que los enlaces entre documentos son relativos y funcionan correctamente.
- **Mantenimiento del TODO**: Mantener [TODO.md](TODO.md) actualizado. Cuando surjan ideas, tareas o trabajo pendiente durante la documentación o planificación, añadirlos al TODO inmediatamente.
- **Comandos de build**: Actualmente es un repositorio Markdown plano sin pasos de build. Si se añade un generador de sitio estático, documentar los comandos aquí.

## Control de versiones y compatibilidad

- **Prioridad alta**: Antes de actualizar cualquier software o imagen, documentar la versión exacta usada y la fecha de la prueba.
- **Pinear versiones**: En ejemplos y `docker-compose.yml` preferir etiquetas concretas (`image: grafana/grafana:9.0.2`) y evitar `:latest` en documentación reproducible.
- **Matriz de compatibilidad**: Mantener (en la carpeta `infraestructura/` o `docs/`) un archivo `compatibilidad.md` o una tabla en el documento del servicio que indique las versiones recomendadas y las comprobadas entre componentes críticos (ej. Docker Engine, Compose, Prometheus, Grafana, Home Assistant, Vaultwarden).
- **Pruebas de compatibilidad**: Antes de desplegar, probar actualizaciones en un entorno controlado (puede ser una VM o un host de pruebas) e incluir resultados en la ADR o en la documentación del servicio.
- **Notas de lanzamiento**: Revisar siempre las notas de release upstream para breaking changes y documentar cualquier ajuste requerido en la guía del servicio.
- **Registro en documentación del servicio**: Cada guía de servicio debe incluir una sección `Compatibilidad` con versiones probadas, restricciones conocidas y enlaces a notas de lanzamiento (verificados con `fetch`).
- **Rollback y backups**: Documentar el plan de rollback y puntos de restauración antes de aplicar actualizaciones que cambien esquemas o datos persistentes.
- **Reporte de incompatibilidades**: Si un agente detecta o reproduce una incompatibilidad, crear una entrada en `TODO.md` y generar o actualizar un ADR si la decisión de compatibilidad afecta la arquitectura.

## Guías de contribución

- **Idioma**: Todas las contribuciones deben estar en español.
- **Commits**: Deben describir la documentación añadida o actualizada.
- **Nuevas guías**: Deben seguir las **Guías de contenido** (enfoque en ejemplos, snippets listos para usar).
