[🏠 Inicio](../README.md) > [📂 Programación](_index.md)

# Jenkins - CI/CD Automation

**Estado**: Planificación Preliminar

[Jenkins](https://www.jenkins.io/doc/) servirá como el servidor de automatización para tareas de CI/CD (Integración y Despliegue Continuo).

## Consideraciones para Raspberry Pi

Jenkins está basado en Java y puede ser pesado en recursos (RAM).
- **Recomendación**: Limitar la memoria del contenedor o asegurar que la Pi 4 tenga 4GB/8GB de RAM.
- **Alternativa**: Si Jenkins resulta demasiado pesado, evaluar [**Drone CI**](https://docs.drone.io/) o [**Woodpecker**](https://woodpecker-ci.org/) (que se integran muy bien con Gitea), pero por ahora procedemos con Jenkins según solicitud.

## Requisitos

- Imagen [Docker](https://docs.docker.com/): `jenkins/jenkins:lts-jdk17` (Versión LTS recomendada).
- Persistencia: Volumen para `jenkins_home`.
- Acceso a Docker: Jenkins a menudo necesita construir imágenes Docker, por lo que necesitará acceso al socket de Docker del host o usar "Docker in Docker" (DinD).

## Configuración Docker (Borrador)

```yaml
version: "3"
services:
  jenkins:
    image: jenkins/jenkins:lts-jdk17
    container_name: jenkins
    restart: unless-stopped
    privileged: true # A menudo necesario para Docker-in-Docker o acceso a hardware
    user: root # Necesario para acceder al socket de docker si se monta
    ports:
      - "8080:8080"
      - "50000:50000"
    volumes:
      - ./jenkins_home:/var/jenkins_home
      - /var/run/docker.sock:/var/run/docker.sock # Para permitir a Jenkins lanzar comandos docker
```

## Ideas de Pipelines

1.  **Auto-deploy de esta documentación**: Al hacer push a Gitea/GitHub, Jenkins podría regenerar si usáramos un generador de sitios estáticos ([Hugo](https://gohugo.io/documentation/)/[Jekyll](https://jekyllrb.com/docs/)).
2.  **Build de contenedores**: Automatizar la construcción de imágenes para otros servicios del homelab.
3.  **Testing**: Ejecutar tests de proyectos personales.

## Integración con Gitea
- Instalar el plugin de Gitea en Jenkins.
- Configurar Webhooks en Gitea para disparar builds en Jenkins.
