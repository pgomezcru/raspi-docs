[🏠 Inicio](../README.md) > [📂 Infraestructura](_index.md)

# Estrategia de Monitorización del Sistema

Esta guía describe la estrategia general de monitorización para la Raspberry Pi y los servicios del homelab.

## Decisión Arquitectónica

Seguimos el [ADR-0005](../docs/adr/adr-0005-stack-monitoreo-prometheus-grafana.md), que establece un **stack modular** basado en:

- **[Prometheus](prometheus.md)**: Base de datos de series temporales y motor de recolección de métricas.
- **[Grafana](grafana.md)**: Plataforma de visualización y dashboards personalizables.
- **Exporters especializados**: Contenedores dedicados a recolectar métricas específicas.

Este stack reemplaza la implementación inicial de Glances ([ADR-0002 - Superseded](../docs/adr/adr-0002-monitorizacion-sistema.md)).

## Áreas de Monitorización

### 1. Sistema Operativo y Hardware
- **CPU**: Uso, temperatura, frecuencia.
- **Memoria**: RAM disponible, swap, cache.
- **Red**: Tráfico entrante/saliente, conexiones activas.
- **Temperatura**: Crítico en Raspberry Pi para prevenir throttling.

**Herramienta**: [node_exporter](prometheus.md#node-exporter)

### 2. Almacenamiento

#### Tarjeta SD y Disco USB
- **Espacio en disco**: Uso de particiones y puntos de montaje.
- **Salud física (S.M.A.R.T.)**: Sectores dañados, errores de lectura/escritura, temperatura del disco.
  
**Herramienta**: [smartctl_exporter](prometheus.md#smartctl-exporter)

#### NAS (Synology)
- **Disponibilidad**: Verificar que el montaje NFS esté activo.
- **Salud Interna**: Configurar notificaciones por email directamente en Synology DSM (Panel de Control > Notificación). El NAS tiene acceso directo a su hardware S.M.A.R.T.

### 3. Contenedores Docker
- **Estado**: Running, exited, restarting.
- **Recursos**: CPU y RAM por contenedor.
- **Red**: Tráfico de cada contenedor.

**Herramienta**: [cAdvisor](prometheus.md#cadvisor)

### 4. Seguridad
- **Fail2Ban**: Verificar que el servicio `fail2ban-server` esté activo.
- **UFW**: Revisar logs de firewall para detectar picos de tráfico bloqueado.

**Monitorización**: Alertas basadas en procesos (Prometheus) y revisión manual de logs (`/var/log/auth.log`, `/var/log/ufw.log`).

### 5. Servicios de Red

#### Nginx (Reverse Proxy)
- **Métricas**: Conexiones activas, requests/segundo, códigos de estado HTTP.
- **Herramienta**: [nginx-prometheus-exporter](https://github.com/nginxinc/nginx-prometheus-exporter) o módulo stub_status.

#### AdGuard Home (DNS/Bloqueo de Ads)
- **Métricas**: Consultas DNS, dominios bloqueados, tasa de bloqueo.
- **Herramienta**: AdGuard Home expone métricas nativas en `/control/stats` (puede parsearse con exporters custom o consultar directamente desde Grafana).

### 6. NAS (Synology)
- **Disponibilidad**: Verificar montajes NFS activos.
- **Salud del Hardware**: S.M.A.R.T., temperatura, estado RAID, uso de volúmenes.

**Herramienta**: [SNMP Exporter](NAS_monitoring.md) + Notificaciones por email del propio DSM.

### 7. Servicios Específicos (Futuro)
Conforme se desplieguen servicios (Gitea, Jenkins, etc.), se añadirán exporters específicos o se configurarán sus propios endpoints de métricas.

## Implementación

Consulta las guías específicas:
- **[Prometheus](prometheus.md)**: Configuración del servidor de métricas.
- **[Grafana](grafana.md)**: Configuración de dashboards y visualización.
- **[Glances (Descontinuado)](glances.md)**: Referencia histórica de la implementación anterior.

## Acceso y Puertos

| Servicio | Puerto | URL |
|----------|--------|-----|
| Grafana | 3000 | `http://<IP-RASPBERRY>:3000` |
| Prometheus | 9090 | `http://<IP-RASPBERRY>:9090` |
| node_exporter | 9100 | `http://<IP-RASPBERRY>:9100/metrics` |
| cAdvisor | 8080 | `http://<IP-RASPBERRY>:8080` |

> **Seguridad**: Estos puertos deben exponerse **solo a la red local**. Para acceso externo, usar VPN o Reverse Proxy con autenticación.
