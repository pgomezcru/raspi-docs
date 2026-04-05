## Why

Docker arranca como servicio de systemd sin verificar que `/mnt/usb-data` esté montado. Si el SSD USB no está disponible al boot (fallo de montaje, problema de hardware), Docker arrancaría igualmente y los contenedores escribirían datos en la tarjeta SD, potencialmente corrompiéndola y enmascarando la ausencia del SSD.

## What Changes

- Crear un override de systemd para `docker.service` con la directiva `RequiresMountsFor=/mnt/usb-data`
- Recargar el daemon de systemd y verificar que la dependencia está activa
- Documentar el comportamiento esperado: Docker falla a arrancar si `/mnt/usb-data` no está montado

## Capabilities

### New Capabilities
_(ninguna — es hardening de infraestructura, no una capacidad de usuario)_

### Modified Capabilities
_(ninguna)_

## Impact

- **Ficheros de sistema**: nuevo fichero `/etc/systemd/system/docker.service.d/requires-usb.conf`
- **Comportamiento de arranque**: Docker no arrancará si el SSD no está montado (comportamiento deseado)
- **Operaciones de mantenimiento**: al desmontar el SSD intencionalmente, hay que parar Docker manualmente antes
- **Recuperación**: si el SSD falla al montar, los contenedores no arrancan pero el sistema base sigue operativo (SSH accesible)
