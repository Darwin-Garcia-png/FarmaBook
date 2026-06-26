# FarmaBook — Sistema de Gestión Farmacéutica

Aplicación de escritorio desarrollada en **Flutter** para la administración integral de farmacias. Compila de forma nativa para **Windows** con enfoque en rendimiento, usabilidad en mostrador y experiencia de usuario tipo _premium_.

---

## Índice

- [Visión general](#visi%C3%B3n-general)
- [Módulos](#m%C3%B3dulos)
- [Roles y permisos](#roles-y-permisos)
- [Capturas de pantalla](#capturas-de-pantalla)
- [Stack tecnológico](#stack-tecnol%C3%B3gico)
- [Arquitectura](#arquitectura)
- [Estructura del proyecto](#estructura-del-proyecto)
- [Rutas](#rutas)
- [Atajos de teclado](#atajos-de-teclado)
- [API](#api)
- [Build](#build)
- [Desarrollo](#desarrollo)
- [Créditos](#cr%C3%A9ditos)

---

## Visión general

FarmaBook es un sistema de escritorio pensado para la operación diaria de una farmacia. Permite gestionar inventario, controlar lotes con fecha de vencimiento, realizar ventas con generación de recibo, consultar estadísticas del negocio y administrar usuarios del sistema, todo desde una sola aplicación con interfaz moderna y responsiva.

El proyecto se conecta a un backend REST (Node.js + MySQL) alojado en la nube, con autenticación JWT y operaciones CRUD completas.

---

## Módulos

### Panel de Inicio
Dashboard principal con indicadores clave del día:
- **KPIs**: ingresos del día, egresos, % stock saludable, ganancia neta.
- **Últimas ventas**: listado de las 5 transacciones más recientes.
- **Top productos**: ranking de los 3 más vendidos del día.
- **Alertas activas**: stock bajo y productos próximos a vencer.
- **Acceso rápido**: botones directos a los módulos principales.

### Almacén Central
Gestión completa del inventario de medicamentos:
- **Catálogo de productos** con imagen, nombre, nombre genérico, concentración, presentación, casa farmacéutica, categoría y proveedor.
- **Búsqueda** por nombre, código de barras o escaneo.
- **Filtros combinados**: por categoría, casa farmacéutica, proveedor, presentación y stock bajo.
- **Stock por lote**: el stock real se calcula sumando las cantidades disponibles de todos los lotes del producto.
- **Paginación infinita** con scroll.
- **Roles**: admin puede crear, editar y eliminar productos; empleado solo visualiza.

### Punto de Venta
Módulo de cobro rápido:
- **Buscador de productos** con vista de resultados que muestra stock, precio y estado (disponible, bajo stock, vencido, sin stock).
- **Productos más vendidos** cargados por defecto al abrir el módulo.
- **Carrito de compras** con ajuste de cantidades, subtotales y total.
- **Registro de cliente** opcional (nombre y cédula).
- **Generación de recibo** en PDF con opción de impresión.
- **Historial de ventas** con búsqueda y detalle.

### Gestión de Lotes
Control de trazabilidad y fechas de vencimiento:
- **Clasificación automática**: lotes activos, por vencer (<60 días), vencidos, bajo stock e historial.
- **Semáforo visual**: colores según estado del lote.
- **CRUD completo** de lotes con edición y eliminación.
- **Alertas** de vencimiento integradas con el sistema de notificaciones.

### Estadísticas
Analítica completa del negocio:
- **Resumen del día**: ingresos, ventas, ticket promedio, unidades vendidas, hora pico.
- **Ventas por hora**: gráfica de barras (24 horas).
- **Rendimiento mensual**: ingresos, egresos, balance, mejor día.
- **Tendencia diaria**: evolución de ingresos día por día en el mes.
- **Top productos**: ranking de más vendidos (hoy, mes, global).
- **Categorías**: gráfica pastel de distribución por tipo.
- **Exportación a PDF** con reporte completo descargable.

### Catálogos
Datos maestros del sistema:
- **Casas farmacéuticas**: registro y gestión de laboratorios.
- **Categorías**: clasificación de productos por tipo.
- **Presentaciones**: formas farmacéuticas (tabletas, jarabe, inyectable, etc.).
- **Proveedores**: datos de contacto de distribuidores.
- **Usuarios**: creación de cuentas con roles (Admin/Employee) y asignación de token por usuario.

### Manual de Ayuda
Guía integrada con:
- Descripción detallada de cada módulo.
- Flujos de trabajo paso a paso.
- Preguntas frecuentes.
- Resolución de errores comunes.
- Contenido adaptativo según el rol del usuario.

### Notificaciones
Sistema proactivo de alertas:
- Stock bajo (productos por debajo del mínimo configurado).
- Próximos a vencer (30 días antes de la fecha de caducidad).
- Indicador animado con conteo de no leídas.
- Navegación directa: tocar una alerta lleva al módulo correspondiente.

---

## Roles y permisos

| Módulo | Admin | Employee |
|--------|:-----:|:--------:|
| Panel de Inicio | ✅ | ✅ |
| Almacén Central (solo ver) | ✅ | ✅ |
| Almacén Central (editar/borrar) | ✅ | ❌ |
| Punto de Venta | ✅ | ✅ |
| Gestión de Lotes | ✅ | ❌ |
| Estadísticas | ✅ | ❌ |
| Catálogos (Casas, Categorías, Presentaciones, Proveedores, Usuarios) | ✅ | ❌ |
| Manual de Ayuda (contenido completo) | ✅ | ✅ (filtrado) |
| Configuración / Ajustes | ✅ | ✅ (solo ver perfil) |
| Notificaciones | ✅ | ✅ |
| Acerca de / Créditos | ✅ | ✅ |

---

## Capturas de pantalla

| Módulo | Vista |
|--------|-------|
| Login | _—pendiente—_ |
| Panel de Inicio | _—pendiente—_ |
| Almacén Central | _—pendiente—_ |
| Punto de Venta | _—pendiente—_ |
| Gestión de Lotes | _—pendiente—_ |
| Estadísticas | _—pendiente—_ |
| Configuración | _—pendiente—_ |

---

## Stack tecnológico

| Tecnología | Versión | Propósito |
|---|---|---|
| **Flutter** | >=3.5.0 | Framework UI multiplataforma (compilación nativa Windows) |
| **Dart** | >=3.5.0 | Lenguaje de programación |
| **Provider** | ^6.0.0 | Gestión de estado (patrón ChangeNotifier) |
| **GoRouter** | ^14.8.1 | Enrutamiento declarativo con transiciones animadas |
| **Dio** | ^5.7.0 | Cliente HTTP con interceptores, timeout y logging |
| **fl_chart** | ^0.69.0 | Gráficos de barras, pastel y radiales |
| **flutter_secure_storage** | ^9.2.4 | Almacenamiento cifrado de tokens JWT |
| **printing + pdf** | ^5.13.4 / ^3.11.1 | Generación e impresión de recibos y reportes |
| **image_picker** | ^1.2.1 | Selección de imágenes desde galería |
| **flutter_keyboard_shortcuts** | — | Atajos de teclado para escritorio |
| **mocktail** | ^1.0.4 | Mocks para tests unitarios y de widgets |

---

## Arquitectura

```
┌─────────────────────────────────────────────────────────┐
│                      Router (GoRouter)                    │
│        /  /inicio  /almacen  /ventas  /configuracion      │
└──────────────────────┬──────────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────────┐
│                     Screens (Views)                      │
│          dashboard, inicio, almacen, ventas, ...          │
│       Escuchan a controllers via context.watch<T>()       │
└──────────────────────┬──────────────────────────────────┘
                       │  Consumer / Consumer2 / Consumer3
┌──────────────────────▼──────────────────────────────────┐
│                  Controllers (ViewModel)                 │
│      ChangeNotifier que expone estado + métodos           │
│      almacen_controller, ventas_controller, ...           │
└──────────────────────┬──────────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────────┐
│                     Services (API)                       │
│     api_service.dart — métodos estáticos HTTP (Dio)      │
│     auth_service.dart — login/logout con JWT             │
└──────────────────────┬──────────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────────┐
│                   Backend (Node.js + MySQL)              │
│     https://farmabook.jonathanalarcon.qzz.io              │
└─────────────────────────────────────────────────────────┘
```

**Flujo de datos:**
1. El usuario interactúa con una **Screen** (Widget).
2. La Screen llama a un método del **Controller**.
3. El Controller ejecuta la lógica de negocio y llama a **ApiService**.
4. ApiService realiza la petición HTTP (con token JWT en header).
5. La respuesta se parsea y el Controller actualiza su estado.
6. `notifyListeners()` dispara la reconstrucción de la Screen.

---

## Estructura del proyecto

```
lib/
├── main.dart                     # Punto de entrada, providers y tema
├── controllers/                  # ChangeNotifiers (ViewModel)
│   ├── almacen_controller.dart
│   ├── config_controller.dart
│   ├── dashboard_controller.dart
│   ├── estadisticas_controller.dart
│   ├── inicio_controller.dart
│   ├── login_controller.dart
│   ├── lotes_controller.dart
│   ├── notificaciones_controller.dart
│   ├── usuarios_controller.dart
│   ├── ventas_controller.dart
│   └── categorias_controller.dart
├── models/
│   └── producto_model.dart        # Modelo de datos de producto
├── screens/                       # Pantallas de la aplicación
│   ├── login_screen.dart
│   ├── dashboard_screen.dart      # Scaffold principal con drawer
│   ├── inicio_screen.dart         # Panel de inicio
│   ├── almacen_screen.dart        # Almacén central
│   ├── ventas_screen.dart         # Punto de venta
│   ├── lotes_screen.dart          # Gestión de lotes
│   ├── estadisticas_screen.dart   # Estadísticas
│   ├── configuracion_screen.dart  # Ajustes del sistema
│   ├── categorias_screen.dart     # Catálogo de categorías
│   ├── casas_screen.dart          # Catálogo de casas farmacéuticas
│   ├── presentaciones_screen.dart # Catálogo de presentaciones
│   ├── proveedores_screen.dart    # Catálogo de proveedores
│   ├── usuarios_screen.dart       # Catálogo de usuarios
│   ├── manual_screen.dart         # Manual de ayuda
│   ├── forgot_password_screen.dart
│   ├── reset_password_screen.dart
│   └── verify_pin_screen.dart
├── services/                      # Comunicación HTTP
│   ├── api_service.dart           # Todos los endpoints REST
│   └── auth_service.dart          # Autenticación JWT
├── providers/
│   └── theme_provider.dart        # (eliminado, tema claro fijo)
├── router/
│   └── app_router.dart            # Definición de rutas
├── theme/
│   └── app_theme.dart             # Tema claro con paleta Rei
├── utils/
│   ├── app_logger.dart            # Logging estructurado
│   ├── global_error_handler.dart  # Manejo global de errores
│   ├── inventory_dialogs.dart     # Diálogos de inventario
│   ├── price_formatter.dart       # Formateo de moneda
│   └── user_session.dart          # Sesión del usuario (singleton)
└── widgets/                       # Componentes reutilizables
    ├── animations.dart            # Animaciones (AnimatedEntry, etc.)
    ├── premium_header.dart        # Header con notificaciones
    ├── shimmer_loading.dart       # Skeleton loading
    ├── keyboard_shortcuts.dart    # Atajos de teclado
    ├── error_display.dart         # Mensajes de error
    ├── almacen/
    │   ├── product_card.dart      # Tarjeta de producto
    │   └── batch_details_modal.dart # Modal de lotes
    └── ventas/
        ├── cart_section.dart
        ├── sales_results_grid.dart
        ├── sales_search_section.dart
        └── receipt_dialog.dart
```

---

## Rutas

| Ruta | Pantalla | Transición |
|------|----------|------------|
| `/login` | Login | — |
| `/forgot-password` | Recuperar contraseña | fade + slide |
| `/reset-password` | Restablecer contraseña | fade + slide |
| `/verify-pin` | Verificar PIN | fade + slide |
| `/inicio` | Dashboard principal | fade + slide |
| `/almacen` | Almacén Central | fade + slide |
| `/ventas` | Punto de Venta | fade + slide |
| `/lotes` | Gestión de Lotes | fade + slide |
| `/estadisticas` | Estadísticas | fade + slide |
| `/configuracion` | Configuración | fade + slide |
| `/manual` | Manual de Ayuda | fade + slide |
| `/categorias` | Catálogo Categorías | fade + slide |
| `/casas` | Catálogo Casas | fade + slide |
| `/presentaciones` | Catálogo Presentaciones | fade + slide |
| `/proveedores` | Catálogo Proveedores | fade + slide |
| `/usuarios` | Catálogo Usuarios | fade + slide |

Las transiciones usan `CustomTransitionPage` con fade y slide.

---

## Atajos de teclado

### Dashboard (globales)

| Tecla | Acción |
|-------|--------|
| `F1` | Abrir Manual de Ayuda |
| `Escape` | Volver a Inicio |
| `Ctrl+1` | Panel Inicio |
| `Ctrl+2` | Almacén Central |
| `Ctrl+3` | Punto de Venta |
| `Ctrl+4` | Gestión de Lotes |
| `Ctrl+5` | Estadísticas |

### Punto de Venta

| Tecla | Acción |
|-------|--------|
| `F2` | Enfocar campo de código de barras |
| `Escape` | Limpiar búsqueda / volver a búsqueda |
| `Ctrl+Enter` | Cobrar (procesar venta) |

### Login

| Tecla | Acción |
|-------|--------|
| `Enter` (en Usuario) | Saltar a Contraseña |
| `Enter` (en Contraseña) | Ejecutar inicio de sesión |

---

## API

- **Base URL**: `https://farmabook.jonathanalarcon.qzz.io`
- **Autenticación**: JWT vía header `Authorization: Bearer <token>`
- **Formato**: JSON (`Content-Type: application/json`)
- **Interceptor**: logging automático de peticiones y respuestas

### Endpoints principales

| Método | Endpoint | Propósito |
|--------|----------|-----------|
| `POST` | `/login` | Inicio de sesión |
| `GET` | `/users` | Listar usuarios |
| `POST` | `/users` | Crear usuario |
| `PATCH` | `/users/:id` | Actualizar usuario |
| `GET` | `/products` | Listar productos |
| `POST` | `/products` | Crear producto |
| `PATCH` | `/products/:id` | Actualizar producto |
| `DELETE` | `/products/:id` | Eliminar producto |
| `GET` | `/batches/product/:id` | Obtener lotes por producto |
| `POST` | `/batches` | Crear lote |
| `DELETE` | `/batches/:id` | Eliminar lote |
| `GET` | `/sales` | Historial de ventas |
| `POST` | `/sales` | Registrar venta |
| `GET` | `/analytics/dashboard` | KPIs del panel de inicio |
| `GET` | `/analytics/products/top` | Productos más vendidos |
| `GET` | `/analytics/report` | Reporte completo de estadísticas |
| `GET` | `/categories` | Listar categorías |
| `GET` | `/notifications` | Listar notificaciones |

---

## Build

### Requisitos

- Flutter SDK >=3.5.0
- Dart >=3.5.0
- Visual Studio 2022 con workload "Desarrollo para escritorio con C++"
- Git

### Compilación para Windows

```powershell
flutter clean
flutter pub get
flutter build windows --release
```

El ejecutable se genera en `build\windows\x64\runner\Release\`.

Para copiar al escritorio:
```powershell
robocopy "build\windows\x64\runner\Release" "C:\Users\...\Desktop\FarmaBook" /E
```

### Tests

```powershell
flutter test
```

Ejecuta tests unitarios y de widgets (32 tests actualmente).

---

## Desarrollo

### Convenciones

- **Estado**: Provider + ChangeNotifier (un controller por módulo).
- **UI**: Widgets stateless puros; solo los StatefulWidget necesarios para animaciones controladas.
- **API**: `api_service.dart` contiene todos los métodos HTTP como estáticos.
- **Rutas**: definidas en `router/app_router.dart` con GoRouter.
- **Estilo de código**: sin comentarios en el código; nombres descriptivos en inglés para variables/métodos.
- **Errores**: `ErrorDisplay` widget para mostrar errores; `global_error_handler.dart` para captura global.
- **Paleta de colores**: definida en `AppTheme` dentro de `theme/app_theme.dart` (inspiración Rei Ayanami).

### Añadir un nuevo módulo

1. Crear `screens/mi_modulo_screen.dart` con la UI.
2. Crear `controllers/mi_modulo_controller.dart` extendiendo `ChangeNotifier`.
3. Registrar el provider en `main.dart`.
4. Añadir la ruta en `router/app_router.dart`.
5. Agregar la entrada en el drawer de `dashboard_screen.dart`.
6. Implementar los llamados HTTP en `api_service.dart`.

---

## Créditos

Desarrollado por:

- **Cristian Rabelo**
- **Jonathan Alarcon**
- **Darwin Garcia**

---

*FarmaBook v1.0.0 — Sistema de Gestión Farmacéutica*
