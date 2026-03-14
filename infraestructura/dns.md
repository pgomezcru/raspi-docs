## 📌 Configuración DNS en Raspberry Pi (AdGuard Home en Docker)

### 🎯 Objetivo

Usar **AdGuard Home (Docker)** como **DNS primario** del host (Raspberry Pi) y el **router (`192.168.1.1`) como DNS secundario**, evitando dependencias de redes internas de Docker.

---

### 🧱 Arquitectura final

```
Raspberry Pi (192.168.1.101)
 ├─ Docker
 │   └─ AdGuard Home (IP interna Docker: 172.18.0.3)
 │       ↳ publicado en 192.168.1.101:53 (TCP/UDP)
 └─ Sistema (NetworkManager)
     ↳ DNS primario: 192.168.1.101
     ↳ DNS secundario: 192.168.1.1
```

---

### 🔧 Cambios realizados

#### 1️⃣ Publicación correcta del DNS del contenedor

Se expuso el puerto 53 del contenedor **solo en la IP LAN del host**, no en todas las interfaces:

```yaml
ports:
  - "192.168.1.101:53:53/tcp"
  - "192.168.1.101:53:53/udp"
```

✔️ Evita interferencias con servicios locales  
✔️ Evita bucles DNS  
✔️ Más seguro que `53:53`

---

#### 2️⃣ Confirmación de publicación del puerto

Verificación de que el host escucha DNS vía Docker:

```bash
sudo ss -lunp | grep ':53'
sudo lsof -i :53
```

Resultado:

- `docker-proxy` escuchando en `*:53` (TCP/UDP)
- Sin conflictos con otros resolvers

---

#### 3️⃣ Prueba directa del DNS publicado

```bash
dig @192.168.1.101 google.com
```

✔️ Respuesta correcta desde AdGuard

---
#### 4️⃣ Identificación del gestor de red

Se comprobó que **`dhcpcd` no está presente**.  
El sistema usa **NetworkManager** (Debian 12 / Raspberry Pi OS moderno).

---
#### 5️⃣ Configuración del DNS del sistema (NetworkManager)

Se fijó el DNS manualmente para la conexión activa, ignorando el DNS recibido por DHCP:

```bash
sudo nmcli connection modify "Wired" \
  ipv4.ignore-auto-dns yes \
  ipv4.dns "192.168.1.101 192.168.1.1"
```

✔️ AdGuard como primario  
✔️ Router como fallback

Aplicado sin cortar SSH:

```bash
sudo nmcli device reapply eth0
```

---

#### 6️⃣ Verificación del DNS efectivo

```bash
cat /etc/resolv.conf
nmcli device show eth0 | grep DNS
```

Resultado esperado:

```
nameserver 192.168.1.101
nameserver 192.168.1.1
```

---

#### 7️⃣ Prueba de tolerancia a fallos

```bash
docker stop adguard-home
dig google.com
docker start adguard-home
```

✔️ Resolución correcta vía router cuando AdGuard cae  
✔️ Recuperación automática al volver a arrancar

---

### 🚫 Decisiones conscientes (qué NO se hizo)

- No usar IP interna Docker (`172.x`)
- No editar `/etc/resolv.conf` a mano
- No desactivar `systemd-resolved`
- No usar `127.0.0.1` como DNS
- No bindear `53:53` en `0.0.0.0`

---

### ✅ Estado final

- DNS robusto
- Arranque seguro
- Sin dependencias circulares
- Preparado para extender a toda la LAN

---

### Posibles siguientes pasos:

- **router anunciando AdGuard por DHCP**
- **bloqueo de bypass DNS**
- **métricas de AdGuard en Grafana**
