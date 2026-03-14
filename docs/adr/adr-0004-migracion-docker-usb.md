---
title: "ADR-0004: Migración de Docker Root a Almacenamiento USB"
status: "Accepted"
date: "2025-12-31"
authors: "Admin"
tags: ["infraestructura", "docker", "almacenamiento", "rendimiento"]
supersedes: ""
superseded_by: ""
---

# ADR-0004: Migración de Docker Root a Almacenamiento USB

## Status

**Accepted**

## Context

La Raspberry Pi 4 utiliza por defecto una tarjeta SD para el sistema operativo y el almacenamiento de datos. Docker, por su naturaleza, realiza operaciones intensivas de lectura/escritura (I/O) en su directorio raíz (`/var/lib/docker`), donde se almacenan imágenes, contenedores y volúmenes.

Las tarjetas SD tienen limitaciones significativas:
1.  **Baja velocidad de escritura aleatoria**: Afecta el rendimiento de bases de datos y compilaciones.
2.  **Vida útil limitada**: Las escrituras constantes degradan la tarjeta, llevando a corrupción de datos y fallo del sistema.
3.  **Dificultad de recuperación**: Si la SD falla, se pierden tanto el SO como los datos de los contenedores si no hay backups externos.

Se dispone de un disco USB (SSD o HDD) conectado a la Raspberry Pi y un NAS en la red.

## Decision

Se ha decidido **mover el directorio raíz de Docker (`data-root`) al disco USB externo**, separando así el sistema operativo (SD) de los datos de las aplicaciones (USB).

La configuración se realizará mediante el archivo `/etc/docker/daemon.json`, apuntando a una ruta en el punto de montaje del USB (ej. `/mnt/usb-data/docker`).

## Consequences

### Positive

- **POS-001**: **Mayor Rendimiento**: El bus USB 3.0 ofrece un ancho de banda y IOPS muy superiores a la interfaz SD, mejorando la respuesta de los servicios.
- **POS-002**: **Durabilidad de la SD**: Al eliminar las escrituras intensivas de logs y bases de datos de la SD, se extiende drásticamente su vida útil.
- **POS-003**: **Recuperación ante Desastres**: En caso de fallo del SO (SD corrupta), los datos de los servicios permanecen intactos en el USB. Basta con flashear una nueva SD, instalar Docker y apuntar al USB para recuperar el estado anterior.
- **POS-004**: **Portabilidad**: El disco USB con los datos puede conectarse a otra Raspberry Pi o PC Linux en caso de fallo de hardware de la placa.

### Negative

- **NEG-001**: **Dependencia de Hardware**: El arranque de los servicios Docker dependerá de que el disco USB esté correctamente montado al inicio.
- **NEG-002**: **Punto Único de Fallo**: Si el disco USB falla, todos los servicios se detienen (mitigable con backups al NAS).
- **NEG-003**: **Complejidad de Configuración**: Requiere pasos adicionales post-instalación de Docker y gestión correcta de `/etc/fstab`.

## Alternatives Considered

### Mantener Docker en la SD

- **ALT-001**: **Description**: Usar la configuración por defecto.
- **ALT-002**: **Rejection Reason**: Alto riesgo de corrupción de la SD a corto/medio plazo y rendimiento subóptimo para servicios como Gitea o Jenkins.

### Mover Docker al NAS (NFS)

- **ALT-003**: **Description**: Montar `/var/lib/docker` sobre un share NFS del NAS.
- **ALT-004**: **Rejection Reason**: Latencia de red inaceptable para operaciones de sistema de archivos de Docker (overlayfs). Problemas de compatibilidad con ciertos drivers de almacenamiento y bloqueo de archivos (file locking).

### Boot desde USB (Sin SD)

- **ALT-005**: **Description**: Eliminar la SD y arrancar el SO completo desde el USB.
- **ALT-006**: **Rejection Reason**: Aunque viable, se prefiere mantener el SO separado de los datos para facilitar la reinstalación del sistema sin tocar la partición de datos. Además, permite usar la SD para el bootloader y configuraciones base si el USB tarda en inicializar.

## Implementation Notes

- **IMP-001**: El disco USB debe montarse automáticamente al inicio vía `/etc/fstab` con la opción `nofail` para no bloquear el boot si el disco no está.
- **IMP-002**: Se debe detener el servicio Docker antes de mover los datos existentes (si los hubiera) y aplicar la configuración.
- **IMP-003**: La ruta recomendada en el USB será `/mnt/usb-data/docker-root`.

## References

- **REF-001**: [Estrategia de Almacenamiento](../infraestructura/estrategia-almacenamiento.md)
- **REF-002**: [Docker Daemon configuration file](https://docs.docker.com/engine/reference/commandline/dockerd/#daemon-configuration-file)
