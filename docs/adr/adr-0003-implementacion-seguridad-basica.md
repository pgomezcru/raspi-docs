---
title: "ADR-0003: Implementación de Capas de Seguridad Básica"
status: "Accepted"
date: "2025-12-31"
authors: "Admin"
tags: ["seguridad", "infraestructura", "hardening"]
supersedes: ""
superseded_by: ""
---

# ADR-0003: Implementación de Capas de Seguridad Básica

## Status

**Accepted**

## Context

El servidor Raspberry Pi opera en una red doméstica y aloja servicios que podrían ser expuestos o accedidos lateralmente. La configuración por defecto de Linux permite conexiones en todos los puertos abiertos y no mitiga activamente los intentos de intrusión.

Es necesario establecer:
1. Un control estricto sobre qué puertos están accesibles (Firewall).
2. Un mecanismo reactivo para bloquear intentos de acceso maliciosos, específicamente ataques de fuerza bruta contra SSH.

## Decision

Se ha decidido implementar una estrategia de seguridad de dos capas utilizando herramientas estándar de Linux:

1. **UFW (Uncomplicated Firewall)**: Para la gestión de reglas de iptables/nftables.
2. **Fail2Ban**: Para el monitoreo de logs y baneo automático de IPs sospechosas.

Esta decisión se alinea con la guía de [Configuración Inicial](../infraestructura/configuracion-inicial.md).

## Consequences

### Positive

- **POS-001**: **Simplicidad de Gestión**: UFW abstrae la complejidad de iptables, permitiendo reglas simples como `ufw allow ssh`.
- **POS-002**: **Protección Activa**: Fail2Ban reduce drásticamente el ruido en los logs y el riesgo de compromiso por fuerza bruta.
- **POS-003**: **Bajo Impacto**: Ambas herramientas son ligeras y adecuadas para el hardware de la Raspberry Pi.

### Negative

- **NEG-001**: **Riesgo de Lockout**: Una configuración incorrecta de UFW (ej. habilitar sin permitir SSH) puede dejar al administrador sin acceso remoto.
- **NEG-002**: **Falsos Positivos**: Fail2Ban podría banear al administrador si olvida la contraseña varias veces (mitigable con whitelisting).

## Alternatives Considered

### Gestión Manual de Iptables/Nftables

- **ALT-001**: **Description**: Escribir scripts directos para cargar reglas en el kernel.
- **ALT-002**: **Rejection Reason**: Alta complejidad y curva de aprendizaje. Mayor probabilidad de errores humanos que dejen el sistema vulnerable o inaccesible.

### CrowdSec

- **ALT-003**: **Description**: Un IPS moderno y colaborativo que utiliza inteligencia de amenazas global.
- **ALT-004**: **Rejection Reason**: Aunque es una tecnología superior, añade una capa de complejidad (agentes, bouncers, cuenta en la nube opcional) que excede los requisitos actuales de un setup básico. Se considera para una futura evolución.

### SSHGuard

- **ALT-005**: **Description**: Alternativa más ligera a Fail2Ban escrita en C.
- **ALT-006**: **Rejection Reason**: Fail2Ban tiene una comunidad más grande, más filtros predefinidos para otros servicios (no solo SSH) y es el estándar de facto en guías de Raspberry Pi.

## Implementation Notes

- **IMP-001**: UFW debe configurarse con política por defecto `deny incoming`.
- **IMP-002**: Fail2Ban debe configurarse copiando `jail.conf` a `jail.local` para persistencia.
- **IMP-003**: Verificar siempre el acceso SSH en una nueva terminal antes de cerrar la sesión actual tras activar el firewall.

## References

- **REF-001**: [Configuración Inicial y Hardening](../infraestructura/configuracion-inicial.md)
- **REF-002**: [UFW Documentation](https://help.ubuntu.com/community/UFW)
- **REF-003**: [Fail2Ban Documentation](https://www.fail2ban.org/wiki/index.php/Main_Page)
