## Context

El homelab no tiene backups operativos. El NAS Synology DS110j (`192.168.1.102`) existe en la red local y tiene un volumen NFS disponible, pero `/mnt/nas` no está montado en la Pi. `restic` está instalado (`v0.18.0`) pero sin uso. Todo el estado de producción vive exclusivamente en `/mnt/usb-data/` en el SSD.

## Goals / Non-Goals

**Goals:**
- Montar el NAS automáticamente cuando esté disponible (sin bloquear el arranque si está offline)
- Implementar backup diario de `/mnt/usb-data/` al NAS vía `rsync`
- El backup debe ser ejecutable manualmente y también por cron

**Non-Goals:**
- Backups incrementales o deduplicados con restic (puede ser una mejora futura)
- Backup de la tarjeta SD del sistema operativo
- Backup cifrado (por ahora, la red es LAN privada)
- Notificaciones por email/webhook en caso de fallo

## Decisions

### 1. rsync sobre restic (por ahora)
**Decisión**: usar `rsync` simple en lugar de `restic`.
**Razón**: rsync es suficiente para el volumen actual de datos, produce un directorio legible directamente en el NAS (sin necesidad de herramientas adicionales para restaurar), y elimina la complejidad de inicializar y gestionar un repositorio restic.
**Alternativa descartada**: restic — más potente para deduplicación e historial, pero introduce complejidad innecesaria en esta fase.

### 2. systemd automount para el NAS
**Decisión**: usar `x-systemd.automount` en `/etc/fstab` con `noauto,_netdev`.
**Razón**: el NAS puede estar apagado al arrancar la Pi. Con `noauto` + `x-systemd.automount`, el directorio se monta solo cuando se accede (lazy mount) y no bloquea el boot si el NAS no está disponible.
**Alternativa descartada**: montaje estático en fstab sin automount — bloquearía el arranque si el NAS no está accesible.

### 3. Script rsync con fecha en destino
**Decisión**: cada ejecución crea un directorio fechado en el NAS (`/mnt/nas/pi/docker-backups/<yyyy-mm-dd>/`).
**Razón**: permite comparar snapshots y restaurar a un punto concreto sin sobrescribir el backup anterior.

## Risks / Trade-offs

- **NAS offline**: si el NAS no está disponible cuando cron ejecuta el backup, rsync fallará. Mitigación: añadir `mountpoint -q /mnt/nas` como check previo en el script.
- **Espacio en NAS**: el DS110j tiene capacidad limitada. Sin rotación automática, los backups acumulan espacio. Mitigación: añadir lógica de limpieza de backups >30 días en el script.
- **Consistencia de datos**: rsync no garantiza consistencia transaccional de los datos de Postgres (gitea-db). Mitigación: parar el contenedor gitea-db antes del rsync y arrancarlo después (o usar pg_dump como pre-backup).

## Migration Plan

1. Crear entrada NFS en `/etc/fstab` con `noauto,x-systemd.automount,_netdev`
2. Ejecutar `systemctl daemon-reload` y verificar con `systemctl status mnt-nas.automount`
3. Probar acceso a `/mnt/nas/` (trigger del automount)
4. Crear script `/mnt/usb-data/backup-scripts/backup.sh`
5. Ejecutar manualmente y verificar resultado en NAS
6. Añadir entrada en crontab: `0 3 * * * /mnt/usb-data/backup-scripts/backup.sh`
7. Documentar en `infraestructura/Backups.md`

## Open Questions

- ¿Qué hacer con gitea-db durante el backup? ¿Parar el contenedor o usar pg_dump?
- ¿Cuántos días de retención en el NAS antes de eliminar backups antiguos?
- ¿Es necesario verificar la integridad del backup (rsync --checksum)?
