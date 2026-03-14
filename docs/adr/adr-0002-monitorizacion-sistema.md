---
title: "ADR-0002: Estrategia de Monitorización del Sistema"
status: "Superseded"
date: "2025-12-30"
authors: "Admin"
tags: ["monitorización", "docker", "infraestructura"]
supersedes: ""
superseded_by: "ADR-0005"
---

# ADR-0002: Estrategia de Monitorización del Sistema

## Status

**Superseded** (por ADR-0005)

> Este ADR fue rechazado debido a la dificultad de personalizar Glances fuera de su configuración predeterminada. Se pivotó hacia un stack más modular y flexible basado en Prometheus + Grafana.

## Context

Necesitamos una solución para monitorizar la salud de la Raspberry Pi (CPU, Memoria, Temperatura, Disco, Red).
La mayoría de los servicios se ejecutarán en Docker.
Existe la preocupación de que la monitorización deba ejecutarse nativamente en el host para tener visibilidad completa, en lugar de estar aislada en un contenedor.

## Decision

Implementaremos **Glances** como sistema de monitorización principal, ejecutado en **Docker**.

Para abordar la necesidad de "visibilidad del host", el contenedor se configurará con:
1.  `pid: host`: Para ver todos los procesos del sistema.
2.  Montaje de volúmenes de sistema (`/var/run/docker.sock`, `/proc`, `/sys`): Para leer métricas de hardware y contenedores directamente.

## Consequences

### Positive

- **POS-001**: **Limpieza del Host**: No es necesario instalar dependencias de Python o paquetes extra en el sistema operativo base (Raspberry Pi OS).
- **POS-002**: **Portabilidad**: La configuración de monitorización es reproducible y está versionada en código (Docker Compose).
- **POS-003**: **Visibilidad Completa**: Con los flags adecuados, Glances ve exactamente lo mismo que si estuviera instalado nativamente.
- **POS-004**: **Interfaz Web**: Glances proporciona una UI web ligera y una API REST por defecto.

### Negative

- **NEG-001**: **Privilegios**: Requiere una configuración de Docker ligeramente más privilegiada (acceso a `/proc` y `/sys`).

## Alternatives Considered

### Instalación Nativa (apt/pip)

- **ALT-001**: **Description**: Instalar Glances directamente en el sistema operativo.
- **ALT-002**: **Rejection Reason**: Descartada para evitar "drift" en la configuración del sistema operativo y conflictos de dependencias.

### Prometheus + Grafana

- **ALT-003**: **Description**: Stack completo de monitorización con base de datos de series temporales y dashboards avanzados.
- **ALT-004**: **Rejection Reason**: Descartada por el momento por ser una solución más pesada (uso de recursos) y compleja de configurar para una necesidad básica de "salud del sistema". Se puede reevaluar en el futuro si se requieren métricas históricas a largo plazo.

## Implementation Notes

- **IMP-001**: Crear un `docker-compose.yml` específico para monitorización.
- **IMP-002**: Asegurar que el puerto web (61208) esté accesible solo desde la red local o protegido por VPN/Proxy.

## References

- **REF-001**: [Glances Documentation](https://glances.readthedocs.io/)
- **REF-002**: [Docker Host Mode](https://docs.docker.com/network/host/)
