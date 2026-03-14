[🏠 Inicio](../README.md) > [📂 General](_index.md)

# AdGuard Home — DNS Local y Bloqueador de Publicidad

[AdGuard Home](https://adguard.com/en/adguard-home/overview.html) es un servidor DNS local que bloquea publicidad y rastreadores a nivel de red, además de permitir la resolución de nombres personalizados para tu red doméstica.

> **Documentación oficial**: [AdGuard Home Wiki](https://github.com/AdguardTeam/AdGuardHome/wiki)

## Características Principales

- **Bloqueo de publicidad**: Filtra ads, trackers y malware a nivel DNS para todos los dispositivos de la red.
- **DNS Rewrites**: Resuelve nombres personalizados (`git.home.lab → 192.168.1.101`) sin editar archivos de configuración manualmente.
- **DoH/DoT**: Soporte nativo para DNS sobre HTTPS y TLS (cifrado de consultas upstream).
- **Interfaz moderna**: Dashboard web limpio y fácil de usar.
- **Bajo consumo**: ~50-80 MB RAM, escrito en Go (muy eficiente).
- **Estadísticas**: Gráficos de consultas, dominios bloqueados, clientes activos.

## Caso de Uso en tu Red

AdGuard Home servirá como servidor DNS principal para toda tu red doméstica:
- Resuelve nombres locales personalizados (`git.home.lab`, `jenkins.home.lab`, `homarr.home.lab`).
- Bloquea publicidad y trackers en todos los dispositivos (PC, móviles, smart TVs).
- Redirige consultas DNS upstream (ej. a Cloudflare, Google DNS) con cifrado opcional.

## Implementación con Docker Compose

### 1. Estructura de Directorios

Usaremos named volumes para datos persistentes.

```bash
# Crear directorio para el docker-compose
sudo mkdir -p /mnt/usb-data/adguard-home
```

### 2. Archivo `docker-compose.yml`

**Ubicación**: `/mnt/usb-data/adguard-home/docker-compose.yml`

```yaml
version: '3.8'

services:
  adguard:
    image: adguard/adguardhome:latest
    container_name: adguard-home
    restart: unless-stopped
    ports:
    # Exponemos con ip
      - "192.168.1.101:53:53/tcp"
      - "192.168.1.101:53:53/udp"
      - "3000:3000/tcp"  # Setup inicial
      - "8080:80/tcp"    # Admin panel HTTP
      - "8443:443/tcp"   # Admin panel HTTPS
    volumes:
      - adguard-work:/opt/adguardhome/work
      - adguard-conf:/opt/adguardhome/conf
    environment:
      - TZ=Europe/Madrid
    networks:
      - proxy_net

volumes:
  adguard-work:
    name: adguard-work
  adguard-conf:
    name: adguard-conf

networks:
  proxy_net:
    external: true
```

**Notas importantes:**
- **Puerto 53**: Expuesto para DNS.
- **Puerto 3000**: Setup inicial (puedes comentarlo después del setup).
- **Puerto 8080 (host) → 80 (contenedor)**: Panel admin HTTP. Accede vía `http://<IP-Raspberry>:8080`
- **Puerto 8443 (host) → 443 (contenedor)**: Panel admin HTTPS. Accede vía `https://<IP-Raspberry>:8443`
- **Nginx sigue usando 80/443** del host sin conflicto.

### 3. Resolver conflicto de puerto 53

Si ya tienes un servicio DNS corriendo en el puerto 53 (ej. `systemd-resolved`), debes deshabilitarlo.

**Comprobar si hay algo en puerto 53:**
```bash
sudo netstat -tulpn | grep :53
```

**Si `systemd-resolved` está activo:**
```bash
# Deshabilitar systemd-resolved
sudo systemctl disable --now systemd-resolved

# Eliminar el enlace simbólico de resolv.conf
sudo rm /etc/resolv.conf

# Crear un nuevo resolv.conf apuntando a AdGuard (lo haremos después)
echo "nameserver 127.0.0.1" | sudo tee /etc/resolv.conf
```

### 4. Desplegar AdGuard Home

```bash
cd /mnt/usb-data/adguard-home
docker compose up -d
```

Verificar que está corriendo:
```bash
docker compose ps
docker logs adguard-home
```

### 5. Configuración Inicial

1. **Accede al setup inicial**: `http://<IP-Raspberry>:3000`
2. **Configuración del Admin Panel**:
   - Puerto admin: `80` (dentro del contenedor, mapeado a 8080 en el host)
   - Puerto DNS: `53`
   - Usuario y contraseña: configura credenciales seguras
3. **Upstream DNS**: Configura servidores DNS upstream (ej. Cloudflare `1.1.1.1`, Google `8.8.8.8`).
   - Para DoH: `https://dns.cloudflare.com/dns-query`
4. **Listas de bloqueo**: AdGuard viene con listas predefinidas; actívalas o añade personalizadas.

**Después del setup**, accede al panel admin en: `http://<IP-Raspberry>:8080`

### 6. Configurar DNS Rewrites (Nombres Locales)

Para que `git.home.lab` resuelva a la IP de tu Raspberry Pi:

1. Ve a **Filters → DNS rewrites**.
2. Añade cada rewrite:
   - `git.home.lab → 192.168.1.100` (ajusta la IP)
   - `jenkins.home.lab → 192.168.1.100`
   - `homarr.home.lab → 192.168.1.100`
   - `rpi4.home.lab → 192.168.1.100`

**Alternativa con comodín** (si quieres que `*.home.lab` apunte a la misma IP):
- `*.home.lab → 192.168.1.100`

#### Nombre de dominio local en el navegador

>> TODO: Más adelante

El navegador interpreta "hola.home.lab" como una búsqueda en el navegador. Hay que poner barra al final o http delante. Esto puede cambiarse, pero no vamos a gastar tiempo en esto.

### 7. Configurar Dispositivos para Usar AdGuard

#### Opción A: Configurar el Router (Recomendado)

Accede a tu router y cambia el servidor DNS principal a la IP de la Raspberry Pi (ej. `192.168.1.100`). Todos los dispositivos usarán automáticamente AdGuard.

**Ubicación típica en routers:**
- **TP-Link**: `DHCP Settings → Primary DNS`
- **Fritz!Box**: `Internet → Account Information → DNS Server`
- **Mikrotik**: `/ip dhcp-server network set dns-server=192.168.1.100`

#### Opción B: Configurar Manualmente en cada Dispositivo

**Windows:**
- Panel de Control → Red e Internet → Centro de redes → Cambiar configuración del adaptador
- Propiedades de tu conexión → IPv4 → Servidor DNS preferido: `192.168.1.100`

**Linux/Raspberry Pi:**
Edita `/etc/resolv.conf`:
```bash
nameserver 192.168.1.100
```

**Android/iOS:**
- Ajustes → Wi-Fi → (tu red) → DNS: `192.168.1.100`

### 8. Verificar Funcionamiento

1. **Desde cualquier dispositivo**, haz ping a un nombre local:
```bash
ping git.home.lab
```
Debería resolver a `192.168.1.100`.

2. **Comprueba el bloqueo de ads**: visita `http://ads-blocker-test.com` (debería mostrar que los ads están bloqueados).

3. **Ver estadísticas** en el panel admin: `http://<IP-Raspberry>:8080`

## Acceso al Panel Admin vía Nginx Proxy (Opcional)

Si prefieres acceder con un nombre limpio (`adguard.home.lab`) en lugar de `IP:8080`, configura un proxy Nginx.

**Crear `/mnt/usb-data/nginx/conf.d/adguard.conf`:**

```nginx
server {
    listen 80;
    server_name adguard.home.lab;

    location / {
        proxy_pass http://adguard-home:80;  # Puerto interno del contenedor
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

Luego añade el rewrite DNS:
- `adguard.home.lab → 192.168.1.100`

Reinicia Nginx:
```bash
cd /mnt/usb-data/nginx
docker compose restart nginx
```

## Configuración Avanzada

### DoH/DoT (DNS sobre HTTPS/TLS)

Para cifrar las consultas DNS hacia internet:

1. Ve a **Settings → DNS settings → Upstream DNS servers**.
2. Añade servidores DoH:
   ```
   https://dns.cloudflare.com/dns-query
   https://dns.google/dns-query
   ```
3. Marca "Enable parallel requests" para mayor velocidad.

### Listas de Bloqueo Personalizadas

1. Ve a **Filters → DNS blocklists**.
2. Añade listas populares:
   - [StevenBlack's hosts](https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts)
   - [OISD Full](https://big.oisd.nl/)
3. Actualiza las listas automáticamente (configuración en la UI).

### Whitelist/Blacklist Manual

- **Blacklist**: Añade dominios específicos a bloquear en **Filters → Custom filtering rules**.
- **Whitelist**: Si un dominio legítimo es bloqueado por error, añádelo a **Filters → Allowlist**.

## Backup de Configuración

Los datos están en named volumes. Para hacer backup:

```bash
# Encontrar rutas físicas
docker volume inspect adguard-conf | jq -r '.[0].Mountpoint'
docker volume inspect adguard-work | jq -r '.[0].Mountpoint'

# Backup al NAS
sudo rsync -aHAX --info=progress2 \
  /mnt/usb-data/docker-root/volumes/adguard-conf/_data/ \
  /mnt/nas/backups/adguard/conf/

sudo rsync -aHAX --info=progress2 \
  /mnt/usb-data/docker-root/volumes/adguard-work/_data/ \
  /mnt/nas/backups/adguard/work/
```

## Troubleshooting

### No puedo acceder al panel admin

1. Verifica que el contenedor está corriendo:
```bash
docker ps | grep adguard
```

2. Comprueba logs:
```bash
docker logs adguard-home
```

3. Verifica puertos:
```bash
sudo netstat -tulpn | grep -E '(53|3000|80)'
```

### DNS no resuelve nombres locales

1. Comprueba que el rewrite está configurado:
   - Panel admin → Filters → DNS rewrites
2. Prueba la resolución directamente en la Raspberry:
```bash
nslookup git.home.lab 127.0.0.1
```

### Los dispositivos no usan AdGuard

1. Verifica la configuración DNS en el router.
2. Comprueba que los clientes reciben la IP correcta vía DHCP:
```bash
ipconfig /all   # Windows
ip a            # Linux
```

### Puerto 53 en uso

Si otro servicio ocupa el puerto 53:
```bash
sudo lsof -i :53
```
Deshabilita el servicio conflictivo o cambia el puerto en AdGuard (no recomendado).

## Firewall (UFW)

Permite el tráfico DNS si usas UFW:

```bash
# Permitir DNS desde la red local
sudo ufw allow from 192.168.1.0/24 to any port 53 proto tcp
sudo ufw allow from 192.168.1.0/24 to any port 53 proto udp

# Permitir acceso al panel admin desde la red local
sudo ufw allow from 192.168.1.0/24 to any port 8080 proto tcp
sudo ufw allow from 192.168.1.0/24 to any port 8443 proto tcp
```

## Referencias

- **REF-001**: [AdGuard Home Official Site](https://adguard.com/en/adguard-home/overview.html)
- **REF-002**: [AdGuard Home GitHub](https://github.com/AdguardTeam/AdGuardHome)
- **REF-003**: [AdGuard Home Wiki](https://github.com/AdguardTeam/AdGuardHome/wiki)
- **REF-004**: [DNS Rewrites Guide](https://github.com/AdguardTeam/AdGuardHome/wiki/Configuration#dns-rewrites)
