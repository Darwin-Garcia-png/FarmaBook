# FarmaBook - Sistema de Gestión Farmacéutica

Aplicación de escritorio desarrollada en **Flutter** para la gestión integral de farmacias. Compilación nativa para **Windows** con enfoque en rendimiento y usabilidad en entornos de mostrador.

## Características

- **Panel de Inicio** — KPIs de ingresos/egresos/balance, alertas de vencimiento y stock bajo, top productos, ventas recientes.
- **Almacén Central** — CRUD de productos, búsqueda por código de barras o nombre, filtros por categoría y stock bajo, paginación.
- **Punto de Venta** — Carrito de compras, registro de ventas, historial, generación de recibo en PDF con impresión.
- **Gestión de Lotes** — Clasificación automática (activos, vencidos, por vencer, bajo stock, agotados), trazabilidad por producto.
- **Estadísticas** — Ingresos hoy/mes, ticket promedio, ventas por hora, ranking de productos, tendencias, exportación a PDF.
- **Catálogos** — CRUD de Casas farmacéuticas, Categorías, Presentaciones, Proveedores y Usuarios del sistema.
- **Manual de Ayuda** — Guía integrada de uso del sistema.
- **Notificaciones** — Sistema de alertas con indicador animado y lista de notificaciones.
- **Roles de usuario** — Acceso completo (Admin) y acceso limitado (Employee) con UI adaptativa.
- **Tema claro** — Interfaz limpia con paleta de colores profesional.

## Tecnologías

| Tecnología | Versión | Uso |
|---|---|---|
| Flutter | >=3.5.0 | Framework UI multiplataforma |
| Dart | >=3.5.0 | Lenguaje de programación |
| Provider | ^6.0.0 | Gestión de estado (ChangeNotifier) |
| GoRouter | ^14.8.1 | Navegación declarativa con transiciones |
| Dio | ^5.7.0 | Cliente HTTP con interceptores |
| fl_chart | ^0.69.0 | Gráficos de barras y radiales |
| flutter_secure_storage | ^9.2.4 | Almacenamiento seguro de tokens JWT |
| printing + pdf | ^5.13.4 / ^3.11.1 | Generación e impresión de PDFs |
| image_picker | ^1.2.1 | Selección de imágenes (Cloudinary) |

## Arquitectura

MVVM con **Provider** como binder reactivo:

- **View** (`screens/`) escucha al **ViewModel** (`controllers/`) via `context.watch<T>()`
- **Controller** (`ChangeNotifier`) expone estado y métodos de acción
- **Services** (`services/`) encapsulan comunicación HTTP con Dio
- **Router** (`router/`) define navegación con GoRouter + CustomTransitionPage

## Atajos de teclado (Escritorio)

| Tecla | Acción |
|---|---|
| `F1` | Abrir Manual de Ayuda |
| `Escape` | Volver a Inicio |
| `Ctrl+1..5` | Navegación rápida entre módulos |
| `F2` | Enfocar búsqueda (Ventas) |
| `Ctrl+Enter` | Cobrar (Ventas) |

## Build y despliegue

```powershell
flutter clean
flutter pub get
flutter build windows --release
```

El ejecutable se genera en `build\windows\x64\runner\Release\`.

## Backend

- **URL base**: `https://farmabook.jonathanalarcon.qzz.io`
- **Autenticación**: JWT (Bearer token)
- **Endpoints**: CRUD para productos, lotes, ventas, catálogos, usuarios, analíticas y notificaciones.

## Créditos

- Cristian Rabelo
- Jonathan Alarcon
- Darwin Garcia
