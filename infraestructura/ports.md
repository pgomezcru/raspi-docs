[🏠 Inicio](../README.md) > [📂 Infraestructura](_index.md)

# Puertos en uso (resumen)

Listado de puertos mencionados en la documentación del workspace. Para cada entrada se indica puerto, protocolo, servicio/uso y la fuente del documento.

- **22/tcp** — SSH (host) — [infraestructura/configuracion-inicial.md](infraestructura/configuracion-inicial.md)
- **2222/tcp** — SSH del contenedor (host) mapeado a 22 en el contenedor — [programacion/gitea.md](programacion/gitea.md)
- **53/tcp, 53/udp** — DNS (AdGuard Home) — [general/adguard-home.md](general/adguard-home.md)
- **80/tcp** — HTTP (proxy inverso / nginx) — [infraestructura/proxy-inverso.md](nginx.md)
- **443/tcp** — HTTPS (proxy inverso / nginx) — [infraestructura/proxy-inverso.md](nginx.md)
- **3000/tcp** — Gitea / AdGuard UI (host) — [programacion/gitea.md](programacion/gitea.md), [general/adguard-home.md](general/adguard-home.md)
- **8080/tcp** — Jenkins (host) — [programacion/jenkins.md](programacion/jenkins.md)
- **50000/tcp** — Jenkins agents (host) — [programacion/jenkins.md](programacion/jenkins.md)
- **8443/tcp** — Admin HTTPS (servicios varios, p.ej. AdGuard) — [general/adguard-home.md](general/adguard-home.md), [programacion/vscode-server.md](programacion/vscode-server.md)
- **7575/tcp** — Homarr (interno / proxy) — [general/homarr.md](general/homarr.md)
- **61208/tcp** — Glances (monitorización) — [infraestructura/monitorizacion.md](infraestructura/monitorizacion.md)

**Notas:**

- Muchos servicios están pensados para integrarse vía la red interna del proxy (`proxy_net`); en esos casos no deberían exponer puertos en el host salvo necesidad explícita.
- Revisa las reglas de firewall en `infraestructura/configuracion-inicial.md` antes de abrir puertos hacia Internet.
- Confirma siempre los puertos reales en los `docker-compose.yml` o configuraciones de cada servicio si vas a aplicar reglas de firewall o NAT.
