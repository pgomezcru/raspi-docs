## ADDED Requirements

### Requirement: Terminación TLS en nginx para *.home.lab
Nginx debe servir todos los vhosts de `*.home.lab` sobre HTTPS con un certificado válido.

#### Scenario: Acceso HTTPS a un servicio
- **WHEN** un cliente de la LAN accede a `https://<servicio>.home.lab`
- **THEN** nginx establece la conexión TLS con el certificado wildcard y sirve el contenido sin avisos del navegador

#### Scenario: Certificado confiado por los clientes LAN
- **WHEN** la CA local está instalada en el cliente
- **THEN** el navegador muestra el candado verde sin advertencias de seguridad para cualquier subdominio `*.home.lab`

---

### Requirement: Redirección automática HTTP → HTTPS
Las peticiones HTTP deben redirigirse automáticamente a HTTPS.

#### Scenario: Acceso por HTTP
- **WHEN** un cliente accede a `http://<servicio>.home.lab`
- **THEN** nginx responde con redirección 301 a `https://<servicio>.home.lab`

---

### Requirement: Certificado wildcard para todos los servicios
Un único certificado debe cubrir todos los subdominios actuales y futuros de `*.home.lab`.

#### Scenario: Nuevo servicio añadido
- **WHEN** se añade un nuevo vhost `nuevo.home.lab` en nginx
- **THEN** el certificado wildcard existente es válido para ese subdominio sin necesidad de generar uno nuevo
