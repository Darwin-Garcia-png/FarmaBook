```markdown
# 🔌 API Documentation – FarmaBook

## 🌐 Información General

### Base URL
- **Servidor Local:** `http://localhost:3000`

### Headers
```
Content-Type: application/json
Authorization: Bearer <jwt>
```

**Nota:** Todos los endpoints requieren Authorization, excepto `/auth/login`.

---

## 📡 Endpoints

---

### 🔐 Acceso

#### `POST /auth/login`
Autentica un usuario y genera un token JWT.

**Body:**
```json
{
  "username": "Dueño",
  "password": "Admin12345678"
}
```

**Nota sobre validez del token:** En cada petición autenticada se verifica que el usuario siga activo en la base de datos. Si la cuenta fue eliminada (soft delete), el token deja de ser válido y se responde `UNAUTHORIZED_ACCESS` (401) con mensaje `Cuenta deshabilitada`.

---

#### `POST /auth/restore`
Inicia el flujo de recuperación de contraseña. Genera un PIN de 6 dígitos, lo guarda en `password_resets` (firmado en un JWT con expiración de 5 minutos) y lo envía al email del usuario.

**Body:**
```json
{
  "username": "Dueño"
}
```

**Respuesta (200):**
```json
{
  "success": true,
  "message": "Mensaje enviado al correo exitosamente",
  "data": {}
}
```

**Errores:**
- Ninguno por usuario inexistente: por seguridad, si el `username` no existe (o está inactivo) la respuesta es la misma 200 sin enviar email. Esto evita enumeración de usuarios.

---

#### `POST /auth/restore-verify`
Verifica el PIN recibido por email contra el JWT almacenado. Si es válido y no ha expirado, retorna un **JWT especial de reset** (`purpose: 'password_reset'`, expira en 5 minutos) que solo sirve para `/auth/restore-password`.

**Body:**
```json
{
  "username": "Dueño",
  "pin": "482910"
}
```

**Respuesta (200):**
```json
{
  "success": true,
  "message": "PIN verificado exitosamente",
  "data": {
    "token": "<reset_jwt>"
  }
}
```

**Errores:**
- `401 INVALID_RESET` — PIN incorrecto, expirado o no existe solicitud previa.

---

#### `POST /auth/restore-password`
Cambia la contraseña del usuario identificado por el JWT de reset. Requiere el token retornado por `/auth/restore-verify` en el header `Authorization`. Tras el cambio, elimina la fila correspondiente en `password_resets`.

**Headers:**
```
Authorization: Bearer <reset_jwt>
```

**Body:**
```json
{
  "password": "Nueva12345"
}
```

Reglas de la nueva contraseña: 8–25 caracteres alfanuméricos, al menos una mayúscula y un número (mismas que `login`).

**Respuesta (200):**
```json
{
  "success": true,
  "message": "Contraseña actualizada exitosamente",
  "data": {}
}
```

**Errores:**
- `401 INVALID_TOKEN` — token ausente, manipulado, expirado, sin `purpose: 'password_reset'`, ya utilizado (one-shot), o si el usuario asociado fue eliminado tras la verificación.

---

### 📦 Inventario

#### `GET /inventory/search`
Búsqueda fuzzy de **productos activos** en el inventario. Usa la extensión `pg_trgm` de PostgreSQL y compara contra `nombre` y `descripcion`. Resultados ordenados por similitud descendente.

**Query params:**
- `query` (obligatorio): texto de búsqueda (2–50 caracteres).
- `limit` (opcional): máximo de resultados (1–100, default 20).

**Respuesta exitosa (ejemplo):**
```json
{
  "success": true,
  "message": "Se encontraron 2 coincidencia(s)",
  "data": [
    {
      "productoId": "uuid",
      "codigoBarras": "75000000001",
      "nombre": "Paracetamol 500mg",
      "precioPorUnidad": "1200.00",
      "descripcion": "Analgesico y antipiretico",
      "imagenUrl": "https...",
      "cantidadDisponible": 120
    }
  ]
}
```

Notas:
- Solo retorna productos con `activo = true` (los eliminados por soft delete quedan excluidos).
- `precioPorUnidad` se devuelve como string para preservar precisión decimal.
- `cantidadDisponible` es la suma del stock de todos los lotes del producto.
- Si no hay coincidencias, `data` es `[]` y el `message` lo indica.

**Códigos de error:**
- `VALIDATION_ERROR` (400): `query` faltante/corto/largo, o `limit` fuera de rango.

---

### 💊 Productos

#### `GET /inventory/products`
Obtiene todos los productos **activos** con paginación. Pensado para listados: devuelve solo los campos relevantes para mostrar. Para el detalle completo (incluyendo casas, proveedores, dosis, temperaturas, etc.), usar `GET /inventory/products/:identificador`.

**Query params:**
- `categoriaId`: UUID de la categoría (opcional)
- `presentacionId`: UUID de la presentación (opcional)
- `proveedorId`: UUID del proveedor (opcional)
- `casaId`: UUID de la casa (opcional)
- `page`: Número de página (opcional, default: 1)
- `limit`: Cantidad de resultados por página (opcional, default: 20)

**Respuesta exitosa (ejemplo):**
```json
{
  "success": true,
  "message": "Todos los productos devueltos correctamente",
  "data": [
    {
      "productoId": "uuid",
      "codigoBarras": "75000000001",
      "nombre": "Paracetamol 500mg",
      "precioPorUnidad": "1200.00",
      "descripcion": "Analgésico y antipirético",
      "imagenUrl": "https...",
      "cantidadDisponible": 100
    }
  ],
  "pagination": {
    "total": 50,
    "page": 1,
    "limit": 20,
    "totalPages": 3
  }
}
```

Notas:
- `precioPorUnidad` se devuelve como string para preservar precisión decimal.
- `casasId`/`proveedoresId` **no** se incluyen en el listado; consultar el endpoint de detalle si se necesitan.

**Códigos de error:**
- `CATEGORY_NOT_FOUND` (404): Categoría no encontrada
- `PRESENTATION_NOT_FOUND` (404): Presentación no encontrada
- `SUPPLIER_NOT_FOUND` (404): Proveedor no encontrado
- `HOUSE_NOT_FOUND` (404): Casa no encontrada
- `PAGE_NOT_FOUND` (404): Página solicitada no existe
- `VALIDATION_ERROR` (400): Error de validación

---

#### `GET /inventory/products/:identificador`
Obtiene un producto **activo** por su identificador (UUID o código de barras), con detalle completo.

**Path params:**
- `identificador`: Código de barras o UUID del producto

**Respuesta exitosa (ejemplo):**
```json
{
  "success": true,
  "message": "Producto devuelto correctamente",
  "data": {
    "productoId": "uuid",
    "codigoBarras": "75000000001",
    "nombre": "Paracetamol 500mg",
    "nombreGenerico": "Paracetamol",
    "concentracion": "500mg",
    "descripcion": "Analgésico y antipirético",
    "precioPorUnidad": "1200.00",
    "dosisRecomendada": "1 tableta cada 6-8 horas",
    "tempMin": "15.00",
    "tempMax": "25.00",
    "categoriaId": "uuid",
    "presentacionId": "uuid",
    "imagenUrl": "https...",
    "cantidadDisponible": 100,
    "casasId": ["uuid"],
    "proveedoresId": ["uuid"]
  }
}
```

Notas:
- `precioPorUnidad`, `tempMin` y `tempMax` se devuelven como string para preservar precisión decimal.
- Los productos eliminados (soft delete) no se exponen.

**Códigos de error:**
- `PRODUCT_NOT_FOUND` (404): Producto no encontrado o inactivo
- `VALIDATION_ERROR` (400): Identificador inválido

---

#### `POST /inventory/products`
Crea un nuevo producto. Solo accesible para rol `Dueño`.

**Content-Type:** `multipart/form-data`

| Campo    | Tipo | Requerido | Descripción |
|----------|------|-----------|-------------|
| `data`   | Text | Sí        | JSON con los campos del producto (ver más abajo) |
| `imagen` | File | No        | Imagen del producto (`image/png`, `image/jpeg`, `image/webp`, máx. 5MB). Se sube a S3 y la URL pública se guarda en `imagenUrl`. |

**Contenido del campo `data` (JSON):**
```json
{
  "codigoBarras": "75000000001",
  "nombre": "Paracetamol 500mg",
  "nombreGenerico": "Paracetamol",
  "concentracion": "500mg",
  "descripcion": "Analgésico y antipirético",
  "precioPorUnidad": 2.50,
  "dosisRecomendada": "500mg cada 6 horas",
  "tempMin": 15,
  "tempMax": 25,
  "proveedores": [
    { "proveedorId": "uuid-v4", "costo": 1500.00 },
    { "proveedorId": "uuid-v4", "costo": 1800.50 }
  ],
  "categoriaId": "uuid-v4",
  "presentacionId": "uuid-v4",
  "casas": ["uuid-v4", "uuid-v4"]
}
```

Campos obligatorios:
- `codigoBarras`: 8–14 dígitos.
- `nombre`, `nombreGenerico`, `concentracion`: strings.
- `precioPorUnidad`: número > 0.
- `categoriaId`, `presentacionId`: UUID v4 existentes.
- `proveedores`: arreglo de `{ proveedorId, costo }` (mínimo 1, sin duplicados; `costo` > 0).
- `casas`: arreglo de UUIDs (mínimo 1, sin duplicados).

Campos opcionales:
- `descripcion`, `dosisRecomendada`.
- `tempMin` y `tempMax`: si se envía uno, el otro es obligatorio. `tempMin < tempMax`.

**Códigos de error:**
- `PRODUCT_ALREADY_EXISTS` (409): Producto ya existe
- `BARCODE_ALREADY_EXISTS` (409): Código de barras ya existe
- `CATEGORY_NOT_FOUND` (404): Categoría no encontrada
- `PRESENTATION_NOT_FOUND` (404): Presentación no encontrada
- `SUPPLIER_NOT_FOUND` (404): Uno o más proveedores no existen (devuelve `missingFields` con las uuids inválidas)
- `HOUSE_NOT_FOUND` (404): Una o más casas no existen (devuelve `missingFields` con las uuids inválidas)
- `INVALID_IMAGE_FORMAT` (400): Formato de imagen no soportado
- `IMAGE_TOO_LARGE` (400): La imagen excede 5MB
- `VALIDATION_ERROR` (400): Error de validación

---

#### `PATCH /inventory/products/:id`
Modifica un producto **activo**. Solo accesible para rol `Dueño`.

**Path params:**
- `id`: UUID del producto

**Content-Type:** `multipart/form-data`

| Campo    | Tipo | Requerido | Descripción |
|----------|------|-----------|-------------|
| `data`   | Text | No        | JSON parcial con los campos a modificar |
| `imagen` | File | No        | Nueva imagen (`image/png`, `image/jpeg`, `image/webp`, máx. 5MB). Reemplaza la anterior en S3. |

Debe enviarse al menos uno de los dos (`data` o `imagen`).

**Contenido del campo `data` (JSON, ejemplo):**
```json
{
  "nombre": "<nuevo_nombre>",
  "descripcion": "<nueva_descripcion>"
}
```

Campos modificables vía `data`: `codigoBarras`, `nombre`, `nombreGenerico`, `concentracion`, `descripcion`, `precioPorUnidad`, `dosisRecomendada`, `tempMin`, `tempMax`, `categoriaId`, `presentacionId`. La `imagenUrl` se actualiza únicamente subiendo el archivo `imagen`.

**Respuesta:** retorna el detalle completo del producto, en el mismo formato que `GET /inventory/products/:identificador`.

**Códigos de error:**
- `PRODUCT_NOT_FOUND` (404): Producto no encontrado o inactivo (no se permite actualizar productos eliminados)
- `BARCODE_ALREADY_EXISTS` (409): Código de barras ya existe
- `PRODUCT_ALREADY_EXISTS` (409): Combinación (nombre, categoría, presentación, concentración) ya existe
- `CATEGORY_NOT_FOUND` / `PRESENTATION_NOT_FOUND` (404): FK inválida
- `INVALID_IMAGE_FORMAT` (400): Formato de imagen no soportado
- `IMAGE_TOO_LARGE` (400): La imagen excede 5MB
- `VALIDATION_ERROR` (400): Error de validación

---

#### `DELETE /inventory/products/:id`
Elimina un producto (soft delete).

**Path params:**
- `id`: UUID del producto

**Códigos de error:**
- `PRODUCT_NOT_FOUND` (404): Producto no encontrado

---

#### `GET /inventory/products/:id/batches`
Obtiene los lotes de un producto.

**Path params:**
- `id`: UUID del producto

**Códigos de error:**
- `PRODUCT_NOT_FOUND` (404): Producto no encontrado
- `VALIDATION_ERROR` (400): ID inválido

---

#### `GET /inventory/products/:id/suppliers`
Obtiene todos los proveedores de un producto, incluyendo el `costo` de compra para cada uno.

**Path params:**
- `id`: UUID del producto

**Respuesta exitosa (ejemplo):**
```json
{
  "success": true,
  "data": [
    {
      "proveedorId": "uuid",
      "nombre": "Farmacias del Ahorro",
      "telefono": "3001234567",
      "email": "contacto@farmaciasdelahorro.com",
      "costo": "1500.00"
    }
  ]
}
```

Nota: `costo` se devuelve como string para preservar precisión decimal.

**Códigos de error:**
- `PRODUCT_NOT_FOUND` (404): Producto no encontrado

---

#### `POST /inventory/products/:id/suppliers`
Agrega un proveedor a un producto. Solo accesible para rol `Dueño`. Retorna **201** si se crea la asociación.

**Path params:**
- `id`: UUID del producto

**Body:**
```json
{
  "proveedorId": "uuid",
  "costo": 1500.00
}
```

`costo` es obligatorio (> 0): costo de compra del producto a ese proveedor.

**Códigos de error:**
- `PRODUCT_NOT_FOUND` (404): Producto no encontrado
- `SUPPLIER_NOT_FOUND` (404): Proveedor no encontrado
- `SUPPLIER_ALREADY_EXISTS` (409): Proveedor ya asociado al producto
- `VALIDATION_ERROR` (400): Error de validación

---

#### `DELETE /inventory/products/:id/suppliers/:supplierId`
Desasocia un proveedor de un producto.

**Path params:**
- `id`: UUID del producto
- `supplierId`: UUID del proveedor

**Códigos de error:**
- `SUPPLIER_NOT_ASSOCIATED` (404): Proveedor no está vinculado al producto
- `LAST_SUPPLIER` (409): No se puede eliminar el último proveedor del producto

---

#### `GET /inventory/products/:id/houses`
Obtiene las casas farmacéuticas asociadas a un producto.

**Path params:**
- `id`: UUID del producto

**Códigos de error:**
- `PRODUCT_NOT_FOUND` (404): Producto no encontrado

---

#### `POST /inventory/products/:id/houses`
Agrega una casa farmacéutica a un producto. Solo accesible para rol `Dueño`. Retorna **201** si se crea la asociación.

**Path params:**
- `id`: UUID del producto

**Body:**
```json
{
  "casaId": "uuid"
}
```

**Códigos de error:**
- `PRODUCT_NOT_FOUND` (404): Producto no encontrado
- `HOUSE_NOT_FOUND` (404): Casa no encontrada
- `HOUSE_ALREADY_EXISTS` (409): Casa ya asociada al producto
- `VALIDATION_ERROR` (400): Error de validación

---

#### `DELETE /inventory/products/:id/houses/:houseId`
Desasocia una casa farmacéutica de un producto.

**Path params:**
- `id`: UUID del producto
- `houseId`: UUID de la casa

**Códigos de error:**
- `HOUSE_NOT_ASSOCIATED` (404): Casa no está vinculada al producto
- `LAST_HOUSE` (409): No se puede eliminar la última casa del producto

---

### 🗂️ Categorías

#### `GET /inventory/categories`
Obtiene todas las categorías **activas** con paginación.

**Query params:**
- `page`: Número de página (opcional, default: 1)
- `limit`: Cantidad de resultados por página (opcional, default: 20)

**Respuesta exitosa (ejemplo):**
```json
{
  "success": true,
  "message": "Todas las categorías devueltas correctamente",
  "data": [
    {
      "categoriaId": "uuid",
      "nombre": "Analgesicos",
      "descripcion": "Medicamentos para aliviar el dolor",
      "createdAt": "2026-03-07T15:37:12.974Z"
    }
  ],
  "pagination": {
    "total": 18,
    "page": 1,
    "limit": 20,
    "totalPages": 1
  }
}
```

Nota: las categorías eliminadas (soft delete) no se incluyen ni en `data` ni en `total`. El campo `activo` no se expone.

**Códigos de error:**
- `PAGE_NOT_FOUND` (404): Página solicitada no existe

---

#### `GET /inventory/categories/exists?name=<nombre>`
Verifica si **el nombre está ocupado** en la tabla. Devuelve `true` incluso cuando la categoría que lo lleva está inactiva (soft delete), porque el constraint UNIQUE global impide reutilizarlo. Útil antes de un POST para anticipar conflictos.

**Query params:**
- `name`: Nombre de la categoría

**Respuesta exitosa (ejemplo):**
```json
{
  "success": true,
  "message": "Resultado devuelto correctamente",
  "data": { "exists": true }
}
```

---

#### `GET /inventory/categories/:identificador`
Obtiene una categoría **activa** por su identificador (UUID o nombre).

**Códigos de error:**
- `CATEGORY_NOT_FOUND` (404): Categoría no encontrada o inactiva

---

#### `POST /inventory/categories`
Crea una nueva categoría. Solo accesible para rol `Dueño`.

**Body:**
```json
{
  "nombre": "Analgésicos",
  "descripcion": "Medicamentos para alivio del dolor"
}
```

**Códigos de error:**
- `CATEGORY_ALREADY_EXISTS` (409): Nombre ya existe. Si la categoría con ese nombre está inactiva, el `message` lo indica explícitamente (`Existe una categoría inactiva con ese nombre`).
- `VALIDATION_ERROR` (400): Error de validación

---

#### `PATCH /inventory/categories/:id`
Modifica una categoría **activa** (envía solo los atributos a modificar). Solo accesible para rol `Dueño`.

**Path params:**
- `id`: UUID de la categoría

**Body (ejemplo):**
```json
{
  "nombre": "<nuevo_nombre>",
  "descripcion": "<nueva_descripcion>"
}
```

**Códigos de error:**
- `CATEGORY_NOT_FOUND` (404): Categoría no encontrada o inactiva (no se permite actualizar categorías eliminadas)
- `CATEGORY_ALREADY_EXISTS` (409): Nombre ya existe (puede provenir de una categoría inactiva; el mensaje lo indica)
- `VALIDATION_ERROR` (400): Error de validación

---

#### `DELETE /inventory/categories/:id`
Elimina una categoría (soft delete). Solo accesible para rol `Dueño`.

**Path params:**
- `id`: UUID de la categoría

**Códigos de error:**
- `CATEGORY_NOT_FOUND` (404): Categoría no encontrada o ya inactiva
- `CATEGORY_HAS_ASSOCIATED_PRODUCTS` (409): La categoría tiene productos activos asociados

---

### 📦 Presentaciones

#### `GET /inventory/presentations`
Obtiene todas las presentaciones **activas** con paginación.

**Query params:**
- `page`: Número de página (opcional, default: 1)
- `limit`: Cantidad de resultados por página (opcional, default: 20)

**Respuesta exitosa (ejemplo):**
```json
{
  "success": true,
  "message": "Todas las presentaciones devueltas correctamente",
  "data": [
    {
      "presentacionId": "uuid",
      "nombre": "Tabletas",
      "descripcion": "Comprimidos sólidos para administración oral",
      "createdAt": "2026-03-07T15:37:12.974Z"
    }
  ],
  "pagination": {
    "total": 12,
    "page": 1,
    "limit": 20,
    "totalPages": 1
  }
}
```

Nota: las presentaciones eliminadas (soft delete) no se incluyen ni en `data` ni en `total`. El campo `activo` no se expone.

**Códigos de error:**
- `PAGE_NOT_FOUND` (404): Página solicitada no existe

---

#### `GET /inventory/presentations/exists?name=<nombre>`
Verifica si **el nombre está ocupado** en la tabla. Devuelve `true` incluso cuando la presentación que lo lleva está inactiva (soft delete), porque el constraint UNIQUE global impide reutilizarlo. Útil antes de un POST para anticipar conflictos.

**Query params:**
- `name`: Nombre de la presentación

**Respuesta exitosa (ejemplo):**
```json
{
  "success": true,
  "message": "Resultado devuelto correctamente",
  "data": { "exists": true }
}
```

---

#### `GET /inventory/presentations/:identificador`
Obtiene una presentación **activa** por su identificador (UUID o nombre).

**Códigos de error:**
- `PRESENTATION_NOT_FOUND` (404): Presentación no encontrada o inactiva

---

#### `POST /inventory/presentations`
Crea una nueva presentación. Solo accesible para rol `Dueño`.

**Body:**
```json
{
  "nombre": "Tabletas",
  "descripcion": "Presentación en tabletas"
}
```

**Códigos de error:**
- `PRESENTATION_ALREADY_EXISTS` (409): Nombre ya existe. Si la presentación con ese nombre está inactiva, el `message` lo indica explícitamente (`Existe una presentación inactiva con ese nombre`).
- `VALIDATION_ERROR` (400): Error de validación

---

#### `PATCH /inventory/presentations/:id`
Modifica una presentación **activa** (envía solo los atributos a modificar). Solo accesible para rol `Dueño`.

**Path params:**
- `id`: UUID de la presentación

**Body (ejemplo):**
```json
{
  "nombre": "<nuevo_nombre>",
  "descripcion": "<nueva_descripcion>"
}
```

**Códigos de error:**
- `PRESENTATION_NOT_FOUND` (404): Presentación no encontrada o inactiva (no se permite actualizar presentaciones eliminadas)
- `PRESENTATION_ALREADY_EXISTS` (409): Nombre ya existe (puede provenir de una presentación inactiva; el mensaje lo indica)
- `VALIDATION_ERROR` (400): Error de validación

---

#### `DELETE /inventory/presentations/:id`
Elimina una presentación (soft delete). Solo accesible para rol `Dueño`.

**Path params:**
- `id`: UUID de la presentación

**Códigos de error:**
- `PRESENTATION_NOT_FOUND` (404): Presentación no encontrada o ya inactiva
- `PRESENTATION_HAS_ASSOCIATED_PRODUCTS` (409): La presentación tiene productos activos asociados

---

### 🏛️ Casas

Casas farmacéuticas que distribuyen los productos (p. ej. Genfar, Bayer). Relación N:N con productos.

#### `GET /inventory/houses`
Obtiene todas las casas **activas** con paginación.

**Query params:**
- `page`: Número de página (opcional, default: 1)
- `limit`: Cantidad de resultados por página (opcional, default: 20)

**Respuesta exitosa (ejemplo):**
```json
{
  "success": true,
  "message": "Todas las casas devueltas correctamente",
  "data": [
    {
      "casaId": "uuid",
      "nombre": "Genfar",
      "paisDeOrigen": "Colombia",
      "createdAt": "2026-03-07T15:37:12.974Z"
    }
  ],
  "pagination": {
    "total": 3,
    "page": 1,
    "limit": 20,
    "totalPages": 1
  }
}
```

Nota: las casas eliminadas (soft delete) no se incluyen ni en `data` ni en `total`. El campo `activo` no se expone.

**Códigos de error:**
- `PAGE_NOT_FOUND` (404): Página solicitada no existe

---

#### `GET /inventory/houses/exists?name=<nombre>`
Verifica si **el nombre está ocupado** en la tabla. Devuelve `true` incluso cuando la casa que lo lleva está inactiva (soft delete), porque el constraint UNIQUE global impide reutilizarlo. Útil antes de un POST para anticipar conflictos.

**Query params:**
- `name`: Nombre de la casa

---

#### `GET /inventory/houses/:identificador`
Obtiene una casa **activa** por su identificador (UUID o nombre).

**Códigos de error:**
- `HOUSE_NOT_FOUND` (404): Casa no encontrada o inactiva

---

#### `POST /inventory/houses`
Crea una nueva casa. Solo accesible para rol `Dueño`.

**Body:**
```json
{
  "nombre": "Genfar",
  "paisDeOrigen": "Colombia"
}
```

**Códigos de error:**
- `HOUSE_ALREADY_EXISTS` (409): Nombre ya existe. Si la casa con ese nombre está inactiva, el `message` lo indica explícitamente (`Existe una casa inactiva con ese nombre`).
- `VALIDATION_ERROR` (400): Error de validación

---

#### `PATCH /inventory/houses/:id`
Modifica una casa **activa** (envía solo los atributos a modificar). Solo accesible para rol `Dueño`.

**Path params:**
- `id`: UUID de la casa

**Body (ejemplo):**
```json
{
  "nombre": "<nuevo_nombre>",
  "paisDeOrigen": "<nuevo_pais>"
}
```

**Códigos de error:**
- `HOUSE_NOT_FOUND` (404): Casa no encontrada o inactiva (no se permite actualizar casas eliminadas)
- `HOUSE_ALREADY_EXISTS` (409): Nombre ya existe (puede provenir de una casa inactiva)
- `VALIDATION_ERROR` (400): Error de validación

---

#### `DELETE /inventory/houses/:id`
Elimina una casa (soft delete). Bloquea si tiene productos **activos** asociados (las asociaciones con productos eliminados no impiden el borrado). Solo accesible para rol `Dueño`.

**Path params:**
- `id`: UUID de la casa

**Códigos de error:**
- `HOUSE_NOT_FOUND` (404): Casa no encontrada o ya inactiva
- `HOUSE_HAS_ASSOCIATED_PRODUCTS` (409): La casa tiene productos activos asociados

---

#### `GET /inventory/houses/:id/suppliers`
Lista los proveedores que distribuyen productos de la casa (derivado vía `productoCasas` ⨝ `productoProveedores`).

**Path params:**
- `id`: UUID de la casa

**Respuesta exitosa (ejemplo):**
```json
{
  "success": true,
  "message": "Proveedores de la casa obtenidos correctamente",
  "data": [
    {
      "proveedorId": "uuid",
      "nombre": "Farmacias del Ahorro",
      "telefono": "3001234567",
      "email": "contacto@farmaciasdelahorro.com"
    }
  ]
}
```

**Códigos de error:**
- `HOUSE_NOT_FOUND` (404): Casa no encontrada
- `VALIDATION_ERROR` (400): UUID inválido

---

#### `GET /inventory/houses/:id/products`
Lista los productos asociados a la casa.

**Path params:**
- `id`: UUID de la casa

**Respuesta exitosa (ejemplo):**
```json
{
  "success": true,
  "message": "Productos de la casa obtenidos correctamente",
  "data": [
    {
      "productoId": "uuid",
      "codigoBarras": "7501234567890",
      "nombre": "Paracetamol 500mg",
      "descripcion": "...",
      "precioPorUnidad": "1200.00",
      "categoriaId": "uuid",
      "presentacionId": "uuid"
    }
  ]
}
```

Nota: solo se incluyen productos activos. El campo `activo` no se expone.

**Códigos de error:**
- `HOUSE_NOT_FOUND` (404): Casa no encontrada o inactiva
- `VALIDATION_ERROR` (400): UUID inválido

---

### 🚚 Proveedores

#### `GET /inventory/suppliers`
Obtiene todos los proveedores **activos** con paginación.

**Query params:**
- `page`: Número de página (opcional, default: 1)
- `limit`: Cantidad de resultados por página (opcional, default: 20)

**Respuesta exitosa (ejemplo):**
```json
{
  "success": true,
  "message": "Todos los proveedores devueltos correctamente",
  "data": [
    {
      "proveedorId": "uuid",
      "nombre": "Farmacias del Ahorro",
      "direccion": "Av. Principal 123",
      "telefono": "3001234567",
      "email": "contacto@farmaciasdelahorro.com",
      "createdAt": "2026-03-07T15:37:12.974Z"
    }
  ],
  "pagination": {
    "total": 7,
    "page": 1,
    "limit": 20,
    "totalPages": 1
  }
}
```

Nota: los proveedores eliminados (soft delete) no se incluyen ni en `data` ni en `total`. El campo `activo` no se expone.

**Códigos de error:**
- `PAGE_NOT_FOUND` (404): Página solicitada no existe

---

#### `GET /inventory/suppliers/exists?name=<nombre>`
Verifica si **el nombre está ocupado** en la tabla. Devuelve `true` incluso cuando el proveedor que lo lleva está inactivo (soft delete), porque el constraint UNIQUE global impide reutilizarlo. Útil antes de un POST para anticipar conflictos.

**Query params:**
- `name`: Nombre del proveedor

---

#### `GET /inventory/suppliers/exists?email=<email>`
Verifica si **el email está ocupado** en la tabla. Devuelve `true` incluso cuando el proveedor que lo lleva está inactivo. Mismo comportamiento que la variante por nombre.

**Query params:**
- `email`: Email del proveedor

Nota: `name` y `email` son mutuamente excluyentes (xor). Enviar ambos o ninguno → `VALIDATION_ERROR`.

---

#### `GET /inventory/suppliers/:identificador`
Obtiene un proveedor **activo** por su identificador (UUID o nombre).

**Códigos de error:**
- `SUPPLIER_NOT_FOUND` (404): Proveedor no encontrado o inactivo

---

#### `POST /inventory/suppliers`
Crea un nuevo proveedor. Solo accesible para rol `Dueño`.

**Body:**
```json
{
  "nombre": "Farmacéutica XYZ",
  "direccion": "Calle 123 #45-67",
  "telefono": "3001234567",
  "email": "contacto@farmaxyz.com"
}
```

**Códigos de error:**
- `SUPPLIER_ALREADY_EXISTS` (409): Nombre ya existe. Si el proveedor con ese nombre está inactivo, el `message` lo indica explícitamente (`Existe un proveedor inactivo con ese nombre`).
- `SUPPLIER_EMAIL_ALREADY_EXISTS` (409): Email ya existe. Si el proveedor con ese email está inactivo, el `message` lo indica explícitamente (`Existe un proveedor inactivo con ese email`).
- `VALIDATION_ERROR` (400): Error de validación

---

#### `PATCH /inventory/suppliers/:id`
Modifica un proveedor **activo** (envía solo los atributos a modificar). Solo accesible para rol `Dueño`.

**Path params:**
- `id`: UUID del proveedor

**Body (ejemplo):**
```json
{
  "nombre": "<nuevo_nombre>",
  "direccion": "<nueva_direccion>"
}
```

**Códigos de error:**
- `SUPPLIER_NOT_FOUND` (404): Proveedor no encontrado o inactivo (no se permite actualizar proveedores eliminados)
- `SUPPLIER_ALREADY_EXISTS` (409): Nombre ya existe (puede provenir de un proveedor inactivo)
- `SUPPLIER_EMAIL_ALREADY_EXISTS` (409): Email ya existe (puede provenir de un proveedor inactivo)
- `VALIDATION_ERROR` (400): Error de validación

---

#### `DELETE /inventory/suppliers/:id`
Elimina un proveedor (soft delete). Solo accesible para rol `Dueño`.

**Path params:**
- `id`: UUID del proveedor

**Códigos de error:**
- `SUPPLIER_NOT_FOUND` (404): Proveedor no encontrado o ya inactivo
- `SUPPLIER_HAS_ASSOCIATED_PRODUCTS` (409): El proveedor tiene productos activos asociados

---

#### `GET /inventory/suppliers/:id/product-houses`
Lista las casas cuyos productos son distribuidos por el proveedor (derivado vía `productoProveedores` ⨝ `productoCasas`).

**Path params:**
- `id`: UUID del proveedor

**Respuesta exitosa (ejemplo):**
```json
{
  "success": true,
  "message": "Casas del proveedor obtenidas correctamente",
  "data": [
    {
      "casaId": "uuid",
      "nombre": "Genfar",
      "paisDeOrigen": "Colombia"
    }
  ]
}
```

**Códigos de error:**
- `SUPPLIER_NOT_FOUND` (404): Proveedor no encontrado
- `VALIDATION_ERROR` (400): UUID inválido

**Códigos de error:**
- `SUPPLIER_NOT_FOUND` (404): Proveedor no encontrado
- `SUPPLIER_HAS_ASSOCIATED_PRODUCTS` (409): El proveedor tiene productos asociados

---

### 📦 Lotes

Los lotes representan inventario físico atómico y no admiten borrado (ni lógico ni duro) para preservar trazabilidad e historial. No expone `/exists` porque la unicidad relevante es la tupla `(productoId, fechaDeVencimiento)`, gestionada por la constraint UNIQUE.

#### `GET /inventory/batches`
Lista lotes con filtros opcionales y paginación.

**Query params:**
- `page`: Número de página (requerido junto con `limit`)
- `limit`: Cantidad de resultados por página (requerido junto con `page`)
- `productoId` (opcional): UUID del producto. Filtra los lotes de ese producto.
- `vencidosAntes` (opcional): ISO date. Filtra lotes con `fechaDeVencimiento <= vencidosAntes`.
- `vencidosDespues` (opcional): ISO date. Filtra lotes con `fechaDeVencimiento >= vencidosDespues`.

Combina `vencidosAntes` y `vencidosDespues` para obtener un rango. Los resultados se ordenan por `fechaDeVencimiento` ascendente (los más próximos a vencer primero).

**Respuesta exitosa (ejemplo):**
```json
{
  "success": true,
  "message": "Todos los lotes devueltos correctamente",
  "data": [
    {
      "loteId": "uuid",
      "productoId": "uuid",
      "nombreLote": "LOTE-2025-001",
      "fechaDeVencimiento": "2027-06-30T00:00:00.000Z",
      "cantidadDisponible": 100,
      "costoDeCompra": "350000.00",
      "createdAt": "2026-03-07T15:37:12.974Z"
    }
  ],
  "pagination": {
    "total": 42,
    "page": 1,
    "limit": 20,
    "totalPages": 3
  }
}
```

Nota: `costoDeCompra` se devuelve como string para preservar precisión decimal. `cantidadDisponible` es entero.

**Códigos de error:**
- `PAGE_NOT_FOUND` (404): Página solicitada no existe
- `VALIDATION_ERROR` (400): Filtro desconocido o tipo inválido

---

#### `GET /inventory/batches/:id`
Obtiene un lote por su UUID.

**Path params:**
- `id`: UUID del lote

**Códigos de error:**
- `BATCH_NOT_FOUND` (404): Lote no encontrado
- `VALIDATION_ERROR` (400): ID inválido

---

#### `POST /inventory/batches`
Crea un nuevo lote. Solo accesible para rol `Dueño`.

**Body:**
```json
{
  "productoId": "uuid-v4",
  "nombreLote": "LOTE-2025-001",
  "fechaDeVencimiento": "2027-06-30T00:00:00.000Z",
  "cantidadDisponible": 100,
  "costoDeCompra": 350000
}
```

**Códigos de error:**
- `PRODUCT_NOT_FOUND` (404): Producto no encontrado
- `BATCH_ALREADY_EXISTS` (409): Ya existe un lote con ese producto y fecha
- `VALIDATION_ERROR` (400): Error de validación

---

#### `PATCH /inventory/batches/:id`
Modifica un lote existente (envía solo los atributos a modificar). Solo accesible para rol `Dueño`.
**Nota:** No se permite modificar `fechaDeVencimiento`, `productoId` ni `costoDeCompra`.

**Path params:**
- `id`: UUID del lote

**Body (ejemplo):**
```json
{
  "nombreLote": "<nuevo_nombre>",
  "cantidadDisponible": 200
}
```

**Códigos de error:**
- `BATCH_NOT_FOUND` (404): Lote no encontrado
- `VALIDATION_ERROR` (400): Error de validación

---

### 💰 Ventas

#### `POST /sales`
Crea una nueva venta y descuenta el stock de los lotes correspondientes.

**Body:**
```json
{
  "saleData": [
    { "codigoProducto": "75000000001", "cantidad": 1 },
    { "codigoProducto": "75000000004", "cantidad": 2 }
  ],
  "clienteId": "1234567890"
}
```

`clienteId` es obligatorio (cédula/identificación del cliente, solo dígitos, hasta 15 caracteres). Si en `saleData` aparece el mismo `codigoProducto` más de una vez, las cantidades se suman antes de descontar stock (se inserta una única fila en el detalle).

**Respuesta exitosa (ejemplo):**
```json
{
  "success": true,
  "message": "Venta realizada correctamente",
  "data": {
    "ventaId": "uuid",
    "numeroFactura": 42,
    "clienteId": "1234567890",
    "total": "11.50",
    "activo": true,
    "fechaDeVenta": "2026-03-07T16:13:00.000Z",
    "productosVendidos": [
      {
        "productoId": "uuid",
        "nombre": "Paracetamol 500mg",
        "cantidadDeUnidades": 1,
        "subTotal": "2.50"
      }
    ]
  }
}
```

El campo `numeroFactura` es un entero autoincremental único asignado por la base de datos al crear la venta. El campo `activo` indica si la venta sigue vigente (`true`) o fue anulada (`false`).

**Códigos de error:**
- `PRODUCT_NOT_FOUND` (404): Producto no encontrado
- `OUT_OF_STOCK` (409): Stock insuficiente
- `VALIDATION_ERROR` (400): Error de validación

---

#### `GET /sales`
Obtiene el historial de ventas con paginación y filtros opcionales. Se ordena por `fechaDeVenta` descendente (lo más reciente primero).

**Query params:**
- `productoId` (opcional): UUID del producto
- `categoriaId` (opcional): UUID de categoría
- `presentacionId` (opcional): UUID de presentación
- `proveedorId` (opcional): UUID de proveedor
- `fechaInicio` (opcional): ISO 8601
- `fechaFin` (opcional): ISO 8601 (requiere `fechaInicio` y debe ser ≥ `fechaInicio`)
- `page` (requerido junto con `limit`): Número de página
- `limit` (requerido junto con `page`): Cantidad de resultados por página

Los importes monetarios (`total`, `subTotal`) se devuelven como strings para preservar precisión decimal.

**Respuesta exitosa (ejemplo):**
```json
{
  "success": true,
  "message": "Todas las ventas devueltas correctamente",
  "data": [
    {
      "ventaId": "uuid",
      "numeroFactura": 42,
      "clienteId": "1234567890",
      "total": "11.50",
      "activo": true,
      "fechaDeVenta": "2026-03-07T16:13:00.000Z",
      "productosVendidos": [
        {
          "productoId": "uuid",
          "nombre": "Paracetamol 500mg",
          "cantidadDeUnidades": 1,
          "subTotal": "2.50"
        }
      ]
    }
  ],
  "pagination": {
    "total": 10,
    "page": 1,
    "limit": 20,
    "totalPages": 1
  }
}
```

**Códigos de error:**
- `VALIDATION_ERROR` (400): Error de validación en filtros

---

#### `GET /sales/:id`
Obtiene una venta por su UUID.

**Path params:**
- `id`: UUID de la venta

**Respuesta exitosa (ejemplo):**
```json
{
  "success": true,
  "message": "Venta obtenida correctamente",
  "data": {
    "ventaId": "uuid",
    "numeroFactura": 42,
    "clienteId": "1234567890",
    "total": "11.50",
    "activo": true,
    "fechaDeVenta": "2026-03-07T16:13:00.000Z",
    "productosVendidos": [
      {
        "productoId": "uuid",
        "nombre": "Paracetamol 500mg",
        "cantidadDeUnidades": 1,
        "subTotal": "2.50"
      }
    ]
  }
}
```

**Códigos de error:**
- `SALE_NOT_FOUND` (404): Venta no encontrada
- `VALIDATION_ERROR` (400): ID inválido

---

#### `DELETE /sales/:id`
Anula una venta y restaura el stock exacto a los lotes que originalmente fueron consumidos (gracias al rastreo por detalle/lote registrado al crear la venta). La venta no se borra: queda marcada con `activo: false` para preservar trazabilidad e historial.

**Path params:**
- `id`: UUID de la venta

**Respuesta exitosa (ejemplo):**
```json
{
  "success": true,
  "message": "Venta anulada correctamente",
  "data": {
    "ventaId": "uuid",
    "numeroFactura": 42,
    "clienteId": "1234567890",
    "total": "11.50",
    "activo": false,
    "fechaDeVenta": "2026-03-07T16:13:00.000Z",
    "productosVendidos": [ /* ... */ ]
  }
}
```

**Códigos de error:**
- `SALE_NOT_FOUND` (404): Venta no encontrada
- `SALE_ALREADY_CANCELLED` (409): La venta ya estaba anulada
- `VALIDATION_ERROR` (400): ID inválido

---

### 👥 Usuarios

`PATCH /users/:id` admite que el solicitante se edite a sí mismo o que un `Dueño` edite cualquier cuenta. El resto de endpoints (`GET`, `POST`, `DELETE`, `restore`, `deleted`) requieren rol `Dueño`. Tras eliminar un usuario su token deja de ser válido en el siguiente request (el middleware verifica `activo=true`).

#### `GET /users`
Lista los usuarios activos paginados.

**Query params:**
- `page`, `limit` (opcionales, se envían juntos).

**Respuesta exitosa (ejemplo):**
```json
{
  "success": true,
  "message": "Todos los usuarios devueltos correctamente",
  "data": [
    {
      "usuarioId": "uuid",
      "nombre": "Dueño",
      "email": "dueno@farmabook.com",
      "rolNombre": "Dueño",
      "createdAt": "2026-03-07T15:37:12.974Z"
    }
  ],
  "pagination": { "total": 1, "page": 1, "limit": 20, "totalPages": 1 }
}
```

---

#### `GET /users/deleted`
Lista los usuarios eliminados (soft-deleted), paginados. Sólo accesible al rol `Dueño` — sirve para gestionar la restauración. Misma forma de respuesta que `GET /users`.

---

#### `GET /users/:nombre`
Busca usuarios activos por coincidencia parcial de nombre, paginado.

**Path params:**
- `nombre`: término de búsqueda (mínimo 2 caracteres).

**Query params:**
- `page`, `limit` (opcionales).

**Respuesta:** misma forma que `GET /users`.

**Códigos de error:**
- `VALIDATION_ERROR` (400): término menor a 2 caracteres o paginación inválida.

---

#### `POST /users`
Crea un nuevo usuario con rol `Empleado` (por diseño no se exponen otros roles).

**Body:**
```json
{
  "username": "NuevoUsuario",
  "email": "nuevo@farmabook.com",
  "password": "Password1234567"
}
```

**Códigos de error:**
- `USER_ALREADY_EXISTS` (409): nombre o email ya existe.
- `VALIDATION_ERROR` (400): error de validación.

---

#### `PATCH /users/:id`
Modifica un usuario existente (envía solo los atributos a modificar).

**Path params:**
- `id`: UUID del usuario.

**Body (ejemplo):**
```json
{
  "username": "<nuevo_nombre>",
  "email": "<nuevo_email>",
  "password": "<nueva_contrasena>",
  "currentPassword": "<contrasena_actual>"
}
```

**Reglas de acceso:**
- Un usuario común sólo puede modificar su propia cuenta.
- Un `Dueño` puede modificar cualquier cuenta (incluida la propia).

**`currentPassword`:**
- **Obligatorio siempre que el usuario se modifique a sí mismo**, sin importar qué campo cambie. La sesión activa no autoriza por sí sola cambios sensibles en el perfil.
- **No se requiere** cuando un `Dueño` modifica a otro usuario.

**Cambio de contraseña propia:**
- Si el usuario cambia su propia contraseña, la respuesta incluye un campo adicional `token` con un JWT recién emitido. Los tokens anteriores quedan invalidados; el cliente debe reemplazar el token actual por el devuelto.

**Códigos de error:**
- `ACCESS_DENIED` (403): el solicitante no puede modificar esta cuenta.
- `USER_NOT_FOUND` (404): el usuario no existe o está eliminado (usar `PATCH /users/:id/restore` antes de modificarlo).
- `USER_ALREADY_EXISTS` (409): nombre o email ya en uso. A usuarios sin rol `Dueño` se devuelve el mensaje genérico `No se pudo actualizar, verifica los datos` para evitar enumeración.
- `CURRENT_PASSWORD_REQUIRED` (400): falta `currentPassword` al editarse a sí mismo.
- `INVALID_PASSWORD` (401): `currentPassword` no coincide.
- `VALIDATION_ERROR` (400): error de validación.

---

#### `PATCH /users/:id/restore`
Restaura un usuario eliminado (`activo: false → true`). Sólo `Dueño`.

**Path params:**
- `id`: UUID del usuario eliminado.

**Respuesta exitosa:** devuelve el usuario reactivado, incluyendo `rolNombre`.

**Códigos de error:**
- `USER_NOT_FOUND` (404): no existe un usuario eliminado con ese id (idempotente: restaurar un usuario activo también devuelve 404).
- `VALIDATION_ERROR` (400): UUID inválido.

---

#### `DELETE /users/:id`
Elimina un usuario (soft delete). El token del eliminado deja de ser válido en el próximo request (el middleware filtra `activo=true`). El estado se puede revertir con `PATCH /users/:id/restore`.

**Path params:**
- `id`: UUID del usuario.

**Códigos de error:**
- `ROLE_NOT_DELETABLE` (403): no se puede eliminar a un `Dueño`.
- `USER_NOT_FOUND` (404): usuario no encontrado o ya inactivo.

---

### 📊 Analíticas

Todas las métricas excluyen ventas anuladas (`activo = false`). Los montos monetarios (`ingresosDiarios`, `ingresosMensuales`, `egresosMensuales`, `balanceMensual`, `costoPromedio`, `ingresosGenerados`) se devuelven como **strings** para preservar precisión decimal — el frontend debe castear si requiere operar numéricamente.

Las rutas analíticas son accesibles para cualquier rol autenticado (lectura para empleados), excepto `GET /analytics/report` que requiere rol `Dueño`.

#### `GET /analytics/revenues/today`
Obtiene los ingresos del día actual (ventas activas).

**Respuesta exitosa:**
```json
{ "success": true, "data": { "ingresosDiarios": "1500.00" } }
```

---

#### `GET /analytics/revenues/month`
Obtiene los ingresos del mes en curso.

**Respuesta exitosa:**
```json
{ "success": true, "data": { "ingresosMensuales": "45230.50" } }
```

---

#### `GET /analytics/sales/today`
Obtiene la cantidad de ventas (transacciones activas) del día.

**Respuesta exitosa:**
```json
{ "success": true, "data": { "ventasDelDia": 12 } }
```

---

#### `GET /analytics/sales/month`
Obtiene la cantidad de ventas del mes.

```json
{ "success": true, "data": { "ventasMensuales": 312 } }
```

---

#### `GET /analytics/products/top`
Obtiene los productos más vendidos.

**Query params:**
- `limit` (opcional): tope de resultados.
- `period` (opcional): `today` | `month` | `all` (default `all`).

**Respuesta exitosa:**
```json
{
  "success": true,
  "data": [
    {
      "productoId": "uuid",
      "nombre": "Paracetamol 500mg",
      "unidadesVendidas": 120,
      "vecesVendido": 87,
      "ingresosGenerados": "1234.50"
    }
  ]
}
```

`vecesVendido` cuenta en cuántas ventas distintas apareció el producto (gracias a la deduplicación por venta).

---

#### `GET /analytics/expenses`
Obtiene los egresos del mes en curso (suma de `costoDeCompra` de lotes ingresados).

```json
{ "success": true, "data": { "egresosMensuales": "10500.00" } }
```

---

#### `GET /analytics/balance`
Balance del mes (`ingresos - egresos`).

```json
{ "success": true, "data": { "balanceMensual": "34730.50" } }
```

---

#### `GET /analytics/report`
Genera un reporte PDF con las ventas del mes en curso (solo ventas activas). Requiere rol `Dueño`. Devuelve `Content-Type: application/pdf` con `Content-Disposition: attachment`.

---

#### `GET /analytics/suppliers/by-avg-cost`
Ranking de proveedores por el promedio de `costo` de los productos que distribuyen. Útil para identificar al proveedor más barato (o más caro).

**Query params:**
- `order`: `asc` (default) | `desc`. `asc` lista primero a los más baratos.
- `limit` (opcional): número de resultados. Si se omite, retorna todos.
- `casaId`: UUID opcional. Si se provee, limita el cálculo a productos de esa casa farmacéutica.

**Respuesta exitosa (ejemplo):**
```json
{
  "success": true,
  "message": "Proveedores ordenados por costo promedio devueltos correctamente",
  "data": [
    {
      "proveedorId": "uuid",
      "nombre": "Farmacias del Ahorro",
      "costoPromedio": "1000.00",
      "productosCount": 12
    }
  ]
}
```

**Códigos de error:**
- `HOUSE_NOT_FOUND` (404): `casaId` no corresponde a ninguna casa
- `VALIDATION_ERROR` (400): parámetros inválidos

---

### 🔔 Server-Sent Events (SSE)

**Nota:** Todos los canales SSE requieren token JWT válido como query param (el `EventSource` nativo del navegador no permite headers personalizados). La conexión se rechaza con `401 Unauthorized` si el token es inválido o ausente, y con `403 Forbidden` si el rol no tiene acceso.

Cada conexión se mantiene abierta como un stream HTTP `text/event-stream`. El servidor envía un comentario `: ping` cada 25 s para evitar que proxies/NAT corten la conexión inactiva. El navegador (`EventSource`) reconecta automáticamente si el stream se cae.

Formato de los mensajes (estándar SSE):
```
data: {"tipo":"...","payload":{...}}\n\n
```

#### `GET /notifications?token=<jwt>`
Canal de notificaciones en tiempo real. Accesible para todos los roles.

Ejemplo de cliente:
```js
const es = new EventSource(`http://localhost:3000/notifications?token=${jwt}`);
es.onmessage = (e) => {
  const { tipo, payload } = JSON.parse(e.data);
  // ...
};
```

Al conectarse, el servidor envía inmediatamente el historial de las últimas 100 notificaciones:
```json
{
  "tipo": "historial",
  "payload": [
    {
      "notificacionId": "uuid",
      "tipo": "stock_bajo",
      "mensaje": "Stock bajo en lote: LOTE-2025-001",
      "payload": {
        "loteId": "uuid",
        "nombreLote": "LOTE-2025-001",
        "productoId": "uuid",
        "cantidadDisponible": 1
      },
      "created_at": "2026-03-12T19:25:17.822689"
    }
  ]
}
```

Eventos en tiempo real:

**`stock_bajo`** — Se emite cuando la cantidad disponible de un lote cae por debajo de 10:
```json
{
  "tipo": "stock_bajo",
  "payload": {
    "notificacionId": "uuid",
    "tipo": "stock_bajo",
    "mensaje": "Stock bajo en lote: LOTE-2025-001",
    "payload": {
      "loteId": "uuid",
      "nombreLote": "LOTE-2025-001",
      "productoId": "uuid",
      "cantidadDisponible": 1
    },
    "created_at": "2026-03-12T19:25:17.822689"
  }
}
```

**`vencimiento`** — Se emite diariamente a las 8am para lotes que vencen en los próximos 30 días:
```json
{
  "tipo": "vencimiento",
  "payload": {
    "notificacionId": "uuid",
    "tipo": "vencimiento",
    "mensaje": "Lote próximo a vencer: LOTE-2025-090",
    "payload": {
      "loteId": "uuid",
      "nombreLote": "LOTE-2025-090",
      "productoId": "uuid",
      "cantidadDisponible": 300,
      "fechaDeVencimiento": "2026-03-20 00:00:00"
    },
    "created_at": "2026-03-12T17:41:00.064059"
  }
}
```

---

#### `GET /movements?token=<jwt>`
Canal de historial de cambios en tiempo real. **Solo accesible para el rol Dueño.**

Al conectarse, el servidor envía inmediatamente el historial de los últimos 100 cambios:
```json
{
  "tipo": "historial",
  "payload": [
    {
      "cambioId": "uuid",
      "usuarioId": "uuid",
      "nombreUsuario": "Dueño",
      "accion": "venta",
      "entidad": "venta",
      "payload": { },
      "created_at": "2026-03-12T19:25:17.822689"
    }
  ]
}
```

Evento en tiempo real:

**`movimientos`** — Se emite cuando se realiza cualquier operación de escritura:
```json
{
  "tipo": "movimientos",
  "payload": {
    "cambioId": "uuid",
    "usuarioId": "uuid",
    "nombreUsuario": "Dueño",
    "accion": "venta",
    "entidad": "venta",
    "payload": {
      "ventaId": "uuid",
      "total": 119998800,
      "fechaDeVenta": "2026-03-12T19:25:17.744Z",
      "productosVendidos": [
        {
          "nombre": "Paracetamol 500mg",
          "subTotal": 119998800,
          "productoId": "uuid",
          "cantidadDeUnidades": 99999
        }
      ]
    },
    "created_at": "2026-03-12T19:25:17.822689"
  }
}
```

**Valores posibles de `accion`:** `crear`, `modificar`, `eliminar`, `venta`

**Valores posibles de `entidad`:** `lote`, `producto`, `venta`, `usuario`, `proveedor`, `categoria`, `presentacion`


```