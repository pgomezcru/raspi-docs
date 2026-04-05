## 1. Habilitar SNMP en el NAS Synology

- [ ] 1.1 Acceder al panel DSM del NAS (`http://192.168.1.102`)
- [ ] 1.2 Ir a: Panel de Control → Terminal y SNMP → SNMP
- [ ] 1.3 Activar SNMP v2c con community string (anotar la community string usada)
- [ ] 1.4 Verificar desde la Pi: `snmpwalk -v2c -c <community> 192.168.1.102 sysDescr`
  - Resultado esperado: descripción del sistema Synology

## 2. Obtener y preparar configuración snmp_exporter

- [ ] 2.1 Descargar `snmp.yml` con módulo Synology (comunidad Prometheus o generador oficial)
- [ ] 2.2 Crear directorio: `compose/prometheus/snmp_exporter/`
- [ ] 2.3 Guardar el `snmp.yml` en `compose/prometheus/snmp_exporter/snmp.yml`
- [ ] 2.4 Verificar que el módulo incluye OIDs para CPU, RAM, temperatura y volúmenes del DS110j

## 3. Añadir snmp_exporter al compose de Prometheus

- [ ] 3.1 Editar `compose/prometheus/docker-compose.yml`: añadir servicio `snmp-exporter` con imagen `prom/snmp-exporter` (versión pinneada) y bind mount del `snmp.yml`
- [ ] 3.2 Editar `compose/prometheus/prometheus/prometheus.yml`: añadir job `snmp` con `params: {module: [synology], target: [192.168.1.102]}` y `static_configs: [{targets: ["snmp-exporter:9116"]}]`
- [ ] 3.3 Redesplegar stack: `bash ~/raspi-docs/compose/deploy.sh prometheus`

## 4. Verificar métricas

- [ ] 4.1 Comprobar que snmp-exporter está activo: `docker ps | grep snmp`
- [ ] 4.2 Consultar métricas directamente: `curl "http://localhost:9116/snmp?module=synology&target=192.168.1.102" | head -20`
- [ ] 4.3 Verificar en Prometheus UI: `up{job="snmp"}` → debe ser 1

## 5. Crear dashboard de NAS en Grafana

- [ ] 5.1 Importar o crear dashboard con paneles para CPU %, RAM %, temperatura de discos, estado de volúmenes
- [ ] 5.2 Exportar el dashboard como JSON
- [ ] 5.3 Guardar en `compose/grafana/provisioning/dashboards/nas-synology.json`
- [ ] 5.4 Redesplegar Grafana: `bash ~/raspi-docs/compose/deploy.sh grafana`

## 6. Documentar

- [ ] 6.1 Completar `infraestructura/NAS_monitoring.md` con: habilitación SNMP, configuración del exporter, job de Prometheus, instrucciones del dashboard
- [ ] 6.2 Añadir `snmp-exporter` al `manifest.yml` si se gestiona como servicio separado
- [ ] 6.3 Actualizar `monitoring/prometheus.md` con el nuevo job `snmp`
