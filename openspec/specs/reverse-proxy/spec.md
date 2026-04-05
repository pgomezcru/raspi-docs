## Requirements

### Requirement: Punto de entrada HTTP centralizado
Nginx debe actuar como único punto de entrada para todo el tráfico HTTP dirigido a servicios internos.

#### Scenario: Nginx en ejecución como proxy inverso
- **WHEN** un cliente realiza una petición HTTP al puerto 80 de `192.168.1.101`
- **THEN** nginx enruta la petición al contenedor correcto según el `server_name` configurado

---

### Requirement: Enrutamiento por nombre de host
Cada servicio debe ser accesible mediante un subdominio de `home.lab`.

#### Scenario: Vhost configurado para un servicio
- **WHEN** se realiza una petición a `<servicio>.home.lab`
- **THEN** nginx hace proxy al contenedor correspondiente en su puerto interno

---

### Requirement: Red proxy_net compartida
Todos los servicios expuestos vía nginx deben estar conectados a la red externa `proxy_net`.

#### Scenario: Servicio conectado a proxy_net
- **WHEN** un servicio está definido con `networks: [proxy_net]` en su compose
- **THEN** nginx puede resolver su `container_name` como hostname dentro de `proxy_net`

---

### Requirement: Configuración externalizada en bind mount
Las configuraciones de vhost deben persistir fuera del contenedor nginx.

#### Scenario: Configuración en /mnt/usb-data/nginx/
- **WHEN** nginx arranca con bind mount en `/mnt/usb-data/nginx/conf.d:/etc/nginx/conf.d:ro`
- **THEN** los cambios en vhosts se aplican recargando nginx sin recrear el contenedor

---

### Requirement: Arranque automático
Nginx debe arrancar automáticamente tras un reinicio del sistema.

#### Scenario: restart policy configurada
- **WHEN** el host reinicia o Docker se reinicia
- **THEN** el contenedor nginx arranca automáticamente con `restart: unless-stopped`
