# Configuración inicial

Después de instalar RustDesk Manager, configura el servidor de IDs para ver qué equipos están online.

## Pasos

1. Abre **Ajustes** (icono de engranaje en la esquina superior derecha)
2. En la sección **Servidor**, introduce:

| Campo | Descripción | Ejemplo |
|-------|-------------|---------|
| **Servidor de IDs** | Host de tu servidor RustDesk (hbbs). Es lo único necesario para el estado online | `rustdesk.tudominio.com` |
| **Key RustDesk** | Clave pública de tu servidor (referencia) | `AbC123...=` |
| **URL / Usuario / Contraseña** | Datos de la API de administración (servidor `rustdesk-api`). **Opcionales**, ver [más abajo](#servidor-api-opcional) | — |

3. Haz clic en **Guardar**

!!! success "Estado online"
    El Manager pregunta al servidor de IDs (puerto TCP 21115) qué equipos de tu agenda están conectados. No requiere credenciales de administrador y solo consulta los IDs que tú has añadido.

!!! warning "Cliente RustDesk"
    El Manager solo lanza el RustDesk instalado en tu equipo, que debe estar configurado con tu servidor y tu key (el instalador de `deployment/` lo hace por ti).

## Servidor API (opcional)

Los campos **URL del servidor**, **Usuario** y **Contraseña** corresponden al panel de administración del servidor (`rustdesk-api`, por ejemplo `https://rustdesk.tudominio.com:21443`).

- **Para qué sirven**: solo para el botón **Probar conexión**, que comprueba que el Manager llega a tu servidor y que las credenciales son válidas. El estado online y las conexiones **no** dependen de ellos.
- **Si montas tu propio servidor**: rellénalos con la URL de tu panel y un usuario de administración si quieres usar *Probar conexión*. Si no, déjalos vacíos.
- **Si eres cliente de otra persona** que te ha facilitado el servidor: déjalos **vacíos**. No necesitas credenciales de administración y no deberías tenerlas.

!!! danger "No pongas el «Servidor API» en el cliente RustDesk"
    Esta URL se rellena únicamente en el Manager. Configurarla en los ajustes de red del cliente RustDesk puede provocar el error «deadline has elapsed».

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
