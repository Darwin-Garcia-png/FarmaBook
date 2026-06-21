import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../controllers/recovery_controller.dart';
import '../screens/ventas_screen.dart';
import '../screens/login_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/inicio_screen.dart';
import '../screens/almacen_screen.dart';
import '../screens/proveedores_screen.dart';
import '../screens/categorias_screen.dart';
import '../screens/presentaciones_screen.dart';
import '../screens/estadisticas_screen.dart';
import '../screens/configuracion_screen.dart';
import '../screens/usuarios_screen.dart';
import '../screens/manual_screen.dart';
import '../screens/forgot_password_screen.dart';
import '../screens/verify_pin_screen.dart';
import '../screens/reset_password_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Page<dynamic> _slidePage(Widget child) {
  return CustomTransitionPage(
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.04, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: child,
        ),
      );
    },
  );
}

final GoRouter appRouter = GoRouter(
  navigatorKey: navigatorKey,
  initialLocation: '/login',
  routes: <RouteBase>[
    GoRoute(
      path: '/login',
      name: 'login',
      pageBuilder: (context, state) => _slidePage(const LoginScreen()),
    ),
    GoRoute(
      path: '/forgot-password',
      pageBuilder: (context, state) => _slidePage(ForgotPasswordScreen(
        controller: state.extra as RecoveryController? ?? RecoveryController(),
      )),
    ),
    GoRoute(
      path: '/verify-pin',
      pageBuilder: (context, state) => _slidePage(VerifyPinScreen(
        controller: state.extra as RecoveryController,
      )),
    ),
    GoRoute(
      path: '/reset-password',
      pageBuilder: (context, state) => _slidePage(ResetPasswordScreen(
        controller: state.extra as RecoveryController,
      )),
    ),
    GoRoute(
      path: '/dashboard',
      name: 'dashboard',
      pageBuilder: (context, state) => _slidePage(const DashboardScreen()),
    ),
    GoRoute(
      path: '/ventas',
      pageBuilder: (context, state) => _slidePage(const VentasScreen()),
    ),
    GoRoute(
      path: '/inicio',
      pageBuilder: (context, state) => _slidePage(const InicioScreen()),
    ),
    GoRoute(
      path: '/almacen',
      pageBuilder: (context, state) => _slidePage(const AlmacenScreen()),
    ),
    GoRoute(
      path: '/proveedores',
      pageBuilder: (context, state) => _slidePage(const ProveedoresScreen()),
    ),
    GoRoute(
      path: '/categorias',
      pageBuilder: (context, state) => _slidePage(const CategoriasScreen()),
    ),
    GoRoute(
      path: '/presentaciones',
      pageBuilder: (context, state) => _slidePage(const PresentacionesScreen()),
    ),
    GoRoute(
      path: '/estadisticas',
      pageBuilder: (context, state) => _slidePage(const EstadisticasScreen()),
    ),
    GoRoute(
      path: '/configuracion',
      pageBuilder: (context, state) => _slidePage(const ConfigScreen()),
    ),
    GoRoute(
      path: '/usuarios',
      pageBuilder: (context, state) => _slidePage(const UsuariosScreen()),
    ),
    GoRoute(
      path: '/manual',
      pageBuilder: (context, state) => _slidePage(const ManualScreen()),
    ),
  ],
);
