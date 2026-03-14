[🏠 Inicio](../README.md) > [📂 Infraestructura](_index.md)

# Conexión a Raspberry Pi 4

Guía para conectar a la Raspberry Pi 4 mediante SSH desde diferentes sistemas operativos.

## Prerrequisitos

- **Dirección IP** de la Raspberry Pi (ej. `192.168.1.100`).
- **Usuario** (por defecto suele ser `pi` o el que hayas configurado).
- **SSH habilitado** en la Raspberry Pi.

## Desde Windows

### Opción 1: Windows Terminal / PowerShell (Recomendado)

Windows 10 y 11 incluyen un cliente [OpenSSH](https://www.openssh.com/) nativo.

```powershell
# Sintaxis: ssh usuario@ip
ssh pi@192.168.1.100
```

### Opción 2: PuTTY

Si prefieres una interfaz gráfica:
1. Descarga e instala [PuTTY](https://www.putty.org/).
2. En "Host Name (or IP address)", introduce la IP.
3. Asegúrate de que el puerto es **22** y el tipo de conexión es **SSH**.
4. Haz clic en **Open**.

## Desde Linux

La mayoría de distribuciones Linux tienen el cliente SSH instalado por defecto.

```bash
# Abre tu terminal favorita y ejecuta:
ssh pi@192.168.1.100
```

## Solución de problemas

Si no puedes conectar:
1. Verifica que la Pi esté encendida y conectada a la red.
2. Intenta hacer ping a la IP:
   ```bash
   ping 192.168.1.100
   ```
3. Asegúrate de haber habilitado SSH (creando un archivo vacío llamado `ssh` en la partición `boot` de la tarjeta SD si es una instalación nueva).
