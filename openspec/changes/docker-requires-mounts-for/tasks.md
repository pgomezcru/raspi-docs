## 1. Crear override de systemd

- [ ] 1.1 Crear directorio del drop-in: `sudo mkdir -p /etc/systemd/system/docker.service.d/`
- [ ] 1.2 Crear fichero `/etc/systemd/system/docker.service.d/requires-usb.conf` con:
  ```ini
  [Unit]
  RequiresMountsFor=/mnt/usb-data
  ```
- [ ] 1.3 Recargar el daemon de systemd: `sudo systemctl daemon-reload`

## 2. Verificar la configuración

- [ ] 2.1 Verificar que la directiva está activa: `systemctl show docker | grep RequiresMountsFor`
  - Resultado esperado: `RequiresMountsFor=/mnt/usb-data`
- [ ] 2.2 Reiniciar Docker y verificar que arranca correctamente con el SSD montado: `sudo systemctl restart docker && docker ps`
- [ ] 2.3 Verificar el estado de la unidad: `systemctl status docker`

## 3. Documentar

- [ ] 3.1 Documentar en `infraestructura/configuracion-inicial.md` la dependencia Docker ↔ SSD y el comportamiento esperado si el SSD no monta
- [ ] 3.2 Añadir nota en `infraestructura/estrategia-almacenamiento.md`: "Docker requiere /mnt/usb-data montado para arrancar"
- [ ] 3.3 Actualizar `estado.md`: añadir esta mejora como resuelta
