[🏠 Inicio](../README.md) > [📂 Infraestructura](_index.md)

# Montar la ubicación de red /mnt/usb-data en 192.168.1.101 (Raspberry Pi) — Windows y Linux

Resumen breve: instrucciones para montar la carpeta remota `/mnt/usb-data` que está en la Raspberry Pi con IP `192.168.1.101`, desde Linux (incluyendo WSL2) y Windows. Se presentan dos opciones: Samba/CIFS (ideal para Windows) y NFS (más natural en Linux). Incluye opciones temporales y permanentes, permisos y recomendaciones de seguridad.

**Requisitos previos**
- Conectividad de red entre el equipo cliente y `192.168.1.101`.
- En la Raspberry Pi: carpeta compartida `/mnt/usb-data` creada y exportada (Samba o NFS).
- En clientes Linux: paquetes `cifs-utils` para CIFS/SMB y `nfs-common` para NFS.
- En Windows: acceso a la red local y credenciales de la cuenta Samba si aplica.

**Enlace a documentación oficial**
- Samba: https://www.samba.org/samba/docs/
- Montar disco/enlaces en WSL2: https://learn.microsoft.com/en-us/windows/wsl/wsl2-mount-disk
- NFS (exports): https://linux.die.net/man/5/exports

> Nota: se asume que la Raspberry Pi ya comparte `/mnt/usb-data` como recurso `usb-data`. Si no, abajo hay ejemplos mínimos de configuración en la Pi.

---

## Tecnologías en la Raspberry e implicaciones para clientes (resumen rápido)
- Qué instalar en la Raspberry:
  - Samba: paquete `samba` (+ `smbpasswd`) para compartir vía SMB/CIFS (recomendado si hay clientes Windows).
  - NFS: paquete `nfs-kernel-server` para exportar via NFS (recomendado para clientes Linux).
  - Firewall: configurar UFW para permitir solo la LAN; crear reglas específicas para Samba/NFS.
  - Permisos: propietario `admin:docker` y permisos `750` para configuraciones/ logs según la política del proyecto.
- Implicaciones para clientes:
  - Windows: usar SMB/CIFS (Samba). NFS en Windows requiere componentes adicionales y suele ser menos cómodo.
  - Linux: NFS ofrece mejor compatibilidad POSIX, rendimiento y manejo de permisos/UID/GID; CIFS funciona bien pero puede complicar permisos y atributos extendidos.
  - WSL2: puede usar la unidad mapeada por Windows (recomendado) o montar CIFS desde la distribución Linux.
- ¿Necesito ambos (Samba + NFS)?
  - Si tu red es homogénea (solo Linux): basta con NFS — ganarás simplicidad y mejor manejo POSIX.
  - Si tu red es homogénea (solo Windows): basta con Samba/CIFS.
  - Si tienes ambos (Windows + Linux): ofrecer ambos servicios es práctico — Windows usa Samba y Linux usa NFS para mejor rendimiento y permisos.
  - Qué pierdes/ganas:
    - Usar solo Samba en Linux: mayor compatibilidad con Windows pero posible pérdida de comportamiento POSIX (permisos/propietarios, symlinks, locking finos).
    - Usar solo NFS con Windows: mayor fricción y necesidad de configuración extra en Windows; puede ser inestable para ciertas aplicaciones Windows.
    - Mantener ambos: mayor superficie de mantenimiento y potenciales problemas de coherencia si ambos exponen la misma ruta sin cuidados (asegurar permisos y ownership coherente).
- Recomendación práctica:
  - Entorno mixto: habilitar ambos servicios en la Pi y documentar cuál usa cada cliente.
  - Entorno Linux-only: NFS.
  - Entorno Windows-only o con usuarios Windows principales: Samba.

> DECISIÓN: En este proyecto, dado que se usan ambos tipos de clientes, se instalarán y configurarán ambos servicios en la Raspberry Pi.

---

## 1) Opciones en la Raspberry Pi (ejemplos mínimos)

### Samba (smb.conf) — ejemplo mínimo para exponer /mnt/usb-data:

```ini
# Ejemplo mínimo en /etc/samba/smb.conf (añadir sección)
[usb-data]
   path = /mnt/usb-data
   valid users = share
   read only = no
   browsable = yes
   create mask = 0640
   directory mask = 0750
```

Tras el cambio

```bash
sudo systemctl restart smbd nmbd
```

#### Opciones comunes de Samba (referencia rápida)

Opción | Valores típicos | Descripción breve | Ejemplo
--- | ---: | --- | ---
valid users | usuario1, @grupo | Lista de usuarios/grupos permitidos | valid users = pi,@sambashare
read only | yes / no | Controla si la compartición es de solo lectura | read only = no
guest ok | yes / no | Permite acceso anónimo (no recomendado) | guest ok = no
force user | nombre | Fuerza todas las operaciones como usuario dado | force user = admin
force group | nombre | Fuerza grupo para nuevos archivos/dirs | force group = docker
create mask | octal | Máscara de permisos para archivos nuevos | create mask = 0640
directory mask | octal | Máscara de permisos para directorios nuevos | directory mask = 0750
vfs objects | lista | Plugins VFS (recycle, shadow_copy2, etc.) | vfs objects = recycle
max protocol | NT1 / SMB2 / SMB3 | Forzar versión máxima de SMB | max protocol = SMB3
server signing | auto / mandatory / disabled | Firma de paquetes SMB (seguridad) | server signing = auto
map acl inherit | yes / no | Mapear herencia ACL de POSIX a SMB | map acl inherit = yes

### NFS (exports) — ejemplo mínimo en /etc/exports:

```
/mnt/usb-data 192.168.1.0/24(rw,sync,no_subtree_check,root_squash)
```

- Seguridad y permisos en la Pi:

```bash
sudo chown -R admin:docker /mnt/usb-data
sudo chmod 750 /mnt/usb-data
# Asegurar que certificados privados (si hay) sean root:root 750
```

---

## 2) Samba/CIFS — recomendado para Windows

- Montaje temporal en Linux:

```bash
sudo apt update
sudo apt install cifs-utils    # si no está instalado
sudo mkdir -p /mnt/usb-data
sudo mount -t cifs //192.168.1.101/usb-data /mnt/usb-data \
  -o credentials=/root/.smbcredentials,uid=1000,gid=1000,vers=3.0,dir_mode=0750,file_mode=0640
```

- Archivo de credenciales seguro (`/root/.smbcredentials`):

```
username=pi
password=TU_PASSWORD
# chmod 600 /root/.smbcredentials
```

- Entrada de ejemplo en `/etc/fstab` (CIFS, montaje persistente):

```text
//192.168.1.101/usb-data  /mnt/usb-data  cifs  credentials=/root/.smbcredentials,uid=1000,gid=1000,vers=3.0,dir_mode=0750,file_mode=0640,_netdev  0  0
```

- En Windows: mapear unidad de red
  - Explorador -> "Conectar a unidad de red" -> \\192.168.1.101\usb-data
  - O desde CMD/PowerShell:
    net use Z: \\192.168.1.101\usb-data /user:share TU_PASSWORD

### Mapear en Windows 10 (si no ves "Conectar a unidad de red")
- Pasos GUI (recomendado):
  1. Abrir Explorador de archivos y seleccionar "Este equipo" / "This PC" en la columna izquierda.  
  2. En la cinta superior (pestaña "Equipo"/"Computer") hacer clic en "Conectar a unidad de red" / "Map network drive".  
  3. Elegir letra (ej. Z:) y en Carpeta poner \\192.168.1.101\usb-data. Marcar "Conectar con credenciales diferentes" si hace falta. Finalizar.

- Alternativas rápidas:
  - En la barra de direcciones del Explorador escribir: \\192.168.1.101\usb-data y pulsar Enter.
  - Desde PowerShell/CMD (persistente):
    net use Z: \\192.168.1.101\usb-data /user:share TU_PASSWORD /persistent:yes

- Causas comunes por las que no ves la opción y soluciones:
  - No estás en "This PC": la opción solo aparece al seleccionar "Este equipo" / "This PC". Abre esa vista y vuelve a mirar la cinta.
  - Network Discovery desactivado: en Panel de control > Centro de redes y recursos compartidos > Cambiar configuración de uso compartido avanzado → Activar descubrimiento de red y uso compartido de archivos.
  - Problema de protocolo SMB: Windows usa SMB2/SMB3 por defecto; asegúrate en la Raspberry Pi que Samba permita SMB2/3 (ej. en smb.conf: max protocol = SMB3). No habilites SMB1 salvo que sea imprescindible.
  - Firewall en la Pi: verificar que UFW permite Samba para la LAN (sudo ufw allow from 192.168.1.0/24 to any app Samba).
  - Permisos/credenciales incorrectos: usar "Conectar con credenciales diferentes" o el comando net use con el usuario correcto.

- En WSL2: si Windows ya mapeó la unidad Z: se accede desde WSL en /mnt/z; o montar directamente desde WSL usando el mismo comando `mount -t cifs` que en Linux.

---

## 3) NFS — recomendado para clientes Linux

- Montaje temporal en Linux (cliente):

```bash
sudo apt install nfs-common
sudo mkdir -p /mnt/usb-data
sudo mount -t nfs 192.168.1.101:/mnt/usb-data /mnt/usb-data
```

- Entrada de ejemplo en `/etc/fstab` (NFS, persistente):

```text
192.168.1.101:/mnt/usb-data  /mnt/usb-data  nfs  defaults,_netdev  0  0
```

- Notas: NFS no es nativamente soportado por Windows sin componentes adicionales; para compartir con Windows use Samba/CIFS.

---

## 4) Firewall y Fail2Ban (seguridad)

- Permitir Samba en UFW (red local solo):

```bash
sudo ufw allow from 192.168.1.0/24 to any app Samba
```

- Permitir NFS en UFW (si usa NFS):

```bash
sudo ufw allow from 192.168.1.0/24 to any port nfs
```

- No exponer Samba/NFS directamente a Internet. Usar VPN si se necesita acceso remoto. Considere Fail2Ban para proteger servicios expuestos.

---

## 5) Buenas prácticas y permisos (alineado con políticas del proyecto)
- Use cuentas dedicadas y contraseñas seguras para Samba; guarde credenciales en archivos con permisos 600.  
- En la Raspberry Pi, mantenga la propiedad de configuraciones y logs en `admin:docker` y permisos en 750 cuando el dato vaya a ser usado por contenedores según la política del proyecto.  
- Use `_netdev` en fstab para evitar bloqueos en arranques de red.  
- Testear con `mount -a` y verificar antes de reiniciar.

---

## ¿Qué usuario debo usar?

- Opciones habituales:
  - Reusar usuario existente (ej. pi o admin): sencillo, menos usuarios que gestionar.
  - Crear un usuario dedicado para la compartición (recomendado): p. ej. "share" o "usbshare".

- Recomendación del proyecto:
  - Para configuraciones y logs usados por contenedores use owner admin:docker con permisos 750.
  - Para acceso de usuarios al recurso de red cree un usuario dedicado (ej. share) y sincronice UID/GID si se usa NFS.

- Comandos de ejemplo (crear usuario "share", asignar ownership y activar en Samba):

```bash
# crear usuario en la Pi (interactivo)
sudo adduser share
# o crear sin home:
# sudo adduser --system --group --no-create-home share

# dar ownership del recurso
sudo chown -R share:docker /mnt/usb-data
sudo chmod 750 /mnt/usb-data

# activar usuario en Samba (asignar contraseña SMB)
sudo smbpasswd -a share
# comprobar UID/GID
id share   # anotar UID/GID para clientes NFS
```

- Nota NFS: NFS respeta UID/GID — para que los permisos funcionen correctamente cree el mismo UID/GID en los clientes Linux o use el usuario admin:docker de forma coherente entre servidores y clientes.

---

Si quieres, agrego ejemplos listos para copiar (entradas completas para `/etc/fstab`, `/etc/samba/smb.conf` y `/etc/exports`) o lo incluyo en el `_index.md` de `infraestructura`.
