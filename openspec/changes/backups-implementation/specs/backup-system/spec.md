## ADDED Requirements

### Requirement: Montaje automático del NAS
El sistema debe montar el NAS automáticamente cuando esté disponible, sin bloquear el arranque si no lo está.

#### Scenario: NAS disponible en la red
- **WHEN** el sistema accede a `/mnt/nas/` y el NAS está encendido y accesible en `192.168.1.102`
- **THEN** systemd monta automáticamente el NFS y el directorio es accesible

#### Scenario: NAS no disponible al arranque
- **WHEN** el sistema arranca y el NAS no está encendido o no es alcanzable
- **THEN** el arranque se completa normalmente sin errores (montaje diferido, no bloqueante)

---

### Requirement: Backup manual ejecutable del SSD al NAS
Debe existir un script que copie `/mnt/usb-data/` al NAS y sea ejecutable manualmente.

#### Scenario: Ejecución manual del script de backup
- **WHEN** el usuario ejecuta `/mnt/usb-data/backup-scripts/backup.sh` como `admin`
- **THEN** el contenido de `/mnt/usb-data/` se copia a `/mnt/nas/pi/docker-backups/<yyyy-mm-dd>/` y el script termina con código de salida 0

#### Scenario: NAS no montado al ejecutar el script
- **WHEN** se ejecuta el script de backup y `/mnt/nas` no está montado
- **THEN** el script termina con error y mensaje descriptivo, sin crear directorios vacíos en destino

---

### Requirement: Backup nocturno automático
El backup debe ejecutarse automáticamente cada noche sin intervención manual.

#### Scenario: Cron ejecuta el backup
- **WHEN** son las 03:00 y el cron del usuario `admin` está activo
- **THEN** se ejecuta el script `backup.sh` y el resultado queda en el log del sistema

---

### Requirement: Retención de backups anteriores
Los backups deben conservarse un número limitado de días para no agotar el espacio en el NAS.

#### Scenario: Limpieza de backups antiguos
- **WHEN** el script de backup se ejecuta
- **THEN** los directorios de backup con más de 30 días de antigüedad en `/mnt/nas/pi/docker-backups/` se eliminan automáticamente
