[🏠 Inicio](../README.md) > [📂 Infraestructura](_index.md)

# Guía de Fail2Ban: Conceptos y Escenarios Futuros

Fail2Ban es un "vigilante" automatizado que protege tu servidor de ataques de fuerza bruta.

## ¿Cómo funciona?

1.  **Vigila**: Lee continuamente los archivos de log (ej. `/var/log/auth.log`, logs de Nginx, logs de Gitea).
2.  **Detecta**: Busca patrones definidos (ej. "Failed password", "Login failed").
3.  **Castiga**: Si una IP comete X errores en Y tiempo, Fail2Ban actualiza el firewall (iptables/UFW) para bloquear esa IP temporalmente.

---

## Escenario 1: El Ataque SSH (Inmediato)

Este es el escenario más común desde el minuto 1 que conectas la Raspberry a la red.

**Situación**:
Un bot intenta adivinar la contraseña de `root` o `pi` miles de veces por minuto.

**Configuración Típica (`/etc/fail2ban/jail.local`)**:
```ini
[sshd]
enabled = true
port    = ssh
logpath = %(sshd_log)s
maxretry = 3        # A los 3 intentos fallidos...
bantime  = 1d       # ...te vas fuera 1 día entero.
findtime = 10m      # (Los 3 intentos deben ocurrir en una ventana de 10 min)
```

**Resultado**:
El bot prueba 3 contraseñas. A la cuarta, su conexión se corta. Tu log deja de llenarse de basura y tu CPU descansa.

---

## Escenario 2: Exponiendo Gitea a Internet (Futuro)

**Situación**:
Decides abrir el puerto 3000 (o el 80/443 a través de un proxy) en tu router para acceder a tu Gitea desde fuera de casa. Ahora, cualquiera puede ver tu pantalla de login de Gitea e intentar entrar.

**El Problema**:
Fail2Ban por defecto mira los logs del sistema (SSH). No sabe que Gitea existe ni dónde guarda sus logs.

**La Solución**:
Necesitas crear un "filtro" y una "jaula" (jail) para Gitea.

1.  **El Filtro** (Decirle a Fail2Ban qué buscar):
    Gitea escribe en su log algo como: `Failed authentication attempt for user...`
2.  **La Jaula** (Decirle qué log mirar):
    Como Gitea corre en Docker, necesitamos que Gitea escriba sus logs en un volumen que el host pueda leer (ej. `/var/log/gitea/gitea.log`).

```ini
# Ejemplo hipotético de jail para Gitea
[gitea]
enabled = true
filter = gitea
logpath = /ruta/a/tu/volumen/gitea/log/gitea.log
maxretry = 5
action = iptables-allports[name=gitea]
```

> **Nota Importante con Docker**: Si usas Docker, Fail2Ban (que corre en el host) modifica las reglas de iptables del host. Docker a veces se salta UFW, pero Fail2Ban suele trabajar directamente sobre iptables, lo cual es efectivo. Sin embargo, hay una complejidad extra: **Docker Userland Proxy**. A veces Docker hace que todo el tráfico parezca venir de una IP interna (172.x.x.x). Configurar Fail2Ban con Docker requiere asegurarse de que la IP real del atacante llegue a los logs.

---

## Escenario 3: El Reverse Proxy (Nginx/Traefik)

**Situación**:
Tienes Gitea, Jenkins y VS Code Server. No quieres abrir 3 puertos en el router. Abres solo el 443 y usas un Reverse Proxy (como Nginx) para redirigir:
- `git.midominio.com` -> Gitea
- `code.midominio.com` -> VS Code

**Estrategia de Defensa**:
En lugar de vigilar cada servicio individualmente, vigilas al portero (Nginx).

Si alguien intenta hacer login en Gitea y falla, Gitea devuelve un error HTTP 401 (Unauthorized). Nginx registra ese 401.

**Configuración**:
Configuras Fail2Ban para leer los logs de Nginx (`/var/log/nginx/access.log`) buscando muchas peticiones que resulten en error 401/403 desde la misma IP.

```ini
[nginx-http-auth]
enabled = true
filter = nginx-http-auth
port    = http,https
logpath = /var/log/nginx/error.log
```

Esta es la forma más eficiente de proteger múltiples servicios Dockerizados.

---

## Comandos Útiles para el Día a Día

Ver el estado general y qué jaulas están activas:
```bash
sudo fail2ban-client status
```

Ver detalles de una jaula (cuántos baneados hay):
```bash
sudo fail2ban-client status sshd
```

Desbanear una IP (ej. si te bloqueaste a ti mismo por error):
```bash
sudo fail2ban-client set sshd unbanip 192.168.1.50
```
