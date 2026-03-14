[🏠 Inicio](../README.md) > [📂 Programación](_index.md)

# VS Code Server (Code-Server)

**Estado**: Planificación Preliminar

Ejecutar VS Code en un navegador permite desarrollar desde cualquier dispositivo (iPad, Laptop de trabajo) accediendo a la potencia y archivos de la Raspberry Pi.

## Selección de Software

Utilizaremos [**code-server**](https://coder.com/docs/code-server/latest) (mantenido por Coder), que es la implementación más popular y estable para [Docker](https://docs.docker.com/).

## Requisitos

- Imagen Docker: `lscr.io/linuxserver/code-server:latest`
- Persistencia: Volumen para `/config` (configuraciones de usuario y extensiones) y acceso a las carpetas de proyectos.

## Configuración Docker (Borrador)

```yaml
version: "3"
services:
  code-server:
    image: lscr.io/linuxserver/code-server:latest
    container_name: code-server
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Europe/Madrid
      - PASSWORD=password # ¡Cambiar esto!
      - SUDO_PASSWORD=password # Opcional, para instalar paquetes en la terminal
    volumes:
      - ./config:/config
      - /home/pi/projects:/home/coder/project # Mapear carpeta de proyectos del host
    ports:
      - "8443:8443"
    restart: unless-stopped
```

## Ventajas
- **Entorno Persistente**: La terminal y los archivos se quedan donde los dejaste.
- **Acceso Local**: Al mapear volúmenes, puedes editar archivos que residen en la Raspberry Pi directamente.
- **Extensiones**: Soporta la mayoría de extensiones de VS Code (aunque usa el marketplace de Open VSX por defecto).

## Notas de Seguridad
- Es **crítico** no exponer este puerto a internet sin una VPN ([WireGuard](https://www.wireguard.com/)/[Tailscale](https://tailscale.com/kb/)) o un Reverse Proxy con autenticación robusta, ya que da acceso total a la terminal del servidor.
