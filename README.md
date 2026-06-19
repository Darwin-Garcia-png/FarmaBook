# FarmaBook

Aplicación de escritorio para la gestión integral de una farmacia. Desarrollada en **Flutter** con soporte para **Windows** (build nativo) y **Web**.

---

## Arquitectura: MVVM con Provider

El proyecto sigue el patrón **MVVM (Model-View-ViewModel)** usando `Provider` como binder reactivo.

```
Model (datos) ───> ViewModel (lógica + estado) ───> View (UI reactiva)
                        │
                  notifyListeners()
                        │
                        ▼
              Provider (ChangeNotifier)
```

**Flujo de datos:**
1. La **View** (`screens/`) escucha al **ViewModel** (`controllers/`) via `context.watch<Controller>()`
2. El usuario interactúa con la UI → llama métodos del Controller
3. El Controller modifica el **Model** (datos) o expone nuevas propiedades
4. El Controller llama `notifyListeners()` → la View se repinta automáticamente
5. El Controller se comunica con el backend a través de **Services** (`services/`)

Este patrón evita que el Controller manipule directamente la View (como en MVC clásico). Cada Controller es un `ChangeNotifier` independiente que gestiona su propio estado.

---

## Estructura del proyecto

```
lib/
├── main.dart                    # Punto de entrada, providers globales, configuración inicial
├── controllers/                 # ViewModels — lógica de negocio y estado
├── models/                      # Clases de datos con fromJson/toJson
├── services/                    # Comunicación HTTP con el backend
├── screens/                     # Pantallas completas (Widgets Stateful)
├── widgets/                     # Widgets reutilizables
├── providers/                   # Providers globales (tema oscuro/claro)
├── router/                      # Configuración de GoRouter (navegación)
├── theme/                       # Temas claro/oscuro (paleta Rei Ayanami)
├── utils/                       # Helpers, constantes, formateo, diálogos
└── assets/                      # Recursos estáticos (sonidos, iconos)
```

---

### `lib/main.dart` — Punto de entrada

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Límites de caché de imágenes para reducir RAM
  PaintingBinding.instance.imageCache.maximumSize = 20;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 10 << 20;
  // Inicializar formatos de fecha en español
  await initializeDateFormatting('es', null);
  // Inicializar ApiService (configurar adapter HTTP + cargar token)
  try { await ApiService.init(); } catch (_) {}
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AlmacenController()),
        ChangeNotifierProvider(create: (_) => LotesController()),
        ChangeNotifierProvider(create: (_) => DashboardController()),
        ChangeNotifierProvider(create: (_) => NotificacionesController()),
      ],
      child: const MyApp(),
    ),
  );
}
```

**Responsabilidades:**
- Inicializar Flutter binding, caché de imágenes, formatos de fecha
- Configurar `ApiService.dio` (adapter HTTP con `badCertificateCallback` para entornos de desarrollo/QA)
- Cargar token JWT desde `flutter_secure_storage`
- Registrar los **Providers globales** en `MultiProvider` para que estén disponibles en toda la app
- Lanzar `MaterialApp.router` con GoRouter

---

### `lib/controllers/` — ViewModels (14 archivos)

Cada controller hereda de `ChangeNotifier` y expone:
- **Propiedades de estado** (listas de datos, flags de carga, errores)
- **Métodos de acción** (`init()`, `fetchX()`, `search()`, etc.)
- **Auto-clear automático**: timer de 5 minutos tras la última interacción; al expirar, llama `clearData()` para liberar RAM

| Archivo | ViewModel de | Responsabilidad |
|---|---|---|
| `almacen_controller.dart` | Almacén Central | CRUD productos, búsqueda, filtros por categoría/stock bajo, paginación |
| `lotes_controller.dart` | Gestión de Lotes | Carga de lotes, clasificación (vencidos/porVencer/bajoStock/saludables/agotados), paginación |
| `ventas_controller.dart` | Punto de Venta | Búsqueda de productos, carrito de compras, registro de ventas, historial |
| `inicio_controller.dart` | Dashboard Inicio | KPIs (ingresos/egresos/balance), top productos, alertas de vencimiento y stock bajo |
| `estadisticas_controller.dart` | Estadísticas | Ingresos hoy/mes, ticket promedio, ventas por hora, ranking productos, tendencias |
| `login_controller.dart` | Login | Autenticación (email + password), manejo de tokens JWT |
| `dashboard_controller.dart` | Navegación | Índice de pestaña seleccionada, logout |
| `notificaciones_controller.dart` | Notificaciones | Consulta de notificaciones del sistema |
| `categorias_controller.dart` | Catálogo Categorías | CRUD de categorías de productos |
| `presentaciones_controller.dart` | Catálogo Presentaciones | CRUD de presentaciones (tabletas, jarabes, etc.) |
| `proveedores_controller.dart` | Catálogo Proveedores | CRUD de proveedores |
| `casas_controller.dart` | Catálogo Casas | CRUD de casas farmacéuticas |
| `usuarios_controller.dart` | Usuarios | CRUD de usuarios del sistema |
| `config_controller.dart` | Configuración | Ajustes de la aplicación |

**Métodos clave comunes:**
- `init()` — carga inicial de datos (llamado tras login o al entrar a la pantalla)
- `touch()` — reinicia el timer de auto-clear (llamado en `initState` de cada pantalla)
- `scheduleAutoClear()` — programa limpieza de datos tras 5 min
- `clearData()` — libera memoria limpiando listas

---

### `lib/models/` — Modelos de datos (9 archivos)

Clases Dart con `factory fromJson()` y `toJson()` para serialización.

| Archivo | Clase(s) | Propiedades principales |
|---|---|---|
| `producto_model.dart` | `Producto` | productoId, codigoBarras, nombre, descripcion, categoriaId, presentacionId, cantidadDisponible, precioPorUnidad, imagenUrl |
| `lote_model.dart` | `Lote` | batchId, productoId, nombreLote, fechaDeVencimiento, cantidadDisponible, costoDeCompra |
| `venta_model.dart` | `Venta`, `ProductoVendido` | ventaId, total, fechaDeVenta, clienteId, lista de productos con cantidad y subtotal |
| `categoria_model.dart` | `Categoria` | categoriaId, nombre, descripcion, activo |
| `presentacion_model.dart` | `Presentacion` | presentacionId, nombre, descripcion, activo |
| `proveedor_model.dart` | `Proveedor` | proveedorId, nombre, direccion, telefono, email, activo |
| `usuario_model.dart` | `Usuario` | usuarioId, nombre, activo, rolId |
| `notificacion_model.dart` | `Notificacion` | notificacionId, tipo, mensaje, payload, createdAt |
| `movimiento_model.dart` | `Movimiento` | cambioId, usuarioId, nombreUsuario, accion, entidad, payload, createdAt |

---

### `lib/services/` — Comunicación con el backend (2 archivos)

#### `api_service.dart`

Clase **estática** que encapsula toda la comunicación HTTP usando **Dio 5.7+**.

**Componentes:**
- `_dio` (static final) — instancia global de Dio configurada con baseUrl y timeouts
- `_cachedToken` — token JWT en memoria (evita leer `flutter_secure_storage` en cada petición)
- `_configureAdapter()` — configura `IOHttpClientAdapter` con `badCertificateCallback` (permite certificados SSL autofirmados en desarrollo)
- `setAuthHeader()` — inyecta `Authorization: Bearer <token>` antes de cada petición
- `releaseMemory()` — limpia token y caché cuando la app pasa a segundo plano

**Métodos principales (todos static async):**

| Categoría | Métodos |
|---|---|
| Productos | `getProductos(page, limit)`, `searchProducts(query)`, `getProductByIdentifier(id)`, `saveProduct()`, `deleteProduct(id)` |
| Lotes | `getBatches(page, limit)`, `getBatchesByProduct(productId)`, `createBatch(data)`, `updateBatch(id, data)`, `deleteBatch(id)`, `validateStock(productId, quantity)` |
| Ventas | `getSales(limit)`, `getSaleById(id)`, `registerSale(data)`, `deleteSale(id)` |
| Catálogos | `getCategories()`, `getPresentations()`, `getSuppliers()` |
| Usuarios | `getUsers()`, `createUser(data)`, `updateUser(id, data)`, `deleteUser(id)` |
| Analíticas | `getRevenueToday()`, `getRevenueMonth()`, `getExpenses()`, `getBalance()`, `getTopProducts(limit, period)` |
| Imágenes | `uploadImage(file)` → Cloudinary |
| Auth | `setToken(token)`, `getToken()`, `clearCachedToken()` |

**Manejo de errores:** Un interceptor global `onError` muestra un overlay animado con el mensaje de error usando `GlobalErrorHandler`.

#### `auth_service.dart`

Servicio independiente para autenticación. Usa una **instancia Dio dedicada** (separada de `ApiService.dio`) para evitar conflictos de estado durante el login.

**Métodos:**
- `login(email, password)` — POST `/auth/login`, extrae token de múltiples campos posibles (`data.token`, `token`, `access_token`, `accessToken`, `jwt`)
- `logout()` — elimina el token

---

### `lib/screens/` — Pantallas (14 archivos)

Cada pantalla es un `StatefulWidget` que:
1. Obtiene su Controller vía `context.read<Controller>()` (providers globales) o creándolo directamente
2. Usa `context.watch<Controller>()` en el build para escuchar cambios
3. Llama `controller.touch()` en `initState` y `controller.scheduleAutoClear()` al salir
4. Incluye un botón de **refresh manual** (↻) en el AppBar

| Archivo | Ruta | Descripción |
|---|---|---|
| `login_screen.dart` | `/login` | Formulario de login (email + password). Llama `AlmacenController.init()` y `LotesController.init()` tras login exitoso |
| `dashboard_screen.dart` | `/dashboard` | Drawer de navegación + scaffold con cuerpo intercambiable según pestaña |
| `inicio_screen.dart` | (case 0) | KPIs, gráfico de salud de inventario, anillos radiales, ventas recientes, top productos, alertas |
| `almacen_screen.dart` | (case 1) | Grid de productos con búsqueda, filtro stock bajo, categorías, edición rápida |
| `ventas_screen.dart` | (case 2) | Punto de venta: búsqueda de productos, carrito, historial de ventas, recibo |
| `lotes_screen.dart` | (case 3) | Lotes clasificados (activos/vencidos/porVencer/bajoStock/agotados), búsqueda |
| `estadisticas_screen.dart` | (case 4) | KPIs, gráficos de barras (ingresos por hora/día/mes), ranking productos |
| `categorias_screen.dart` | `/categorias` | CRUD de categorías |
| `presentaciones_screen.dart` | `/presentaciones` | CRUD de presentaciones |
| `proveedores_screen.dart` | `/proveedores` | CRUD de proveedores |
| `casas_screen.dart` | `/casas` | CRUD de casas farmacéuticas |
| `usuarios_screen.dart` | `/usuarios` | CRUD de usuarios |
| `configuracion_screen.dart` | `/configuracion` | Ajustes de la aplicación |
| `manual_screen.dart` | `/manual` | Manual de ayuda del sistema |

---

### `lib/widgets/` — Widgets reutilizables

#### `almacen/`
- `product_card.dart` — Tarjeta de producto en el grid del Almacén. Muestra nombre, precio en COP, stock, imagen. Menú contextual para editar/eliminar
- `batch_details_modal.dart` — Modal con detalle de lotes de un producto específico

#### `ventas/`
- `cart_section.dart` — Carrito de compras: lista de items, cantidad, subtotal, campo "Nombre del Cliente" (requerido), botón COBRAR
- `receipt_dialog.dart` — Diálogo de recibo/PDF después de una venta exitosa. Muestra productos, total, nombre del cliente
- `sales_results_grid.dart` — Grid de resultados de búsqueda de productos para agregar al carrito
- `sales_search_section.dart` — Barra de búsqueda de productos por código de barras o nombre

#### Otros
- `custom_text_field.dart` — InputDecorator personalizado con estilo consistente
- `gradient_button.dart` — Botón con gradiente animado
- `premium_header.dart` — Encabezado decorativo para catálogos

---

### `lib/widgets/` — Widgets reutilizables (continuación)

- `keyboard_shortcuts.dart` — Sistema de atajos de teclado para escritorio (`AppShortcuts.wrap`)
- `animations.dart` — `AnimatedEntry`, `HoverScale`, `ParticleBackground`

### `lib/utils/` — Utilidades (7 archivos)

| Archivo | Propósito |
|---|---|
| `app_constants.dart` | Constantes globales: `baseUrl`, timeouts, claves de Cloudinary, tokenKey |
| `price_formatter.dart` | `formatCop(num)` — Formatea un número a pesos colombianos: `$1,500`, `$12,000`, `$1,200,000` |
| `global_error_handler.dart` | Overlay animado tipo "toast" para errores HTTP. Aparece desde arriba con animación y se oculta tras 4s |
| `inventory_dialogs.dart` | Diálogos complejos: `showEditProduct()` (editar producto), `showAddEditBatch()` (crear/editar lote con todos los campos precargados), `showAddEditProduct()` (crear producto + lote), `showAddStock()` (agregar stock a lote existente) |
| `download_helper.dart` | Helper para descargar archivos (PDF exportado) |
| `download_helper_stub.dart` | Stub para desktop de download_helper |
| `download_helper_web.dart` | Implementación web de download_helper |

---

### `lib/providers/` — Providers globales

- `theme_provider.dart` — `ThemeProvider`: toggle entre tema claro/oscuro. Persiste la preferencia.

### `lib/router/` — Navegación

- `app_router.dart` — Configuración de **GoRouter** con 13 rutas:
  - `/login` → LoginScreen
  - `/dashboard` → DashboardScreen
  - `/ventas` → VentasScreen
  - `/inicio` → InicioScreen
  - `/almacen` → AlmacenScreen
  - `/proveedores` → ProveedoresScreen
  - `/categorias` → CategoriasScreen
  - `/presentaciones` → PresentacionesScreen
  - `/estadisticas` → EstadisticasScreen
  - `/configuracion` → ConfigScreen
  - `/usuarios` → UsuariosScreen

Contiene `navigatorKey` (GlobalKey) usado por `GlobalErrorHandler` para mostrar overlays sin necesidad de contexto.

### `lib/theme/` — Temas

- `app_theme.dart` — Paleta de colores **Rei Ayanami** (Evangelion):
  - `ayanamiBlue` (#6DABE4), `greenMetal` (#2F855A), `reiOrangeRed` (#E53E3E)
  - `lightTheme` y `darkTheme` completos con Material3

---

## Flujo de navegación

```
LoginScreen ──(login exitoso)──> AlmacenController.init() + LotesController.init()
                                        │
                                        ▼
                                  DashboardScreen
                                        │
                          ┌─────────────┼─────────────┐
                          ▼             ▼             ▼
                   InicioScreen   AlmacenScreen   VentasScreen
                   (KPIs, alerts) (productos)     (carrito, ventas)
                          │             │
                          ▼             ▼
                   Estadisticas    LotesScreen
                   Screen          (lotes clasificados)
```

## Gestión de memoria

- **Auto-clear**: Cada controller tiene un `Timer` de 5 minutos. Si el usuario no interactúa con una pantalla en ese tiempo, los datos se limpian (`clearData()`).
- **Botón refresh** (↻): Para recargar datos de una pantalla manualmente.
- **Caché de imágenes**: Limitado a 20 imágenes, 10 MB máximo.
- **Paginación**: Productos (20 por página), Lotes (100 por página), Ventas (30 en historial).
- **`releaseMemory()`**: Limpia token y headers cuando la app pasa a segundo plano.

## Formato de precios

Todos los precios se muestran en **pesos colombianos (COP)** usando `formatCop()`:
```
0        → $0
1500     → $1,500
1250000  → $1,250,000
```

## Tecnologías

| Tecnología | Versión | Uso |
|---|---|---|
| Flutter | ≥3.5.0 | Framework UI multiplataforma |
| Dart | ≥3.5.0 | Lenguaje de programación |
| Dio | ^5.7.0 | Cliente HTTP con interceptores |
| Provider | ^6.0.0 | Gestión de estado reactiva |
| GoRouter | ^14.8.1 | Navegación declarativa |
| fl_chart | ^0.69.0 | Gráficos (barras, radiales) |
| flutter_secure_storage | ^9.2.4 | Almacenamiento seguro de tokens |
| printing | ^5.13.4 | Generación de PDFs |
| pdf | ^3.11.1 | Creación de documentos PDF |
| image_picker | ^1.2.1 | Selección de imágenes (subida a Cloudinary) |

## Animaciones y UX

### Widgets de animación (`lib/widgets/animations.dart`)
- **`AnimatedEntry`** — Entrada escalonada con fade + slide para listas/grids
- **`HoverScale`** — Escala + elevación al hover sobre tarjetas y botones
- **`ParticleBackground`** — Fondo animado con partículas flotantes (login screen)
- **`ShimmerList`** — Skeleton loading animado con gradiente móvil

### Login rediseñado
- Fondo con gradiente animado y orbes pulsantes
- Iconos flotantes de la marca Rx dibujados con `CustomPaint`
- Formulario glassmorphism con entrada escalonada
- Campos con animación al enfocar, botón con hover

### Transiciones entre pantallas
Todas las rutas usan `CustomTransitionPage` con fade + slide (`easeOutCubic`) gracias a GoRouter.

## Atajos de teclado (`lib/widgets/keyboard_shortcuts.dart`)

Atajos disponibles en escritorio (Windows/Linux):

| Tecla | Ámbito | Acción |
|-------|--------|--------|
| `F1` | Global | Abrir Manual de Ayuda |
| `Escape` | Global | Volver a Inicio |
| `Ctrl+1` | Global | Panel Inicio |
| `Ctrl+2` | Global | Almacén Central |
| `Ctrl+3` | Global | Punto de Venta |
| `Ctrl+4` | Global | Gestión de Lotes |
| `Ctrl+5` | Global | Estadísticas |
| `F2` | Ventas | Enfocar campo de código de barras |
| `Ctrl+Enter` | Ventas | Cobrar (procesar venta) |
| `Escape` | Ventas | Limpiar búsqueda / volver a búsqueda |

## Roles y permisos

- **Dueño/Admin**: Acceso completo a todas las funcionalidades
- **Empleado/Cajero/Vendedor**: Acceso limitado — ocultos: CATÁLOGOS, ajustes, botones de editar/eliminar, y sección "Personal y Roles"

## Build y despliegue

### Windows (.exe)

```powershell
flutter clean
flutter pub get
flutter build windows --release
```

El ejecutable se genera en `build\windows\x64\runner\Release\farmaboook_flutter.exe`.

Para crear un instalador MSIX:
```powershell
flutter pub get
dart run msix:create
```

### Web

```powershell
flutter build web
```

Los archivos estáticos se generan en `build\web\`.

## Backend

- **URL base**: `https://farmabook.jonathanalarcon.qzz.io`
- **Autenticación**: JWT (Bearer token)
- **Endpoints**: CRUD para productos, lotes, ventas, categorías, presentaciones, proveedores, usuarios, analíticas y autenticación

---

## API del backend

### Autenticación
- `POST /auth/login` — Iniciar sesión (email + password → JWT)

### Productos
- `GET /inventory/products` — Listar productos (paginado)
- `GET /inventory/search?query=` — Buscar productos
- `GET /inventory/products/:id` — Obtener un producto
- `POST /inventory/products` — Crear producto
- `PATCH /inventory/products/:id` — Actualizar producto
- `DELETE /inventory/products/:id` — Eliminar producto

### Lotes
- `GET /inventory/batches` — Listar lotes (paginado)
- `GET /inventory/products/:id/batches` — Lotes de un producto
- `POST /inventory/batches` — Crear lote
- `PATCH /inventory/batches/:id` — Actualizar lote
- `DELETE /inventory/batches/:id` — Eliminar lote
- `POST /inventory/validate-stock` — Validar stock

### Ventas
- `GET /sales` — Listar ventas
- `GET /sales/:id` — Obtener venta
- `POST /sales` — Registrar venta
- `DELETE /sales/:id` — Eliminar venta

### Catálogos
- `GET /inventory/categories` — Categorías
- `POST /inventory/categories` — Crear categoría
- `PATCH /inventory/categories/:id` — Actualizar categoría
- `DELETE /inventory/categories/:id` — Eliminar categoría
- `GET /inventory/presentations` — Presentaciones
- `POST /inventory/presentations` — Crear presentación
- `PATCH /inventory/presentations/:id` — Actualizar presentación
- `DELETE /inventory/presentations/:id` — Eliminar presentación
- `GET /inventory/suppliers` — Proveedores
- `POST /inventory/suppliers` — Crear proveedor
- `PATCH /inventory/suppliers/:id` — Actualizar proveedor
- `DELETE /inventory/suppliers/:id` — Eliminar proveedor

### Analíticas
- `GET /analytics/revenues/today` — Ingresos del día
- `GET /analytics/revenues/month` — Ingresos del mes
- `GET /analytics/expenses` — Egresos
- `GET /analytics/balance` — Balance
- `GET /analytics/products/top` — Top productos

### Usuarios
- `GET /users` — Listar usuarios
- `POST /users` — Crear usuario
- `PATCH /users/:id` — Actualizar usuario
- `DELETE /users/:id` — Eliminar usuario

### Notificaciones
- `GET /notifications` — Listar notificaciones
