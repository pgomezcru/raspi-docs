## 1. Generar certificado wildcard con mkcert

- [ ] 1.1 Instalar `mkcert` en Goliath (Windows): `winget install FiloSottile.mkcert`
- [ ] 1.2 Instalar la CA local en el almacén de Windows: `mkcert -install`
- [ ] 1.3 Generar certificado wildcard: `mkcert "*.home.lab" "home.lab"`
  - Produce: `_wildcard.home.lab+1.pem` (cert) y `_wildcard.home.lab+1-key.pem` (clave)
- [ ] 1.4 Copiar ambos ficheros a `/mnt/usb-data/nginx/certs/` en la Pi (vía unidad `I:` o scp)
- [ ] 1.5 Ajustar permisos: `chmod 640 /mnt/usb-data/nginx/certs/*.pem && chown root:docker /mnt/usb-data/nginx/certs/*.pem`

## 2. Configurar nginx para HTTPS

- [ ] 2.1 Para cada vhost en `/mnt/usb-data/nginx/conf.d/`:
  - Añadir servidor en puerto 80 que redirige a HTTPS (301)
  - Añadir servidor en puerto 443 con `ssl_certificate` y `ssl_certificate_key`
  - Añadir directivas SSL modernas: `ssl_protocols TLSv1.2 TLSv1.3`, `ssl_ciphers`, `ssl_session_cache`
- [ ] 2.2 Verificar sintaxis nginx: `docker exec nginx_proxy nginx -t`
- [ ] 2.3 Recargar nginx: `docker exec nginx_proxy nginx -s reload`
- [ ] 2.4 Verificar HTTPS en Goliath: `https://grafana.home.lab`, `https://gitea.home.lab`, etc.

## 3. Actualizar URLs en Homarr

- [ ] 3.1 Acceder a la configuración de Homarr
- [ ] 3.2 Actualizar todos los widgets/integraciones para usar `https://` en lugar de `http://`
- [ ] 3.3 Verificar que los widgets de integración (Grafana, Gitea) siguen funcionando

## 4. Distribuir la CA a otros clientes

- [ ] 4.1 Exportar la CA de mkcert: `mkcert -CAROOT` → copiar `rootCA.pem`
- [ ] 4.2 Instalar en Nemo (Linux): añadir a `/usr/local/share/ca-certificates/` + `update-ca-certificates`
- [ ] 4.3 Documentar proceso de instalación en Android e iOS en `infraestructura/https-plan.md`

## 5. Documentar

- [ ] 5.1 Actualizar `infraestructura/https-plan.md` con el proceso completo y fecha de expiración del cert
- [ ] 5.2 Documentar en cada fichero de servicio (`monitoring/grafana.md`, etc.) que las URLs son ahora HTTPS
- [ ] 5.3 Actualizar `infraestructura/ports.md` para reflejar que 80 → redirige y 443 → TLS activo
