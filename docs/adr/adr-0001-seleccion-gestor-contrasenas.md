---
title: "ADR-0001: Selección de Gestor de Contraseñas"
status: "Accepted"
date: "2025-12-30"
authors: "Usuario"
tags: ["seguridad", "herramientas", "gestión"]
supersedes: ""
superseded_by: ""
---

# ADR-0001: Selección de Gestor de Contraseñas

## Status

**Accepted**

## Context

El proyecto requiere un sistema centralizado y seguro para la gestión de credenciales (contraseñas, claves API, claves SSH). Los requisitos principales identificados son:
- **Costo**: Preferencia por soluciones de bajo costo o gratuitas.
- **Integración Multiplataforma**: Debe funcionar fluidamente en Linux, Windows y Android.
- **Facilidad de Uso**: La experiencia de usuario debe ser sencilla, minimizando la fricción en la sincronización.
- **Seguridad y Confianza**: La solución debe tener una reputación sólida de seguridad.

Se evaluaron tres opciones principales: Bitwarden, KeePassXC y 1Password.

## Decision

Se ha seleccionado **Bitwarden** como el gestor de contraseñas oficial para el proyecto.

Esta decisión se basa en su equilibrio óptimo entre funcionalidad gratuita, seguridad de código abierto y facilidad de sincronización en la nube sin configuraciones complejas adicionales.

## Consequences

### Positive

- **POS-001**: **Costo Cero**: La versión gratuita cubre todas las necesidades actuales del proyecto.
- **POS-002**: **Sincronización Automática**: Elimina la necesidad de gestionar manualmente la sincronización de archivos de base de datos entre dispositivos.
- **POS-003**: **Código Abierto**: Permite auditoría de seguridad y ofrece la posibilidad futura de auto-alojamiento (Self-hosting) mediante Vaultwarden.
- **POS-004**: **Integración**: Dispone de clientes nativos robustos para todas las plataformas requeridas (Windows, Linux, Android).

### Negative

- **NEG-001**: **Dependencia de Terceros**: Al usar la nube de Bitwarden (por defecto), confiamos la disponibilidad a un tercero, a diferencia de una solución local pura como KeePassXC.
- **NEG-002**: **Complejidad de Auto-alojamiento**: Si se decide migrar a self-hosted en el futuro, requerirá mantenimiento de infraestructura adicional (Docker, backups, seguridad).

## Alternatives Considered

### KeePassXC

- **ALT-001**: **Description**: Gestor de contraseñas local, gratuito y de código abierto que guarda las claves en un archivo cifrado `.kdbx`.
- **ALT-002**: **Rejection Reason**: La sincronización entre dispositivos no es nativa. Requiere configurar servicios externos (Dropbox, Syncthing, Google Drive) para mantener la base de datos actualizada en todos los dispositivos, lo cual añade fricción y complejidad operativa en comparación con Bitwarden.

### 1Password

- **ALT-003**: **Description**: Gestor de contraseñas comercial de alta calidad con excelente UX y seguridad.
- **ALT-004**: **Rejection Reason**: Descartado principalmente por el costo. Es una solución de pago por suscripción que no ofrece una capa gratuita suficiente para los requisitos de "gastar poco dinero", y es de código cerrado.

## Implementation Notes

- **IMP-001**: Instalar el cliente de escritorio en la estación de trabajo Windows y en los entornos Linux con interfaz gráfica.
- **IMP-002**: Instalar la extensión de navegador en los navegadores principales.
- **IMP-003**: Instalar la aplicación móvil en Android.
- **IMP-004**: (Opcional) Evaluar la implementación de Vaultwarden en la Raspberry Pi en una fase futura del proyecto.

## References

- **REF-001**: [Bitwarden Official Site](https://bitwarden.com/)
- **REF-002**: [KeePassXC Official Site](https://keepassxc.org/)
