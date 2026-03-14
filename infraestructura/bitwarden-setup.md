[🏠 Inicio](../README.md) > [📂 Infraestructura](_index.md)

# Configuración de Bitwarden

Guía de implementación para el gestor de contraseñas seleccionado (ver [ADR-0001](../docs/adr/adr-0001-seleccion-gestor-contrasenas.md)).

## 1. Instalación en Escritorio

### Windows
1. Descargar el instalador desde [bitwarden.com/download](https://bitwarden.com/download/).
2. Ejecutar el `.exe` e iniciar sesión.
3. **Recomendación**: Habilitar "Desbloqueo con Windows Hello" en `Ajustes > Seguridad` para acceso rápido.

### Linux (Debian/Ubuntu/Raspberry Pi OS)
Para entornos con interfaz gráfica:

```bash
# Opción AppImage (Universal)
wget "https://vault.bitwarden.com/download/?app=desktop&platform=linux" -O Bitwarden.AppImage
chmod +x Bitwarden.AppImage
./Bitwarden.AppImage
```

## 2. Extensiones de Navegador

Es la forma más eficiente de usar el gestor.

- **Chrome/Brave/Edge**: Instalar desde Chrome Web Store.
- **Firefox**: Instalar desde Firefox Add-ons.

> **Tip**: Configura el atajo de teclado `Ctrl+Shift+L` para auto-completar contraseñas instantáneamente.

## 3. Dispositivos Móviles (Android)

1. Instalar desde Google Play Store.
2. Ir a `Ajustes > Servicios de Autocompletado`.
3. Habilitar Bitwarden para que detecte campos de contraseña en otras apps.

## 4. Operaciones y Gestión de Secretos

Una vez instalado, el flujo de trabajo recomendado es el siguiente:

### Generación de Contraseñas
Nunca reutilices contraseñas. Usa el **Generador** integrado:
- **Longitud**: Mínimo 16 caracteres (recomendado 20+).
- **Complejidad**: Incluir mayúsculas, minúsculas, números y símbolos.
- **Passphrases**: Para contraseñas que debas escribir manualmente (ej. contraseña maestra), usa el modo "Frase de contraseña" (ej. `bateria-grapa-caballo-correcto`).

### Organización
- **Carpetas**: Agrupa los ítems por categoría (ej. `Infraestructura`, `Personal`, `Finanzas`).
- **Notas Seguras**: Úsalas para guardar claves SSH, tokens de API, o respuestas a preguntas de seguridad.
- **Campos Personalizados**: Si un servicio requiere más que usuario/pass (ej. un `App ID`), añade un campo personalizado oculto.

### Compartir Secretos (Bitwarden Send)
No envíes contraseñas por chat o correo. Usa **Bitwarden Send**:
1. Crea un "Send" de texto o archivo.
2. Configura:
   - **Eliminación**: Tras 1 hora o 1 acceso.
   - **Contraseña**: Opcional, para protección extra.
3. Comparte el enlace generado.

### Copias de Seguridad (Backups)
Aunque la nube de Bitwarden tiene redundancia, es vital tener tu propia copia.
1. Ve a la Bóveda Web (Web Vault) > **Herramientas** > **Exportar Bóveda**.
2. Formato: `.json` (Cifrado) es lo mejor para restaurar en Bitwarden.
3. **Importante**: Si exportas en texto plano (`.json` o `.csv` sin cifrar), guarda ese archivo en un volumen VeraCrypt o medio offline seguro inmediatamente.

## 5. Notas sobre Self-Hosting (Futuro)

Aunque actualmente usamos la nube oficial, el ADR contempla la posibilidad de usar [**Vaultwarden**](https://github.com/dani-garcia/vaultwarden) en la Raspberry Pi.

Requisitos previos para esa fase:
- Docker instalado.
- Dominio propio o DDNS.
- Certificado SSL (HTTPS es obligatorio).
