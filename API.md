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

---

### 📦 Inventario

#### `GET /inventory/all`
Obtiene todos los recursos del inventario.

#### `GET /inventory/search?query=<query>`
Búsqueda fuzzy global en el inventario.

**Query params:**
- `query`: Texto de búsqueda (mínimo 2 caracteres)

---

### 💊 Productos

#### `GET /inventory/products`
Obtiene todos los productos con paginación. Soporta filtros opcionales.

**Query params:**
- `categoriaId`: UUID de la categoría (opcional)
- `presentacionId`: UUID de la presentación (opcional)
- `proveedorId`: UUID del proveedor (opcional)
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
      "descripcion": "Analgésico y antipirético",
      "categoriaId": "uuid",
      "presentacionId": "uuid",
      "proveedoresId": ["uuid"],
      "cantidadDisponible": 100,
      "imagenUrl": "https..."
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

**Códigos de error:**
- `CATEGORY_NOT_FOUND` (404): Categoría no encontrada
- `PRESENTATION_NOT_FOUND` (404): Presentación no encontrada
- `SUPPLIER_NOT_FOUND` (404): Proveedor no encontrado
- `PAGE_NOT_FOUND` (404): Página solicitada no existe
- `VALIDATION_ERROR` (400): Error de validación

---

#### `GET /inventory/products/:identificador`
Obtiene un producto por su identificador.

**Path params:**
- `identificador`: Código de barras o UUID del producto

**Códigos de error:**
- `PRODUCT_NOT_FOUND` (404): Producto no encontrado
- `VALIDATION_ERROR` (400): Identificador inválido

---

#### `POST /inventory/products`
Crea un nuevo producto.

**Body:**
```json
{
  "codigoBarras": "75000000001",
  "nombre": "Paracetamol 500mg",
  "descripcion": "Analgésico y antipirético",
  "precioPorUnidad": 2.50,
  "dosisRecomendada": "500mg cada 6 horas",
  "proveedorId": "uuid-v4",
  "categoriaId": "uuid-v4",
  "presentacionId": "uuid-v4",
  "imagenUrl": "https..."
}
```

Para obtener la imagenUrl hay hacer la petición a:

`POST https://api.cloudinary.com/v1_1/dfffmvroq/image/upload`

**Body:** `multipart/form-data`

| Campo | Tipo | Valor |
|       |      |       |
| `file`| File | La imagen |
| `upload_preset` | Text | `farmabook` |

La imagenUrl es el `secure_url` de la respuesta

**Códigos de error:**
- `PRODUCT_ALREADY_EXISTS` (409): Producto ya existe
- `BARCODE_ALREADY_EXISTS` (409): Código de barras ya existe
- `CATEGORY_NOT_FOUND` (404): Categoría no encontrada
- `PRESENTATION_NOT_FOUND` (404): Presentación no encontrada
- `SUPPLIER_NOT_FOUND` (404): Proveedor no encontrado
- `VALIDATION_ERROR` (400): Error de validación

---

#### `PATCH /inventory/products/:id`
Modifica un producto existente (envía solo los atributos a modificar).

**Path params:**
- `id`: UUID del producto

**Body (ejemplo):**
```json
{
  "nombre": "<nuevo_nombre>",
  "descripcion": "<nueva_descripcion>"
}
```

**Códigos de error:**
- `PRODUCT_NOT_FOUND` (404): Producto no encontrado
- `BARCODE_ALREADY_EXISTS` (409): Código de barras ya existe
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
Obtiene todos los proveedores de un producto.

**Path params:**
- `id`: UUID del producto

**Códigos de error:**
- `PRODUCT_NOT_FOUND` (404): Producto no encontrado

---

#### `POST /inventory/products/:id/suppliers`
Agrega un proveedor a un producto.

**Path params:**
- `id`: UUID del producto

**Body:**
```json
{
  "proveedorId": "uuid"
}
```

**Códigos de error:**
- `PRODUCT_NOT_FOUND` (404): Producto no encontrado
- `SUPPLIER_NOT_FOUND` (404): Proveedor no encontrado
- `SUPPLIER_ALREADY_EXISTS` (409): Proveedor ya asociado al producto

---

#### `DELETE /inventory/products/:id/suppliers/:supplierId`
Desasocia un proveedor de un producto.

**Path params:**
- `id`: UUID del producto
- `supplierId`: UUID del proveedor

**Códigos de error:**
- `PRODUCT_NOT_FOUND` (404): Producto no encontrado
- `SUPPLIER_NOT_ASSOCIATED` (404): Proveedor no asociado al producto
- `LAST_SUPPLIER` (409): No se puede eliminar el último proveedor

---

### 🗂️ Categorías

#### `GET /inventory/categories`
Obtiene todas las categorías con paginación.

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
      "activo": true,
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

**Códigos de error:**
- `PAGE_NOT_FOUND` (404): Página solicitada no existe

---

#### `GET /inventory/categories/exists?name=<nombre>`
Verifica si existe una categoría por nombre.

**Query params:**
- `name`: Nombre de la categoría

---

#### `GET /inventory/categories/:identificador`
Obtiene una categoría por su identificador (UUID o nombre).

**Códigos de error:**
- `CATEGORY_NOT_FOUND` (404): Categoría no encontrada

---

#### `POST /inventory/categories`
Crea una nueva categoría.

**Body:**
```json
{
  "nombre": "Analgésicos",
  "descripcion": "Medicamentos para alivio del dolor"
}
```

**Códigos de error:**
- `CATEGORY_ALREADY_EXISTS` (409): Categoría ya existe
- `VALIDATION_ERROR` (400): Error de validación

---

#### `PATCH /inventory/categories/:id`
Modifica una categoría existente (envía solo los atributos a modificar).

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
- `CATEGORY_NOT_FOUND` (404): Categoría no encontrada
- `CATEGORY_ALREADY_EXISTS` (409): Nombre ya existe
- `VALIDATION_ERROR` (400): Error de validación

---

#### `DELETE /inventory/categories/:id`
Elimina una categoría.

**Path params:**
- `id`: UUID de la categoría

**Códigos de error:**
- `CATEGORY_NOT_FOUND` (404): Categoría no encontrada
- `CATEGORY_HAS_ASSOCIATED_PRODUCTS` (409): La categoría tiene productos asociados

---

### 📦 Presentaciones

#### `GET /inventory/presentations`
Obtiene todas las presentaciones con paginación.

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
      "activo": true,
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

**Códigos de error:**
- `PAGE_NOT_FOUND` (404): Página solicitada no existe

---

#### `GET /inventory/presentations/exists?name=<nombre>`
Verifica si existe una presentación por nombre.

**Query params:**
- `name`: Nombre de la presentación

---

#### `GET /inventory/presentations/:identificador`
Obtiene una presentación por su identificador (UUID o nombre).

**Códigos de error:**
- `PRESENTATION_NOT_FOUND` (404): Presentación no encontrada

---

#### `POST /inventory/presentations`
Crea una nueva presentación.

**Body:**
```json
{
  "nombre": "Tabletas",
  "descripcion": "Presentación en tabletas"
}
```

**Códigos de error:**
- `PRESENTATION_ALREADY_EXISTS` (409): Presentación ya existe
- `VALIDATION_ERROR` (400): Error de validación

---

#### `PATCH /inventory/presentations/:id`
Modifica una presentación existente (envía solo los atributos a modificar).

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
- `PRESENTATION_NOT_FOUND` (404): Presentación no encontrada
- `PRESENTATION_ALREADY_EXISTS` (409): Nombre ya existe
- `VALIDATION_ERROR` (400): Error de validación

---

#### `DELETE /inventory/presentations/:id`
Elimina una presentación.

**Path params:**
- `id`: UUID de la presentación

**Códigos de error:**
- `PRESENTATION_NOT_FOUND` (404): Presentación no encontrada
- `PRESENTATION_HAS_ASSOCIATED_PRODUCTS` (409): La presentación tiene productos asociados

---

### 🚚 Proveedores

#### `GET /inventory/suppliers`
Obtiene todos los proveedores con paginación.

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
      "activo": true,
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

**Códigos de error:**
- `PAGE_NOT_FOUND` (404): Página solicitada no existe

---

#### `GET /inventory/suppliers/exists?name=<nombre>`
Verifica si existe un proveedor por nombre.

**Query params:**
- `name`: Nombre del proveedor

---

#### `GET /inventory/suppliers/exists?email=<email>`
Verifica si existe un proveedor por email.

**Query params:**
- `email`: Email del proveedor

---

#### `GET /inventory/suppliers/:identificador`
Obtiene un proveedor por su identificador (UUID o nombre).

**Códigos de error:**
- `SUPPLIER_NOT_FOUND` (404): Proveedor no encontrado

---

#### `POST /inventory/suppliers`
Crea un nuevo proveedor.

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
- `SUPPLIER_ALREADY_EXISTS` (409): Nombre ya existe
- `SUPPLIER_EMAIL_ALREADY_EXISTS` (409): Email ya existe
- `VALIDATION_ERROR` (400): Error de validación

---

#### `PATCH /inventory/suppliers/:id`
Modifica un proveedor existente (envía solo los atributos a modificar).

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
- `SUPPLIER_NOT_FOUND` (404): Proveedor no encontrado
- `SUPPLIER_ALREADY_EXISTS` (409): Nombre ya existe
- `SUPPLIER_EMAIL_ALREADY_EXISTS` (409): Email ya existe
- `VALIDATION_ERROR` (400): Error de validación

---

#### `DELETE /inventory/suppliers/:id`
Elimina un proveedor.

**Path params:**
- `id`: UUID del proveedor

**Códigos de error:**
- `SUPPLIER_NOT_FOUND` (404): Proveedor no encontrado
- `SUPPLIER_HAS_ASSOCIATED_PRODUCTS` (409): El proveedor tiene productos asociados

---

### 📦 Lotes

#### `GET /inventory/batches`
Obtiene todos los lotes registrados.

#### `GET /inventory/batches/:id`
Obtiene un lote por su UUID.

**Path params:**
- `id`: UUID del lote

**Códigos de error:**
- `BATCH_NOT_FOUND` (404): Lote no encontrado
- `VALIDATION_ERROR` (400): ID inválido

---

#### `POST /inventory/batches`
Crea un nuevo lote.

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
Modifica un lote existente (envía solo los atributos a modificar).
**Nota:** No se permite modificar `fechaDeVencimiento` ni `productoId`.

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
  ]
}
```

**Respuesta exitosa (ejemplo):**
```json
{
  "success": true,
  "message": "Venta realizada correctamente",
  "data": {
    "ventaId": "uuid",
    "total": "11.50",
    "fechaDeVenta": "2026-03-07T16:13:00.000Z",
    "productosVendidos": [
      {
        "productoId": "uuid",
        "nombre": "Paracetamol 500mg",
        "cantidadDeUnidades": 1,
        "subTotal": 2.5
      }
    ]
  }
}
```

**Códigos de error:**
- `PRODUCT_NOT_FOUND` (404): Producto no encontrado
- `OUT_OF_STOCK` (409): Stock insuficiente
- `VALIDATION_ERROR` (400): Error de validación

---

#### `GET /sales`
Obtiene todas las ventas con paginación y filtros opcionales.

**Query params:**
- `productoId`: UUID del producto (opcional)
- `fechaInicio`: Fecha de inicio ISO 8601 (opcional)
- `fechaFin`: Fecha de fin ISO 8601 (opcional, requiere `fechaInicio`)
- `page`: Número de página (opcional, default: 1)
- `limit`: Cantidad de resultados por página (opcional, default: 20)

**Respuesta exitosa (ejemplo):**
```json
{
  "success": true,
  "message": "Todas las ventas devueltas correctamente",
  "data": [
    {
      "ventaId": "uuid",
      "total": "11.50",
      "fechaDeVenta": "2026-03-07T16:13:00.000Z",
      "productosVendidos": [
        {
          "productoId": "uuid",
          "nombre": "Paracetamol 500mg",
          "cantidadDeUnidades": 1,
          "subTotal": 2.5
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
    "total": "11.50",
    "fechaDeVenta": "2026-03-07T16:13:00.000Z",
    "productosVendidos": [
      {
        "productoId": "uuid",
        "nombre": "Paracetamol 500mg",
        "cantidadDeUnidades": 1,
        "subTotal": 2.5
      }
    ]
  }
}
```

**Códigos de error:**
- `SALE_NOT_FOUND` (404): Venta no encontrada
- `VALIDATION_ERROR` (400): ID inválido

---

### 👥 Usuarios

#### `GET /users`
Obtiene todos los usuarios registrados.

**Respuesta exitosa (ejemplo):**
```json
{
  "success": true,
  "message": "Usuarios devueltos correctamente",
  "data": [
    {
      "usuarioId": "uuid",
      "nombre": "Dueño",
      "activo": true,
      "rolId": "uuid",
      "createdAt": "2026-03-07T15:37:12.974Z"
    }
  ]
}
```

---

#### `GET /users/:nombre`
Obtiene un usuario por su nombre de usuario.

**Path params:**
- `nombre`: Nombre del usuario

**Códigos de error:**
- `USER_NOT_FOUND` (404): Usuario no encontrado
- `VALIDATION_ERROR` (400): Error de validación

---

#### `POST /users`
Crea un nuevo usuario.

**Body:**
```json
{
  "username": "NuevoUsuario",
  "password": "Password1234567"
}
```

**Códigos de error:**
- `USER_ALREADY_EXISTS` (409): Usuario ya existe
- `VALIDATION_ERROR` (400): Error de validación

---

#### `PATCH /users/:id`
Modifica un usuario existente (envía solo los atributos a modificar).

**Path params:**
- `id`: UUID del usuario

**Body (ejemplo):**
```json
{
  "username": "<nuevo_nombre>",
  "password": "<nueva_contrasena>",
  "currentPassword": "<contrasena_actual>"
}
```
**Nota:** `currentPassword` es obligatorio si se envía `password`.

**Códigos de error:**
- `USER_NOT_FOUND` (404): Usuario no encontrado
- `USER_ALREADY_EXISTS` (409): Nombre ya existe
- `VALIDATION_ERROR` (400): Error de validación

---

#### `DELETE /users/:id`
Elimina un usuario (soft delete).

**Path params:**
- `id`: UUID del usuario

**Códigos de error:**
- `USER_NOT_FOUND` (404): Usuario no encontrado

---

### 📊 Analíticas

#### `GET /analytics/revenues/today`
Obtiene los ingresos de hoy.

---

#### `GET /analytics/revenues/month`
Obtiene los ingresos del mes.

---

#### `GET /analytics/sales/today`
Obtiene la cantidad de ventas de hoy.

---

#### `GET /analytics/sales/month`
Obtiene la cantidad de ventas del mes.

---

#### `GET /analytics/products/top`
Obtiene los productos más vendidos.

---

#### `GET /analytics/expenses`
Obtiene los egresos de inventario del mes.

---

#### `GET /analytics/balance`
Obtiene el balance general y de caja.

---

#### `GET /analytics/report`
Obtiene el reporte de estadísticas en formato PDF.

---

### 🔔 WebSocket

**Nota:** Todos los canales WebSocket requieren token JWT válido como query param. La conexión se rechaza con `401 Unauthorized` si el token es inválido o ausente, y con `403 Forbidden` si el rol no tiene acceso.

#### `ws://localhost:3000/notifications?token=<jwt>`
Canal de notificaciones en tiempo real. Accesible para todos los roles.

Al conectarse, el servidor envía inmediatamente el historial de notificaciones:
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

#### `ws://localhost:3000/movements?token=<jwt>`
Canal de historial de cambios en tiempo real. **Solo accesible para el rol Dueño.**

Al conectarse, el servidor envía inmediatamente el historial de cambios:
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