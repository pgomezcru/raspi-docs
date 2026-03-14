[🏠 Inicio](../README.md) > [📂 Infraestructura](_index.md)

# Gestión de Claves SSH

Esta guía profundiza en el ciclo de vida, buenas prácticas y recuperación de claves SSH, un componente crítico para la seguridad de tu infraestructura.

## Ciclo de Vida de una Clave SSH

### 1. Generación
Se recomienda usar el algoritmo [**Ed25519**](https://ed25519.cr.yp.to/) por su seguridad y rendimiento. Si no es compatible con algún sistema muy antiguo, usa **RSA** con 4096 bits.

```bash
# Recomendado (Ed25519)
ssh-keygen -t ed25519 -C "comentario_identificativo"

# Alternativa (RSA 4096)
ssh-keygen -t rsa -b 4096 -C "comentario_identificativo"
```

### 2. Protección (Passphrase)
Siempre establece una **passphrase** (frase de contraseña) al generar la clave. Esto cifra la clave privada en tu disco. Si alguien roba tu archivo de clave privada, no podrá usarlo sin la frase.

### 3. Rotación
Es buena práctica rotar las claves periódicamente (ej. anualmente) o inmediatamente si sospechas que han sido comprometidas.
1. Genera un nuevo par de claves.
2. Añade la nueva clave pública al servidor (`~/.ssh/authorized_keys`).
3. Verifica que puedes conectar con la nueva clave.
4. Elimina la clave pública antigua del servidor.
5. Elimina la clave privada antigua de tu cliente.

```bash
# 1. Generar nueva clave (en tu PC local)
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_new -C "nueva_clave_2025"

# 2. Copiar la nueva identidad al servidor
ssh-copy-id -i ~/.ssh/id_ed25519_new.pub usuario@192.168.1.10

# 3. Probar conexión (forzando el uso de la nueva clave)
ssh -i ~/.ssh/id_ed25519_new usuario@192.168.1.10

# 4. (En el servidor) Editar authorized_keys para borrar la línea de la clave vieja
# nano ~/.ssh/authorized_keys

# 5. (En local) Reemplazar la clave vieja por la nueva (backup opcional de la vieja)
mv ~/.ssh/id_ed25519 ~/.ssh/id_ed25519_old
mv ~/.ssh/id_ed25519_new ~/.ssh/id_ed25519
```

## Recuperación tras Pérdida

Si pierdes tu clave privada o olvidas la passphrase, **no hay forma de recuperarla**. Perderás el acceso SSH si esa era la única forma de entrar.

### Estrategias de Mitigación

1.  **Múltiples Claves**: Autoriza claves de diferentes dispositivos (ej. tu PC de escritorio y tu portátil). Si pierdes uno, entras con el otro.
2.  **Usuario de Rescate (Físico)**: Mantén un usuario con contraseña habilitada pero **solo accesible localmente** (conectando teclado y monitor a la Pi).
3.  **Acceso Físico (Tarjeta SD)**:
    *   Apaga la Pi y saca la tarjeta SD.
    *   Móntala en otro ordenador Linux.
    *   Edita el sistema de archivos para añadir una nueva clave pública en `/home/usuario/.ssh/authorized_keys` o reactivar temporalmente la autenticación por contraseña en `/etc/ssh/sshd_config`.

## Buenas Prácticas

- **No compartir claves privadas**: Cada usuario/dispositivo debe tener su propio par de claves.
- **Permisos correctos**: SSH es muy estricto con los permisos de archivo.
    *   `~/.ssh`: 700 (`drwx------`)
    *   `~/.ssh/authorized_keys`: 600 (`-rw-------`)
    *   Clave privada local: 600 (`-rw-------`)
- **Uso de Agente SSH**: Para no escribir la passphrase cada vez, usa `ssh-agent`.
    *   Windows: El servicio "OpenSSH Authentication Agent".
    *   Linux/Mac: `eval "$(ssh-agent -s)" && ssh-add ~/.ssh/id_ed25519`.
