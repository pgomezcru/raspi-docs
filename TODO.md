---

kanban-plugin: board

---

## Varios

- [ ] Revisar los [puertos](infraestructura/ports.md) #Configuración
- [ ] Listado de hardware #Configuración 
	- [ ] Deberíamos tener una lista de hardware disponible, usado y no usado
	- [ ] Agents.md debe conoceerla.
- [ ] macvlan: publicara los contenedores con ip - investigar #Configuración


## Configuración del sistema

- [ ] Puedo checkear si el **NAS** está online? puedo encenderlo desde la rpi? #Configuración
- [ ] Evitar que **docker** escriba en el disco sin disco: #Configuración
	    - sudo systemctl edit docker
	        [Unit]
	        RequiresMountsFor=/mnt/usb-data
	    - sudo systemctl daemon-reexec
	    - sudo systemctl daemon-reload
	    - systemctl show docker | grep RequiresMountsFor
	    - Investigar
- [ ] Automontaje del **NAS**: investigar #Configuración
	    en fstab:
	    192.168.1.102:/volume1/Pablo /mnt/nas/pablo nfs noauto,x-systemd.automount,_netdev,rsize=8192,wsize=8192,timeo=14,intr 0 0
	        noauto
	            → no intenta montar en el arranque (evita bloqueos)
	        x-systemd.automount
	            → systemd crea un automount unit
	            → se monta solo la primera vez que accedes al directorio
	        _netdev
	            → le dice al sistema que es red (orden correcto de arranque)
- [ ] **Bitwarden**: Instalar clientes de escritorio (Windows/Linux).  #Configuración
- [ ] **Bitwarden**: Instalar extensiones de navegador. #Configuración
- [ ] **Bitwarden**: Configurar app móvil en Android. #Configuración
- [ ] **Bitwarden**: *(Futuro)* Evaluar despliegue de Vaultwarden (Self-hosted). #Configuración


## Homepage

- [ ] Añadir iconos a [[homarr]] #Homepage


## Monitorización

- [~] **SMART** #Monitorización
- [~] Mostrar secciones en **homarr** #Monitorización
- [ ] Configurar **dashboards en Grafana** #Monitorización
- [ ] Borrar datos con el label node-exporter:9100 [más info](monitoring/prometheus.md#borrado-de-datos-antiguos) #Monitorización
- [ ] Que me haga "ejercicios" de grafana porque no me entero #Monitorización
- [ ] Los dashboards que creo en grafana no se guardan como json? #Monitorización
- [ ] otros exportes #Monitorización
- [ ] Estudio métricas #Monitorización
- [ ] Recogida de logs #Monitorización
	- [ ] Loki: sistema de agregación/almacenamiento y consulta de logs (API HTTP, puerto típ. 3100). Usa LogQL para consultas; es standalone, no un componente de Prometheus.
	- [ ] Promtail: agente/shipper que hace tail/parse de archivos de log (p. ej. /var/lib/docker/containers/*/*.log) y los envía a Loki. Es un recolector de logs, no un "exporter" de Prometheus.
	- [ ] Alternativas/variantes: Grafana Agent puede reemplazar a Promtail y además enviar métricas (y logs) a los backends; también están Fluent Bit, Vector, Fluentd como collectors.
- [ ] Sacar info de samba  #Monitorización
	- log file = /var/log/samba/log.%m
- [ ] Sacar info de nginx #Monitorización
- [ ] Sacar info de ufw #Monitorización


## CI/CD

- [ ] [Gitea](programacion/gitea.md):**Sincronización**: Configurar Mirroring (Espejo) con repositorios de GitHub. #CICD
- [ ] [Gitea](programacion/gitea.md):Crear Token de Acceso Personal (PAT) en GitHub para el mirroring. #CICD
- [ ] [Jenkins](programacion/jenkins.md):Desplegar contenedor Docker (`jenkins/jenkins:lts-jdk17`). #CICD
- [ ] [Jenkins](programacion/jenkins.md):Configurar volumen `jenkins_home`. #CICD
- [ ] [Jenkins](programacion/jenkins.md):Configurar acceso al socket Docker del host (`/var/run/docker.sock`). #CICD
- [ ] [Jenkins](programacion/jenkins.md):Instalar plugin de integración con Gitea. #CICD
- [ ] [VS Code Server](programacion/vscode-server.md):Desplegar contenedor Docker (`linuxserver/code-server`). #CICD
- [ ] [VS Code Server](programacion/vscode-server.md):Establecer contraseña segura en variables de entorno. #CICD
- [ ] [VS Code Server](programacion/vscode-server.md):Mapear volumen de proyectos locales para persistencia. #CICD


## Multimedia

- [ ] Investigar servidores multimedia #Multimedia 
	- [ ] Los puede mover la raspberry?
- [ ] Gestión de AceStream (streaming directo p2p): puedo ver la tele inglesa? #Multimedia


## Descargas

- [ ] Torrent


## IA



## Doing

- [ ] **Backups** #Configuración
	    - Backup puntual
	        sudo rsync -az --delete --numeric-ids --xattrs -acls /mnt/usb-data/ /mnt/nas/pi/docker-backups/<aaaa-mm-dd>/
	    - Backup nocturno al NAS de:
	        - docker volumes
	        - configuración rpi


## Done

- [x] Configurar todos los enlaces de homarr #Homepage
- [X] **Grafana/Prometheus**: Montar manuales #Monitorización
- [X] **Grafana/Prometheus**: Desplegar contenedores #Monitorización
- [X] **Prometheus**: Configurar exporters #Monitorización
- [X] ~~**Glances**: Crear `docker-compose.yml` con `pid: host`.~~ *(deprecado, sustituido por Prometheus+Grafana — ADR-0005)* #Monitorización
- [X] ~~**Glances**: Desplegar contenedor y verificar acceso web (Puerto 61208).~~ *(deprecado, sustituido por Prometheus+Grafana — ADR-0005)* #Monitorización
- [X] Decidir el servicio que se utilizará como homepage. #Homepage
- [X] Montar manual de Homarr #Homepage
- [X] Montar Homarr vía Docker Compose #Homepage
- [X] Aprender a manejar Homarr #Homepage
- [X] **[Firewall](infraestructura/configuracion-inicial.md#4-firewall-básico-ufw)**: Configurar UFW (Permitir SSH, habilitar servicio). #Configuración
- [X] **[Seguridad](infraestructura/configuracion-inicial.md#5-protección-contra-fuerza-bruta-fail2ban)**: Instalar y configurar Fail2Ban para protección contra fuerza bruta. #Configuración
- [X] **[Red](infraestructura/arquitectura-red.md)**: Asignar IPs estáticas en el router para la Raspberry Pi y el NAS. #Configuración
	    - [X] IP Fija Raspberry Pi
	    - [X] IP Fija NAS
- [X] **[Almacenamiento](infraestructura/estrategia-almacenamiento.md)**: Configurar montaje NFS del NAS en la Raspberry Pi (para multimedia/backups). #Configuración
	    - [X] Preparar disco USB
	        - [X] Vaciar
	        - [X] Formatear a ext4
	        - [X] Montar automáticamente en el arranque (`/etc/fstab`)
	    - [X] Montar volúmenes NFS del NAS
	    - [X] Mover Docker Root al USB
- [X] **[Proxy Inverso](nginx.md)**: Desplegar Nginx en Docker y configurar red `proxy_net` para futuros servicios. #Configuración
	    - [X] Preparar el sistema
	    - [X] montar docker-compose.yml
	    - [~] Página de no encontrado
- [X] AdGuard
- [+] [Certificados SSL](infraestructura/https-plan.md) (Let's Encrypt) => más adelante, cuando haya servicios expuestos. #Configuración
- [X] **[Nombre de dominio / Homepage](nginx.md#homepage)** #Configuración


***

## Archive

- [x] [[homarr]] está desactualizado! Actualizar a la versión 1.0 #Homepage
	- [x] el problema es que la raspberry no está usando adguard como dns. Hay una conversación "homarr" con copilot que detalla el tema. 2026-01-13 19:36
- [x] Cambar [[infraestructura/dns.md]] para que se use como dns el contenedor de adguard y no el router 2026-01-13 19:36
- [x] [Gitea](programacion/gitea.md):Configurar persistencia de datos. #CICD 2026-01-13 19:36
- [x] [Gitea](programacion/gitea.md):Desplegar contenedor Docker (`gitea/gitea:latest`). #CICD 2026-01-13 19:36
- [x] [Gitea](programacion/gitea.md):Configurar reverse proxy Nginx (`gitea.conf`). #CICD 2026-03-21
- [x] samba #Configuración
	    [X] Montar la carpeta de la raspberry en el pc
	    [x] Añadir la carpeta de la raspberry al workspace de vscode 2026-01-13 19:36

%% kanban:settings
```
{"kanban-plugin":"board","list-collapse":[false,false,false,true,true,true,true,true,false,false],"show-checkboxes":true,"move-tags":true,"tag-action":"kanban","archive-with-date":true,"append-archive-date":true,"date-picker-week-start":1}
```
%%