## Why

Gitea funciona correctamente como servidor Git local, pero los repositorios no tienen copia en la nube. Si la Raspberry Pi falla, todos los repositorios locales se pierden. El mirroring con GitHub proporciona backup automático offsite sin coste adicional.

## What Changes

- Crear un Personal Access Token (PAT) en GitHub con scope `repo` para el usuario de mirroring
- Configurar un push mirror en Gitea para el repositorio `raspi-docs` apuntando a su equivalente en GitHub
- Verificar la sincronización inicial y documentar el proceso para futuros repositorios

## Capabilities

### New Capabilities
_(ninguna)_

### Modified Capabilities
- `gitea-vcs`: se añade capacidad de mirroring unidireccional (push) hacia GitHub

## Impact

- **Gitea**: configuración de mirror vía UI de administración o API de Gitea
- **GitHub**: requiere repositorio destino creado y PAT con permisos de escritura
- **Red**: tráfico HTTPS saliente desde Pi → `github.com` (puerto 443)
- **Credenciales**: el PAT se almacena en Gitea — gestionar con cuidado, no exponer en el repo
- **Sincronización**: el mirror es unidireccional (Gitea → GitHub); los cambios en GitHub no se propagan automáticamente
