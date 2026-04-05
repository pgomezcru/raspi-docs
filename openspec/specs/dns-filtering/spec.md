## Requirements

### Requirement: Servidor DNS en la IP de la Raspberry Pi
AdGuard Home debe resolver peticiones DNS en el puerto 53 de la IP estática de la Pi.

#### Scenario: AdGuard escuchando en 192.168.1.101:53
- **WHEN** un cliente de la LAN usa `192.168.1.101` como servidor DNS
- **THEN** AdGuard responde a las peticiones DNS en TCP y UDP puerto 53

---

### Requirement: Filtrado de publicidad y rastreadores
AdGuard debe bloquear dominios de publicidad y rastreo usando listas de bloqueo.

#### Scenario: Dominio en lista de bloqueo
- **WHEN** un cliente resuelve un dominio presente en las listas configuradas de AdGuard
- **THEN** AdGuard devuelve NXDOMAIN o 0.0.0.0 en lugar de la IP real

---

### Requirement: Resolución de dominios locales
AdGuard debe resolver los dominios `*.home.lab` a la IP de la Raspberry Pi.

#### Scenario: Resolución de subdominio local
- **WHEN** un cliente resuelve `<servicio>.home.lab`
- **THEN** AdGuard devuelve `192.168.1.101`

---

### Requirement: Panel de administración web
AdGuard debe ofrecer una interfaz web de administración accesible en la LAN.

#### Scenario: Acceso al panel de administración
- **WHEN** un usuario accede a `http://192.168.1.101:3000` o `http://192.168.1.101:8080`
- **THEN** se muestra el panel de administración de AdGuard Home

---

### Requirement: Persistencia de configuración y datos de trabajo
La configuración y los datos de trabajo de AdGuard deben persistir entre reinicios.

#### Scenario: Volúmenes nombrados configurados
- **WHEN** el contenedor adguard-home se reinicia
- **THEN** la configuración y estadísticas DNS se conservan en los volúmenes `adguard-conf` y `adguard-work`
