# FarmaBook Flutter Project — Anchored Summary

## UI Architecture
- **State management**: Provider + ChangeNotifier
- **Routing**: GoRouter
- **Theme**: `AppTheme` (light/dark) with Rei Ayanami palette
- **Animations**: `AnimatedEntry`, `HoverScale`, `ParticleBackground` in `lib/widgets/animations.dart`
- **Shimmer loading**: `ShimmerList` in `lib/widgets/shimmer_loading.dart`

## Key Fixes (Session 2026-06-18)

### UserSession (`lib/utils/user_session.dart`)
- `_deepFindUser()` — searches for nested `usuario`/`user`/`data` objects
- `_firstNonEmpty()` — tries 7+ field name variants for email & role
- `_parseInt()` — handles both `int` and parsable `String` for `userId`
- `isDueno` — matches `dueño`, `admin`, `administrador`
- `isEmpleado` — matches `empleado`, `cajero`, `vendedor`
- `canEdit` — alias for `isDueno`

### Mis información personal dialog (`configuracion_screen.dart`)
- Redesigned with gradient header, animated scale entrance (`showGeneralDialog`)
- Shows: User ID, email, role, account type (Admin/Empleado)
- **Hidden from Empleado**: "Personal y Roles" section, Settings gear in header

### Empleado restrictions (hidden UI)
| Screen | Hidden from Empleado |
|--------|---------------------|
| Dashboard drawer | CATÁLOGOS expansion tile |
| Inicio | Settings gear icon |
| Config | "Personal y Roles" section |
| Proveedores | FAB, edit/delete buttons |
| Casas | FAB, edit/delete buttons |
| Presentaciones | FAB, edit/delete buttons |
| Categorías | FAB, edit/delete buttons |
| Usuarios | FAB, edit/delete buttons (screen itself inaccessible) |
| Almacén (product cards) | edit/delete overlay icons |

### Button shadow
- Hover shadow alpha reduced: `0.3` → `0.15` (both light & dark themes)

### Notification dialog (`dashboard_screen.dart`)
- New: `_AnimatedNotifDialog` — gradient header, animated item entrance via `_NotifItem`
- Items fade+slide in with staggered delay, show severity dot + colored border

### Screen improvements
- **Proveedores**: `AnimatedEntry` + `HoverScale` applied to cards
- **Casas**: `AnimatedEntry` + `HoverScale` applied to cards
- **Presentaciones**: `CircularProgressIndicator` → `ShimmerList`, `AnimatedEntry` + `HoverScale` on cards
- **Categorías**: Already had `_AnimatedCatCard` animation
- **Usuarios**: `AnimatedEntry` on user cards

## Keyboard Shortcuts (`lib/widgets/keyboard_shortcuts.dart`)
Atajos de teclado para escritorio (Windows/Linux/Mac):

### Dashboard (global)
| Tecla | Acción |
|-------|--------|
| `F1` | Abrir Manual de Ayuda |
| `Escape` | Volver a Inicio |
| `Ctrl+1` | Panel Inicio |
| `Ctrl+2` | Almacén Central |
| `Ctrl+3` | Punto de Venta |
| `Ctrl+4` | Gestión de Lotes |
| `Ctrl+5` | Estadísticas |

### Ventas (punto de venta)
| Tecla | Acción |
|-------|--------|
| `F2` | Enfocar campo de código de barras |
| `Escape` | Limpiar búsqueda / volver a búsqueda |
| `Ctrl+Enter` | Cobrar (procesar venta) |

## Build & Deploy
- `flutter build windows --release` → output in `build\windows\x64\runner\Release\`
- Release files copied to `C:\Users\Garci\Desktop\FarmaBook\`
