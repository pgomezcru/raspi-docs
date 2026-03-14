[🏠 Inicio](../README.md) > [📂 Infraestructura](_index.md)

# Estrategia de Backups

## Resumen ejecutivo
Breve guía práctica para realizar backups fiables usando restic. Cobertura: volúmenes Docker, dumps de BBDD e IaC. Destino primario: NAS (/mnt/nas/pi). Destino de pruebas y restores de alta fidelidad: SSD local (/mnt/usb-data).

## Sección mínima: poner backups en marcha rápido

Si necesitas habilitar backups lo antes posible sin implementar todo el runbook, sigue estos pasos mínimos de forma segura:

- **Preparar** (una sola vez en el Pi):

```bash
# crear o copiar el fichero de contraseña de restic para el usuario admin
# Opción A (si ya existe en /etc): copiarlo al home de admin
# Opción B (si no existe): generar uno nuevo seguro
if [ -f /etc/restic/RESTIC_PASSWORD ]; then
  sudo sh -c 'cp /etc/restic/RESTIC_PASSWORD /home/admin/.restic_password'
else
  # Genera una contraseña fuerte de 32 bytes codificada en base64
  sudo sh -c 'openssl rand -base64 32 > /home/admin/.restic_password'
fi
sudo chown admin:admin /home/admin/.restic_password
sudo chmod 600 /home/admin/.restic_password

# asegurarse de que el repo existe y es accesible (si no, inicializarlo)
export RESTIC_REPOSITORY=/mnt/nas/pi/restic-repo
export RESTIC_PASSWORD_FILE=/home/admin/.restic_password
sudo -u admin restic snapshots --repo "$RESTIC_REPOSITORY" --password-file "$RESTIC_PASSWORD_FILE" || \
  sudo -u admin restic init --repo "$RESTIC_REPOSITORY" --password-file "$RESTIC_PASSWORD_FILE"
```

- **Backup inmediato de un volumen (ejemplo: Gitea)**

```bash
# como admin (no usar root interactivo si no hace falta)
export RESTIC_REPOSITORY=/mnt/nas/pi/restic-repo
export RESTIC_PASSWORD_FILE=/home/admin/.restic_password

# (opcional) generar dump de BBDD si procede
# docker exec -t gitea-db pg_dumpall -U gitea > /mnt/usb-data/gitea/tmp/db_dump.sql

# backup del volumen del servicio
sudo -u admin restic backup /mnt/usb-data/docker-root/volumes/gitea-data/_data --tag gitea --host "$(hostname)" --password-file "$RESTIC_PASSWORD_FILE" --repo "$RESTIC_REPOSITORY"

# aplicar política mínima de retención
sudo -u admin restic forget --prune --keep-daily 7 --keep-weekly 4 --keep-monthly 12 --repo "$RESTIC_REPOSITORY" --password-file "$RESTIC_PASSWORD_FILE"
```

- **Notas de seguridad y operación rápida**
  - Ejecutar los comandos como `admin` usando `sudo -u admin` o iniciar sesión como `admin` para evitar usar root constantemente.
  - Para servicios con TSDB (Prometheus) o BBDD, generar un dump lógico antes del backup para garantizar consistencia.
  - Estos pasos son un punto de partida; documenta cada ejecución en el `_log.md` correspondiente.

Esta sección mínima permite tener copias rápidas y recuperables mientras se trabaja en el plan completo.

## Alcance
- Volúmenes Docker listados en el host.
- Dumps y restauraciones de bases de datos (lógicas).
- Carpeta de configuración / IaC (repositorios).
- Scripts por servicio en /mnt/usb-data/<servicio>/ (versionados junto a docker-compose).

## Requisitos previos

- Repositorio restic accesible en NAS: /mnt/nas/pi/restic-repo.
- Fichero de contraseña accesible por el usuario de operación: /home/admin/.restic_password (admin:admin, 600) — ver comandos abajo.
- Restic instalado en host (recomendado) o imagen pinneada si se usa contenedor.
- SSD conectado al host: /mnt/usb-data (para pruebas/restore).

## Referencia oficial
- https://restic.net/  <!-- verificar URL antes de usar -->

## Destinos y rutas
- Repositorio: /mnt/nas/pi/restic-repo
- RESTIC_PASSWORD: /etc/restic/RESTIC_PASSWORD
- Tests/restores de alta fidelidad (SSD): /mnt/usb-data/restore-tests/<fecha>
- Fallback pruebas (NAS, con precauciones): /mnt/nas/pi/restore-tests/<fecha>

## Decisión: restic en host vs contenedor
- Recomendado: instalar restic en el host (acceso nativo a volúmenes, mejor I/O, integración con cron/systemd).
- Contenedor: usar si se requiere aislamiento; hay que montar explícitamente /var/lib/docker/volumes, /mnt/usb-data y /etc/restic/RESTIC_PASSWORD y validar rendimiento.

## Crear el archivo de contraseña accesible por admin (resumen)
- Generar y asegurar en el home de admin (recomendado para ejecutar restic sin sudo):
```bash
# crear copia segura del password para admin
sudo sh -c 'openssl rand -base64 32 > /home/admin/.restic_password'
sudo chown admin:admin /home/admin/.restic_password
sudo chmod 600 /home/admin/.restic_password

# alternativa: si ya existe en /etc, copiarla de forma segura
# sudo cp /etc/restic/RESTIC_PASSWORD /home/admin/.restic_password && sudo chown admin:admin /home/admin/.restic_password && sudo chmod 600 /home/admin/.restic_password
```
- NO commitear ni incluir /home/admin/.restic_password en repositorios públicos.

## Inicializar repositorio restic (como admin sin root)
- Asegurar que el usuario admin tiene permisos de escritura en el repo (ACL):
```bash
# ejecutar como root una sola vez para conceder permisos al usuario admin sobre el repo NAS
sudo setfacl -R -m u:admin:rwx /mnt/nas/pi/restic-repo
```
- Luego, como admin (sin sudo) iniciar el repositorio usando su fichero de contraseña:
```bash
export RESTIC_REPOSITORY=/mnt/nas/pi/restic-repo
export RESTIC_PASSWORD_FILE=/home/admin/.restic_password
restic init --repo "$RESTIC_REPOSITORY" --password-file "$RESTIC_PASSWORD_FILE"
```

## Procedimiento de backup (runbook simplificado)
1. Preparar: verificar espacio en NAS y SSD, ENSAYAR permisos.
2. (Opcional) Parar contenedores que requieren quiesce:
   docker-compose -f /path/to/docker-compose.yml stop <service>
3. Generar dumps de BBDD (psql/mysql) y colocarlos en ruta temporal segura.
4. Ejecutar restic backup sobre rutas que contienen config/data/dumps.
5. Ejecutar restic forget + prune según política.
6. Reiniciar contenedores detenidos.
7. Registrar resultado en logs y notificar si hay fallo.

Ejemplo (backup usando usuario admin):
```bash
export RESTIC_REPOSITORY=/mnt/nas/pi/restic-repo
export RESTIC_PASSWORD_FILE=/home/admin/.restic_password
restic backup /var/lib/docker/volumes/gitea-data/_data --tag gitea --host "$(hostname)"
restic forget --prune --keep-daily 7 --keep-weekly 4 --keep-monthly 12
```

## Scripts por servicio (patrón)
Colocar `backup-prep.sh` en `/mnt/usb-data/<servicio>/` y versionarlo junto al docker-compose (sin secretos). Permisos recomendados: owner admin:docker, chmod 750.

Plantilla (adaptar):
```bash
# filepath: /mnt/usb-data/<servicio>/backup-prep.sh
#!/usr/bin/env bash
set -euo pipefail
SERVICE_NAME="<servicio>"
SVC_DIR="/mnt/usb-data/${SERVICE_NAME}"
LOG="${SVC_DIR}/backup.log"
export RESTIC_REPOSITORY="/mnt/nas/pi/restic-repo"
export RESTIC_PASSWORD_FILE="/home/admin/.restic_password"

echo "$(date -Iseconds) - START ${SERVICE_NAME}" >> "${LOG}"
# Opcional parar servicio
# (cd "${SVC_DIR}" && docker-compose -f docker-compose.yml stop ${SERVICE_NAME})
# Crear dump si procede
# docker exec -t ${SERVICE_NAME}_db pg_dump -U postgres dbname > "${SVC_DIR}/tmp/db_dump.sql"
BACKUP_PATHS=("${SVC_DIR}/config" "${SVC_DIR}/data")
restic backup "${BACKUP_PATHS[@]}" --tag "${SERVICE_NAME}" --host "$(hostname)" >> "${LOG}" 2>&1
restic forget --prune --keep-daily 7 --keep-weekly 4 --keep-monthly 12 >> "${LOG}" 2>&1
# Limpiar temporales
# shred -u "${SVC_DIR}/tmp/db_dump.sql"
# (cd "${SVC_DIR}" && docker-compose -f docker-compose.yml start ${SERVICE_NAME})
echo "$(date -Iseconds) - END ${SERVICE_NAME}" >> "${LOG}"
```

## Política de retención recomendada
- keep-daily 7
- keep-weekly 4
- keep-monthly 12
Ajustar según espacio y necesidades de RPO.

## Estrategia de pruebas de restauración
- Priorizar SSD host: /mnt/usb-data/restore-tests/<fecha> para restores reales (mejor RTO fidelidad).
- Cadencia:
  - Semanal: pruebas parciales (dumps, volúmenes pequeños).
  - Mensual: restore end-to-end de un servicio crítico (p. ej. gitea).
  - Tras cambios mayores: pruebas ad-hoc.
- Runbook de restore (ejemplo):
```bash
# ejemplo restore con usuario admin
export RESTIC_REPOSITORY=/mnt/nas/pi/restic-repo
export RESTIC_PASSWORD_FILE=/home/admin/.restic_password
SNAPSHOT=$(restic snapshots --json --repo "$RESTIC_REPOSITORY" --password-file "$RESTIC_PASSWORD_FILE" | jq -r '.[0].short_id')
restic restore "$SNAPSHOT" --target /mnt/usb-data/restore-tests/gitea --repo "$RESTIC_REPOSITORY" --password-file "$RESTIC_PASSWORD_FILE"
# montar/arrancar contenedores de prueba apuntando a la ruta restaurada y ejecutar smoke tests
```
- Validaciones mínimas: existencia archivos, conteos básicos, arranque de contenedores, endpoints de salud, consultas simples a BBDD.

## Automatización y orquestación
- Job central (cron/systemd) recorre /mnt/usb-data/* y ejecuta backup-prep.sh si existe y es ejecutable.
- Guardar logs por servicio y centralizar alertas (email/Telegram).
- Ejemplo cron global: `/etc/cron.d/backup-restic` o systemd timer según preferencia.

## Seguridad y buenas prácticas
- RESTIC_PASSWORD con permisos 640 root:root; no en repo.
- No restaurar archivos de datos físicos de BBDD en discos de red; usar restores lógicos.
- Documentar versión de restic usada (pinnearla en este documento).
- Evitar backups durante ventanas de máxima carga; comprobar espacio disponible.

## Comprobaciones pre-upgrade (checklist rápido)
- [ ] Snapshot reciente válido en restic.
- [ ] Logs de backup sin errores.
- [ ] Espacio NAS y SSD suficiente.
- [ ] Plan de rollback documentado.

## Tareas pendientes / TODO
- Añadir entrada en TODO.md con calendario de pruebas de restauración.
- Registrar la versión exacta de restic instalada y fecha de prueba.
- Revisar permisos en /mnt/usb-data/docker-root según directrices.

## Usar restic sin root

Objetivo: permitir que el usuario de operación (p.ej. `admin`) ejecute backups/restore con restic sin usar root en todas las operaciones, manteniendo el menor privilegio posible.

Opciones y pasos recomendados (elige y adapta según política de seguridad):

1) Fichero de contraseña en el home del usuario (recomendado)
- Crear copia segura del password para que sólo `admin` la lea:
```bash
sudo cp /etc/restic/RESTIC_PASSWORD /home/admin/.restic_password
sudo chown admin:admin /home/admin/.restic_password
sudo chmod 600 /home/admin/.restic_password
# Usar en scripts:
export RESTIC_PASSWORD_FILE=/home/admin/.restic_password
```
- Ventaja: evita exponer /etc a procesos no-root. Recomendado para ejecución diaria por `admin`.

2) Dar al usuario acceso al repositorio restic (ACL)
- Restic necesita escribir en el repo; conceder acceso mínimo:
```bash
# permitir lectura/escritura al usuario admin sobre el repo (ACL)
sudo setfacl -R -m u:admin:rwx /mnt/nas/pi/restic-repo
# confirmar
getfacl /mnt/nas/pi/restic-repo | sed -n '1,10p'
```
- Nota: usar ACLs sólo sobre la ruta del repo y documentar el cambio.

3) Acceso a volúmenes Docker (lectura) sin root
- Si los datos a respaldar están en /var/lib/docker/volumes, dar lectura recursiva sólo a los volúmenes necesarios:
```bash
sudo setfacl -R -m u:admin:rx /var/lib/docker/volumes/gitea-data/_data
```
- Alternativa: mover/duplicar datos montados a rutas en /mnt/usb-data donde `admin` tenga control (mejor control y versionado).

4) Permisos para comandos Docker (dumps)
- Para ejecutar `docker exec` sin sudo, añade `admin` al grupo docker:
```bash
sudo usermod -aG docker admin
# luego: cerrar sesión / volver a iniciar o usar: newgrp docker
```
- Riesgo: miembro del grupo docker tiene acceso efectivo a root en el host; evaluar su conveniencia.

5) Sudoers con privilegios limitados (opción más controlada)
- Si prefieres no añadir admin al grupo docker ni cambiar ACLs, permitir comandos concretos mediante /etc/sudoers.d/backup:
```text
# filepath: /etc/sudoers.d/backup
Cmnd_Alias BACKUP_CMDS = /usr/bin/restic, /usr/bin/docker exec *, /usr/bin/docker-compose -f /mnt/usb-data/*/docker-compose.yml *
admin ALL=(root) NOPASSWD: BACKUP_CMDS
```
- Ajustar rutas y comandos con precisión. WARNING: otorgar comandos docker puede ser potente; documentar y auditar.

6) Ejecución desde scripts por servicio
- En los `backup-prep.sh` usar la copia del password y rutas con permisos ya configurados:
```bash
export RESTIC_REPOSITORY=/mnt/nas/pi/restic-repo
export RESTIC_PASSWORD_FILE=/home/admin/.restic_password
restic backup /mnt/usb-data/grafana/config --tag grafana
```

Consideraciones de seguridad y operativa
- Minimizar la superficie: aplicar ACLs sólo a rutas necesarias y documentar cada cambio.
- Evitar chmod 644 en /etc/restic/RESTIC_PASSWORD; preferir copia en home con 600 o ACL temporal.
- Registrar en este documento qué volúmenes y rutas se han abierto y por qué.
- Si la política exige máxima separación, ejecutar restic vía un servicio systemd que corra como usuario “backup” con solo los accesos necesarios.