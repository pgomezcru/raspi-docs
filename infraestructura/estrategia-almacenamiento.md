[🏠 Inicio](../README.md) > [📂 Infraestructura](_index.md)

# Estrategia de Almacenamiento: USB vs NAS

Al configurar servicios en la Raspberry Pi, una decisión crítica es dónde almacenar los datos. Tenemos dos opciones principales: un disco conectado directamente por USB o montar volúmenes de red desde el Synology NAS.

## Tabla Comparativa

| Característica | Disco USB (Directo) | NAS Mount (NFS/SMB) |
| :--- | :--- | :--- |
| **Velocidad (Latencia)** | ✅ **Baja** (USB 3.0 es rápido) | ⚠️ Media (Depende de la red) |
| **Ancho de Banda** | ✅ ~300-400 MB/s (SSD) | ⚠️ ~100 MB/s (Limitado por Gigabit Ethernet) |
| **Fiabilidad** | ⚠️ Punto único de fallo (si es 1 disco) | ✅ **Alta** (RAID en el NAS) |
| **Dependencia** | Solo energía | Red + Switch + Servidor NAS |
| **Uso de CPU (Pi)** | Bajo | Medio (Overhead de red/protocolo) |

## Guía de Decisión

### ¿Cuándo usar Disco USB (SSD Recomendado)?

Utiliza almacenamiento local USB para **cargas de trabajo intensivas en I/O** o datos que requieren baja latencia.

*   **Bases de Datos**: Los archivos de datos de [PostgreSQL](https://www.postgresql.org/docs/), [MySQL](https://dev.mysql.com/doc/), [MongoDB](https://www.mongodb.com/docs/). La latencia de red mata el rendimiento de las BBDD.
*   **Contenedores Docker**: `/var/lib/docker`. Las imágenes y capas de contenedores deben cargar rápido.
*   **Compilación/Builds**: Jenkins workspaces, carpetas `node_modules`, etc. Muchos archivos pequeños se leen/escriben mucho más rápido en local.
*   **Swap**: Si necesitas memoria virtual (aunque se recomienda evitarlo en SDs, en SSD es aceptable).

### ¿Cuándo usar Montaje NAS (NFS)?

Utiliza el NAS para **almacenamiento masivo, compartido o copias de seguridad**.

*   **Multimedia**: Películas, Series, Música ([Plex](https://support.plex.tv/articles/)/[Jellyfin](https://jellyfin.org/docs/)). El streaming secuencial funciona perfecto por red.
*   **Backups**: Destino de copias de seguridad de los contenedores (ej. dumps de BBDD).
*   **Archivos Estáticos Grandes**: ISOs, instaladores, documentos PDF, libros.
*   **Datos Compartidos**: Archivos que necesitas acceder desde tu PC y la Raspberry simultáneamente.

## Recomendación para tus Servicios

| Servicio | Tipo de Dato | Recomendación | Razón |
| :--- | :--- | :--- | :--- |
| **Gitea** | Repositorios Git | **USB (SSD)** | Git realiza muchas operaciones de archivos pequeños. Rendimiento. |
| **Gitea** | Backup Repos | **NAS** | Seguridad y redundancia. |
| **Jenkins** | Workspace / Home | **USB (SSD)** | Compilaciones intensivas en disco. |
| **VS Code** | Proyectos | **USB (SSD)** | Búsquedas de texto y git status requieren baja latencia. |
| **Bitwarden** | Base de Datos | **USB (SSD)** | Rendimiento de BBDD. |
| **Media Server** | Películas | **NAS** | Volumen de datos alto, acceso secuencial. |

## Implementación Técnica

### 1. Mover Docker Root al USB (Data Root Migration)

Siguiendo el [ADR-0004](../docs/adr/adr-0004-migracion-docker-usb.md), moveremos todos los datos de Docker al disco USB para proteger la tarjeta SD y facilitar la recuperación ante desastres.

**Paso 1: Preparar el punto de montaje**
Asegúrate de que tu disco USB está montado correctamente (ej. en `/mnt/usb-data`).

```bash
# Crear directorio para Docker en el USB
sudo mkdir -p /mnt/usb-data/docker-root
```

**Paso 2: Configurar Docker**
Editamos (o creamos) el archivo de configuración del demonio.

```bash
sudo nano /etc/docker/daemon.json
```

Añade el siguiente contenido:

```json
{
  "data-root": "/mnt/usb-data/docker-root"
}
```

**Paso 3: Aplicar cambios**

```bash
# Detener Docker
sudo systemctl stop docker

# (Opcional) Mover datos existentes si ya tenías contenedores
# sudo rsync -aP /var/lib/docker/ /mnt/usb-data/docker-root/

# Reiniciar Docker
sudo systemctl start docker
```

Este proceso hará que Docker use el disco USB para almacenar todas las imágenes, contenedores y volúmenes.

**Paso 4: Verificar**
Comprueba que Docker está usando la nueva ruta:

```bash
docker info | grep "Docker Root Dir"
# Debería salir: Docker Root Dir: /mnt/usb-data/docker-root
```

### 2. Montaje del NAS (NFS)

Para montar carpetas del NAS en la Raspberry Pi de forma eficiente, prefiere **NFS** sobre SMB (Samba) por tener menor overhead en Linux.

Ejemplo en `/etc/fstab`:
```bash
# Montaje del NAS para multimedia
192.168.1.11:/volume1/video /mnt/nas/video nfs defaults,auto,rsize=8192,wsize=8192,timeo=14,intr 0 0
```
#### Permisos de los volúmenes NFS

Al montar el NAS directamente en la Raspberry Pi observo que se puede montar pero los permisos no coinciden. Parece ser que NFS asigna permisos por el UID/GID del usuario remoto y distintas máquinas clientes pueden tener distintos UID o incluso el mismo usuario puede tener distinto UID en distintas máquinas.

La manera más sencilla, aunque menos segura, es en la carpeta compartida del NAS en el panel de control, en permisos NFS añadir como cliente la IP de la máquina que quiere conectarse por NFS y darle permisos de lectura y escritura como "root squash" (esto hace que cualquier usuario remoto se mapee al usuario "nobody" del NAS, evitando problemas de permisos). En nuestro DSM "Asignar todos los usuarios a admin". Con esto ya debería funcionar sin problemas.

## Conservación del disco USB

En cierto momento, el cabezal del disco estuvo haciendo muchísimo ruido. Tras investigar, se ejecutó

```bash
sudo hdparm -B 254 /dev/sda
```

y parece que el ruido desapareció. Esto configura el APM (Advanced Power Management) del disco para que no entre en modo ahorro de energía agresivo, lo cual puede causar ruidos y desgaste innecesario.

Habrá que tener un ojo puesto en ese disco. La información SMART asegura que, a pesar de ser un disco antiguo, está en buen estado.