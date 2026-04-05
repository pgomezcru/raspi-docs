## 1. Migrar Prometheus

- [ ] 1.1 Crear directorio destino en SSD: `sudo mkdir -p /mnt/usb-data/prometheus/data && sudo chown root:root /mnt/usb-data/prometheus/data`
- [ ] 1.2 Parar Prometheus: `docker stop prometheus`
- [ ] 1.3 Copiar datos del volumen nombrado al SSD:
  `docker run --rm -v prometheus-data:/source -v /mnt/usb-data/prometheus/data:/dest alpine sh -c "cp -a /source/. /dest/"`
- [ ] 1.4 Actualizar `compose/prometheus/docker-compose.yml`: reemplazar `prometheus-data:/prometheus` por `/mnt/usb-data/prometheus/data:/prometheus`
- [ ] 1.5 Redesplegar: `bash ~/raspi-docs/compose/deploy.sh prometheus`
- [ ] 1.6 Verificar que Prometheus arranca y consultas históricas funcionan: `curl http://localhost:9090/api/v1/query?query=up`
- [ ] 1.7 Eliminar volumen nombrado: `docker volume rm prometheus-data`

## 2. Migrar Grafana

- [ ] 2.1 Crear directorio destino: `sudo mkdir -p /mnt/usb-data/grafana/data && sudo chown 472:472 /mnt/usb-data/grafana/data`
- [ ] 2.2 Parar Grafana: `docker stop grafana`
- [ ] 2.3 Copiar datos del volumen:
  `docker run --rm -v grafana-data:/source -v /mnt/usb-data/grafana/data:/dest alpine sh -c "cp -a /source/. /dest/"`
- [ ] 2.4 Actualizar `compose/grafana/docker-compose.yml`: reemplazar `grafana-data:/var/lib/grafana` por `/mnt/usb-data/grafana/data:/var/lib/grafana`
- [ ] 2.5 Redesplegar: `bash ~/raspi-docs/compose/deploy.sh grafana`
- [ ] 2.6 Verificar acceso a Grafana en `http://grafana.home.lab` y que la configuración persiste
- [ ] 2.7 Eliminar volumen nombrado: `docker volume rm grafana-data`

## 3. Migrar AdGuard Home

- [ ] 3.1 Crear directorios destino:
  `sudo mkdir -p /mnt/usb-data/adguard-home/work /mnt/usb-data/adguard-home/conf`
- [ ] 3.2 Parar AdGuard: `docker stop adguard-home`
  > ⚠️ DNS local deja de funcionar durante este paso
- [ ] 3.3 Copiar datos de los dos volúmenes:
  `docker run --rm -v adguard-work:/source -v /mnt/usb-data/adguard-home/work:/dest alpine sh -c "cp -a /source/. /dest/"`
  `docker run --rm -v adguard-conf:/source -v /mnt/usb-data/adguard-home/conf:/dest alpine sh -c "cp -a /source/. /dest/"`
- [ ] 3.4 Actualizar `compose/adguard-home/docker-compose.yml`: reemplazar volúmenes nombrados por bind mounts
- [ ] 3.5 Redesplegar: `bash ~/raspi-docs/compose/deploy.sh adguard-home`
- [ ] 3.6 Verificar resolución DNS: `nslookup grafana.home.lab 192.168.1.101`
- [ ] 3.7 Eliminar volúmenes nombrados: `docker volume rm adguard-work adguard-conf`

## 4. Documentar

- [ ] 4.1 Actualizar `estado.md`: marcar divergencia #2 (volúmenes nombrados) como resuelta
- [ ] 4.2 Actualizar documentación de cada servicio con las nuevas rutas de bind mount
