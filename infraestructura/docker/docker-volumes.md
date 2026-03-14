**Buenas Prácticas — Volúmenes Docker**

- **Principio**: Usa `named volumes` gestionados por Docker salvo que haya una razón clara para un `bind mount`. Los `named volumes` se almacenan en `Docker Root Dir` (p.ej. `/mnt/usb-data/docker-root/volumes/.../_data`).

- **Nombres previsibles**: Define nombres explícitos en `docker-compose.yml` para evitar prefijos automáticos:
  ```yaml
  volumes:
    gitea-data:
      name: gitea-data
  ```
  Resultado en disco: `/mnt/usb-data/docker-root/volumes/gitea-data/_data`

- **Estructura en Compose**: Ejemplo mínimo usando `named volume`:
  ```yaml
  services:
    gitea:
      image: gitea/gitea:latest
      volumes:
        - gitea-data:/data
  volumes:
    gitea-data:
      name: gitea-data
  ```

- **Cuándo usar bind mounts (excepciones)**: sólo cuando necesites editar ficheros desde el host o exponer certificados/konfs en edición frecuente — p.ej. `nginx` confs o certificados TLS. Si necesitas control absoluto sobre la ruta, usa `bind` explícito a `/mnt/usb-data/...`.

- **Inspección y trazabilidad**:
  - Lista volúmenes: `docker volume ls`
  - Ver ruta física: `docker volume inspect gitea-data` → campo `Mountpoint`

- **Backups y restauración**:
  - Hacer backup con `rsync` desde el `Mountpoint`:
    ```bash
    docker volume inspect gitea-data | jq -r '.[0].Mountpoint'
    sudo rsync -aHAX --info=progress2 /mnt/usb-data/docker-root/volumes/gitea-data/_data/ /backup/gitea/
    ```
  - Para restaurar: parar contenedores, rsync de vuelta y arrancar.

- **Migración / cambiar `data-root`**:
  1. `rsync -aHAXx --numeric-ids /var/lib/docker/ /mnt/usb-data/docker-root/` (copia inicial)
  2. `sudo systemctl stop docker`
  3. `rsync -aHAXx --numeric-ids --delete /var/lib/docker/ /mnt/usb-data/docker-root/`
  4. `sudo systemctl start docker`

- **Permisos y propietarios**:
  - Evita `chown` masivo desde el host; usa contenedores para arreglar propietarios si es necesario:
    ```bash
    docker run --rm -v gitea-data:/data alpine chown -R 1000:1000 /data
    ```
  - Asegura que el UID/GID dentro del contenedor corresponde a los que esperas.

- **Seguridad y secretos**:
  - No guardes secretos en volúmenes de forma insegura. Usa `docker secrets` o variables gestionadas cuando sea posible.
  - Para certificados, monta como `:ro` si usas bind mounts.

- **Limpieza**:
  - Elimina volúmenes huérfanos con `docker volume prune` (revisa antes).
  - Para evitar confusión, nombra volúmenes explícitamente en los `Compose` y usa `COMPOSE_PROJECT_NAME` si quieres control de prefijos.

- **Control fino (opcional)**: si quieres que un named volume apunte a una ruta concreta en el USB, usa driver `local` y `driver_opts` (bind):
  ```yaml
  volumes:
    nginx-certs:
      driver: local
      driver_opts:
        type: none
        device: /mnt/usb-data/nginx/certs
        o: bind
  ```

- **Regla práctica**: “Todo en `docker-root` y named volumes, salvo configs/certs que necesiten edición o integración con el host” — así mantienes portabilidad, backups simples y coherencia con el ADR.

¿Quieres que agregue esta micro-guía a proxy-inverso.md y/o estrategia-almacenamiento.md con ejemplos concretos para Nginx y Gitea?