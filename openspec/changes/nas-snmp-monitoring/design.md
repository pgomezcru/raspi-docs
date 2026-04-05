## Context

El NAS es un Synology DS110j con DSM. Synology soporta SNMP v1/v2c/v3 nativo desde el panel de administración. `snmp_exporter` de Prometheus Community es el estándar para exponer métricas SNMP en formato Prometheus. El compose del stack de monitorización ya gestiona el servicio de red `monitoring` y tiene acceso a `proxy_net`.

## Goals / Non-Goals

**Goals:**
- Métricas del NAS visibles en Prometheus (CPU, RAM, temperatura, estado de volúmenes, red)
- Dashboard Grafana con estado básico del NAS
- El exporter funciona tanto si el NAS está online como offline (sin crashear el stack)

**Non-Goals:**
- SNMP v3 con autenticación en esta fase (v2c con community string en LAN privada es suficiente)
- Alertas en Prometheus/Grafana (se puede añadir después)
- Métricas de discos individuales a nivel S.M.A.R.T del NAS (el DS110j puede no exponerlo vía SNMP)

## Decisions

### 1. snmp_exporter con módulo Synology personalizado
**Decisión**: usar `prom/snmp-exporter` con un `snmp.yml` generado con el generador oficial o usando el módulo `if_mib` + OIDs específicos de Synology.
**Razón**: el generador oficial de Prometheus permite crear módulos adaptados a los MIBs del dispositivo. Synology publica sus MIBs en el centro de descargas.
**Alternativa descartada**: usar el módulo genérico `if_mib` únicamente — demasiado limitado, no expone métricas de CPU/RAM del NAS.

### 2. Community string SNMP v2c
**Decisión**: usar SNMP v2c con community string `public` (o personalizada).
**Razón**: red LAN privada, el DS110j es un dispositivo doméstico. La complejidad de SNMPv3 no se justifica.

### 3. snmp_exporter añadido al compose de prometheus
**Decisión**: añadir el servicio en `compose/prometheus/docker-compose.yml` junto a los demás exporters.
**Razón**: mantiene el stack de monitorización cohesionado en un único compose.

### 4. Target del NAS como parámetro en prometheus.yml
**Decisión**: el job `snmp` usa `params: {module: [synology], target: [192.168.1.102]}` y el scrape apunta a `snmp-exporter:9116`.
**Razón**: arquitectura estándar de snmp_exporter (el exporter actúa como proxy hacia el dispositivo SNMP).

## Risks / Trade-offs

- **NAS apagado**: si el NAS está offline, el scrape de Prometheus fallará pero no afecta al resto del stack. Los datos simplemente no se recogerán.
- **DS110j es hardware antiguo**: el Synology DS110j tiene recursos muy limitados y puede que no soporte todos los OIDs de los MIBs modernos de Synology. Puede requerir pruebas con `snmpwalk` para identificar qué métricas están disponibles realmente.
- **Generación del snmp.yml**: requiere el generador de snmp_exporter y los MIBs de Synology, proceso algo laborioso. Alternativa rápida: usar un `snmp.yml` preconfigurado de la comunidad para Synology.

## Migration Plan

1. Habilitar SNMP v2c en el NAS: Panel DSM → Panel de Control → Terminal y SNMP
2. Verificar desde la Pi: `snmpwalk -v2c -c public 192.168.1.102 sysDescr`
3. Obtener `snmp.yml` con módulo Synology (generador oficial o community)
4. Añadir servicio `snmp-exporter` en `compose/prometheus/docker-compose.yml`
5. Añadir job en `compose/prometheus/prometheus/prometheus.yml`
6. Redesplegar stack prometheus: `deploy.sh prometheus`
7. Verificar en Prometheus UI: `up{job="snmp"}` = 1
8. Importar o crear dashboard Grafana para NAS
9. Completar `infraestructura/NAS_monitoring.md`

## Open Questions

- ¿Qué OIDs expone realmente el DS110j? Necesita verificación con `snmpwalk`.
- ¿Community string personalizada o `public`? Decidir según política de seguridad del homelab.
