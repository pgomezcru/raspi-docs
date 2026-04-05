## 1. Redesplegar cadvisor con versión pinneada

- [ ] 1.1 En la Pi como `admin`: `cd ~/raspi-docs && git pull`
- [ ] 1.2 Ejecutar: `bash ~/raspi-docs/compose/deploy.sh prometheus`
  - Esto copia el compose actualizado y ejecuta `docker compose up -d`
  - Docker detecta el cambio de imagen en cadvisor y recrea solo ese contenedor

## 2. Verificar

- [ ] 2.1 Verificar la imagen del contenedor: `docker inspect cadvisor --format '{{.Config.Image}}'`
  - Resultado esperado: `gcr.io/cadvisor/cadvisor:v0.55.1`
- [ ] 2.2 Verificar que cadvisor está activo: `docker ps | grep cadvisor`
- [ ] 2.3 Verificar métricas en Prometheus: consultar `up{job="cadvisor"}` → debe ser 1

## 3. Documentar

- [ ] 3.1 Actualizar `estado.md`: marcar divergencia #5 (cadvisor :latest) como resuelta
- [ ] 3.2 Actualizar `monitoring/prometheus.md`: corregir la versión documentada de cadvisor a `v0.55.1`
