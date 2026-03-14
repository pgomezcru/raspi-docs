[🏠 Inicio](../README.md) > [📂 Infraestructura](_index.md)

# Grafana - Visualización de Métricas

Grafana es la plataforma de visualización que consulta datos de Prometheus y los muestra en dashboards personalizables ([ADR-0005](../docs/adr/adr-0005-stack-monitoreo-prometheus-grafana.md)).

## ¿Por qué Grafana Separado?

Grafana se despliega en su propio `docker-compose.yml` por:
- **Múltiples Datasources**: Grafana puede conectarse a Prometheus, bases de datos (PostgreSQL, MySQL), InfluxDB, Elasticsearch, APIs custom, etc.
- **Independencia**: Si reinicias Prometheus, Grafana sigue funcionando (y viceversa).
- **Escalabilidad**: Puedes tener múltiples instancias de Prometheus (ej. una por servicio) y Grafana las agrega.

## Implementación (Docker Compose)

Crea `~/docker/grafana/docker-compose.yml`:

```yaml
version: "3.8"

services:
  grafana:
    image: grafana/grafana-oss:latest
    container_name: grafana
    restart: unless-stopped
    user: "472"  # Usuario grafana (evita problemas de permisos)
    environment:
      - GF_SECURITY_ADMIN_USER=admin
      - GF_SECURITY_ADMIN_PASSWORD=changeme  # ¡CAMBIAR ESTO!
      - GF_INSTALL_PLUGINS=  # Dejar vacío o añadir plugins separados por coma
    volumes:
      - grafana-data:/var/lib/grafana
      - ./provisioning:/etc/grafana/provisioning
    ports:
      - "3001:3000"
    networks:
      - monitoring  # Red interna para comunicarse con Prometheus
      - proxy_net   # Red externa para acceso vía Nginx reverse proxy

volumes:
  grafana-data:
    name: grafana-data

networks:
  monitoring:
    external: true  # Conecta a la red creada por el stack de Prometheus
  proxy_net:
    external: true  # Red compartida con Nginx (debe existir previamente)
```

> **Importante**: Las redes `monitoring` y `proxy_net` deben existir previamente:
> ```bash
> docker network create monitoring  # Si no existe (creada por Prometheus)
> docker network create proxy_net   # Red compartida con Nginx
> ```

## Despliegue

```bash
cd ~/docker/grafana
mkdir -p provisioning/datasources provisioning/dashboards
docker-compose up -d
```

## Configuración Inicial

### 1. Acceso
Abre `http://<IP-RASPBERRY>:3001`
- **Usuario**: `admin`
- **Contraseña**: `changeme` (la que definiste)

### 2. Añadir Datasource

#### Opción A: Manual (Primera Vez)
1. Ir a **Configuration > Data Sources > Add data source**
2. Seleccionar **Prometheus**
3. URL: `http://prometheus:9090`
4. Guardar y testear

#### Opción B: Provisionamiento Automático (Recomendado)
Crea `~/docker/grafana/provisioning/datasources/prometheus.yml`:

```yaml
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
    editable: true
```

### Otros Datasources (Ejemplos)

Grafana puede conectarse a múltiples fuentes de datos simultáneamente.

#### PostgreSQL (ej. para Gitea/Jenkins)
```yaml
  - name: PostgreSQL
    type: postgres
    url: postgres-host:5432
    database: gitea
    user: grafana_reader
    secureJsonData:
      password: 'secret'
```

#### InfluxDB (si migras desde otro sistema)
```yaml
  - name: InfluxDB
    type: influxdb
    url: http://influxdb:8086
    database: metrics
```

#### MySQL (para logs o métricas custom)
```yaml
  - name: MySQL
    type: mysql
    url: mysql-host:3306
    database: logs
    user: grafana
```

### 3. Importar Dashboards

Grafana Labs ofrece miles de dashboards preconstruidos. Los más útiles para Raspberry Pi:

#### Dashboard: Node Exporter Full
- **ID**: 1860
- **Descripción**: CPU, RAM, disco, red, temperatura.
- **Importar**: Dashboard > Import > 1860 > Select "Prometheus" datasource

#### Dashboard: Docker Container & Host Metrics
- **ID**: 179
- **Descripción**: Métricas de contenedores (via cAdvisor).
- **Importar**: Dashboard > Import > 179

#### Dashboard: S.M.A.R.T. Disk Health
No hay un dashboard oficial completo. Crear uno personalizado con paneles para:
- `smartctl_device_smart_healthy`
- `smartctl_device_temperature`

## Dashboards Personalizados

### Ejemplo: Panel de Temperatura
1. Crear nuevo dashboard
2. Añadir panel tipo "Gauge"
3. Query PromQL:
   ```promql
   node_hwmon_temp_celsius{chip="cpu_thermal"}
   ```
4. Configurar umbrales:
   - Verde: < 60°C
   - Amarillo: 60-75°C
   - Rojo: > 75°C

### Ejemplo: Uso de Disco
```promql
100 - ((node_filesystem_avail_bytes{mountpoint="/"} * 100) / node_filesystem_size_bytes{mountpoint="/"})
```

## Alertas en Grafana

Grafana puede enviar alertas (email, Telegram, Discord) basadas en queries de Prometheus.

### Configurar Canal de Notificación
1. **Alerting > Contact Points > New contact point**
2. Configurar email/webhook
3. Crear "Alert Rule" en cualquier panel
4. Ejemplo: Alertar si CPU > 90% durante 5 minutos

## Provisionamiento de Dashboards

Para versionar tus dashboards en código:

`~/docker/grafana/provisioning/dashboards/default.yml`:

```yaml
apiVersion: 1

providers:
  - name: 'Default'
    orgId: 1
    folder: ''
    type: file
    disableDeletion: false
    updateIntervalSeconds: 10
    allowUiUpdates: true
    options:
      path: /etc/grafana/provisioning/dashboards
```

Guardar los JSON de tus dashboards en ese directorio.

## Integración con Reverse Proxy (Nginx)

Para exponer Grafana a través de un dominio (ej. `grafana.local` o `grafana.tudominio.com`), configurar Nginx como proxy inverso.

### Configuración de Nginx

Archivo `/etc/nginx/sites-available/grafana`:

```nginx
server {
    listen 80;
    server_name grafana.home.lab;  # O tu dominio

    location / {
        proxy_pass http://grafana:3001;  # Usa el nombre del contenedor en proxy_net
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # WebSocket support para live updates
    location /api/live/ {
        proxy_pass http://grafana:3001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "Upgrade";
        proxy_set_header Host $host;
    }
}
```

> **Nota**: Si Nginx está en un contenedor Docker, debe estar en la red `proxy_net`. Si Nginx está instalado directamente en el host, usa `http://localhost:3001` en lugar de `http://grafana:3001`.

Habilitar:
```bash
sudo ln -s /etc/nginx/sites-available/grafana /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

### Actualizar Configuración de Grafana

Si usas un subpath (ej. `http://tudominio.com/grafana`), añade al `docker-compose.yml`:

```yaml
    environment:
      - GF_SERVER_ROOT_URL=http://tudominio.com/grafana
      - GF_SERVER_SERVE_FROM_SUB_PATH=true
```

## Integración con Homarr

[Homarr](https://homarr.dev/) es un dashboard unificado para servicios self-hosted. Grafana puede integrarse de dos formas:

### Opción 1: Enlace Simple (Widget)

En Homarr, añadir un **App** con:
- **Nombre**: Grafana
- **URL**: `http://192.168.1.10:3001` (o tu dominio)
- **Icono**: Seleccionar "Grafana" de la lista

Homarr mostrará un tile clickeable que abre Grafana en nueva pestaña.

### Opción 2: Iframe Embebido

Para mostrar un dashboard de Grafana **dentro** de Homarr:

1. En Grafana, ir al dashboard deseado
2. Click en **Share** > **Embed**
3. Copiar la URL de iframe (ej. `http://grafana.local/d/abc123/dashboard?orgId=1&kiosk`)
4. En Homarr, añadir un **iframe widget** con esa URL

> **Nota**: Requiere configurar `GF_SECURITY_ALLOW_EMBEDDING=true` en Grafana (riesgo de seguridad, solo en red local).

### Opción 3: Integración API (Avanzado)

Homarr puede consultar la API de Grafana para mostrar:
- Estado de alertas activas
- Número de dashboards

Requiere crear un **API Token** en Grafana:
1. Grafana > Configuration > API Keys > New API Key (rol: Viewer)
2. En Homarr, configurar la integración con el token

## Seguridad

- **Cambiar contraseña por defecto** inmediatamente.
- **No exponer puerto 3001 a internet** sin VPN o Reverse Proxy con autenticación adicional.
- **Configurar SSL/TLS** en producción (vía proxy inverso con Let's Encrypt).
- **Restringir embedding**: Solo habilitar `GF_SECURITY_ALLOW_EMBEDDING` si usas iframe en red local confiable.

## Backup

El volumen `grafana-data` contiene:
- Configuración de dashboards
- Usuarios y permisos
- Configuración de alertas

**Backup**:
```bash
docker run --rm -v grafana-data:/data -v $(pwd):/backup alpine tar czf /backup/grafana-backup.tar.gz -C /data .
```

**Restore**:
```bash
docker run --rm -v grafana-data:/data -v $(pwd):/backup alpine sh -c "cd /data && tar xzf /backup/grafana-backup.tar.gz"
```
