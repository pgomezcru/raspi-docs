## Context

nginx ya expone el puerto 443 en su docker-compose.yml y tiene el bind mount `/mnt/usb-data/nginx/certs:/etc/nginx/certs:ro` preparado. El directorio de certs está vacío. Todos los servicios del homelab usan el dominio `*.home.lab` gestionado por AdGuard. Los clientes son dispositivos de LAN privada (sin acceso desde internet), por lo que Let's Encrypt con validación HTTP no es viable directamente.

## Goals / Non-Goals

**Goals:**
- Terminar TLS en nginx para todos los vhosts de `*.home.lab`
- Redirigir HTTP (80) → HTTPS (443) automáticamente
- Que los navegadores de los clientes LAN no muestren avisos de certificado

**Non-Goals:**
- Certificados públicos de Let's Encrypt (requeriría exposición pública o DNS challenge)
- Renovación automática en esta fase
- TLS mutual (mTLS) entre servicios internos

## Decisions

### 1. mkcert como CA local
**Decisión**: usar `mkcert` para crear una CA local y generar un certificado wildcard `*.home.lab`.
**Razón**: mkcert instala la CA en el almacén de certificados del sistema, haciendo que todos los navegadores confíen en los certs automáticamente. Es la opción más sencilla para una LAN privada.
**Alternativa descartada**: OpenSSL + distribución manual del cert — funcional pero tedioso de instalar en cada cliente.
**Alternativa descartada**: Let's Encrypt con DNS challenge — posible pero requiere un proveedor DNS con API (el dominio `.home.lab` es local).

### 2. Certificado wildcard único para *.home.lab
**Decisión**: un solo certificado wildcard `*.home.lab` compartido por todos los vhosts.
**Razón**: simplifica la gestión. Añadir un nuevo servicio no requiere generar un nuevo cert.

### 3. Terminación TLS en nginx (no en los contenedores)
**Decisión**: solo nginx maneja TLS; los contenedores siguen comunicándose en HTTP por `proxy_net`.
**Razón**: arquitectura estándar de proxy inverso; los servicios internos no necesitan saber de TLS.

## Risks / Trade-offs

- **Distribución de la CA**: cada cliente nuevo requiere instalar la CA de mkcert manualmente. Mitigación: documentar el proceso por plataforma (Windows, Linux, Android, iOS).
- **Renovación**: `mkcert` genera certs válidos 2-10 años pero no se renuevan automáticamente. Mitigación: anotar la fecha de expiración en la documentación.
- **Android/iOS**: instalar CAs de terceros en móviles requiere pasos adicionales dependientes de la versión del SO. Puede no ser trivial en iOS.

## Migration Plan

1. Instalar `mkcert` en Goliath (Windows) — genera la CA local
2. Ejecutar `mkcert -install` para añadir la CA al almacén de Windows
3. Generar `mkcert "*.home.lab"` → produce `_wildcard.home.lab.pem` y `_wildcard.home.lab-key.pem`
4. Copiar los ficheros a `/mnt/usb-data/nginx/certs/` en la Pi
5. Actualizar cada vhost en `/mnt/usb-data/nginx/conf.d/` con los bloques `ssl_*` y redirección HTTP→HTTPS
6. Recargar nginx: `docker exec nginx_proxy nginx -s reload`
7. Distribuir la CA a los demás clientes (Nemo, móviles)
8. Documentar en `infraestructura/https-plan.md`

## Open Questions

- ¿En qué dispositivos es prioritario instalar la CA primero? (Goliath primero, luego Nemo)
- ¿Cómo manejar la CA en los móviles Android? (requiere investigación por versión de Android)
