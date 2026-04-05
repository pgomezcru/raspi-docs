## Why

No existe ningún sistema de backup operativo. El NAS no está montado, no hay scripts, no hay cron, y los datos de todos los servicios (Gitea, AdGuard, Prometheus, Grafana) solo existen en el SSD de la Raspberry Pi. Un fallo hardware implica pérdida total e irrecuperable de datos.

## What Changes

- Configurar el automontaje del NAS Synology DS110j en `/mnt/nas` vía NFS (systemd automount)
- Crear script `backup.sh` con `rsync` para copiar `/mnt/usb-data/` al NAS
- Añadir entrada en cron para backups nocturnos automáticos
- Documentar el procedimiento de restauración manual

## Capabilities

### New Capabilities
- `backup-system`: Capacidad de realizar y programar backups del contenido del SSD al NAS via rsync

### Modified Capabilities
_(ninguna)_

## Impact

- **Ficheros de sistema**: `/etc/fstab` (entrada NFS), posiblemente `/etc/systemd/system/` (automount unit)
- **Scripts**: nuevo fichero en `/mnt/usb-data/backup-scripts/backup.sh`
- **Cron**: entrada en crontab del usuario `admin`
- **Red**: tráfico NFS entre Pi (`192.168.1.101`) y NAS (`192.168.1.102`)
- **Dependencia**: el NAS debe estar encendido y accesible en la red local
