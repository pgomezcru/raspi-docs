# Log infraestructura

## 30/12/2025
- Creada la documentación inicial
- Creado el usuario admin y deshabilitado el usuario pi 

## 31/12/2025
- Hardening de SSH
    - Clave ssh: passphrase "animal prodigioso con tilde"
- instalación ufw
- instalación fail2ban
- IPs fijas
    - rpi4 => 101
    - nas => 102
- Borro el contenido del USB

## 01/01/2026
- Formateo el USB a ext4
- Montaje automático del USB en /mnt/usb-data
- Creo una nueva carpeta compartida "pi" en el NAS
- Monto todas las carpetas del NAS por NFS en la Raspberry Pi
- creado /etc/docker/daemon.json para mover el Docker Root al USB
- montado el nginx
- montado homarr
- montado Glances

## 02/01/2026
- intentando conseguir que glances muestre SMART
  - No he sido capaz, pivotando a prometheus + grafana
- Generar documentación prometheus + grafana
