## Why

El contenedor `cadvisor` en producción usa la imagen `gcr.io/cadvisor/cadvisor:latest`, mientras que `compose/prometheus/docker-compose.yml` ya tiene `v0.55.1` pinneado. El contenedor nunca se redeployó tras el fix de versiones (commit `db91910`). Esta divergencia viola la política de AGENTS.md y supone riesgo de rotura silenciosa en la siguiente actualización de `:latest`.

## What Changes

- Redesplegar el contenedor `cadvisor` usando el compose del repositorio, que ya tiene `v0.55.1`
- Verificar que el contenedor en producción muestra la versión correcta
- Actualizar `estado.md` para reflejar la divergencia resuelta

## Capabilities

### New Capabilities
_(ninguna)_

### Modified Capabilities
_(ninguna — corrección operativa, no cambia requisitos)_

## Impact

- **Tiempo de inactividad**: segundos (recreación del contenedor)
- **Datos**: cadvisor es stateless, no hay pérdida de datos
- **Métricas**: breve interrupción en métricas de cadvisor durante el redespliegue
- **Compose**: no requiere cambios, el compose ya tiene la versión correcta
