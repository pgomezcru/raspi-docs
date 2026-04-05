## 1. Preparar GitHub

- [ ] 1.1 Verificar que el repositorio `raspi-docs` existe en GitHub; crearlo si no existe (privado recomendado)
- [ ] 1.2 En GitHub: Settings → Developer Settings → Personal Access Tokens (classic) → Generate new token
  - Scope mínimo: `repo` (acceso completo a repositorios privados)
  - Nombre descriptivo: `gitea-mirror-raspi-docs`
  - Guardar el token de forma segura (se muestra solo una vez)

## 2. Configurar mirror en Gitea

- [ ] 2.1 Acceder a Gitea: `http://gitea.home.lab`
- [ ] 2.2 Navegar al repositorio `raspi-docs` → Settings → Repository → Mirror Settings
- [ ] 2.3 En "Push Mirrors", añadir nuevo mirror:
  - Remote URL: `https://github.com/<usuario>/raspi-docs.git`
  - Git user: nombre de usuario de GitHub
  - Password/Token: el PAT generado en el paso 1.2
  - Sync interval: `8h` (o `24h`)
- [ ] 2.4 Forzar sincronización inicial con "Sync Now"

## 3. Verificar sincronización

- [ ] 3.1 En GitHub, verificar que los commits de Gitea aparecen en el repositorio
- [ ] 3.2 Hacer un commit de prueba en Gitea y verificar que aparece en GitHub tras la siguiente sincronización (o forzar con "Sync Now")

## 4. Documentar

- [ ] 4.1 Actualizar `programacion/gitea.md`: añadir sección "Mirroring con GitHub" con instrucciones para configurar mirrors en futuros repositorios
- [ ] 4.2 Actualizar `TODO.md`: mover tarea de mirroring a "Done"
- [ ] 4.3 Actualizar `estado.md`: marcar divergencia #6 (mirroring no configurado) como resuelta
