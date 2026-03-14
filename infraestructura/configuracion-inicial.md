[🏠 Inicio](../README.md) > [📂 Infraestructura](_index.md)

# Configuración Inicial y Hardening de Raspberry Pi 4

Esta guía cubre los pasos esenciales para asegurar una Raspberry Pi 4 recién instalada, pasando de una configuración por defecto insegura a un servidor robusto.

## 1. Actualización del Sistema

Lo primero es siempre tener el software al día.

```bash
sudo apt update && sudo apt full-upgrade -y
# Opcional: Limpiar paquetes antiguos
sudo apt autoremove -y
```

## 2. Gestión de Usuarios

### Cambiar la contraseña del usuario actual
Si usas el usuario `pi` con una contraseña débil, cámbiala inmediatamente.

```bash
passwd
```

### Crear un nuevo usuario administrador (Recomendado)
Es buena práctica no usar el usuario por defecto `pi`. Vamos a crear uno nuevo (ej. `admin`) y darle permisos `sudo`.

```bash
# Crear usuario (sigue las instrucciones)
sudo adduser admin

# Añadir al grupo sudo
sudo usermod -aG sudo admin

# Verificar que funciona (desde otra terminal)
ssh admin@rpi4.local
```

*Nota: Una vez verificado que el nuevo usuario funciona, puedes bloquear el usuario `pi` con `sudo passwd -l pi`.*

## 3. Hardening de SSH

El acceso por contraseña es vulnerable a fuerza bruta. Usaremos claves SSH.

> 📘 **Guía Detallada**: Para más información sobre tipos de claves, rotación y recuperación, consulta la guía de [Gestión de Claves SSH](ssh-keys.md).

### Generar claves (En tu ordenador local, NO en la Pi)

**Windows (PowerShell) / Linux / Mac:**
```bash
ssh-keygen -t ed25519 -C "tu_email@ejemplo.com"
```

### Copiar la clave pública a la Pi

**Desde Linux / Mac:**
```bash
ssh-copy-id admin@rpi4.local
```

**Desde Windows (PowerShell):**
El comando `ssh-copy-id` no está disponible nativamente en Windows. Usa este comando para copiar la clave:

```powershell
type $env:USERPROFILE\.ssh\id_ed25519.pub | ssh admin@rpi4.local "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
```

**Método manual (si ssh-copy-id falla):**
Copia el contenido de tu archivo `.pub` local y pégalo en `~/.ssh/authorized_keys` en la Pi.

### Deshabilitar autenticación por contraseña
**¡CUIDADO!** Haz esto solo después de confirmar que puedes entrar con tu clave SSH.

Edita la configuración de SSH:
```bash
sudo nano /etc/ssh/sshd_config
```

Busca y modifica estas líneas:
```ini
PasswordAuthentication no
PermitRootLogin no
```

Reinicia el servicio SSH:
```bash
sudo systemctl restart ssh
```

## 4. Firewall Básico (UFW)

Instala y configura `ufw` ([Uncomplicated Firewall](https://help.ubuntu.com/community/UFW)) para cerrar puertos no usados.

```bash
sudo apt install ufw -y

# Permitir SSH (¡CRÍTICO! Si no lo haces, te quedarás fuera)
sudo ufw allow ssh

# Habilitar el firewall
sudo ufw enable
```

Ver estado:
```bash
sudo ufw status
```

## 5. Protección contra Fuerza Bruta (Fail2Ban)

[Fail2Ban](https://github.com/fail2ban/fail2ban/wiki) banea IPs que intentan adivinar tu contraseña repetidamente.

```bash
sudo apt install fail2ban -y
```

La configuración por defecto suele ser suficiente para SSH, pero puedes crear una copia local para personalizarla:

```bash
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
sudo systemctl restart fail2ban
```

Verificar que está corriendo:
```bash
sudo fail2ban-client status sshd
```

## 6. Instalación de Docker

Para ejecutar contenedores modernos, instalaremos la versión oficial de Docker (no la de los repositorios de Debian/Raspbian).

### Instalación mediante script oficial

```bash
# Descargar e instalar
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
```

### Configuración de permisos (Post-instalación)

Para ejecutar comandos `docker` sin `sudo` (necesario para scripts y comodidad):

```bash
# Añadir tu usuario actual al grupo docker
sudo usermod -aG docker $USER
```

> **Importante**: Debes cerrar sesión y volver a entrar (o reiniciar) para que este cambio de grupo surta efecto.

### Verificación

```bash
# Comprobar versiones (Docker Compose v2 ya viene incluido)
docker version
docker compose version

# Prueba rápida
docker run hello-world
```

