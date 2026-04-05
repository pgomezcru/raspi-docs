## 1. Gitea — Habilitar Actions y registrar runner

- [ ] 1.1 Añadir `[actions] ENABLED = true` en `/mnt/usb-data/docker-root/gitea/data/gitea/conf/app.ini`
- [ ] 1.2 Reiniciar el contenedor `gitea` para aplicar el cambio de configuración
- [ ] 1.3 Obtener el registration token del runner en Gitea (Site Administration → Actions → Runners)
- [ ] 1.4 Añadir la variable `ACT_RUNNER_TOKEN=<token>` al `.env` del compose de Gitea en la raspi

## 2. Gitea — Añadir act_runner al compose

- [ ] 2.1 Añadir el servicio `act-runner` en `compose/gitea/docker-compose.yml` (imagen, env vars, volúmenes: socket Docker + bind mount de datos)
- [ ] 2.2 Desplegar el stack actualizado con `deploy.sh gitea` y verificar que `act-runner` aparece activo en el panel de Gitea

## 3. raindrop-tracker — Compose de producción

- [ ] 3.1 Crear `compose/raindrop-tracker/docker-compose.yml` con la configuración de producción (key del bot, `restart: "no"`, rutas absolutas de la raspi)
- [ ] 3.2 Añadir la entrada `raindrop-tracker` en `compose/manifest.yml`

## 4. Raspi — Preparar el entorno del servicio

- [ ] 4.1 Generar la SSH key del bot en la raspi: `ssh-keygen -t ed25519 -C "raindrop-tracker-bot" -f ~/.ssh/raindrop_tracker_bot -N ""`
- [ ] 4.2 Añadir la clave pública como deploy key en el repo de Gitea (Settings → Deploy Keys, con permiso de escritura)
- [ ] 4.3 Añadir el host de Gitea a `known_hosts`: `ssh-keyscan -p 2222 gitea.local >> ~/.ssh/known_hosts`
- [ ] 4.4 Clonar el repo en la raspi: `git clone git@gitea.local:pablo/raindrop-tracker.git /mnt/usb-data/raindrop-tracker/`
- [ ] 4.5 Crear el fichero `.env` en `/mnt/usb-data/raindrop-tracker/.env` con `RAINDROP_TOKEN`, `GIT_COMMIT=true`, `GIT_PUSH=true`
- [ ] 4.6 Desplegar el compose de producción con `deploy.sh raindrop-tracker`

## 5. Raspi — Build y test manual

- [ ] 5.1 Hacer build de la imagen: `docker compose -f /mnt/usb-data/raindrop-tracker/docker-compose.yml build`
- [ ] 5.2 Ejecutar una vez manualmente y verificar que se genera commit y push: `docker compose -f /mnt/usb-data/raindrop-tracker/docker-compose.yml run --rm raindrop-tracker`
- [ ] 5.3 Verificar en Gitea que el commit aparece en el repo raindrop-tracker

## 6. Raspi — Configurar cron

- [ ] 6.1 Añadir entrada de cron en la raspi (`crontab -e`) para ejecutar el contenedor cada 6 horas con redirección de logs a `/var/log/raindrop-tracker.log`

## 7. Gitea Actions — Workflow en raindrop-tracker

- [ ] 7.1 Crear el directorio `.gitea/workflows/` en el repo `raindrop-tracker`
- [ ] 7.2 Crear `.gitea/workflows/bookmark-updated.yml` con `on: push` filtrado por `paths: ['data/**']` y un job que muestre el resumen de cambios
- [ ] 7.3 Habilitar Actions en el repo raindrop-tracker en Gitea (Settings → Features → Actions)
- [ ] 7.4 Hacer push del workflow y verificar que la Action se dispara y completa correctamente
