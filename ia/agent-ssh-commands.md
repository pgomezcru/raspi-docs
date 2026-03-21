[🏠 Inicio](../README.md) > [📂 IA](_index.md)

# Comandos SSH del agente — Referencia rápida

Guía de referencia para los comandos que el agente puede ejecutar en la Raspberry Pi via SSH.  
El alias `raspi-claude` apunta a `192.168.1.101` con el usuario `claude-agent`.

Para el modelo de seguridad completo (usuario, clave SSH, sudoers, hooks) ver [Claude Code](claude-code.md).

---

## Comandos permitidos (sin confirmación)

Operaciones de solo lectura e inspección que el agente puede ejecutar libremente:

```bash
# Contenedores Docker
ssh raspi-claude docker ps
ssh raspi-claude docker logs <container> --tail 50
ssh raspi-claude docker inspect <container>
ssh raspi-claude docker stats --no-stream

# Sistema de ficheros y recursos
ssh raspi-claude df -h /mnt/usb-data
ssh raspi-claude free -h
ssh raspi-claude uptime
ssh raspi-claude cat /mnt/usb-data/<path>

# Servicios y logs del sistema
ssh raspi-claude sudo journalctl -u <unit> -n 50
ssh raspi-claude systemctl status <unit>
```

---

## Comandos que requieren confirmación del usuario

Operaciones que modifican el estado del sistema. El agente debe mostrar el plan y esperar aprobación explícita antes de ejecutar:

```bash
# Gestión de contenedores
ssh raspi-claude docker restart <container>
ssh raspi-claude docker stop <container>
ssh raspi-claude docker start <container>
ssh raspi-claude docker compose up -d
ssh raspi-claude docker pull <image>

# Servicios del sistema y paquetes
ssh raspi-claude sudo systemctl restart <unit>
ssh raspi-claude sudo apt update
```

---

## Comandos prohibidos

Los agentes tienen **PROHIBIDO** ejecutar los siguientes comandos. Están bloqueados tanto en `settings.json` de Claude Code como en los hooks de seguridad (`block-dangerous.ps1`):

| Comando | Motivo |
|---------|--------|
| `rm`, `sudo rm` | Eliminación de ficheros/directorios |
| `dd` | Escritura directa en dispositivos de bloque |
| `mkfs`, `wipefs` | Formateo de discos |
| `sudo passwd` | Cambio de contraseñas |
| `sudo userdel`, `sudo usermod` | Modificación de usuarios |
| `sudo reboot`, `sudo shutdown` | Apagado/reinicio del sistema |

> Si una tarea requiere ejecutar alguno de estos comandos, el agente debe comunicárselo al usuario para que lo ejecute manualmente.
