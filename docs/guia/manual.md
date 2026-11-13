# Manual de uso

## Pantalla principal

Al abrir la aplicación verás:

- **Barra lateral izquierda:** Categorías, grupos y búsqueda
- **Área principal:** Lista de equipos

## Vistas disponibles

Arriba a la derecha hay dos botones para cambiar la vista:

| Vista | Descripción |
|-------|-------------|
| **Cuadrícula** | Tarjetas grandes con toda la información |
| **Lista** | Filas compactas tipo tabla (ideal para muchos equipos) |

Tu preferencia se guarda automáticamente.

## Gestión de categorías

Las categorías agrupan varios grupos (ej: "Clientes", "Interno", "Externo").

### Crear categoría

1. Clic en el botón **+** junto a "CATEGORÍAS"
2. Introduce nombre y color
3. Clic en "Guardar"

### Editar/Eliminar categoría

- Usa los iconos de lápiz y papelera junto al nombre
- Al eliminar una categoría, sus grupos quedan sin categoría (no se eliminan)

## Gestión de grupos

Los grupos contienen equipos (ej: "Oficina Madrid", "Oficina Barcelona").

### Crear grupo

1. Clic en **+ Añadir grupo** dentro de una categoría
2. Introduce nombre, color y categoría
3. Clic en "Guardar"

### Editar/Eliminar grupo

- Usa los iconos de lápiz y papelera junto al nombre
- Al eliminar un grupo, sus equipos quedan sin grupo (no se eliminan)

## Gestión de equipos

### Tu agenda

La agenda empieza vacía y contiene únicamente los equipos que tú añades. La app no importa equipos del servidor, así que nadie ve equipos que no le corresponden.

### Añadir equipo manualmente

1. Clic en **"Nuevo Equipo"** (botón morado)
2. Rellena los campos:
   - **Nombre:** Identificador descriptivo
   - **ID de RustDesk:** El número de 9 dígitos
   - **Contraseña:** Contraseña de acceso (opcional)
   - **Grupo:** Selecciona un grupo
   - **Descripción:** Notas adicionales
   - **Color:** Color del icono
3. Clic en "Guardar"

!!! note "ID duplicado"
    Si el ID ya existe en "Sin clasificar", la app te avisará para que lo edites desde allí.

### Editar/Eliminar equipo

- Clic en los iconos de lápiz o papelera en la tarjeta/fila

## Conectar a un equipo

Cada equipo tiene dos botones de acción:

| Botón | Color | Función |
|-------|-------|---------|
| 📁 Carpeta | Azul | Abre **transferencia de archivos** |
| 🖥️ Pantalla | Verde | Abre **escritorio remoto** |

Al hacer clic, RustDesk se abrirá automáticamente con el ID y contraseña del equipo.

## Indicador de estado

Cada equipo tiene un indicador circular:

| Color | Significado |
|-------|-------------|
| 🟢 Verde | Online: el equipo está encendido, con RustDesk activo y conectado al servidor |
| ⚪ Gris | Offline: apagado, sin Internet o RustDesk cerrado |
| ◯ Círculo hueco | Desconocido: no se pudo consultar el servidor de IDs |

El estado se consulta al abrir la app y se actualiza cada 15 segundos.

## Filtrar equipos

### Por grupo

- Clic en un grupo en la barra lateral
- **Todos los equipos:** Ver todos
- **Sin clasificar:** Equipos nuevos sin grupo asignado
- **Sin grupo:** Equipos que tenían grupo pero fue eliminado

### Por búsqueda

- Escribe en el campo de búsqueda
- Busca por nombre, ID o descripción

## Ordenar equipos (vista lista)

Haz clic en las cabeceras de columna:

- **Nombre:** Orden alfabético
- **ID:** Por número de RustDesk
- **Grupo:** Por nombre de grupo

Clic de nuevo para invertir el orden. Las columnas son redimensionables.

## Tema claro/oscuro

Clic en el icono de luna/sol en la esquina superior derecha de la barra lateral.

## Import/Export

En **Ajustes > Importar/Exportar**:

| Acción | Descripción |
|--------|-------------|
| **Exportar** | Descarga un archivo JSON con toda la configuración y datos |
| **Importar** | Restaura desde un archivo de backup |
