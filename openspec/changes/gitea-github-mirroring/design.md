## Context

Gitea corre con nginx como proxy inverso y PostgreSQL como backend. El repositorio `raspi-docs` existe en Gitea y es donde se almacena la documentación del homelab. El mismo repositorio existe en GitHub (`github.com/<usuario>/raspi-docs`). El mirroring de Gitea soporta espejos push (Gitea → remoto) y pull (remoto → Gitea).

## Goals / Non-Goals

**Goals:**
- Los commits a `raspi-docs` en Gitea se sincronizan automáticamente con GitHub
- El mirror es unidireccional: Gitea como fuente, GitHub como backup

**Non-Goals:**
- Mirror bidireccional (los cambios en GitHub no se propagan a Gitea)
- Mirroring de otros repositorios en esta fase
- Mirror de issues, PRs o wikis

## Decisions

### 1. Push mirror (Gitea → GitHub)
**Decisión**: configurar un push mirror en Gitea.
**Razón**: el flujo de trabajo es escribir en Gitea local; GitHub es solo backup. Un pull mirror invertiría el flujo de trabajo.

### 2. PAT de GitHub con scope mínimo
**Decisión**: crear un PAT clásico con solo scope `repo` (o un fine-grained token limitado al repositorio específico).
**Razón**: principio de mínimo privilegio. El token solo necesita poder hacer push al repositorio destino.

### 3. Configuración vía UI de Gitea
**Decisión**: configurar el mirror desde la UI de administración de Gitea (Settings → Mirror).
**Razón**: la UI es más segura que la API para introducir credenciales; evita que el PAT quede en logs de comandos.

## Risks / Trade-offs

- **PAT expuesto en Gitea**: el PAT se almacena internamente en Gitea (base de datos PostgreSQL). No se expone en el repo ni en ficheros de configuración. Riesgo bajo.
- **Repositorio GitHub debe existir**: el mirror fallará si el repo destino no existe. Mitigación: crear el repo en GitHub antes de configurar el mirror.
- **Divergencia si se hace push directo en GitHub**: si alguien empuja commits directamente a GitHub, el mirror no los recoge (es unidireccional). Documentar que GitHub es solo backup, no punto de desarrollo.

## Migration Plan

1. Crear (si no existe) el repositorio `raspi-docs` en GitHub
2. En GitHub: Settings → Developer Settings → Personal Access Tokens → crear PAT con scope `repo`
3. En Gitea (`gitea.home.lab`): repositorio `raspi-docs` → Settings → Mirror Settings
4. Configurar push mirror: URL `https://github.com/<usuario>/raspi-docs.git`, usuario y PAT
5. Forzar sincronización inicial y verificar en GitHub que los commits aparecen
6. Documentar en `programacion/gitea.md`: instrucciones para configurar mirrors en futuros repos
