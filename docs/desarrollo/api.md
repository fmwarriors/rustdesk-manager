# API REST

El servidor Express corre en `http://localhost:5050` cuando la app está en ejecución.

## Equipos

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/api/devices` | Lista todos los equipos |
| POST | `/api/devices` | Crear equipo |
| PUT | `/api/devices/:id` | Actualizar equipo |
| DELETE | `/api/devices/:id` | Eliminar equipo |
| POST | `/api/devices/:id/connect` | Conectar vía RustDesk |
| POST | `/api/devices/:id/transfer` | Abrir transferencia de archivos |

### Ejemplo: Crear equipo

```bash
curl -X POST http://localhost:5050/api/devices \
  -H "Content-Type: application/json" \
  -d '{
    "rustdesk_id": "123456789",
    "name": "Equipo de prueba",
    "password": "secreto",
    "group_id": 1
  }'
```

## Grupos

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/api/groups` | Lista grupos |
| POST | `/api/groups` | Crear grupo |
| PUT | `/api/groups/:id` | Actualizar grupo |
| DELETE | `/api/groups/:id` | Eliminar grupo |

## Categorías

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/api/categories` | Lista categorías |
| POST | `/api/categories` | Crear categoría |
| PUT | `/api/categories/:id` | Actualizar categoría |
| DELETE | `/api/categories/:id` | Eliminar categoría |

## Estado

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/api/status` | Estado de equipos (online/offline) |
| POST | `/api/status/refresh` | Consultar ahora al servidor de IDs (hbbs, puerto 21115) |

## Equipos sin clasificar

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/api/sync/pending` | Número de equipos sin grupo asignado |

## Configuración

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/api/config` | Obtener configuración |
| POST | `/api/config` | Guardar configuración |
| POST | `/api/config/test` | Probar conexión al servidor |

## Import/Export

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/api/export` | Exportar datos (JSON) |
| POST | `/api/import` | Importar datos (JSON) |
