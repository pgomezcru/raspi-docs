# Estado del Homelab — Análisis de Divergencias

> Generado el 2026-03-21. Compara la documentación del repositorio con el estado real de la Raspberry Pi (`192.168.1.101`).

---

## Resumen ejecutivo

| Categoría | Cantidad |
|-----------|----------|
| ✅ Servicios funcionando como se documenta | 8 |
| 🔴 Divergencias importantes (implementación ≠ documentación) | 6 |
| 🟡 Avisos menores / deuda técnica | 3 |
| ⬜ Contenedores sin documentar corriendo en producción | 2 |
| ❌ Documentado pero no implementado (pendientes) | 5 |

---

## ✅ Servicios que coinciden con la documentación

| Servicio | Tipo | Notas |
|----------|------|-------|
| **nginx_proxy** | Docker | Corriendo, bind mounts correctos en `/mnt/usb-data/nginx/` |
| **homarr** | Docker | Corriendo, bind mounts correctos en `/mnt/usb-data/docker-root/homarr/` |
| **gitea** + **gitea-db** | Docker | Corriendo, bind mounts en `/mnt/usb-data/docker-root/gitea/` |
| **adguard-home** | Docker | Corriendo, puertos 53/3000/8080/8443 expuestos correctamente |
| **prometheus** | Docker | Corriendo, scrape de 5 exporters correctamente configurado |
| **smartctl-exporter** | Docker | Corriendo, acceso a `/dev` del host |
| **fail2ban** | Systemd | Activo |
| **Samba** (smbd + nmbd) | Systemd | Activo |

---

## 🔴 Divergencias importantes

### 1. node-exporter sin montaje del filesystem del host

**Documentado** (`prometheus.md`): El contenedor debe tener `/:/host:ro,rslave` para exponer métricas reales del SO.

**Real**: El contenedor no tiene ningún bind mount (`Binds: null`). Solo tiene `pid: host`.

**Impacto**: node-exporter reporta métricas desde dentro del contenedor, no del host real. Las métricas de disco, filesystem y algunos indicadores de CPU/memoria pueden ser incorrectas o incompletas en Grafana.

---

### 2. Volúmenes de AdGuard Home, Grafana y Prometheus no son bind mounts

La convención de `AGENTS.md` establece que los datos deben persistir en bind mounts bajo `/mnt/usb-data/`.

| Contenedor | Volumen real | Convención esperada |
|------------|-------------|---------------------|
| **adguard-home** | Volúmenes nombrados `adguard-work` y `adguard-conf` | `/mnt/usb-data/adguard-home/...` |
| **grafana** (datos) | Volumen nombrado `grafana-data` | `/mnt/usb-data/grafana/data` |
| **prometheus** (TSDB) | Volumen nombrado `prometheus-data` | `/mnt/usb-data/prometheus/data` |

**Impacto**: Los datos de estos servicios no son directamente accesibles en el SSD para inspección, backup manual o migración. Aunque hay carpetas en `/mnt/usb-data/` para estos servicios, los contenedores no las usan para persistencia.

> Nota: AdGuard y Grafana sí tienen carpetas en `/mnt/usb-data/` pero su uso es parcial (configs/provisioning), no los datos principales.

---

### 3. NAS no montado — backups imposibles hacia NAS

**Documentado** (`Backups.md`): destino primario de restic es `/mnt/nas/pi/restic-repo`.

**Real**: `/mnt/nas` no está montado. El directorio `/mnt/nas/` existe pero está vacío.

**Impacto**: Aunque restic está instalado (`v0.18.0`), ningún backup puede ejecutarse hacia el NAS. No hay scripts de backup en `/mnt/usb-data/backup-scripts/` y no hay entradas en crontab.

**Estado de backups**: No implementados en la práctica.

---

### 4. Monitorización del NAS (SNMP) no implementada

**Documentado**: `monitoring/NAS_monitoring.md` describe integración vía SNMP del Synology NAS DS110j.

**Real**: El archivo `NAS_monitoring.md` no existe en el repositorio. El `prometheus.yml` no tiene ningún job de `snmp_exporter`. No hay contenedor SNMP exporter corriendo.

**Impacto**: No hay métricas del NAS en Grafana.

---

### 5. Cadvisor usa `:latest` en vez de la versión pinneada

**Documentado** (`prometheus.md`): `gcr.io/cadvisor/cadvisor:v0.52.1`

**Real**: `gcr.io/cadvisor/cadvisor:latest`

**Impacto**: Riesgo de rotura en actualizaciones automáticas. Contradice la política de AGENTS.md de pinear versiones exactas.

---

### 6. Gitea: mirroring con GitHub sin configurar

**Documentado** (`programacion/gitea.md`): El despliegue del contenedor y la persistencia están completados (Archive en TODO.md). Quedan pendientes la creación del PAT en GitHub y la configuración del mirroring bidireccional.

**Real**: Gitea corre correctamente con PostgreSQL y nginx proxy, pero el mirroring con GitHub no está configurado.

**Impacto**: Gitea funciona como servidor Git local, pero no sincroniza con GitHub. Los repositorios no tienen backup en la nube.

---

## 🟡 Avisos menores / deuda técnica

### A. Todas las imágenes usan tags no pinneadas

AGENTS.md exige "Pin exact versions in docker-compose.yml, avoid `:latest`". Estado actual:

| Contenedor | Tag actual |
|------------|-----------|
| prometheus | `:latest` |
| node-exporter | `:latest` |
| grafana | `:latest` |
| homarr | `:latest` |
| gitea | `:latest` |
| gitea-db | `postgres:15` (serie mayor, no versión exacta) |
| nginx_proxy | `:latest` |
| adguard-home | `:latest` |
| smartctl-exporter | `:master` |

Solo `smartctl-exporter` usa una imagen específica de ARM64 como documenta `prometheus.md`, pero con tag `:master`.

---

### B. Directorio residual de Glances en el SSD

Existe `/mnt/usb-data/glances/` pero Glances está deprecado (ADR-0002 supersedido por ADR-0005). No hay contenedor glances corriendo, que es lo correcto. El directorio residual puede limpiarse.

---

### C. UFW: estado no verificable por claude-agent

El usuario `claude-agent` no tiene permiso para ejecutar `sudo ufw status`. UFW aparece como activo en systemctl, pero no se pudo verificar las reglas concretas ni compararlas con `infraestructura/configuracion-inicial.md`.

---

## ⬜ Contenedores en producción sin documentar

Estos contenedores están corriendo y aparecen en `prometheus.yml`, pero no tienen documentación en el repositorio:

| Contenedor | Imagen | Puerto | Job en prometheus.yml |
|------------|--------|--------|----------------------|
| **prometheus-metrics-table** | `prometheus-prometheus-metrics-table` (imagen local custom) | 9102 | `prometheus-metrics-table` |
| **docker-metadata-exporter** | `prometheus-docker-metadata-exporter` (imagen local custom) | 9101 | `docker-metadata-exporter` |

Ambos son imágenes construidas localmente, no imágenes públicas. Su propósito, configuración y origen no están documentados.

---

## ❌ Documentado pero no implementado (pendientes conocidos)

Estos servicios están en la documentación pero no desplegados. Se listan a título informativo, no son divergencias problemáticas:

| Servicio | Archivo | Notas |
|----------|---------|-------|
| **Jenkins** | `programacion/jenkins.md` | No hay contenedor corriendo |
| **VS Code Server** | `programacion/vscode-server.md` | No hay contenedor corriendo |
| **HTTPS / Certificados** | `infraestructura/https-plan.md` | nginx sin TLS en producción |
| **Backups automatizados** | `infraestructura/Backups.md` | Sin scripts, sin cron, NAS no montado |
| **NAS SNMP monitoring** | *(el .md no existe aún)* | Sin exporter, sin job en prometheus |

---

## Acciones recomendadas por prioridad

| Prioridad | Acción |
|-----------|--------|
| 🔴 Alta | Corregir bind mounts de `node-exporter` para que exponga métricas reales del host |
| 🔴 Alta | Montar NAS e implementar al menos un backup manual para validar el flujo |
| 🔴 Alta | Documentar `prometheus-metrics-table` y `docker-metadata-exporter` (qué son, para qué sirven, cómo se construyen) |
| 🟡 Media | Migrar volúmenes nombrados de AdGuard, Grafana y Prometheus a bind mounts en SSD |
| 🟡 Media | Pinear versiones exactas de todas las imágenes Docker |
| 🟡 Media | Actualizar `TODO.md`: mover Gitea a "hecho" |
| 🟢 Baja | Limpiar directorio residual `/mnt/usb-data/glances/` |
