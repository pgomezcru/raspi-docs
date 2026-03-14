---
title: "ADR-0005: Stack de Monitorización Prometheus + Grafana"
status: "Accepted"
date: "2026-01-02"
authors: "Admin"
tags: ["monitorización", "prometheus", "grafana", "docker", "infraestructura"]
supersedes: "ADR-0002"
superseded_by: ""
---

# ADR-0005: Stack de Monitorización Prometheus + Grafana

## Status

**Accepted**

## Context

Tras implementar Glances (ADR-0002), se identificaron limitaciones significativas al intentar personalizar la monitorización más allá de las capacidades "out-of-the-box" de la herramienta.

Necesidades específicas no cubiertas adecuadamente por Glances:
- Monitorización detallada de salud de discos (S.M.A.R.T.) con alertas personalizadas
- Métricas históricas a largo plazo para análisis de tendencias
- Dashboards completamente personalizables según las necesidades del homelab
- Alertas flexibles basadas en umbrales específicos
- Monitorización de contenedores Docker con detalle granular
- Integración con futuros servicios (Gitea, Jenkins, etc.)

## Decision

Implementaremos un **stack modular de monitorización** basado en:

1.  **Prometheus**: Base de datos de series temporales y motor de recolección de métricas.
2.  **Grafana**: Plataforma de visualización y dashboards.
3.  **Exporters especializados** (ejecutados como contenedores Docker):
    -   **node_exporter**: Métricas del sistema operativo (CPU, RAM, red, disco).
    -   **smartctl_exporter**: Salud de discos (S.M.A.R.T. para SD y USB).
    -   **cadvisor**: Métricas de contenedores Docker.

## Consequences

### Positive

- **POS-001**: **Flexibilidad Total**: Dashboards completamente personalizables en Grafana sin limitaciones de diseño.
- **POS-002**: **Historial de Métricas**: Prometheus almacena datos históricos, permitiendo análisis de tendencias y patrones a largo plazo.
- **POS-003**: **Alertas Avanzadas**: Sistema de alertas nativo de Prometheus con reglas personalizables (ej. "alertar si temperatura CPU > 75°C durante 5 minutos").
- **POS-004**: **Ecosistema Estándar**: Stack utilizado en producción por miles de empresas; abundante documentación y soporte comunitario.
- **POS-005**: **Escalabilidad**: Fácil añadir nuevos exporters conforme se agreguen servicios (ej. blackbox_exporter para uptime checks, exporters específicos de Gitea/Jenkins).
- **POS-006**: **Separación de Responsabilidades**: Cada exporter es un contenedor independiente, facilitando debug y actualizaciones.

### Negative

- **NEG-001**: **Mayor Complejidad Inicial**: Requiere configuración de múltiples servicios interconectados vs solución "todo en uno" de Glances.
- **NEG-002**: **Consumo de Recursos**: Prometheus + Grafana son más pesados que Glances (se estima ~200-300MB RAM adicionales en total).
- **NEG-003**: **Curva de Aprendizaje**: Requiere familiarizarse con PromQL (lenguaje de consulta de Prometheus) y configuración de Grafana.
- **NEG-004**: **Persistencia de Datos**: Requiere gestión de volúmenes para almacenamiento histórico de métricas.

## Alternatives Considered

### Glances (Solución Anterior - ADR-0002)

- **ALT-001**: **Description**: Herramienta monolítica de monitorización con interfaz web integrada.
- **ALT-002**: **Rejection Reason**: Dificultad extrema para personalizar dashboards y configurar alertas específicas. La configuración de exporters adicionales (especialmente S.M.A.R.T.) requiere modificaciones no estándar del contenedor. Limitado soporte para métricas históricas a largo plazo.

### Netdata

- **ALT-003**: **Description**: Plataforma de monitorización en tiempo real con dashboards interactivos.
- **ALT-004**: **Rejection Reason**: Aunque tiene dashboards atractivos, también presenta limitaciones de personalización similares a Glances. Su modelo de almacenamiento de métricas (Cloud opcional) no se alinea con la filosofía self-hosted del proyecto.

### Zabbix

- **ALT-005**: **Description**: Sistema de monitorización empresarial completo.
- **ALT-006**: **Rejection Reason**: Demasiado pesado para un homelab en Raspberry Pi. Requiere base de datos relacional adicional (MySQL/PostgreSQL) solo para métricas. Complejidad de configuración desproporcionada para las necesidades actuales.

## Implementation Notes

- **IMP-001**: Crear un `docker-compose.yml` único para el stack completo de monitorización (Prometheus + Grafana + exporters).
- **IMP-002**: **Persistencia**: 
  - Prometheus: Volumen en USB/SSD para base de datos de métricas.
  - Grafana: Volumen para configuración y dashboards.
- **IMP-003**: **Privilegios**: node_exporter y smartctl_exporter requieren acceso al host (pid: host y montaje de /dev).
- **IMP-004**: **Seguridad**: El puerto de Grafana (3000) debe exponerse solo a la red local inicialmente. Acceso externo solo vía VPN o Reverse Proxy con autenticación.
- **IMP-005**: **Configuración Inicial**:
  - Importar dashboards preconstruidos de Grafana Labs (ej. "Node Exporter Full", "Docker Container & Host Metrics").
  - Configurar datasource de Prometheus en Grafana (http://prometheus:9090).
- **IMP-006**: **Retención de Datos**: Configurar Prometheus con --storage.tsdb.retention.time=30d (ajustar según espacio disponible).

## References

- **REF-001**: [Prometheus Documentation](https://prometheus.io/docs/introduction/overview/)
- **REF-002**: [Grafana Documentation](https://grafana.com/docs/grafana/latest/)
- **REF-003**: [node_exporter GitHub](https://github.com/prometheus/node_exporter)
- **REF-004**: [smartctl_exporter GitHub](https://github.com/prometheus-community/smartctl_exporter)
- **REF-005**: [cAdvisor Documentation](https://github.com/google/cadvisor)