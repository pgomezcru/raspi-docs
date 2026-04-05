## Why

Todos los servicios del homelab se sirven en HTTP sin cifrado. Las credenciales de administración (Grafana, Gitea, AdGuard, Homarr) viajan en texto plano por la red local. Además, los navegadores modernos marcan los formularios HTTP como inseguros, degradando la experiencia de uso.

## What Changes

- Generar un certificado wildcard autofirmado para `*.home.lab` (o usar `mkcert` para CA local de confianza)
- Configurar nginx para escuchar en 443 con TLS y redirigir HTTP → HTTPS
- Instalar la CA local en los clientes de la LAN (Goliath, Nemo, móviles)
- Actualizar las URLs en Homarr de `http://` a `https://`

## Capabilities

### New Capabilities
- `tls-termination`: nginx gestiona terminación TLS para todos los servicios de `*.home.lab`

### Modified Capabilities
- `reverse-proxy`: se añade escucha en 443 y redirección 301 desde 80

## Impact

- **compose/nginx/docker-compose.yml**: ya expone 443, requiere bind mount de certs
- **`/mnt/usb-data/nginx/certs/`**: directorio para almacenar cert y clave privada
- **`/mnt/usb-data/nginx/conf.d/`**: actualizar todos los vhosts con bloque `ssl_*`
- **Clientes**: requiere instalar la CA local en cada dispositivo para evitar avisos del navegador
- **Homarr**: actualizar URLs de integraciones y widgets
