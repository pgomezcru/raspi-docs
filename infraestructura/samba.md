[🏠 Inicio](../README.md) > [📂 Infraestructura](_index.md)

# Manual Básico de Samba en Linux

Samba es un software de código abierto que permite compartir archivos y impresoras entre sistemas Linux y Windows. En este contexto de servidor doméstico en Raspberry Pi, se utiliza para compartir almacenamiento persistente (como SSD o NAS) de manera segura.

> **Nota**: Para más detalles, consulta la documentación oficial de Samba: [https://www.samba.org/samba/docs/](https://www.samba.org/samba/docs/).

## Instalación

Instala Samba en Debian/Ubuntu (como Raspbian en Raspberry Pi):

```bash
sudo apt update
sudo apt install samba samba-common-bin
```

## Configuración Básica

Edita el archivo de configuración `/etc/samba/smb.conf`. Agrega una sección para compartir una carpeta, por ejemplo:

```ini
[shared_folder]
   path = /mnt/usb-data/shared
   browseable = yes
   writable = yes
   guest ok = no
   valid users = admin
```

Reinicia el servicio:

```bash
sudo systemctl restart smbd
sudo systemctl enable smbd
```

## Configuración Avanzada

A continuación, se explica un ejemplo de configuración más detallada para compartir la carpeta `/mnt/usb-data`, basada en un setup real. Esta configuración asegura permisos estrictos, compatibilidad con Windows y integración con Docker.

```ini
[usb-data]
   path = /mnt/usb-data
   valid users = admin
   read only = no
   browsable = yes
   force user = admin       # Fuerza que todos los archivos creados pertenezcan al usuario 'admin' (compatible con Windows)
   force group = docker     # Fuerza que pertenezcan al grupo 'docker' (útil para contenedores Docker)
   create mask = 0750       # Permisos para archivos nuevos: rwxr-x--- (lectura/escritura para propietario, lectura/ejecución para grupo)
   directory mask = 0750    # Permisos para directorios nuevos: rwxr-x--- (lectura/escritura/ejecución para propietario, lectura/ejecución para grupo)
```

En este caso las mask indican que los nuevos archivos y directorios creados tendrán permisos restrictivos, evitando acceso a otros usuarios del sistema.

### Explicación de Opciones:
- **path**: Ruta absoluta de la carpeta a compartir en el sistema de archivos.
- **valid users**: Solo el usuario 'admin' puede acceder; mejora la seguridad limitando el acceso.
- **read only = no**: Permite escritura en la carpeta.
- **browsable = yes**: La carpeta es visible en la lista de recursos compartidos.
- **force user/group**: Asegura que archivos creados desde Windows se asignen al usuario/grupo correcto en Linux, evitando problemas de permisos.
- **create mask/directory mask**: Define permisos predeterminados para nuevos archivos/directorios, priorizando seguridad (sin acceso para otros usuarios).

Esta configuración es ideal para almacenamiento persistente en SSD/NAS, con backups recomendados. Para integración Docker, verifica que el grupo 'docker' tenga permisos adecuados.

## Seguridad

- **Autenticación**: Usa usuarios del sistema. Agrega un usuario Samba con `sudo smbpasswd -a admin`.
- **Permisos**: Asegura que la carpeta compartida tenga permisos adecuados (ej. `chown admin:admin /mnt/usb-data/shared`).
- **Exposición**: No expongas Samba directamente a internet; usa VPN o proxy reverso si es necesario.

## Gestión de Usuarios

En Samba, los usuarios se gestionan a través de una relación entre usuarios del sistema Linux, usuarios Samba y credenciales de Windows. Los usuarios Samba son extensiones de los usuarios Linux, y las conexiones desde Windows requieren que las credenciales coincidan.

### Relación entre Usuarios:
- **Usuario Linux**: Base del sistema (ej. `admin`). Debe existir en `/etc/passwd`.
- **Usuario Samba**: Se crea con `smbpasswd` para el usuario Linux correspondiente. Permite autenticación SMB.
- **Usuario Windows**: Cliente que se conecta con nombre de usuario y contraseña que deben coincidir con el usuario Samba/Linux.

Para crear un usuario:
1. Crea o verifica el usuario Linux: `sudo useradd -m admin` (si no existe).
2. Agrega al grupo Docker si es necesario: `sudo usermod -aG docker admin`.
3. Establece contraseña Samba: `sudo smbpasswd -a admin`.

Los usuarios Windows deben usar el mismo nombre y contraseña. Si hay discrepancias, la autenticación falla. Para listar usuarios Samba: `sudo pdbedit -L`.

### Verificación de Usuarios:
- Para verificar si un usuario existe en Samba y tiene contraseña: `sudo pdbedit -Lv admin` (muestra detalles, incluyendo si la contraseña está configurada).
- Si no tiene contraseña, el comando `smbpasswd -a admin` la establecerá.

## Proxy

Si necesitas acceso remoto, configura un proxy reverso (ej. Nginx) para redirigir tráfico a Samba. Conecta Samba a la red `proxy_net` en Docker si se integra con contenedores.

## Firewall

Abre el puerto 445 (SMB) en UFW:

```bash
sudo ufw allow 445
```

Cierra otros puertos innecesarios para minimizar riesgos.

## Fail2Ban

Configura una jail para proteger contra ataques de fuerza bruta en Samba. Edita `/etc/fail2ban/jail.local`:

```ini
[samba]
enabled = true
port = 445
logpath = /var/log/samba/log.%m
```

Reinicia Fail2Ban: `sudo systemctl restart fail2ban`.

## Almacenamiento

Usa bind mounts para persistencia en `/mnt/usb-data/samba/shared`. Para datos críticos, considera SSD o NAS con backups regulares.

## Homarr

Integra Samba en Homarr agregando un enlace simple al dashboard: configura un widget que apunte a `\\192.168.1.101\shared_folder` (requiere cliente SMB).

## Solución de Problemas

Si no puedes hacer login desde Windows con un usuario Samba que tiene contraseña configurada, sigue estos pasos para diagnosticar:

### Desde Windows:
1. **Verifica la conectividad**: Abre el Explorador de Archivos y navega a `\\192.168.1.101` (o la IP del servidor). Si no ves los recursos compartidos, revisa la red (VPN si es remoto) y firewall de Windows.
2. **Intenta mapear la unidad**: Haz clic derecho en "Este equipo" > "Conectar a unidad de red". Ingresa `\\192.168.1.101\usb-data` y proporciona credenciales (usuario: admin, contraseña Samba). Si falla, anota el error (ej. "Acceso denegado").
3. **Revisa logs de eventos**: Abre el Visor de Eventos (busca "Visor de eventos") > Registros de Windows > Sistema. Busca errores relacionados con SMB o red (códigos como 0x80070043 para problemas de autenticación).
   
   **Ejemplos de filtros para ver eventos relacionados con Samba/SMB**:
   - Filtrar por **Fuente**: Selecciona "Microsoft-Windows-SMBClient" o "Microsoft-Windows-SMBServer" para eventos del cliente/servidor SMB.
   - Filtrar por **ID de Evento**: 30803 (fallo de autenticación SMB), 30804 (conexión exitosa), o 31001 (errores de red SMB).
   - Filtrar por **Palabras clave**: Incluye "SMB" en la descripción del evento.
   - Configura el filtro: En el Visor de Eventos, haz clic derecho en el registro > "Filtrar registro actual" > Agrega criterios como Nivel (Error/Advertencia), Fuente, o ID.

   > Si no ves nada en el registro, intenta reproducir el error (intenta conectar varias veces) para generar eventos. También revisa otros registros como "Aplicación" o "Seguridad" para eventos relacionados. Si es necesario, habilita logging avanzado en Windows para SMB ejecutando `wevtutil sl Microsoft-Windows-SMBClient /e:true` en PowerShell como administrador.

4. **Prueba con otra PC**: Para descartar problemas locales en Windows.

### Desde el Servidor (Raspberry Pi):
1. **Verifica usuarios Samba**: Ejecuta `sudo pdbedit -Lv admin` para confirmar que el usuario existe y tiene contraseña.
2. **Revisa logs de Samba**: `sudo cat /var/log/samba/log.smbd` o `sudo journalctl -u smbd` para errores de autenticación.
3. **Prueba conectividad**: Desde el servidor, `smbclient -L 192.168.1.101 -U admin` (ingresa contraseña) para simular login.
4. **Firewall y puertos**: Asegura que el puerto 445 esté abierto en UFW y no bloqueado por router.

Razones comunes: credenciales incorrectas, usuario no en `valid users`, permisos de carpeta, o conflictos de red. Si persiste, reinicia Samba y verifica configuración en `/etc/samba/smb.conf`.

### Pruebas desde PowerShell

Si la conexión falla al pedir usuario y contraseña, y el lado Linux parece configurado correctamente, prueba desde PowerShell en Windows para diagnosticar. Abre PowerShell como administrador y ejecuta los siguientes comandos paso a paso. Estos generan eventos en el log de Windows (Visor de Eventos) y ayudan a identificar si el problema es de red, autenticación o configuración.

#### 1. Verificar conectividad básica al puerto SMB (445)
   Usa `Test-NetConnection` para confirmar que el puerto 445 esté abierto y accesible desde Windows. Esto no requiere autenticación y genera eventos de red en el log si hay fallos.

   ```powershell
   Test-NetConnection -ComputerName 192.168.1.101 -Port 445
   ```

   - **Resultado esperado**: `TcpTestSucceeded: True`. Si es `False`, revisa firewall en Windows/Router o VPN.
   - **Forzar eventos**: Ejecuta el comando varias veces (ej. 5-10) para generar entradas en el log de red/SMB. Busca en el Visor de Eventos bajo "Microsoft-Windows-SMBClient" (ID 30803 para fallos).

#### 2. Intentar mapear la unidad de red con credenciales
   Usa `net use` para simular la conexión y mapear la carpeta compartida. Esto fuerza un intento de autenticación y genera eventos detallados en el log si falla.

   ```powershell
   net use Z: \\192.168.1.101\usb-data /user:admin
   ```

   - Ingresa la contraseña Samba cuando se solicite. Si falla con "Acceso denegado" o similar, anota el error.
   - **Resultado esperado**: "El comando se completó correctamente" y la unidad Z: aparece en el Explorador de Archivos.
   - **Forzar eventos**: Repite el comando 3-5 veces con credenciales incorrectas (ej. contraseña errónea) para provocar fallos de autenticación. Esto llena el log con eventos de error (ID 30803). Luego, intenta con credenciales correctas para ver si se conecta.
   - **Desmapear si es necesario**: `net use Z: /delete` para limpiar.

#### 3. Habilitar logging avanzado de SMB en Windows (para más eventos)
   Si no salen suficientes eventos, habilita logging detallado temporalmente para capturar más datos durante las pruebas.

   ```powershell
   wevtutil sl Microsoft-Windows-SMBClient /e:true /q:true
   wevtutil sl Microsoft-Windows-SMBServer /e:true /q:true
   ```

   - Ejecuta las pruebas anteriores (Test-NetConnection y net use) después de esto. Los eventos aparecerán en tiempo real en el Visor de Eventos.
   - **Deshabilitar después**: `wevtutil sl Microsoft-Windows-SMBClient /e:false` y lo mismo para SMBServer, para evitar logs excesivos.

#### Consejos adicionales para fallos de usuario/contraseña:
- Verifica que el usuario "admin" exista en Samba (`sudo pdbedit -Lv admin` en Linux) y que la contraseña coincida exactamente (case-sensitive).
- Desde Linux, prueba la conexión inversa: `smbclient -L 192.168.1.101 -U admin` (ingresa contraseña) para confirmar autenticación.
- Si persiste, revisa `/etc/samba/smb.conf` por errores de sintaxis (`testparm`) y reinicia Samba (`sudo systemctl restart smbd`).
- Eventos comunes en log: Fallos de autenticación (ID 30803) indican credenciales erróneas; errores de red (ID 31001) sugieren problemas de conectividad.

> **Comentario del usuario**: Si sigues teniendo problemas, comparte los errores específicos de PowerShell y eventos del log para más ayuda.
