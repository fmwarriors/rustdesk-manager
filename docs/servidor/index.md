# Servidor RustDesk

Esta guía explica cómo montar tu propia infraestructura de RustDesk para tener un sistema de control remoto completamente gratuito y bajo tu control.

## ¿Qué es RustDesk?

[RustDesk](https://rustdesk.com/) es una alternativa **open source** a TeamViewer, AnyDesk y similares. Permite:

- Control remoto de escritorio
- Transferencia de archivos
- Conexiones seguras cifradas
- Funciona en Windows, macOS, Linux, iOS y Android

!!! success "Ventaja principal"
    Puedes usar los servidores públicos de RustDesk gratuitamente, o **montar tu propio servidor** para tener control total sobre tus conexiones.

## Componentes del sistema

Para una instalación completa self-hosted necesitas:

### 1. RustDesk Server (Oficial, gratuito)

El servidor oficial de RustDesk consta de dos servicios:

| Servicio | Función |
|----------|---------|
| **hbbs** (ID/Rendezvous Server) | Gestiona los IDs de los clientes y facilita el establecimiento de conexiones |
| **hbbr** (Relay Server) | Retransmite el tráfico cuando no es posible una conexión P2P directa |

:material-github: [github.com/rustdesk/rustdesk-server](https://github.com/rustdesk/rustdesk-server)

### 2. RustDesk API Server (Comunidad)

El servidor oficial no incluye panel web ni API REST. Para gestionar usuarios, ver equipos conectados y tener una interfaz de administración, existe un proyecto de la comunidad:

:material-github: [github.com/lejianwen/rustdesk-api](https://github.com/lejianwen/rustdesk-api)

!!! note "Créditos"
    Desarrollado por [lejianwen](https://github.com/lejianwen). Proyecto open source bajo licencia MIT.

### 3. RustDesk Manager (Este proyecto)

Una aplicación de escritorio para gestionar tus conexiones de forma visual, consultando el estado online al servidor de IDs.

## Opciones de despliegue

El servidor RustDesk puede instalarse de varias formas, todas gratuitas:

| Método | Dificultad | Ideal para |
|--------|------------|------------|
| **Docker** | Media | Synology NAS, VPS, servidores Linux |
| **Docker Compose** | Media | Despliegue reproducible |
| **Binarios directos** | Fácil | Cualquier servidor Linux/Windows |
| **Script de instalación** | Fácil | Servidores Linux con systemd |

## Guías de instalación

### :material-docker: Docker Compose

Instalación paso a paso con Docker.

[:octicons-arrow-right-24: Guía Docker](docker.md)

### :material-network: Configuración de red

Puertos, NAT y firewall.

[:octicons-arrow-right-24: Guía de red](red.md)

### :material-lock: HTTPS y seguridad

Certificados SSL con Let's Encrypt.

[:octicons-arrow-right-24: Guía HTTPS](https.md)

### :material-wrench: Mantenimiento

Logs, backups y actualizaciones.

[:octicons-arrow-right-24: Guía de mantenimiento](mantenimiento.md)

## Recursos externos

- [Documentación oficial de RustDesk](https://rustdesk.com/docs/)
- [RustDesk Server - GitHub](https://github.com/rustdesk/rustdesk-server)
- [RustDesk API - GitHub](https://github.com/lejianwen/rustdesk-api)
- [Foro de la comunidad RustDesk](https://github.com/rustdesk/rustdesk/discussions)
