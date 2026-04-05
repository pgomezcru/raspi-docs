## Requirements

### Requirement: Servidor Git self-hosted
Gitea debe ofrecer un servidor Git accesible en la LAN para alojar repositorios.

#### Scenario: Gitea en ejecución con PostgreSQL
- **WHEN** los contenedores `gitea` y `gitea-db` están en ejecución
- **THEN** es posible hacer `git clone`, `git push` y `git pull` a repos en Gitea

---

### Requirement: Interfaz web accesible vía proxy inverso
Gitea debe ser accesible mediante un nombre de dominio gestionado por nginx.

#### Scenario: Vhost de Gitea configurado en nginx
- **WHEN** un usuario navega a `http://gitea.home.lab`
- **THEN** nginx enruta la petición al contenedor `gitea` en el puerto 3000

---

### Requirement: Persistencia de datos en SSD
Los datos de Gitea (repositorios, configuración) deben persistir en bind mounts en el SSD.

#### Scenario: Bind mounts en /mnt/usb-data/gitea/
- **WHEN** el contenedor gitea se recrea o actualiza
- **THEN** los repositorios y configuración persisten en `/mnt/usb-data/docker-root/gitea/`

---

### Requirement: Base de datos PostgreSQL dedicada
Gitea debe usar PostgreSQL como backend de base de datos para metadata de repositorios, usuarios e issues.

#### Scenario: gitea-db como servicio dependiente
- **WHEN** el contenedor gitea arranca
- **THEN** se conecta al contenedor `gitea-db` (PostgreSQL) para toda la metadata

---

### Requirement: Arranque automático de ambos contenedores
Gitea y su base de datos deben arrancar automáticamente tras reinicios.

#### Scenario: restart policy en ambos contenedores
- **WHEN** el host o Docker se reinicia
- **THEN** `gitea-db` arranca primero y `gitea` arranca a continuación con `restart: unless-stopped`
