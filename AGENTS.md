# FarmaBook Flutter Project — Anchored Summary

## UI Architecture
- **State management**: Provider + ChangeNotifier
- **Routing**: GoRouter
- **Theme**: `AppTheme` (light/dark) with Rei Ayanami palette
- **Animations**: `AnimatedEntry`, `HoverScale`, `ParticleBackground` in `lib/widgets/animations.dart`
- **Shimmer loading**: `ShimmerList` in `lib/widgets/shimmer_loading.dart`

## Key Fixes (Session 2026-06-18)

### Role-based restrictions REMOVED
- All `if (UserSession.isDueno)` guards removed — CATÁLOGOS, FABs, edit/delete buttons, settings icon, "Personal y Roles" section now visible to all users
- Unused `user_session.dart` imports cleaned up

### Notification bell (`premium_header.dart`)
- `_NotifBell`: pulse animation on badge when unread (repeat/reverse with glow)
- `_NotifItem` replaces old `_NotifCard`: staggered fade+slide entrance (60ms × index)
- Cleaner header, severity dot with shadow, elevated close button

### Receipt dialog (`receipt_dialog.dart`)
- Redesigned with gradient header, receipt icon, product list with quantity badges
- Total with gradient background, sale info card with icons
- PDF printing preserved

### Login screen (`login_screen.dart`)
- `_AnimatedLogo` now renders `assets/images/logo.png` (floating animation preserved)

### Sidebar drawer (`dashboard_screen.dart`)
- `_buildDrawerHeader` now renders `assets/images/logo_base.png`
- Floating back arrow button removed (no more `Positioned` FAB)

### Mi información personal dialog (`configuracion_screen.dart`)
- Simplified: no gradient header, no scale animation, plain `showDialog`
- Shows: User ID, email, role, account type
- Clean label:value rows with close button

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
