## 1. Configurar provisioning de dashboards

- [ ] 1.1 Crear fichero `compose/grafana/provisioning/dashboards/dashboard.yml`:
  ```yaml
  apiVersion: 1
  providers:
    - name: homelab
      folder: Homelab
      type: file
      options:
        path: /etc/grafana/provisioning/dashboards
  ```
- [ ] 1.2 Verificar que el bind mount de provisioning en `compose/grafana/docker-compose.yml` cubre el directorio de dashboards

## 2. Dashboard: Estado del sistema (node-exporter)

- [ ] 2.1 Obtener dashboard "Node Exporter Full" de Grafana Labs (ID: 1860) como JSON base
- [ ] 2.2 Adaptar para el homelab: eliminar paneles irrelevantes, mantener CPU, RAM, disco, red, uptime
- [ ] 2.3 Guardar en `compose/grafana/provisioning/dashboards/sistema.json`

## 3. Dashboard: Contenedores Docker (cadvisor)

- [ ] 3.1 Obtener dashboard de cadvisor de Grafana Labs como JSON base
- [ ] 3.2 Adaptar: mostrar CPU/RAM por contenedor, estado running/stopped
- [ ] 3.3 Guardar en `compose/grafana/provisioning/dashboards/contenedores.json`

## 4. Dashboard: Salud de almacenamiento (smartctl)

- [ ] 4.1 Crear dashboard manual con métricas de smartctl-exporter: temperatura, horas encendido, sectores realocados, estado SMART general
- [ ] 4.2 Guardar en `compose/grafana/provisioning/dashboards/almacenamiento.json`

## 5. Desplegar y verificar

- [ ] 5.1 Redesplegar Grafana: `bash ~/raspi-docs/compose/deploy.sh grafana`
- [ ] 5.2 Verificar en Grafana UI: carpeta "Homelab" debe contener los 3 dashboards
- [ ] 5.3 Comprobar que los paneles muestran datos (no "No data")

## 6. Documentar

- [ ] 6.1 Actualizar `monitoring/grafana.md`: sección "Dashboards" con la lista de dashboards provisionados y cómo añadir nuevos
- [ ] 6.2 Documentar el proceso de editar dashboards: editar en UI → exportar JSON → guardar en repo → redesplegar
