[🏠 Inicio](../README.md) > [📂 Infraestructura](_index.md)

# Sistema de despliegue de Docker Compose

El repositorio actúa como **fuente de verdad** para todos los `docker-compose.yml` del homelab. Un script de despliegue copia el fichero del servicio elegido a su ubicación correcta en la Pi, con backup automático del fichero anterior.

## Arquitectura

```
raspi-docs/ (repo Git, clonado en ~/raspi-docs en la Pi)
└── compose/
    ├── deploy.sh              ← script de despliegue
    ├── manifest.yml           ← mapa servicio → ruta destino
    ├── nginx/
    │   └── docker-compose.yml
    ├── prometheus/
    │   └── docker-compose.yml
    ├── grafana/
    │   ├── docker-compose.yml
    │   └── .env.example
    ├── adguard-home/
    │   └── docker-compose.yml
    ├── gitea/
    │   ├── docker-compose.yml
    │   └── .env.example
    └── homarr/
        ├── docker-compose.yml
        └── .env.example
```

Los ficheros `.env` con secretos reales **nunca se commitean** (están en `.gitignore`). Solo existe un `.env.example` por servicio con las variables necesarias pero sin valores.

## Flujo de trabajo

```
1. Editar compose/<servicio>/docker-compose.yml en Windows
2. git push → Gitea (Pi)
3. En la Pi como admin: git pull
4. bash compose/deploy.sh <servicio>   ← copia el fichero, hace backup del anterior
5. cd /mnt/usb-data/<servicio> && docker compose up -d
```

> Los pasos 4 y 5 son manuales e independientes. `deploy.sh` nunca arranca contenedores.

## deploy.sh

```bash
bash ~/raspi-docs/compose/deploy.sh <servicio>
```

**Servicios disponibles:**

| Servicio | Destino en la Pi |
|----------|-----------------|
| `nginx` | `/mnt/usb-data/nginx/docker-compose.yml` |
| `prometheus` | `/mnt/usb-data/prometheus/docker-compose.yml` |
| `grafana` | `/mnt/usb-data/grafana/docker-compose.yml` |
| `adguard-home` | `/mnt/usb-data/adguard-home/docker-compose.yml` |
| `gitea` | `/mnt/usb-data/gitea/docker-compose.yml` |
| `homarr` | `/mnt/usb-data/homarr/docker-compose.yml` |

El script realiza tres acciones:
1. Verifica que el fichero fuente y el directorio destino existen
2. Hace backup del fichero actual: `docker-compose.yml.bak.<YYYYMMDD_HHMMSS>`
3. Copia el fichero del repo al destino

## Gestión de secretos

Los servicios con variables sensibles usan ficheros `.env` que **no están en el repo**. Deben crearse manualmente en la Pi la primera vez, junto al `docker-compose.yml`:

```bash
# Ejemplo para gitea
cp ~/raspi-docs/compose/gitea/.env.example /mnt/usb-data/gitea/.env
nano /mnt/usb-data/gitea/.env   # rellenar los valores reales
```

`docker compose up -d` carga el `.env` automáticamente si está en el mismo directorio que el `docker-compose.yml`.

Servicios con `.env`:

| Servicio | Variable(s) |
|----------|------------|
| `gitea` | `GITEA_DB_PASSWORD` |
| `grafana` | `GRAFANA_ADMIN_PASSWORD` |
| `homarr` | `HOMARR_SECRET_KEY` (64 hex chars: `openssl rand -hex 32`) |

> Guardar los valores reales en Bitwarden como referencia ante un reinstalado.

## Añadir un nuevo servicio

1. Crear `compose/<nuevo-servicio>/docker-compose.yml` en el repo
2. Añadir la entrada en `compose/manifest.yml`
3. Añadir el case en `compose/deploy.sh` (bloque `declare -A TARGET`)
4. Si tiene secretos, crear `compose/<nuevo-servicio>/.env.example`
5. Commit, push, `git pull` en la Pi

## Primer despliegue en una Pi nueva

```bash
# 1. Clonar el repo
cd ~
git clone http://gitea.home.lab/pablo/raspi-docs.git

# 2. Crear los .env con secretos reales (desde Bitwarden)
cp ~/raspi-docs/compose/gitea/.env.example   /mnt/usb-data/gitea/.env
cp ~/raspi-docs/compose/grafana/.env.example /mnt/usb-data/grafana/.env
cp ~/raspi-docs/compose/homarr/.env.example  /mnt/usb-data/homarr/.env
# ... editar cada .env con los valores reales

# 3. Desplegar cada servicio
for svc in nginx prometheus grafana adguard-home gitea homarr; do
    bash ~/raspi-docs/compose/deploy.sh $svc
    echo "--- Desplegado $svc ---"
done

# 4. Arrancar cada stack (en el orden correcto)
cd /mnt/usb-data/nginx       && docker compose up -d
cd /mnt/usb-data/adguard-home && docker compose up -d
cd /mnt/usb-data/prometheus  && docker compose up -d
cd /mnt/usb-data/grafana     && docker compose up -d
cd /mnt/usb-data/homarr      && docker compose up -d
cd /mnt/usb-data/gitea       && docker compose up -d
```

## Decisión de arquitectura

Ver [ADR-0006](../docs/adr/adr-0006-iac-compose-en-repo.md) para el razonamiento completo detrás de este sistema.
