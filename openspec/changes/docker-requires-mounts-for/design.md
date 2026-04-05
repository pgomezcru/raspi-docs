## Context

Docker corre como servicio de systemd. El SSD se monta en `/mnt/usb-data` vía `/etc/fstab`. No hay ninguna dependencia declarada entre la unidad `docker.service` y el montaje del SSD. Si el SSD no monta correctamente al arranque (fallo del dispositivo, error en fstab), Docker arranca igualmente y los contenedores crean sus directorios de datos en la tarjeta SD.

## Goals / Non-Goals

**Goals:**
- Docker no arranca si `/mnt/usb-data` no está montado
- El comportamiento de arranque normal (SSD disponible) no se ve afectado
- La solución es declarativa, no un script de comprobación frágil

**Non-Goals:**
- Monitorización activa del estado del SSD
- Alertas en caso de fallo de montaje
- Proteger otros puntos de montaje (el SSD es la única dependencia crítica de Docker)

## Decisions

### 1. systemd override con RequiresMountsFor
**Decisión**: crear un drop-in de systemd en `/etc/systemd/system/docker.service.d/requires-usb.conf` con la directiva `RequiresMountsFor=/mnt/usb-data`.
**Razón**: es la forma nativa de systemd para declarar dependencias de montaje. No requiere scripts externos. systemd gestiona automáticamente el orden de arranque.
**Alternativa descartada**: script de comprobación en ExecStartPre — más frágil, menos idiomático.
**Alternativa descartada**: `BindsTo` o `After=mnt-usb\x2ddata.mount` — requiere conocer el nombre exacto de la unidad de montaje; `RequiresMountsFor` es más robusto y no depende del nombre.

## Risks / Trade-offs

- **Mantenimiento manual del SSD**: si se desmonta `/mnt/usb-data` intencionalmente (ej. para mantenimiento), Docker no podrá arrancar hasta que vuelva a montarse. Esto es el comportamiento deseado, pero hay que documentarlo. Mitigación: parar Docker antes de desmontar el SSD (`sudo systemctl stop docker`).
- **Fallo silencioso al arranque**: si el SSD falla, Docker simplemente no arranca y los contenedores no están disponibles. Mitigation: el acceso SSH sigue funcionando para diagnóstico.

## Migration Plan

1. Crear directorio: `sudo mkdir -p /etc/systemd/system/docker.service.d/`
2. Crear fichero drop-in:
   ```ini
   # /etc/systemd/system/docker.service.d/requires-usb.conf
   [Unit]
   RequiresMountsFor=/mnt/usb-data
   ```
3. Recargar systemd: `sudo systemctl daemon-reload`
4. Verificar: `systemctl show docker | grep RequiresMountsFor`
5. Reiniciar Docker para confirmar que arranca correctamente con el SSD montado
6. Documentar en `infraestructura/configuracion-inicial.md`
