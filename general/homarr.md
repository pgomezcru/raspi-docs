[🏠 Inicio](../README.md) > [📂 General](_index.md)

# Homarr — Dashboard Centralizado

[Homarr](https://homarr.dev/) es un dashboard moderno y personalizable que sirve como página de inicio para tu servidor, proporcionando acceso rápido a todos tus servicios.

> **Documentación oficial**: [Homarr Docs](https://homarr.dev/docs/introduction)

## Características

- **Interfaz moderna**: Drag & drop para organizar widgets y servicios.
- **Integración de servicios**: Tarjetas con estado en tiempo real (Plex, Sonarr, Radarr, etc.).
- **Búsqueda integrada**: Acceso rápido mediante búsqueda web.
- **Widgets útiles**: Clima, calendario, notas, RSS, uso de recursos.
- **Personalización**: Temas, iconos, fondos personalizables.

## Arquitectura

Homarr será el sitio por defecto en Nginx (puerto 80/443), accesible directamente al entrar a la IP de la Raspberry Pi o al dominio base.

```
Usuario → http://rpi4.local (o IP)
         → Nginx Proxy (puerto 80)
         → Homarr Container (puerto 7575)
```

## Implementación con Docker Compose

### 1. Estructura de Directorios

Seguimos las buenas prácticas de volúmenes (usar named volumes gestionados por Docker).

```bash
# Crear directorio para el docker-compose
sudo mkdir -p /mnt/usb-data/homarr
```

### 2. Archivo `docker-compose.yml`

**Ubicación**: `/mnt/usb-data/homarr/docker-compose.yml`

```yaml
version: '3.8'

services:
  homarr:
    image: ghcr.io/ajnart/homarr:latest
    container_name: homarr
    restart: unless-stopped
    volumes:
      - /mnt/usb-data/docker-root/homarr/config:/app/data/configs
      - /mnt/usb-data/docker-root/homarr/icons:/app/public/icons
      - /mnt/usb-data/docker-root/homarr/data:/data
    environment:
      - TZ=Europe/Madrid
    networks:
      - proxy_net

networks:
  proxy_net:
    external: true

```

**Notas importantes:**
- **No exponer puertos**: Nginx contactará con Homarr internamente vía `proxy_net`.
- **Named volumes**: Los datos de configuración se guardarán en `/mnt/usb-data/docker-root/volumes/homarr-*/_data`.
- **Bind mounts**: Los datos de configuración se guardarán en `/mnt/usb-data/docker-root/homarr/{config,icons,data}`.
- **Timezone**: Ajusta `TZ` según tu ubicación.

### 3. Desplegar el contenedor

```bash
cd /mnt/usb-data/homarr
docker compose up -d
```

Verificar que está corriendo:
```bash
docker compose ps
docker logs homarr
```

### 4. Configuración de Nginx

Edita el archivo de configuración por defecto de Nginx para que apunte a Homarr.

**Ubicación**: `/mnt/usb-data/nginx/conf.d/default.conf`

```nginx
server {
    listen 80;
    server_name _;  # Responde a cualquier dominio/IP

    location / {
        proxy_pass http://homarr:7575;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # WebSocket support (si Homarr lo usa)
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

**Recargar Nginx** para aplicar cambios:
```bash
cd /mnt/usb-data/nginx
docker compose restart nginx
```

### 5. Verificar acceso

Abre tu navegador y ve a:
- `http://<IP-de-tu-Raspberry>` (ej. `http://192.168.1.100`)
- `http://rpi4.local` (si usas mDNS/Avahi)

Deberías ver la pantalla de bienvenida de Homarr.

## Configuración Inicial de Homarr

1. **Primera visita**: Homarr te pedirá crear una contraseña de administrador.
2. **Añadir servicios**: Haz clic en "Add a service" y configura tarjetas para tus servicios (Gitea, Jenkins, etc.).
3. **Personalizar layout**: Arrastra y suelta widgets para organizarlos.
4. **Temas**: Ve a `Settings > Appearance` para cambiar el tema (dark/light).

## Integración con Docker Socket (Opcional)

Si quieres que Homarr muestre el estado de tus contenedores en tiempo real:

1. **Edita `docker-compose.yml`** y añade el socket de Docker:

```yaml
services:
  homarr:
    volumes:
      - homarr-config:/app/data/configs
      - homarr-icons:/app/public/icons
      - homarr-data:/data
      - /var/run/docker.sock:/var/run/docker.sock:ro  # Solo lectura
```

2. **Reinicia Homarr**:
```bash
cd /mnt/usb-data/homarr
docker compose up -d --force-recreate
```

> **Seguridad**: Montar el socket Docker es potencialmente peligroso. Solo hazlo si confías en Homarr y tienes la red proxy bien protegida.

## Backup de Configuración

Los datos de configuración están en named volumes. Para hacer backup:

```bash
# Encontrar la ruta física
docker volume inspect homarr-config | jq -r '.[0].Mountpoint'

# Backup al NAS (ajusta la ruta)
sudo rsync -aHAX --info=progress2 \
  /mnt/usb-data/docker-root/volumes/homarr-config/_data/ \
  /mnt/nas/backups/homarr/config/
```

## Funcionamiento

Homarr separa **dos conceptos distintos**:

### 🔹 App (Service)

* Define **dónde está el servicio**
* Contiene:
  * Host / puerto
  * Tipo de servicio
  * Credenciales
* Es la **fuente de datos**

### 🔹 Widget

* **No se conecta a nada**
* Solo **visualiza datos** de un App existente
* Solo tiene opciones **visuales**

> 🔑 Si un widget no muestra datos → el App está mal o no existe

---

Dentro de Docker:

❌ No existen tus dominios locales (`*.home.lab`)
❌ No se usan puertos del host (`8080`, `8443`)

✔️ Se usan **nombres de servicio Docker**
✔️ Se usan **puertos internos del contenedor**

Ejemplo correcto:

```
http://adguard
```

---

## Para integrar un servicio

**Siempre en este orden**:

1. Crear **App**
2. Ver que el App se pone **verde**
3. Añadir **Widget**
4. El widget se rellena solo

Si saltas el paso 1 → el widget no funciona.

## Troubleshooting

### No puedo acceder a Homarr

1. Verifica que el contenedor está corriendo:
```bash
docker ps | grep homarr
```

2. Comprueba logs:
```bash
docker logs homarr
```

3. Verifica que Nginx puede ver el contenedor en la red `proxy_net`:
```bash
docker network inspect proxy_net | jq '.[0].Containers'
```

4. Testea conexión desde Nginx:
```bash
docker exec nginx_proxy curl -I http://homarr:7575
```

### Nginx muestra "502 Bad Gateway"

- Homarr no ha arrancado completamente (dale unos segundos).
- Ambos contenedores no están en la misma red `proxy_net`.
- Firewall bloqueando comunicación interna (poco probable en Docker).

### Cambios en dashboard no se guardan

- Verifica permisos de los volúmenes:
```bash
docker exec homarr ls -la /app/data/configs
```

## Referencias

- **REF-001**: [Homarr Official Site](https://homarr.dev/)
- **REF-002**: [Homarr GitHub](https://github.com/ajnart/homarr)
- **REF-003**: [Homarr Documentation](https://homarr.dev/docs/introduction)
