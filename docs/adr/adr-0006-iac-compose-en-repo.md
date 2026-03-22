[🏠 Inicio](../../README.md) > [📂 Docs](../_index.md)

# ADR-0006: IaC — docker-compose.yml en el repositorio como fuente de verdad

**Estado**: Accepted
**Fecha**: 2026-03-22

## Contexto

Los ficheros `docker-compose.yml` de cada servicio vivían únicamente en la Pi (`/mnt/usb-data/<servicio>/`), sin control de versiones ni copia de seguridad independiente. Cualquier cambio manual en la Pi podía divergir silenciosamente de la documentación, y un fallo de disco supondría perder las definiciones de todos los servicios.

El repositorio `raspi-docs` existía como documentación pura (Markdown), con ejemplos de compose embebidos en los `.md` pero sin ficheros `.yml` reales. Tras un análisis de divergencias, se detectó que algunos ejemplos en el Markdown ya no coincidían exactamente con lo desplegado.

Adicionalmente, existía el riesgo de que Gitea (el servidor Git local) fuera justamente uno de los contenedores afectados en un escenario de fallo, creando una dependencia circular con la estrategia de backup.

## Decisión

Añadir una carpeta `compose/` al repositorio con los `docker-compose.yml` reales de todos los servicios, y un script `deploy.sh` que actúa como mecanismo de sincronización de la Pi hacia el repo.

**Principios del sistema:**

1. **El repo es la fuente de verdad** — cualquier cambio se hace en el repo, no directamente en la Pi.
2. **deploy.sh solo copia, nunca arranca** — la decisión de reiniciar un contenedor es siempre manual y explícita.
3. **Backup automático** — el script guarda el fichero anterior antes de sobreescribir.
4. **Secretos fuera del repo** — los valores sensibles viven en `.env` en la Pi, nunca en Git. Los `.env.example` documentan las variables requeridas.
5. **Independiente de Gitea** — el repo tiene como remote principal Gitea, pero al estar en GitHub (o cualquier otro remote) como backup, la definición de los servicios sobrevive aunque la Pi falle.

## Alternativas consideradas

| Alternativa | Motivo de descarte |
|-------------|-------------------|
| Mantener composes solo en la Pi | Sin versionado, sin backup independiente |
| Ansible / Terraform | Sobreingeniería para un homelab unipersonal |
| Jenkins pipeline automático | Jenkins aún no desplegado; añade complejidad innecesaria en esta fase |
| Symlinks repo → Pi | Requiere que el repo esté montado en la Pi en todo momento |

## Consecuencias

**Positivas:**
- Los `docker-compose.yml` están versionados y respaldados en Git
- El historial de cambios es trazable con `git log`
- Restaurar un servicio tras un fallo de Pi es: `git clone` + crear `.env` + `deploy.sh` + `docker compose up`
- Elimina la divergencia silenciosa entre documentación y realidad

**Negativas / limitaciones:**
- El despliegue requiere dos pasos manuales: `deploy.sh` + `docker compose up -d`
- Los `.env` con secretos reales no están en el repo — deben restaurarse desde Bitwarden ante un reinstalado
- Los ficheros de configuración de servicios (nginx conf.d, prometheus.yml, etc.) no están incluidos en este sistema — solo los `docker-compose.yml`

## Evolución esperada

Cuando Jenkins esté desplegado, el paso manual `git pull → deploy.sh → docker compose up -d` puede automatizarse mediante un pipeline disparado por webhook de Gitea.
