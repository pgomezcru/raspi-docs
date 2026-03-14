[🏠 Inicio](../README.md)

# Infraestructura

Documentación sobre la configuración base, red, seguridad y acceso a los servidores.

## Guías Disponibles

- [Conexión a Raspberry Pi 4](conexion.md): Guía para conectar a la Raspberry Pi 4 mediante SSH desde diferentes sistemas operativos.
- [Configuración Inicial y Hardening](configuracion-inicial.md): Pasos esenciales para asegurar una Raspberry Pi 4 recién instalada.
- [Gestión de Claves SSH](ssh-keys.md): Guía sobre el ciclo de vida, buenas prácticas y recuperación de claves SSH.
- [Configuración de Bitwarden](bitwarden-setup.md): Guía de implementación para el gestor de contraseñas (Escritorio, Navegador, Móvil).
- [Monitorización del Sistema](monitorizacion.md): Estrategia general de monitorización (Prometheus + Grafana stack).
  - [Prometheus](prometheus.md): Motor de métricas y recolección de datos.
  - [Grafana](grafana.md): Visualización y dashboards personalizables.
  - [Monitorización del NAS](NAS_monitoring.md): Integración del Synology NAS con Prometheus (SNMP).
  - [Glances (Descontinuado)](glances.md): Referencia histórica de la implementación anterior.
- [Guía de Fail2Ban](fail2ban.md): Conceptos básicos y escenarios de protección para servicios expuestos (SSH, Gitea, Docker).
- [Configuración de Proxy Inverso](nginx.md): Implementación de Nginx con Docker para centralizar el acceso a servicios.
- [Arquitectura de Red](arquitectura-red.md): Topología física recomendada y conexión de dispositivos.
- [Estrategia de Almacenamiento](estrategia-almacenamiento.md): Guía de decisión entre uso de disco USB vs NAS (NFS).
