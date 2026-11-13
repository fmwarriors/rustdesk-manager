# Configuración inicial

Después de instalar RustDesk Manager, configura el servidor de IDs para ver qué equipos están online.

## Pasos

1. Abre **Ajustes** (icono de engranaje en la esquina superior derecha)
2. En la sección **Servidor**, introduce:

| Campo | Descripción | Ejemplo |
|-------|-------------|---------|
| **Servidor de IDs** | Host de tu servidor RustDesk (hbbs). Es lo único necesario para el estado online | `rustdesk.tudominio.com` |
| **Key RustDesk** | Clave pública de tu servidor (referencia) | `AbC123...=` |
| **URL / Usuario / Contraseña** | Datos de la API de administración. **Opcionales**: el Manager no los necesita | — |

3. Haz clic en **Guardar**

!!! success "Estado online"
    El Manager pregunta al servidor de IDs (puerto TCP 21115) qué equipos de tu agenda están conectados. No requiere credenciales de administrador y solo consulta los IDs que tú has añadido.

!!! warning "Cliente RustDesk"
    El Manager solo lanza el RustDesk instalado en tu equipo, que debe estar configurado con tu servidor y tu key (el instalador de `deployment/` lo hace por ti).

## Ajustes adicionales

### Idioma

Selecciona tu idioma preferido: Español, English o Français.

### Contraseña por defecto

Define una contraseña que se propondrá para los equipos nuevos.

### Intervalos

- **Estado**: la app refresca el estado online/offline cada 15 segundos

## ¿No tienes servidor?

Si aún no has montado tu servidor RustDesk, consulta la [Guía del servidor](../servidor/index.md) para instalarlo paso a paso.

## Siguiente paso

Continúa con el [Manual de uso](manual.md) para aprender a gestionar tus equipos.
