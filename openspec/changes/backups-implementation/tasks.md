## 1. Configurar montaje automático del NAS

- [ ] 1.1 Verificar que el NAS (`192.168.1.102`) está accesible desde la Pi: `ping 192.168.1.102`
- [ ] 1.2 Verificar que el NFS del NAS está exportado y accesible: `showmount -e 192.168.1.102`
- [ ] 1.3 Crear directorio de montaje: `sudo mkdir -p /mnt/nas/pi`
- [ ] 1.4 Añadir entrada en `/etc/fstab` con `noauto,x-systemd.automount,_netdev,rsize=8192,wsize=8192,timeo=14,intr`
- [ ] 1.5 Recargar systemd: `sudo systemctl daemon-reload`
- [ ] 1.6 Verificar automount: acceder a `/mnt/nas/pi` y comprobar que se monta: `ls /mnt/nas/pi`
- [ ] 1.7 Reiniciar la Pi y verificar que el boot no se bloquea con el NAS apagado

## 2. Crear script de backup

- [ ] 2.1 Crear directorio: `mkdir -p /mnt/usb-data/backup-scripts/`
- [ ] 2.2 Crear `/mnt/usb-data/backup-scripts/backup.sh` con:
  - Comprobación de que `/mnt/nas` está montado antes de proceder
  - Definición de variables: `SRC=/mnt/usb-data/`, `DEST=/mnt/nas/pi/docker-backups/$(date +%Y-%m-%d)/`
  - Parada de `gitea-db` antes del rsync (consistencia de PostgreSQL)
  - Comando rsync: `rsync -az --delete --numeric-ids --xattrs /mnt/usb-data/ $DEST`
  - Arranque de `gitea-db` tras el rsync
  - Limpieza de directorios con más de 30 días: `find /mnt/nas/pi/docker-backups/ -maxdepth 1 -type d -mtime +30 -exec rm -rf {} +`
- [ ] 2.3 Dar permisos de ejecución: `chmod +x /mnt/usb-data/backup-scripts/backup.sh`

## 3. Probar backup manual

- [ ] 3.1 Ejecutar el script manualmente como `admin`: `bash /mnt/usb-data/backup-scripts/backup.sh`
- [ ] 3.2 Verificar en el NAS que el directorio `docker-backups/<fecha>/` contiene los datos esperados
- [ ] 3.3 Verificar que `gitea-db` vuelve a estar activo tras el backup: `docker ps | grep gitea-db`

## 4. Programar backup nocturno

- [ ] 4.1 Añadir entrada en crontab de `admin`: `0 3 * * * /mnt/usb-data/backup-scripts/backup.sh >> /var/log/backup.log 2>&1`
- [ ] 4.2 Verificar la entrada con: `crontab -l`
- [ ] 4.3 Esperar a la siguiente ejecución programada o simular con `run-parts` y verificar el log

## 5. Documentar

- [ ] 5.1 Actualizar `infraestructura/Backups.md` con el procedimiento completo (montaje NAS, script, cron)
- [ ] 5.2 Documentar el procedimiento de restauración manual desde el NAS
- [ ] 5.3 Actualizar `estado.md`: marcar divergencia #3 (NAS no montado) como resuelta
