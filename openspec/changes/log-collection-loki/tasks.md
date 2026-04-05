## 1. Preparar configuraciones de Loki y Promtail

- [ ] 1.1 Crear directorio `compose/prometheus/loki/`
- [ ] 1.2 Crear `compose/prometheus/loki/loki-config.yaml` con:
  - Modo monolítico (`target: all`)
  - Almacenamiento filesystem en `/loki`
  - Retención: `retention_period: 168h` (7 días)
  - Puerto: 3100
- [ ] 1.3 Crear directorio `compose/prometheus/promtail/`
- [ ] 1.4 Crear `compose/prometheus/promtail/promtail-config.yaml` con:
  - `clients: [{url: http://loki:3100/loki/api/v1/push}]`
  - `scrape_configs` con `docker_sd_configs` para descubrimiento automático de contenedores
  - Relabeling para añadir etiquetas `container_name`, `image`, `compose_service`

## 2. Añadir Loki y Promtail al compose

- [ ] 2.1 Editar `compose/prometheus/docker-compose.yml`: añadir servicio `loki`
  - Imagen: `grafana/loki:<version-pinneada>`
  - Bind mounts: config + `/mnt/usb-data/loki:/loki`
  - Red: `monitoring`
- [ ] 2.2 Añadir servicio `promtail` en el mismo compose:
  - Imagen: `grafana/promtail:<version-pinneada>`
  - Bind mounts: config + `/var/run/docker.sock:/var/run/docker.sock:ro` + `/var/lib/docker/containers:/var/lib/docker/containers:ro`
  - Red: `monitoring`
- [ ] 2.3 Crear directorio de datos en SSD: `sudo mkdir -p /mnt/usb-data/loki && sudo chown 10001:10001 /mnt/usb-data/loki`

## 3. Configurar datasource Loki en Grafana

- [ ] 3.1 Crear `compose/grafana/provisioning/datasources/loki.yaml`:
  ```yaml
  apiVersion: 1
  datasources:
    - name: Loki
      type: loki
      url: http://loki:3100
      isDefault: false
  ```
- [ ] 3.2 Verificar que Grafana está en la red `monitoring` (necesario para resolver `loki`)

## 4. Desplegar y verificar

- [ ] 4.1 Crear directorio de datos Loki: `sudo mkdir -p /mnt/usb-data/loki`
- [ ] 4.2 Redesplegar stacks: `bash ~/raspi-docs/compose/deploy.sh prometheus && bash ~/raspi-docs/compose/deploy.sh grafana`
- [ ] 4.3 Verificar que Loki arranca: `docker logs loki | tail -5`
- [ ] 4.4 Verificar que Promtail envía logs: `docker logs promtail | grep "Successfully sent"`
- [ ] 4.5 En Grafana → Explore → datasource Loki: ejecutar `{container_name="grafana"}` y verificar que aparecen logs

## 5. Documentar

- [ ] 5.1 Crear `monitoring/loki.md` con: arquitectura, configuración de Loki, Promtail y Grafana, consultas LogQL básicas
- [ ] 5.2 Actualizar `monitoring/grafana.md`: añadir sección sobre el datasource Loki y ejemplos de uso
- [ ] 5.3 Actualizar `monitoring/prometheus.md` o crear `monitoring/_index.md` que referencie Loki como complemento de logs
