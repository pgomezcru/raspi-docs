[🏠 Inicio](../README.md) > [📂 Infraestructura](_index.md)

# Plan HTTPS para entornos `*.home.lab`

Este documento describe la estrategia recomendada para disponer de HTTPS en el entorno local (`*.home.lab`) hoy (sin dominio público) y la transición futura a certificados públicos (Let's Encrypt) cuando se disponga de dominio/puertos públicos.

## Objetivo

- Proveer TLS para servicios internos (Homarr, AdGuard, Gitea, Jenkins) con la menor fricción para clientes de la LAN.
- Mantener un camino claro para migrar a certificados públicos cuando se tenga dominio.

## Resumen de opciones

- Opción A — CA local (recomendada hoy): crear una Autoridad de Certificación local, emitir certificados para `*.home.lab` y distribuir la CA raíz a los clientes de la LAN.
- Opción B — mkcert (rápido para desarrollo): herramienta que crea una CA local y la instala en el sistema/navegador del equipo usado para generar certificados.
- Opción C — Let's Encrypt (futuro): usar ACME con HTTP-01 o DNS-01 cuando el dominio público y el reenvío de puertos estén disponibles.

## Implementación (Opción A) — CA local con OpenSSL

1. Crear una CA local (hacerlo en la Raspberry o en una máquina de administración):

```bash
openssl genrsa -out /root/ca/myCA.key 4096
openssl req -x509 -new -nodes -key /root/ca/myCA.key -sha256 -days 3650 -out /root/ca/myCA.pem -subj "/CN=HomeLab-CA"
```

2. Generar clave y CSR para el servicio (ej. `adguard.home.lab`):

```bash
openssl genrsa -out /mnt/usb-data/nginx/certs/adguard.home.lab.key 2048
openssl req -new -key /mnt/usb-data/nginx/certs/adguard.home.lab.key -out /tmp/adguard.csr -subj "/CN=adguard.home.lab"
```

3. Firmar el CSR con la CA:

```bash
openssl x509 -req -in /tmp/adguard.csr -CA /root/ca/myCA.pem -CAkey /root/ca/myCA.key -CAcreateserial -out /mnt/usb-data/nginx/certs/adguard.home.lab.crt -days 825 -sha256
```

4. Permisos y ubicación (Nginx espera certificados en `/etc/nginx/certs` si usamos el `docker-compose` con bind mounts):

```bash
sudo chown root:root /mnt/usb-data/nginx/certs/adguard.home.lab.*
sudo chmod 640 /mnt/usb-data/nginx/certs/adguard.home.lab.key
```

5. Configurar Nginx (`/mnt/usb-data/nginx/conf.d/adguard.conf`):

```nginx
server { listen 80; server_name adguard.home.lab; return 301 https://$host$request_uri; }
server {
  listen 443 ssl;
  server_name adguard.home.lab;
  ssl_certificate /etc/nginx/certs/adguard.home.lab.crt;
  ssl_certificate_key /etc/nginx/certs/adguard.home.lab.key;
  location / {
    proxy_pass http://adguard:80;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
  }
}
```

6. Instalar la CA raíz en clientes (Windows/Mac/Linux):

- Windows: `mmc` → Certificates → Trusted Root Certification Authorities → Importar `myCA.pem`.
- macOS: Añadir a Keychain Access → System → marcar como confiable.
- Linux: copiar a `/usr/local/share/ca-certificates/` y `sudo update-ca-certificates` (posible variación según distro).

## Implementación alternativa (mkcert) — desarrollo rápido

- Instala `mkcert` en tu máquina de administración y ejecuta:

```bash
mkcert -install
mkcert -cert-file /mnt/usb-data/nginx/certs/adguard.home.lab.crt -key-file /mnt/usb-data/nginx/certs/adguard.home.lab.key adguard.home.lab
```

- `mkcert` crea una CA local y la instala en el sistema/navegadores automáticamente (útil para pruebas, menos control central que la CA manual).

## Transición futura — Let's Encrypt (cuando haya dominio público)

1. Requisitos:
- Dominio público apuntando a la IP pública del router.
- Redirección de puertos 80 y 443 al host (Raspberry) o uso de DNS-01.

2. Flujo recomendado:
- Usar Certbot (host o docker) con `--webroot` o usar un contenedor ACME client que comprometa `/.well-known/acme-challenge` en Nginx.
- Al obtener certificados colocarlos bajo `/etc/letsencrypt/...` o copiarlos a `/mnt/usb-data/nginx/certs` y actualizar `adguard.conf` con las rutas.
- Automatizar renovación (`certbot renew` + reload nginx).

## Consideraciones y buenas prácticas

- Mantén las claves privadas con permisos restrictivos (propietario `root`, `chmod 640` o `600`).
- Para servicios no‑HTTP (TCP) considera `stream` en Nginx o usar proxy que soporte SNI.
- Documenta en `infraestructura/` qué servicios usan qué certificados y dónde se encuentran los ficheros.
- Si vas a poner el dominio público en el futuro, prepara la red para permitir desafíos ACME o usa DNS-01 con el proveedor DNS.

## Consecuencias

- CA local: ✓ rápido, ✓ sin dependencia externa, ✗ requiere instalar CA en cada cliente.
- Let's Encrypt: ✓ confianza automática en clientes, ✗ requiere dominio/public exposure o DNS-01.

## Referencias

- `openssl` manual
- `mkcert` (https://github.com/FiloSottile/mkcert)
- Let's Encrypt / Certbot (https://certbot.eff.org/)

---
Documento creado para guiar la habilitación de TLS en el entorno `home.lab`. Modifica los ejemplos de rutas si tu `docker-compose` usa otras rutas.
